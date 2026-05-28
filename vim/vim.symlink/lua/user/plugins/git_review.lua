local M = {}
local api = vim.api
local fn = vim.fn

local ns = api.nvim_create_namespace('git_review')
local VIRT_TEXT_MAX = 80  -- max chars for inline virtual text preview
local VIRT_TEXT_GAP = '        '  -- 8 spaces between code and annotation

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function git_root()
  local root = fn.systemlist('git rev-parse --show-toplevel 2>/dev/null')[1]
  if vim.v.shell_error ~= 0 or not root or root == '' then return nil end
  return root
end

local function relfile_from_buffer()
  -- Delegate to the existing vimscript function which already handles
  -- Diffview, Fugitive, and normal buffers.
  return fn.GitReviewFileFromBuffer()
end

local function get_context()
  local root = git_root()
  if not root then
    vim.notify('Not in a git repo', vim.log.levels.WARN)
    return nil, nil, nil
  end
  local relfile = relfile_from_buffer()
  if not relfile or relfile == '' then
    vim.notify('Cannot determine file path', vim.log.levels.WARN)
    return nil, nil, nil
  end
  local line = api.nvim_win_get_cursor(0)[1]
  return root, relfile, line
end

--- Return all raw comment lines for HEAD in this repo.
local function list_comments(root)
  return fn.systemlist('git -C ' .. fn.shellescape(root) .. ' review list HEAD 2>/dev/null')
end

local function list_comments_all(root)
  return fn.systemlist('git -C ' .. fn.shellescape(root) .. ' review list --all HEAD 2>/dev/null')
end

--- Decode \\n literals back to real newlines for display.
local function decode_newlines(s)
  return (s:gsub('\\n', '\n'))
end

--- Encode real newlines to \\n literals for single-line storage.
local function encode_newlines(s)
  return (s:gsub('\n', '\\n'))
end

--- Return all comment texts on a given file:line (with \\n decoded).
local function get_comments_at(root, relfile, line)
  local raw = list_comments(root)
  local pattern = '^' .. vim.pesc(relfile) .. ':' .. line .. ':%s*'
  local results = {}
  for _, c in ipairs(raw) do
    if c:match(pattern) then
      table.insert(results, decode_newlines((c:gsub(pattern, ''))))
    end
  end
  return results
end

--- Return the raw (not decoded) comment text for pattern matching in edit.
local function get_raw_comments_at(root, relfile, line)
  local raw = list_comments(root)
  local pattern = '^' .. vim.pesc(relfile) .. ':' .. line .. ':%s*'
  local results = {}
  for _, c in ipairs(raw) do
    if c:match(pattern) then
      table.insert(results, (c:gsub(pattern, '')))
    end
  end
  return results
end

