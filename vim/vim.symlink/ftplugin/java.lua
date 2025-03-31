-- ~/.config/nvim/ftplugin/java.lua
-- helper function for checking if a table contains a value
local function contains(table, value)
    for _, table_value in ipairs(table) do
        if table_value == value then
            return true
        end
    end

    return false
end

-- helper function for finding a filename in a directory which matches
-- the specified pattern
local function find_file(directory, pattern)
    local filename_found = ''
    local pfile = io.popen('ls "' .. directory .. '"')

    if (pfile == nil) then
        return ''
    end

    for filename in pfile:lines() do
        if (string.find(filename, pattern) ~= nil) then
            filename_found = filename
            break
        end
    end

    return filename_found
end

-- gathers all of the bemol-generated files and adds them to the LSP workspace
local function bemol()
    local bemol_dir = vim.fs.find({ ".bemol" }, { upward = true, type = "directory" })[1]
    local ws_folders_lsp = {}
    if bemol_dir then
        local file = io.open(bemol_dir .. "/ws_root_folders", "r")
        if file then
            for line in file:lines() do
                table.insert(ws_folders_lsp, line)
            end
            file:close()
        end

        for _, line in ipairs(ws_folders_lsp) do
            if not contains(vim.lsp.buf.list_workspace_folders(), line) then
                vim.lsp.buf.add_workspace_folder(line)
            end
        end
    end
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)

  bemol()
end

local jdtls = require "jdtls"
local jdtls_setup = require "jdtls.setup"

local home = os.getenv("HOME")
local root_markers = { ".bemol", }
local root_dir = jdtls_setup.find_root(root_markers)
local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name
local path_to_jdtls = "/opt/jdt-language-server"
local os_type = vim.fn.has("macunix") and "mac" or "linux"
local path_to_config = path_to_jdtls .. "/config_" .. os_type
local path_to_lombok = path_to_jdtls .. "/lombok.jar"
local path_to_plugins = path_to_jdtls .. "/plugins/"
-- the eclipse jar is suffixed with a bunch of version nonsense, so we find it by pattern matching
local path_to_jar = path_to_plugins .. find_file(path_to_plugins, "org.eclipse.equinox.launcher_")

local config = {
    cmd = {
        -- assumes the java binary is in your PATH and at least java17;
        -- if not, specify the full path to the binary
        "java",
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true",
        "-Dlog.level=ALL",
        "-Xmx1g",
        "-javaagent:" .. path_to_lombok,
        "--add-modules=ALL-SYSTEM",
        "--add-opens",
        "java.base/java.util=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.lang=ALL-UNNAMED",

        "-jar",
        path_to_jar,

        "-configuration",
        path_to_config,

        "-data",
        workspace_dir,
    },

    root_dir = root_dir,

    capabilities = {
        workspace = {
            configuration = true
        },
        textDocument = {
            completion = {
                completionItem = {
                    snippetSupport = true
                }
            }
        }
    },

    settings = {
        java = {
            references = {
                includeDecompiledSources = true,
            },
            eclipse = {
                downloadSources = true,
            },
            maven = {
                downloadSources = true,
            },
            sources = {
                organizeImports = {
                    starThreshold = 9999,
                    staticStarThreshold = 9999,
                },
            },
        }
    },

    -- run our bemol function when the LSP attaches to the buffer
    on_attach = on_attach,
}

jdtls.start_or_attach(config)
