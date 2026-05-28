local M = {}

-- Configuration
local VINEFLOWER_PATH = vim.fn.expand("~/.java/vineflower-1.11.1.jar")
local CACHE_DIR = vim.fn.expand("~/.cache/nvim/jar-decompile")
local TEMP_DIR = vim.fn.expand("/tmp/nvim-jar-decompile")

-- Ensure directories exist
local function ensure_dir(path)
    if vim.fn.isdirectory(path) == 0 then
        vim.fn.mkdir(path, "p")
    end
end

-- Generate cache key from jar path and internal path
local function generate_cache_key(jar_path, internal_path)
    local combined = jar_path .. "!" .. internal_path
    return vim.fn.sha256(combined)
end

-- Parse jar:// URL
local function parse_jar_url(url)
    -- Remove jar:// prefix
    local path = url:gsub("^jar://", "")

    -- Split on !/ to separate jar path and internal path
    local jar_path, internal_path = path:match("^(.-)!/(.+)$")

    if not jar_path or not internal_path then
        return nil, "Invalid jar URL format"
    end

    return jar_path, internal_path
end

-- Check if file exists and get modification time
local function get_file_mtime(filepath)
    local stat = vim.loop.fs_stat(filepath)
    return stat and stat.mtime.sec or 0
end

-- Extract class file from jar
local function extract_class_file(jar_path, internal_path, output_path)
    local cmd = string.format("unzip -p '%s' '%s' > '%s'", jar_path, internal_path, output_path)
    local result = vim.fn.system(cmd)
    local exit_code = vim.v.shell_error

    if exit_code ~= 0 then
        return false, "Failed to extract class file: " .. result
    end

    -- Check if file was actually created and has content
    if vim.fn.filereadable(output_path) == 0 or vim.fn.getfsize(output_path) == 0 then
        return false, "Extracted class file is empty or doesn't exist"
    end

    return true, nil
end

-- Decompile class file using Vineflower
local function decompile_class_file(class_file_path, output_dir)
    ensure_dir(output_dir)

    local cmd = string.format("java -jar '%s' '%s' '%s'", VINEFLOWER_PATH, class_file_path, output_dir)
    local result = vim.fn.system(cmd)
    local exit_code = vim.v.shell_error

    if exit_code ~= 0 then
        return false, "Vineflower decompilation failed: " .. result
    end

    return true, nil
end

-- Find decompiled file in output directory (supports both .java and .kt)
local function find_decompiled_file(output_dir, original_class_name)
    -- Vineflower creates .java files for Java classes and .kt files for Kotlin classes
    local base_name = original_class_name:gsub("%.class$", "")

    -- Check for Kotlin file first
    local kt_file = output_dir .. "/" .. base_name .. ".kt"
    if vim.fn.filereadable(kt_file) == 1 then
        return kt_file, "kotlin"
    end

    -- Check for Java file
    local java_file = output_dir .. "/" .. base_name .. ".java"
    if vim.fn.filereadable(java_file) == 1 then
        return java_file, "java"
    end

    -- Fallback: search for any .kt or .java file in the directory
    local kt_files = vim.fn.glob(output_dir .. "/*.kt", false, true)
    if #kt_files > 0 then
        return kt_files[1], "kotlin"
    end

    local java_files = vim.fn.glob(output_dir .. "/*.java", false, true)
    if #java_files > 0 then
        return java_files[1], "java"
    end

    return nil, nil
end