--- Return synced comments (alias#N: ...) at a given file:line.
local function get_synced_comments_at(root, relfile, line)
  local comments = get_comments_at(root, relfile, line)
  local synced = {}
  for _, c in ipairs(comments) do
    local alias_post, text = c:match('^(%w+#%d+):%s*(.*)')
    if alias_post then
      table.insert(synced, { alias_post = alias_post, text = text, full = c })
    end
  end
  return synced
end

local function max_line_len(lines)
  local max = 0
  for _, l in ipairs(lines) do
    if #l > max then max = #l end
  end
  return max
end

local function short_path(relfile)
  -- Show just the filename for the title bar
  return relfile:match('[^/]+$') or relfile
end

local BUBBLE_WIDTH = 90

--- Close a floating window safely.
local function close_win(win)
  if win and api.nvim_win_is_valid(win) then
    api.nvim_win_close(win, true)
  end
  vim.cmd('stopinsert')
end

--- Compute the number of display lines when text wraps at a given width.
local function wrapped_height(lines, width)
  local h = 0
  for _, l in ipairs(lines) do
    h = h + math.max(1, math.ceil(#l / width))
  end
  return h
end

--- Apply common floating window options (wrap, linebreak, no hard-wrap).
local function style_bubble(win)
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].conceallevel = 2
  -- Prevent markdown filetype from inserting hard line breaks
  local buf = api.nvim_win_get_buf(win)
  vim.bo[buf].textwidth = 0
  vim.bo[buf].formatoptions = ''
end

--- Set up submit/cancel keymaps on a bubble buffer, including :q/:wq.
local function set_bubble_keymaps(buf, on_submit, on_cancel)
  local function submit()
    if on_submit then on_submit() end
  end
  local function cancel()
    if on_cancel then on_cancel() end
  end
  vim.keymap.set({ 'n', 'i' }, '<C-s>', submit, { buffer = buf, desc = 'Submit' })
  vim.keymap.set({ 'n', 'i' }, '<C-c>', cancel, { buffer = buf, desc = 'Cancel' })
  vim.keymap.set('n', '<Esc>', cancel, { buffer = buf, desc = 'Cancel' })
  vim.keymap.set('n', 'q', cancel, { buffer = buf, desc = 'Cancel' })
end

--- Apply per-prefix highlighting to a bubble buffer's content lines.
local function highlight_bubble_prefixes(buf)
  local bubble_ns = api.nvim_create_namespace('git_review_bubble')
  local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, line in ipairs(lines) do
    -- @claude-ai / @claude-ai#N (check before @claude — longer prefix first)
    local _, ai_end = line:find('^@claude%-ai#?%d*%s*')
    if ai_end and line:match('^@claude%-ai') then
      api.nvim_buf_set_extmark(buf, bubble_ns, i - 1, 0, {
        end_col = ai_end,
        hl_group = 'GitReviewClaudeAi',
      })
    elseif line:match('^@claude[#%s]') then
      local _, cl_end = line:find('^@claude#?%d*%s*')
      if cl_end then
        api.nvim_buf_set_extmark(buf, bubble_ns, i - 1, 0, {
          end_col = cl_end,
          hl_group = 'GitReviewClaude',
        })
      end
    else
      -- alias#N: marker at start of line (e.g., palashsb#11:, AutoSDE#10:)
      local _, alias_end = line:find('^%S+#%S+:%s*')
      if alias_end then
        api.nvim_buf_set_extmark(buf, bubble_ns, i - 1, 0, {
          end_col = alias_end,
          hl_group = 'GitReviewAlias',
        })
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Show comment bubble (,r)
-- ---------------------------------------------------------------------------

function M.show(opts)
  local root, relfile, line = get_context()
  if not root then return end

  local comments = get_comments_at(root, relfile, line)
  if #comments == 0 then
    vim.notify('No comment on this line.', vim.log.levels.INFO)
    return
  end

  local lines = {}
  for i, c in ipairs(comments) do
    if i > 1 then
      table.insert(lines, '')
      table.insert(lines, '---')
      table.insert(lines, '')
    end
    -- Split decoded multi-line comments into separate display lines
    for _, l in ipairs(vim.split(c, '\n')) do
      table.insert(lines, l)
    end
  end

  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = 'pandoc'
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'
  highlight_bubble_prefixes(buf)

  -- Auto-size: use wider bubble for long lines, taller for wrapped content
  local width = math.min(math.max(max_line_len(lines) + 4, 50), 90)
  local content_height = wrapped_height(lines, width - 2)
  local max_height = math.floor(vim.o.lines * 0.5)
  local height = math.min(content_height, max_height)
  height = math.max(height, 3)

  local enter = opts and opts.enter or false

  local win = api.nvim_open_win(buf, enter, {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
    title = ' Review Comment ',
    title_pos = 'center',
  })
  style_bubble(win)

  if enter then
    -- Scrollable mode: q/Esc to close
    vim.keymap.set('n', 'q', function() close_win(win) end, { buffer = buf })
    vim.keymap.set('n', '<Esc>', function() close_win(win) end, { buffer = buf })
    api.nvim_create_autocmd({ 'BufLeave' }, {
      buffer = buf,
      once = true,
      callback = function() close_win(win) end,
    })
  else
    -- Passive mode: auto-close on cursor move
    api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'BufLeave' }, {
      once = true,
      callback = function() close_win(win) end,
    })
  end
end

--- Show all branch comments at cursor line in scrollable bubble (,R)
function M.show_all()
  local root, relfile, line = get_context()
  if not root then return end

  local raw = list_comments_all(root)
  local pattern = '^' .. vim.pesc(relfile) .. ':' .. line .. ':%s*'
  local comments = {}
  for _, c in ipairs(raw) do
    if c:match(pattern) then
      table.insert(comments, decode_newlines((c:gsub(pattern, ''))))
    end
  end

  if #comments == 0 then
    vim.notify('No comments on this line (all commits).', vim.log.levels.INFO)
    return
  end

  local lines = {}
  for i, c in ipairs(comments) do
    if i > 1 then
      table.insert(lines, '')
      table.insert(lines, '---')
      table.insert(lines, '')
    end
    for _, l in ipairs(vim.split(c, '\n')) do
      table.insert(lines, l)
    end
  end

  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = 'pandoc'
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'
  highlight_bubble_prefixes(buf)

  local width = math.min(math.max(max_line_len(lines) + 4, 50), 90)
  local content_height = wrapped_height(lines, width - 2)
  local max_height = math.floor(vim.o.lines * 0.5)
  local height = math.min(content_height, max_height)
  height = math.max(height, 3)

  local win = api.nvim_open_win(buf, true, {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
    title = ' Review Comments (all commits) ',
    title_pos = 'center',
  })
  style_bubble(win)

  vim.keymap.set('n', 'q', function() close_win(win) end, { buffer = buf })
  vim.keymap.set('n', '<Esc>', function() close_win(win) end, { buffer = buf })
  api.nvim_create_autocmd({ 'BufLeave' }, {
    buffer = buf,
    once = true,
    callback = function() close_win(win) end,
  })
end

--- Show comment bubble in active/scrollable mode (,rs)
function M.show_scroll()
  M.show({ enter = true })
end

-- ---------------------------------------------------------------------------
-- Top-level comment bubble (,rt)
-- ---------------------------------------------------------------------------

function M.top_comment()
  local root = git_root()
  if not root then
    vim.notify('Not in a git repo', vim.log.levels.WARN)
    return
  end

  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = 'pandoc'
  vim.bo[buf].bufhidden = 'wipe'

  local win = api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = math.floor(vim.o.lines * 0.2),
    col = math.floor((vim.o.columns - BUBBLE_WIDTH) / 2),
    width = BUBBLE_WIDTH,
    height = 8,
    style = 'minimal',
    border = 'rounded',
    title = ' Top-Level Comment  <C-s> save ',
    title_pos = 'center',
  })
  style_bubble(win)

  vim.cmd('startinsert')

  set_bubble_keymaps(buf, function()
    local blines = api.nvim_buf_get_lines(buf, 0, -1, false)
    local msg = vim.trim(table.concat(blines, '\n'))
    if msg ~= '' then
      msg = encode_newlines(msg)
      fn.system(string.format(
        'git -C %s review comment -f TOP -l 0 -m %s',
        fn.shellescape(root),
        fn.shellescape(msg)
      ))
      vim.notify(' Top-level comment added.', vim.log.levels.INFO)
    end
    close_win(win)
  end, function()
    close_win(win)
  end)
end

-- ---------------------------------------------------------------------------
-- Add comment bubble (,rc)
-- ---------------------------------------------------------------------------

function M.comment()
  local root, relfile, line = get_context()
  if not root then return end

  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = 'pandoc'
  vim.bo[buf].bufhidden = 'wipe'

  local title = string.format(' Comment %s:%d  <C-s> save ', short_path(relfile), line)
  local win = api.nvim_open_win(buf, true, {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = BUBBLE_WIDTH,
    height = 5,
    style = 'minimal',
    border = 'rounded',
    title = title,
    title_pos = 'center',
  })
  style_bubble(win)

  vim.cmd('startinsert')

  set_bubble_keymaps(buf, function()
    local blines = api.nvim_buf_get_lines(buf, 0, -1, false)
    local msg = vim.trim(table.concat(blines, '\n'))
    if msg ~= '' then
      msg = encode_newlines(msg)
      fn.system(string.format(
        'git -C %s review comment -f %s -l %d -m %s',
        fn.shellescape(root),
        fn.shellescape(relfile),
        line,
        fn.shellescape(msg)
      ))
      vim.notify(' Added.', vim.log.levels.INFO)
      M.place_virtual_text()
    end
    close_win(win)
  end, function()
    close_win(win)
  end)