-- Get cached decompiled file if valid
local function get_cached_file(cache_key, jar_path)
    -- Check for both .kt and .java cached files
    local cache_kt_file = CACHE_DIR .. "/" .. cache_key .. ".kt"
    local cache_java_file = CACHE_DIR .. "/" .. cache_key .. ".java"
    local cache_info_file = CACHE_DIR .. "/" .. cache_key .. ".info"

    local cache_file = nil
    local file_type = nil

    if vim.fn.filereadable(cache_kt_file) == 1 then
        cache_file = cache_kt_file
        file_type = "kotlin"
    elseif vim.fn.filereadable(cache_java_file) == 1 then
        cache_file = cache_java_file
        file_type = "java"
    end

    if not cache_file or vim.fn.filereadable(cache_info_file) == 0 then
        return nil, nil
    end

    -- Check if cache is still valid (jar file hasn't been modified)
    local cache_info = vim.fn.readfile(cache_info_file)
    if #cache_info == 0 then
        return nil, nil
    end

    local cached_mtime = tonumber(cache_info[1])
    local current_mtime = get_file_mtime(jar_path)

    if cached_mtime and current_mtime and cached_mtime >= current_mtime then
        return cache_file, file_type
    end

    return nil, nil
end

-- Save decompiled file to cache
local function save_to_cache(cache_key, source_file_path, file_type, jar_path)
    ensure_dir(CACHE_DIR)

    local extension = file_type == "kotlin" and ".kt" or ".java"
    local cache_file = CACHE_DIR .. "/" .. cache_key .. extension
    local cache_info_file = CACHE_DIR .. "/" .. cache_key .. ".info"

    -- Copy decompiled file to cache
    vim.fn.system(string.format("cp '%s' '%s'", source_file_path, cache_file))

    -- Save jar modification time
    local jar_mtime = get_file_mtime(jar_path)
    vim.fn.writefile({ tostring(jar_mtime) }, cache_info_file)

    return cache_file
end

-- Clean up temporary files
local function cleanup_temp_files(temp_dir)
    if vim.fn.isdirectory(temp_dir) == 1 then
        vim.fn.system(string.format("rm -rf '%s'", temp_dir))
    end
end

-- Main decompilation function
local function decompile_jar_class(jar_path, internal_path)
    -- Check if jar file exists
    if vim.fn.filereadable(jar_path) == 0 then
        return nil, nil, "JAR file not found: " .. jar_path
    end

    -- Check if Vineflower exists
    if vim.fn.filereadable(VINEFLOWER_PATH) == 0 then
        return nil, nil, "Vineflower not found at: " .. VINEFLOWER_PATH
    end

    -- Generate cache key
    local cache_key = generate_cache_key(jar_path, internal_path)

    -- Check cache first
    local cached_file, file_type = get_cached_file(cache_key, jar_path)
    if cached_file then
        return cached_file, file_type, nil
    end

    -- Create temporary directory for this operation
    local temp_operation_dir = TEMP_DIR .. "/" .. cache_key
    ensure_dir(temp_operation_dir)

    local class_file_path = temp_operation_dir .. "/temp.class"
    local decompile_output_dir = temp_operation_dir .. "/output"

    -- Extract class file from jar
    local success, err = extract_class_file(jar_path, internal_path, class_file_path)
    if not success then
        cleanup_temp_files(temp_operation_dir)
        return nil, nil, err
    end

    -- Decompile class file
    success, err = decompile_class_file(class_file_path, decompile_output_dir)
    if not success then
        cleanup_temp_files(temp_operation_dir)
        return nil, nil, err
    end

    -- Find decompiled file
    local class_name = internal_path:match("([^/]+)$") or "Unknown.class"
    local decompiled_file, detected_type = find_decompiled_file(decompile_output_dir, class_name)
    if not decompiled_file then
        cleanup_temp_files(temp_operation_dir)
        return nil, nil, "Decompiled file not found"
    end

    -- Save to cache
    local cached_file_path = save_to_cache(cache_key, decompiled_file, detected_type, jar_path)

    -- Cleanup temporary files
    cleanup_temp_files(temp_operation_dir)

    return cached_file_path, detected_type, nil
end

-- Handle jar:// URL buffer read
function M.handle_jar_buffer()
    local url = vim.fn.expand("<afile>")

    -- Get the current buffer number at the start
    local target_bufnr = vim.fn.bufnr()

    -- Parse jar URL
    local jar_path, internal_path = parse_jar_url(url)
    if not jar_path then
        vim.api.nvim_buf_set_lines(target_bufnr, 0, -1, false, {
            "Error: " .. (internal_path or "Invalid jar URL format"),
            "",
            "Expected format: jar:///path/to/file.jar!/package/Class.class",
            "Got: " .. url
        })
        return
    end

    -- Show loading message
    vim.api.nvim_buf_set_lines(target_bufnr, 0, -1, false, {
        "Decompiling class file...",
        "JAR: " .. jar_path,
        "Class: " .. internal_path,
        "",
        "Please wait..."
    })

    -- Force redraw to show loading message
    vim.cmd("redraw")

    -- Decompile asynchronously to avoid blocking
    vim.defer_fn(function()
        local decompiled_file, file_type, err = decompile_jar_class(jar_path, internal_path)

        if err then
            vim.api.nvim_buf_set_lines(target_bufnr, 0, -1, false, {
                "Decompilation Error:",
                "",
                err,
                "",
                "JAR: " .. jar_path,
                "Class: " .. internal_path
            })
            vim.api.nvim_buf_set_option(target_bufnr, "filetype", "text")
        else
            -- Read decompiled file content
            local content = vim.fn.readfile(decompiled_file)

            -- Set buffer content
            vim.api.nvim_buf_set_lines(target_bufnr, 0, -1, false, content)

            -- Set appropriate options based on file type using buffer number
            if file_type == "kotlin" then
                vim.api.nvim_buf_set_option(target_bufnr, "filetype", "kotlin")
            else
                vim.api.nvim_buf_set_option(target_bufnr, "filetype", "java")
            end

            vim.api.nvim_buf_set_option(target_bufnr, "readonly", true)
            vim.api.nvim_buf_set_option(target_bufnr, "modifiable", false)
            vim.api.nvim_buf_set_option(target_bufnr, "buftype", "nowrite")

            -- Set buffer name to something meaningful
            local class_name = internal_path:match("([^/]+)%.class$") or "Unknown"
            local extension = file_type == "kotlin" and ".kt" or ".java"
            vim.api.nvim_buf_set_name(target_bufnr, "jar://" .. class_name .. extension)
        end

        -- Force redraw and update
        vim.cmd("redraw!")
    end, 100)
end

-- Manual command to open jar:// URLs
function M.open_jar_url(url)
    -- Create a new buffer
    vim.cmd("enew")

    -- Set the buffer name to the jar URL to trigger our autocmd
    vim.api.nvim_buf_set_name(0, url)

    -- Manually trigger the handler
    M.handle_jar_buffer()
end

-- Setup function to register autocmd and commands
function M.setup()
    -- Register autocmd for BufReadCmd
    vim.api.nvim_create_autocmd("BufReadCmd", {
        pattern = "jar://*",
        callback = M.handle_jar_buffer,
        desc = "Handle jar:// protocol for decompilation"
    })

    -- Also try to catch BufNewFile in case BufReadCmd doesn't trigger
    vim.api.nvim_create_autocmd("BufNewFile", {
        pattern = "jar://*",
        callback = M.handle_jar_buffer,
        desc = "Handle jar:// protocol for decompilation (BufNewFile fallback)"
    })

    -- Create user command for manual testing
    vim.api.nvim_create_user_command("JarOpen", function(opts)
        M.open_jar_url(opts.args)
    end, {
        nargs = 1,
        desc = "Manually open a jar:// URL",
        complete = function(arglead, cmdline, cursorpos)
            return { "jar:///path/to/file.jar!/package/Class.class" }
        end
    })
end

return M