end

-- ---------------------------------------------------------------------------
-- Edit comment bubble (,re)
-- ---------------------------------------------------------------------------

function M.edit()
  local root, relfile, line = get_context()
  if not root then return end

  local raw_comments = get_raw_comments_at(root, relfile, line)
  if #raw_comments == 0 then
    vim.notify('No comment on this line. Use ,rc to add one.', vim.log.levels.WARN)
    return
  end

  -- If multiple comments, let user pick which to edit
  -- We track both raw (for pattern matching) and decoded (for display)
  local function open_edit_bubble(existing_raw)
    local existing_decoded = decode_newlines(existing_raw)
    local display_lines = vim.split(existing_decoded, '\n')

    local buf = api.nvim_create_buf(false, true)
    vim.bo[buf].filetype = 'pandoc'
    vim.bo[buf].bufhidden = 'wipe'
    api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)

    local edit_height = math.max(3, wrapped_height(display_lines, BUBBLE_WIDTH - 2) + 2)
    local max_edit_height = math.floor(vim.o.lines * 0.5)
    local win = api.nvim_open_win(buf, true, {
      relative = 'cursor',
      row = 1,
      col = 0,
      width = BUBBLE_WIDTH,
      height = math.min(edit_height, max_edit_height),
      style = 'minimal',
      border = 'rounded',
      title = ' Edit Comment (empty to delete)  <C-s> save ',
      title_pos = 'center',
    })
    style_bubble(win)

    -- Place cursor at end of last line and enter insert mode
    api.nvim_win_set_cursor(win, { #display_lines, #display_lines[#display_lines] })
    vim.cmd('startinsert!')

    set_bubble_keymaps(buf, function()
      local blines = api.nvim_buf_get_lines(buf, 0, -1, false)
      local new_msg = vim.trim(table.concat(blines, '\n'))
      local new_encoded = encode_newlines(new_msg)

      -- Manipulate git notes directly (same logic as GitReviewEdit)
      local sha = vim.trim(fn.system('git -C ' .. fn.shellescape(root) .. ' rev-parse HEAD'))
      local notes = fn.systemlist(
        'git -C ' .. fn.shellescape(root) .. ' notes --ref=refs/notes/reviews show ' .. sha .. ' 2>/dev/null'
      )
      local pattern = '^' .. vim.pesc(relfile) .. ':' .. line .. ':%s*' .. vim.pesc(existing_raw)
      local updated = {}
      for _, n in ipairs(notes) do
        if n:match(pattern) then
          if new_encoded ~= '' then
            table.insert(updated, relfile .. ':' .. line .. ': ' .. new_encoded)
          end
          -- else: drop line (delete)
        else
          table.insert(updated, n)
        end
      end

      if #updated == 0 then
        fn.system('git -C ' .. fn.shellescape(root)
          .. ' notes --ref=refs/notes/reviews remove ' .. sha .. ' 2>/dev/null')
      else
        fn.system('git -C ' .. fn.shellescape(root)
          .. ' notes --ref=refs/notes/reviews add -f -m '
          .. fn.shellescape(table.concat(updated, '\n')) .. ' ' .. sha)
      end

      vim.notify(new_msg == '' and ' Deleted.' or ' Updated.', vim.log.levels.INFO)
      M.place_virtual_text()
      close_win(win)
    end, function()
      close_win(win)
    end)
  end

  if #raw_comments == 1 then
    open_edit_bubble(raw_comments[1])
  else
    vim.ui.select(raw_comments, {
      prompt = 'Edit which comment?',
      format_item = function(item) return decode_newlines(item):sub(1, 70) end,
    }, function(choice)
      if choice then open_edit_bubble(choice) end
    end)
  end
end

-- ---------------------------------------------------------------------------
-- Delete comment (,rd)
-- ---------------------------------------------------------------------------

function M.delete()
  local root, relfile, line = get_context()
  if not root then return end

  local raw_comments = get_raw_comments_at(root, relfile, line)
  if #raw_comments == 0 then
    vim.notify('No comment on this line.', vim.log.levels.WARN)
    return
  end

  local function do_delete(target_raw)
    local sha = vim.trim(fn.system('git -C ' .. fn.shellescape(root) .. ' rev-parse HEAD'))
    local notes = fn.systemlist(
      'git -C ' .. fn.shellescape(root) .. ' notes --ref=refs/notes/reviews show ' .. sha .. ' 2>/dev/null'
    )
    local pattern = '^' .. vim.pesc(relfile) .. ':' .. line .. ':%s*' .. vim.pesc(target_raw)
    local updated = {}
    for _, n in ipairs(notes) do
      if not n:match(pattern) then
        table.insert(updated, n)
      end
    end

    if #updated == 0 then
      fn.system('git -C ' .. fn.shellescape(root)
        .. ' notes --ref=refs/notes/reviews remove ' .. sha .. ' 2>/dev/null')
    else
      fn.system('git -C ' .. fn.shellescape(root)
        .. ' notes --ref=refs/notes/reviews add -f -m '
        .. fn.shellescape(table.concat(updated, '\n')) .. ' ' .. sha)
    end

    vim.notify(' Deleted.', vim.log.levels.INFO)
    M.place_virtual_text()
  end

  if #raw_comments == 1 then
    do_delete(raw_comments[1])
  else
    vim.ui.select(raw_comments, {
      prompt = 'Delete which comment?',
      format_item = function(item) return decode_newlines(item):sub(1, 70) end,
    }, function(choice)
      if choice then do_delete(choice) end
    end)
  end
end

-- ---------------------------------------------------------------------------
-- Reply bubble (,rr)
-- ---------------------------------------------------------------------------

function M.reply()
  local root, relfile, line = get_context()
  if not root then return end

  local synced = get_synced_comments_at(root, relfile, line)
  if #synced == 0 then
    vim.notify('No synced comment to reply to on this line.', vim.log.levels.WARN)
    return
  end

  local function open_reply_bubble(target)
    local buf = api.nvim_create_buf(false, true)
    vim.bo[buf].filetype = 'pandoc'
    vim.bo[buf].bufhidden = 'wipe'

    local lines = {}
    local quote_parts = vim.split(target.text, '\n')
    lines[1] = '> **' .. target.alias_post .. ':** ' .. quote_parts[1]
    for i = 2, #quote_parts do
      table.insert(lines, '> ' .. quote_parts[i])
    end
    table.insert(lines, '')
    table.insert(lines, '---')
    table.insert(lines, '')
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    local title = string.format(' Reply to %s  <C-s> save ', target.alias_post)
    local quote_height = wrapped_height(lines, BUBBLE_WIDTH - 2)
    local reply_height = quote_height + 4  -- quote lines + reply area
    local win = api.nvim_open_win(buf, true, {
      relative = 'cursor',
      row = 1,
      col = 0,
      width = BUBBLE_WIDTH,
      height = math.min(reply_height, 15),
      style = 'minimal',
      border = 'rounded',
      title = title,
      title_pos = 'center',
    })
    style_bubble(win)

    api.nvim_win_set_cursor(win, { #lines, 0 })
    vim.cmd('startinsert')

    set_bubble_keymaps(buf, function()
      local all_lines = api.nvim_buf_get_lines(buf, 0, -1, false)
      local reply_lines = {}
      local past_divider = false
      for _, l in ipairs(all_lines) do
        if past_divider then
          table.insert(reply_lines, l)
        elseif l:match('^%-%-%-') then
          past_divider = true
        end
      end
      local msg = vim.trim(table.concat(reply_lines, '\n'))
      msg = encode_newlines(msg)
      if msg ~= '' then
        local reply_msg = '@reply ' .. target.alias_post .. ': ' .. msg
        fn.system(string.format(
          'git -C %s review comment -f %s -l %d -m %s',
          fn.shellescape(root),
          fn.shellescape(relfile),
          line,
          fn.shellescape(reply_msg)
        ))
        vim.notify(' Reply added.', vim.log.levels.INFO)
        M.place_virtual_text()
      end
      close_win(win)
    end, function()
      close_win(win)
    end)
  end

  if #synced == 1 then
    open_reply_bubble(synced[1])
  else
    vim.ui.select(synced, {
      prompt = 'Reply to which comment?',
      format_item = function(item) return item.alias_post .. ': ' .. item.text:sub(1, 60) end,
    }, function(choice)
      if choice then open_reply_bubble(choice) end
    end)
  end
end

-- ---------------------------------------------------------------------------
-- Ask Claude bubble (,ra)
-- ---------------------------------------------------------------------------

function M.ask()
  local root, relfile, line = get_context()
  if not root then return end

  -- target = { label = display label, text = comment text }
  local function open_ask_bubble(target)
    local buf = api.nvim_create_buf(false, true)
    vim.bo[buf].filetype = 'pandoc'
    vim.bo[buf].bufhidden = 'wipe'

    local lines
    local title
    if target then
      lines = {}
      local quote_parts = vim.split(target.text, '\n')
      if target.label ~= '' then
        lines[1] = '> **' .. target.label .. ':** ' .. quote_parts[1]
      else
        lines[1] = '> ' .. quote_parts[1]
      end
      for i = 2, #quote_parts do
        table.insert(lines, '> ' .. quote_parts[i])
      end
      table.insert(lines, '')
      table.insert(lines, '---')
      table.insert(lines, '')
      if target.label ~= '' then
        title = string.format(' @claude re: %s  <C-s> save ', target.label)
      else
        title = string.format(' @claude %s:%d  <C-s> save ', short_path(relfile), line)
      end
    else
      lines = { '' }
      title = string.format(' @claude %s:%d  <C-s> save ', short_path(relfile), line)
    end
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    local start_row = target and #lines or 1
    local quote_h = target and wrapped_height(lines, BUBBLE_WIDTH - 2) or 0
    local win_height = target and math.min(quote_h + 4, 15) or 5

    local win = api.nvim_open_win(buf, true, {
      relative = 'cursor',
      row = 1,
      col = 0,
      width = BUBBLE_WIDTH,
      height = win_height,
      style = 'minimal',
      border = 'rounded',
      title = title,
      title_pos = 'center',
    })
    style_bubble(win)

    api.nvim_win_set_cursor(win, { start_row, 0 })
    vim.cmd('startinsert')

    set_bubble_keymaps(buf, function()
      local all_lines = api.nvim_buf_get_lines(buf, 0, -1, false)
      local msg_lines
      if target then
        msg_lines = {}
        local past_divider = false
        for _, l in ipairs(all_lines) do
          if past_divider then
            table.insert(msg_lines, l)
          elseif l:match('^%-%-%-') then
            past_divider = true
          end
        end
      else
        msg_lines = all_lines
      end
      local msg = vim.trim(table.concat(msg_lines, '\n'))
      msg = encode_newlines(msg)
      if msg ~= '' then
        -- Auto-number: count existing @claude/@claude#N entries on this line
        local existing = get_comments_at(root, relfile, line)
        local claude_count = 0
        for _, c in ipairs(existing) do
          if c:match('^@claude%-ai[#%s]') or c:match('^@claude[#%s]') then
            claude_count = claude_count + 1
          end
        end
        -- First @claude has no number; 2nd exchange onwards gets #N
        -- Each exchange = 1 @claude + 1 @claude-ai, so round = floor(count/2) + 1
        local round = math.floor(claude_count / 2) + 1
        local prefix
        if not target or target.label == '' then
          prefix = round > 1 and ('@claude#' .. round .. ' ') or '@claude '
        else
          local tag = round > 1 and ('@claude#' .. round .. ' ') or '@claude '
          prefix = tag .. target.label .. ': '
        end
        fn.system(string.format(
          'git -C %s review comment -f %s -l %d -m %s',
          fn.shellescape(root),
          fn.shellescape(relfile),
          line,
          fn.shellescape(prefix .. msg)
        ))
        vim.notify(' @claude note added.', vim.log.levels.INFO)
        M.place_virtual_text()
      end
      close_win(win)
    end, function()
      close_win(win)
    end)
  end

  -- Quote all comments on this line as context, then let user type below.
  local all_comments = get_comments_at(root, relfile, line)
  if #all_comments > 0 then
    local full_text = table.concat(all_comments, '\n\n')
    open_ask_bubble({ label = '', text = full_text })
  else
    open_ask_bubble(nil)
  end
end

-- ---------------------------------------------------------------------------
-- Navigation: jump to next/prev comment, list current file
-- ---------------------------------------------------------------------------

--- Return sorted list of line numbers with comments in current file.
local function get_comment_lines_in_file(root, relfile)
  local raw = list_comments(root)
  local fpat = '^' .. vim.pesc(relfile) .. ':(%d+):'
  local lines_set = {}
  for _, c in ipairs(raw) do
    local lnum = c:match(fpat)
    if lnum then lines_set[tonumber(lnum)] = true end
  end
  local sorted = {}
  for lnum in pairs(lines_set) do
    table.insert(sorted, lnum)
  end
  table.sort(sorted)
  return sorted
end

--- Jump to next comment in current buffer (,rn)
function M.next_comment()
  local root = git_root()
  if not root then return end
  local relfile = relfile_from_buffer()
  if not relfile or relfile == '' then return end

  local lines = get_comment_lines_in_file(root, relfile)
  if #lines == 0 then
    vim.notify('No comments in this file.', vim.log.levels.INFO)
    return
  end

  local cursor = api.nvim_win_get_cursor(0)[1]
  for _, lnum in ipairs(lines) do
    if lnum > cursor then
      api.nvim_win_set_cursor(0, { lnum, 0 })
      M.show()
      return
    end
  end
  vim.notify('No more comments below.', vim.log.levels.INFO)
end

--- Jump to previous comment in current buffer ([r)
function M.prev_comment()
  local root = git_root()
  if not root then return end
  local relfile = relfile_from_buffer()
  if not relfile or relfile == '' then return end

  local lines = get_comment_lines_in_file(root, relfile)
  if #lines == 0 then
    vim.notify('No comments in this file.', vim.log.levels.INFO)
    return
  end

  local cursor = api.nvim_win_get_cursor(0)[1]
  for i = #lines, 1, -1 do
    if lines[i] < cursor then
      api.nvim_win_set_cursor(0, { lines[i], 0 })
      M.show()
      return
    end
  end
  vim.notify('No more comments above.', vim.log.levels.INFO)
end

--- List comments for current file only in quickfix (,rf)
function M.list_file()
  local root = git_root()
  if not root then return end
  local relfile = relfile_from_buffer()
  if not relfile or relfile == '' then return end

  local raw = list_comments(root)
  local fpat = '^' .. vim.pesc(relfile) .. ':(%d+):%s*(.*)'
  local qf = {}
  for _, c in ipairs(raw) do
    local lnum, text = c:match(fpat)
    if lnum then
      table.insert(qf, {
        filename = root .. '/' .. relfile,
        lnum = tonumber(lnum),
        text = decode_newlines(text),
      })
    end
  end

  if #qf == 0 then
    vim.notify('No comments in this file.', vim.log.levels.INFO)
  else
    vim.fn.setqflist(qf)
    vim.cmd('copen')
  end
end

-- ---------------------------------------------------------------------------
-- Virtual text annotations (replaces sign-based gutter markers)
-- ---------------------------------------------------------------------------

--- Place inline virtual text at end of each commented line in the current buffer.
--- In diff view, annotations only appear on the right (new code) pane.
function M.place_virtual_text()
  local bufnr = api.nvim_get_current_buf()

  -- Clear previous virtual text for this buffer
  api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  -- In diff view, skip the left (old code) pane
  if vim.wo.diff then
    local winnr = fn.winnr()
    local total = fn.winnr('$')
    if winnr <= math.floor(total / 2) then return end
  end

  local root = git_root()
  if not root then return end
  local relfile = relfile_from_buffer()
  if not relfile or relfile == '' then return end

  local raw = list_comments(root)
  local fpat = '^' .. vim.pesc(relfile) .. ':(%d+):%s*(.*)'

  -- Group comments by line number
  local by_line = {}
  for _, c in ipairs(raw) do
    local lnum, text = c:match(fpat)
    if lnum then
      lnum = tonumber(lnum)
      if not by_line[lnum] then by_line[lnum] = {} end
      table.insert(by_line[lnum], decode_newlines(text))
    end
  end

  for lnum, comments in pairs(by_line) do
    -- Build two-tone virtual text chunks: [gap + arrow] [prefix] [: text]
    local first = comments[1]:gsub('\n', ' ')
    local alias, rest, prefix_hl
    -- Check @claude-ai / @claude-ai#N before @claude (longer prefix first)
    local ai_tag = first:match('^(@claude%-ai#?%d*)%s')
    local cl_tag = not ai_tag and first:match('^(@claude#?%d*)%s')
    if ai_tag then
      alias = ai_tag
      rest = first:sub(#ai_tag + 1):match('^%s*(.*)')
      prefix_hl = 'GitReviewClaudeAi'
    elseif cl_tag then
      alias = cl_tag
      rest = first:sub(#cl_tag + 1):match('^%s*(.*)')
      prefix_hl = 'GitReviewClaude'
    else
      alias, rest = first:match('^(%w+#%S+):%s*(.*)')
      prefix_hl = 'GitReviewAlias'
    end
    if not alias then
      -- No alias prefix (user comment or first-pass) — single highlight
      alias = nil
      rest = first
    end

    -- Truncate text
    local suffix = ''
    if #comments > 1 then
      suffix = string.format(' (+%d more)', #comments - 1)
    end
    local max_text = VIRT_TEXT_MAX - #suffix
    if #rest > max_text then
      rest = rest:sub(1, max_text - 3) .. '...'
    end
    rest = rest .. suffix

    local chunks = {}
    table.insert(chunks, { VIRT_TEXT_GAP .. '→ ', 'GitReviewArrow' })
    if alias then
      -- alias#N gets colon suffix; @claude/@claude-ai do not
      local sep = prefix_hl == 'GitReviewAlias' and ': ' or ' '
      table.insert(chunks, { alias .. sep, prefix_hl or 'GitReviewAlias' })
    end
    table.insert(chunks, { rest, 'GitReviewText' })

    -- Place virtual text at end of line
    local line_count = api.nvim_buf_line_count(bufnr)
    if lnum >= 1 and lnum <= line_count then
      api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, 0, {
        virt_text = chunks,
        virt_text_pos = 'eol',
        hl_mode = 'combine',
        sign_text = '»',
        sign_hl_group = 'GitReviewArrow',
      })
    end
  end
end

-- ---------------------------------------------------------------------------
-- Setup
-- ---------------------------------------------------------------------------

local function set_highlights()
  if vim.o.termguicolors then
    api.nvim_set_hl(0, 'GitReviewArrow', { fg = '#2aa198', italic = true })
    api.nvim_set_hl(0, 'GitReviewAlias', { fg = '#2aa198', italic = true })
    api.nvim_set_hl(0, 'GitReviewText', { fg = '#2aa198', italic = true })
    api.nvim_set_hl(0, 'GitReviewClaude', { fg = '#cb4b16', bold = true, italic = true })    -- orange: user @claude
    api.nvim_set_hl(0, 'GitReviewClaudeAi', { fg = '#6c71c4', bold = true, italic = true }) -- violet: @claude-ai reply
  else
    api.nvim_set_hl(0, 'GitReviewArrow', { ctermfg = 37, italic = true })
    api.nvim_set_hl(0, 'GitReviewAlias', { ctermfg = 37, italic = true })
    api.nvim_set_hl(0, 'GitReviewText', { ctermfg = 37, italic = true })
    api.nvim_set_hl(0, 'GitReviewClaude', { ctermfg = 166, bold = true, italic = true })    -- orange
    api.nvim_set_hl(0, 'GitReviewClaudeAi', { ctermfg = 133, bold = true, italic = true })  -- violet
  end
end

function M.setup()
  -- Set highlights now and re-apply after colorscheme changes
  set_highlights()
  api.nvim_create_autocmd('ColorScheme', {
    pattern = '*',
    callback = set_highlights,
  })

  -- Replace sign-based markers with virtual text annotations
  api.nvim_create_autocmd('BufEnter', {
    pattern = '*',
    callback = function()
      M.place_virtual_text()
    end,
  })
end

return M
