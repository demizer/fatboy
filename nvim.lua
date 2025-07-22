---@diagnostic disable: missing-fields

vim.opt.list = false
vim.opt.listchars:append("tab:⇥\\ ")
vim.opt.listchars:append("trail:·")
vim.opt.listchars:append("extends:⋯")
vim.opt.listchars:append("precedes:⋯")
vim.opt.listchars:append("nbsp:~")
vim.opt.listchars:append("eol:↴")
vim.opt.listchars:append("space:⋅")
vim.opt.mouse = "a" -- enable mouse support
vim.opt.cursorline = true
vim.opt.cursorcolumn = true
vim.opt.swapfile = true -- How to work with swap files: https://cs.longwood.edu/VimSwap.html
vim.opt.backupdir = vim.fn.stdpath("config") .. "/backups"
vim.opt.directory = vim.fn.stdpath("config") .. "/swapfiles"
vim.opt.autoread = true
vim.opt.backup = true
vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("timestamp_backupext", { clear = true }),
    desc = "Add timestamp to backup extension",
    pattern = "*",
    callback = function()
        vim.opt.backupext = "-" .. vim.fn.strftime("%Y%m%d%H%M")
    end,
})
vim.opt.encoding = "utf-8" -- Set the encoding used in vim
vim.opt.showcmd = true     -- Show commands as they are typed
vim.opt.hidden = true      -- Keep buffers loaded in memory when switching buffers.
vim.opt.confirm = true     -- Confirm before altering file.
vim.opt.wb = false         -- Don't make backups before overwriting a file.
vim.opt.numberwidth = 1    -- Keep line numbers small if it's shown
vim.opt.cmdheight = 1      -- Only one line for command line
vim.opt.errorbells = false -- Stop the beeps
vim.opt.ruler = true       -- Show the line and column of the cursor position.
vim.cmd([[let &showbreak='↳ ']])
vim.opt.breakindent = true
vim.opt.linebreak = true
vim.opt.wrap = true
vim.opt.lazyredraw = true     -- faster scrolling
vim.opt.termguicolors = true  -- enable 24-bit RGB colors
vim.opt.syntax = "enable"     -- enable syntax highlighting
vim.opt.synmaxcol = 240       -- Max column for syntax highlight
vim.opt.number = true         -- show line number
vim.opt.relativenumber = true -- show relative line numbers
vim.opt.rnu = true
vim.opt.scrolloff = 5         -- Keep the cursor from the edge
vim.opt.sidescroll = 3        -- Min number of columns to scroll horizontally.
vim.opt.sidescrolloff = 3     -- Keep 10 columns to the left of the cursor.
vim.opt.showmatch = true      -- highlight matching parenthesis
vim.opt.foldmethod = "marker" -- enable folding (default 'foldmarker')
vim.opt.colorcolumn = "120"   -- line length marker at 80 columns
vim.opt.splitright = true     -- vertical split to the right
vim.opt.splitbelow = true     -- orizontal split to the bottom
vim.opt.ignorecase = true     -- ignore case letters when search
vim.opt.smartcase = true      -- ignore lowercase for the whole pattern
vim.opt.incsearch = true      -- Find the next match as we type the search
vim.opt.hlsearch = true       -- Highlight searches by default
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.spelllang = "en_us"
vim.opt.spellfile = "~/.config/nvim/dict.add"
vim.opt.undodir = os.getenv("HOME") .. "/.config/nvim/undodir"
vim.opt.undofile = true
vim.opt.undolevels = 1000  -- maximum number of changes that can be undone
vim.opt.undoreload = 10000 -- maximum number lines to save for undo on a buffer reload
vim.opt.timeoutlen = 500   -- 16:11 Sat Mar 12 2022: set for whichkey (recommended)
vim.cmd([[
    " Remember last location in file, but not for commit messages.
    " see :help last-position-jump
    " au BufReadPost * if &filetype !~ '^git\c' && line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif

    " Show trailing whitepace and spaces before a tab:
    hi ExtraWhiteSpace ctermbg=darkgreen guibg=red
    au InsertEnter * match ExtraWhiteSpace /\s\+\%#\@<!$/
    au InsertLeave * match ExtraWhiteSpace /\s\+$/

    au FileType dat,java,javascript,html au BufWritePre <buffer> :%s/\s\+$//e

    " Enable spellcheck for markdown files
    " au BufRead,BufNewFile *.md setlocal spell
]])
vim.filetype.add({
    extension = {
        jakt = "jakt",
        odin = "odin",
        v = "v",
        cue = "cue",
        ts = "typescript",
        tsx = "tsx",
        py = "python",
        rs = "rust",
        ha = "hare",
        wgsl = "wgsl",
        c3 = "c3",
        c3i = "c3",
        c3t = "c3",
        nim = "nim",
    },
})
vim.diagnostic.config({
    virtual_text = true,
    underline = true,
    update_in_insert = true,
    float = {
        source = true,
    },
    signs = {
        active = true,
        text = {
            [vim.diagnostic.severity.ERROR] = ' ',
            [vim.diagnostic.severity.WARN] = ' ',
            [vim.diagnostic.severity.HINT] = ' ',
            [vim.diagnostic.severity.INFO] = ' ',
        },
    },
})

local function create_lazygit_config()
    local config_path
    local config_file

    config_path = vim.fn.expand('.nvim/config/lazygit')
    config_file = config_path .. '/config.yml'

    if vim.fn.isdirectory(config_path) == 0 then
        vim.fn.mkdir(config_path, 'p')
    end

    if vim.fn.filereadable(config_file) == 0 then
        local file = io.open(config_file, 'w')
        if file then
            file:write('# Lazygit configuration\n')
            file:close()
        end
    end
end

create_lazygit_config()

-- Open a ui.select to search for a directory to search in
local grep_directory = function()
    local snacks = require("snacks")
    local has_fd = vim.fn.executable("fd") == 1
    local cwd = vim.fn.getcwd()

    local function show_picker(dirs)
        if #dirs == 0 then
            vim.notify("No directories found", vim.log.levels.WARN)
            return
        end

        local items = {}
        for i, item in ipairs(dirs) do
            table.insert(items, {
                idx = i,
                file = item,
                text = item,
            })
        end

        snacks.picker({
            confirm = function(picker, item)
                picker:close()
                snacks.picker.grep({
                    dirs = { item.file },
                })
            end,
            items = items,
            format = function(item, _)
                local file = item.file
                local ret = {}
                local a = Snacks.picker.util.align
                local icon, icon_hl = Snacks.util.icon(file.ft, "directory")
                ret[#ret + 1] = { a(icon, 3), icon_hl }
                ret[#ret + 1] = { " " }
                local path = file:gsub("^" .. vim.pesc(cwd) .. "/", "")
                ret[#ret + 1] = { a(path, 20), "Directory" }

                return ret
            end,
            layout = {
                preview = false,
                preset = "vertical",
            },
            title = "Grep in directory",
        })
    end

    if has_fd then
        local cmd = { "fd", "--type", "directory", "--hidden", "--no-ignore-vcs", "--exclude", ".git" }
        local dirs = {}

        vim.fn.jobstart(cmd, {
            on_stdout = function(_, data, _)
                for _, line in ipairs(data) do
                    if line and line ~= "" then
                        table.insert(dirs, line)
                    end
                end
            end,
            on_exit = function(_, code, _)
                if code == 0 then
                    show_picker(dirs)
                else
                    -- Fallback to plenary if fd fails
                    local fallback_dirs = require("plenary.scandir").scan_dir(cwd, {
                        only_dirs = true,
                        respect_gitignore = true,
                    })
                    show_picker(fallback_dirs)
                end
            end,
        })
    else
        -- Use plenary if fd is not available
        local dirs = require("plenary.scandir").scan_dir(cwd, {
            only_dirs = true,
            respect_gitignore = true,
        })
        show_picker(dirs)
    end
end


local keymaps_spec = {

    --
    -- Top Pickers & Explorer
    --
    { "<leader><space>", function() Snacks.picker.smart() end, icon = { icon = "󰋆", color = "yellow" }, desc = "Pick: Smart Find Files", mode = { "n", "v" } },
    { "<leader>,", function() Snacks.picker.buffers() end, icon = { icon = "󰋆", color = "yellow" }, desc = "Pick: Buffers", mode = { "n", "v" } },
    { "<leader>/", function() Snacks.picker.grep() end, icon = { icon = "󰋆", color = "yellow" }, desc = "Pick: Grep", mode = { "n", "v" } },
    { "<leader>:", function() Snacks.picker.command_history() end, icon = { icon = "󰋆", color = "yellow" }, desc = "Pick: Command History", mode = { "n", "v" } },
    { "<leader>n", function() Snacks.picker.notifications() end, icon = { icon = "󰋆", color = "yellow" }, desc = "Pick: Notification History", mode = { "n", "v" } },
    { "<leader>e", function() Snacks.explorer() end, icon = { icon = "󰋆", color = "yellow" }, desc = "Pick: File", mode = { "n", "v" } },

    -- LLM
    { "<Leader>a", "<cmd>silent CodeCompanionChat Toggle<cr>", icon = { icon = "󰁨", color = "green" }, desc = "CodeCompanion Toggle", mode = { "n", "v" } },
    { "<C-a>", "<cmd>silent CodeCompanionActions<cr>", desc = "CodeCompanion Add", mode = { "n", "v" } },
    { "ga", "<cmd>silent lua CodeCompanionChat Add<cr>", desc = "CodeCompanion Add", mode = { "v" } },


    --
    -- Tabs
    --
    { "<leader><tab>", group = "Tabs", mode = { "n", "v" } },
    { "<leader><tab>n", "<cmd>tabnext<CR>", desc = "next tab", mode = { "n", "v" } },
    { "<leader><tab>p", "<cmd>tabprev<CR>", desc = "previous tab", mode = { "n", "v" } },
    { "<leader><tab>f", "<cmd>tabfirst<CR>", desc = "first tab", mode = { "n", "v" } },
    { "<leader><tab>l", "<cmd>tablast<CR>", desc = "last tab", mode = { "n", "v" } },

    --
    -- Code & LSP
    --
    --
    { "<leader>c", group = "Code", icon = { icon = "󰘦", color = "azure" }, mode = { "n", "v" } },
    { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition", mode = { "n", "v" } },
    { "gD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration", mode = { "n", "v" } },
    { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References", mode = { "n", "v" } },
    { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation", mode = { "n", "v" } },
    { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition", mode = { "n", "v" } },
    { "<C-s>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", desc = "lsp signature_help", mode = { "i" } },
    { "<leader>cf", "<cmd>lua vim.lsp.buf.format()<CR>", desc = "Apply Formatter", mode = { "n", "v" } },
    -- { "<leader>cF", "<cmd>ToggleLspFormatter<CR>", desc = "toggle lsp auto formatter", mode = { "n", "v" } },
    { "<leader>cw", "<cmd>TSPlaygroundToggle<CR>", desc = "treesitter playground", mode = { "n", "v" } },
    { "<leader>cA", "<cmd>lua vim.lsp.buf.code_action()<CR>", desc = "lsp code action", mode = { "n", "v" } },
    { "<leader>cl", "<cmd>LspRestart<CR>", desc = "Restart the lsp agent", mode = { "n", "v" } },
    { "<leader>cr", "<cmd>lua vim.lsp.buf.rename()<CR>", desc = "lsp rename", mode = { "n", "v" } },
    { "<leader>cD", "<cmd>lua vim.lsp.buf.declaration()<CR>", desc = "lsp declaration", mode = { "n", "v" } },
    { "<leader>cd", "<cmd>lua vim.lsp.buf.definition()<CR>", desc = "lsp definition", mode = { "n", "v" } },
    { "<leader>ci", "<cmd>lua vim.lsp.buf.implementation()<CR>", desc = "lsp implementation", mode = { "n", "v" } },
    { "<leader>ct", "<cmd>lua vim.lsp.buf.type_definition()<CR>", desc = "lsp type definition", mode = { "n", "v" } },

    --
    -- File & Find
    --
    { "<leader>f", group = "File/Find", icon = { icon = "󰈞", color = "magenta" }, mode = { "n", "v" } },
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers", mode = { "n", "v" } },
    { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File", mode = { "n", "v" } },
    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files", mode = { "n", "v" } },
    { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Git Files", mode = { "n", "v" } },
    { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects", mode = { "n", "v" } },
    { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent", mode = { "n", "v" } },
    { "<leader>fn", "<cmd>luafile .nvim-commands.lua<CR>", desc = "Load local .nvim-commands.lua", mode = { "n", "v" } },

    --
    -- Search
    --
    { "<leader>s", group = "Search", icon = { icon = "", color = "red" }, mode = { "n", "v" } },

    -- search
    { "<leader>/", function() Snacks.picker.grep() end, icon = { icon = "", color = "red" }, desc = "Search: Workspace" },
    { "<leader>?", function() grep_directory() end, icon = { icon = "", color = "red" }, desc = "Search: Directory" },
    { "<leader>*", function() Snacks.picker.grep_word() end, icon = { icon = "", color = "red" }, desc = "Search: Current word" },
    { "<leader>h", function() Snacks.picker.search_history() end, icon = { icon = "", color = "red" }, desc = "Search: History" },
    { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers", mode = { "n", "v" } },
    { '<leader>s/', function() Snacks.picker.search_history() end, desc = "Search History", mode = { "n", "v" } },
    { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds", mode = { "n", "v" } },
    { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines", mode = { "n", "v" } },
    { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
    { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History", mode = { "n", "v" } },
    { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands", mode = { "n", "v" } },
    { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics", mode = { "n", "v" } },
    { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics", mode = { "n", "v" } },
    { "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep" },
    { "<leader>sH", function() Snacks.picker.help() end, desc = "Help Pages", mode = { "n", "v" } },
    -- { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights", mode = { "n", "v" } },
    { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons", mode = { "n", "v" } },
    { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps", mode = { "n", "v" } },
    { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps", mode = { "n", "v" } },
    { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List", mode = { "n", "v" } },
    { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks", mode = { "n", "v" } },
    { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages", mode = { "n", "v" } },
    { "<leader>sp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec", mode = { "n", "v" } },
    { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List", mode = { "n", "v" } },
    { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume", mode = { "n", "v" } },
    { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo History", mode = { "n", "v" } },
    { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes", mode = { "n", "v" } },
    { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols", mode = { "n", "v" } },
    { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols", mode = { "n", "v" } },
    { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },

    --
    -- Quitting
    --
    { "<leader>q", group = "Quitting", icon = { icon = "󰚵", color = "orange" }, mode = { "n", "v" } },
    { "<leader>qw", "<cmd>q<CR>", desc = "window", mode = { "n", "v" } },
    { "<leader>qW", "<cmd>wincmd o<CR>", desc = "all other windows", mode = { "n", "v" } },
    { "<leader>qb", "<cmd>bdelete<CR>", desc = "buffer", mode = { "n", "v" } },
    { "<leader>qB", "<cmd>only<CR>", desc = "all other buffers", mode = { "n", "v" } },
    { "<leader>qt", "<cmd>tabclose<CR>", desc = "tab", mode = { "n", "v" } },
    { "<leader>qT", "<cmd>tabonly<CR>", desc = "all other tabs", mode = { "n", "v" } },
    { "<leader>qq", "<cmd>cclose<CR>", desc = "quickfix list", mode = { "n", "v" } },
    { "<leader>ql", "<cmd>lclose<CR>", desc = "location list", mode = { "n", "v" } },
    { "<leader>qz", "<cmd>qa<CR>", desc = "Close everything and exit", mode = { "n", "v" } },

    --
    -- User Interface
    --
    { "<leader>u", group = "Ui", icon = { icon = "󰙵 ", color = "cyan" }, mode = { "n", "v" } },
    { "<leader>uc", group = "Colorscheme", icon = { icon = "", color = "purple" }, mode = { "n", "v" } },
    { "<leader>ucd", group = "Dark", icon = { icon = "", color = "gray" }, mode = { "n", "v" } },
    { "<leader>ucl", group = "Light", icon = { icon = "☼", color = "yellow" }, mode = { "n", "v" } },

    --
    -- Trouble & Diagnostics
    --
    { "<leader>x", group = "Trouble/Diagnostics/Quickfix", icon = { icon = "󱖫 ", color = "green" }, mode = { "n", "v" } },
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)", mode = { "n", "v" } },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)", mode = { "n", "v" } },
    { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)", mode = { "n", "v" } },
    { "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP Definitions / references / ... (Trouble)", mode = { "n", "v" } },
    { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)", mode = { "n", "v" } },
    { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)", mode = { "n", "v" } },
    { "<leader>xE", "<cmd>Trouble workspace_diagnostics<CR>", desc = "workspace errors (folke/Trouble)", mode = { "n", "v" } },
    { "<leader>xe", "<cmd>lua vim.diagnostic.open_float()<CR>", desc = "line errors", mode = { "n", "v" } },
    { "<leader>xh", "<cmd>lua vim.lsp.buf.hover()<CR>", desc = "lsp hover", mode = { "n", "v" } },
    { "[", group = "Prev", desc = "Previous", icon = { icon = "󰁍", color = "magenta" }, mode = { "n", "v" } },
    { "<leader>[e", "<cmd>silent lua vim.lsp.diagnostic.goto_prev()<cr>", desc = "lsp error", mode = { "n", "v" } },
    { "<leader>[q", "<cmd>cprevious<cr>", desc = "quickfix item", mode = { "n", "v" }},
    {
        "<leader>[t",
        "<cmd>lua require('trouble').previous({skip_groups = true, jump = true})<cr>",
        desc = "trouble",
        mode = { "n", "v" }
    },
    { "]", group = "Next", desc = "Next", icon = { icon = "󰁔", color = "magenta" }, mode = { "n", "v" } },
    { "<leader>]e", "<cmd>silent lua vim.lsp.diagnostic.goto_next()<cr>", desc = "lsp error", mode = { "n", "v" } },
    { "<leader>]q", "<cmd>cnext<cr>", desc = "quickfix item", mode = { "n", "v" } },
    {
        "<leader>]t",
        "<cmd>lua require('trouble').next({skip_groups = true, jump = true})<cr>",
        desc = "trouble",
        mode = { "n", "v" }
    },

    --
    -- Buffer
    --
    {
        "<leader>b",
        group = "Buffer",
        expand = function()
            return require("which-key.extras").expand.buf()
        end,
        mode = { "n", "v" }
    },
    { "<leader>?",  function() require("which-key").show({ global = false }) end, desc = "Keymaps for Buffer",                 mode = { "n", "v" } },
    { "<C-s>",      "<cmd>w!<CR>",                                                desc = "save",                               mode = { "n", "v" } },
    { "<leader>b.", function() Snacks.scratch() end,                              desc = "Toggle Scratch Buffer",              mode = { "n", "v" } },
    { "<leader>bS", function() Snacks.scratch.select() end,                       desc = "Select Scratch Buffer",              mode = { "n", "v" } },
    { "<leader>bR", function() Snacks.rename.rename_file() end,                   desc = "Rename File",                        mode = { "n", "v" } },
    { "<leader>ba", "<cmd>set spell!<CR>",                                        desc = "toggle spell",                       mode = { "n", "v" } },
    { "<leader>bd", function() Snacks.bufdelete() end,                            desc = "Delete Buffer",                      mode = { "n", "v" } },
    { "<leader>bC", "<cmd>set list!<CR>",                                         desc = "toggle listchars",                   mode = { "n", "v" } },
    { "<leader>bp", "<cmd>set paste! paste?<CR>",                                 desc = "toggle paste",                       mode = { "n", "v" } },
    { "<leader>bc", "<cmd>let @/ = ''<CR>",                                       desc = "clear search buffer",                mode = { "n", "v" } },
    { "<leader>be", "<cmd>e!<CR>",                                                desc = "reload from filesystem",             mode = { "n", "v" } },
    { "<leader>bf", "<cmd>echo expand('%:p')<CR>",                                desc = "print absolute file path of buffer", mode = { "n", "v" } },
    { "<leader>bn", "<cmd>new<CR>",                                               desc = "new",                                mode = { "n", "v" } },
    { "<leader>bo", "<cmd>b#<CR>",                                                desc = "switch to last active buffer",       mode = { "n", "v" } },
    { "<leader>bs", "<cmd>w!<CR>",                                                desc = "save",                               mode = { "n", "v" } },
    {
        "<leader>bx",
        "<cmd>let _s=@/<Bar>%s/\\s\\+$//e<Bar>let @/=_s<Bar>nohl<CR>",
        desc = "delete trailing whitespace",
        mode = { "n", "v" }
    },
    { "<leader>by", "<cmd>%y+<CR>", desc = "copy buffer to clipboard", mode = { "n", "v" } },

    --
    -- Windows
    --
    {
        "<leader>w",
        group = "Windows",
        proxy = "<c-w>",
        expand = function()
            return require("which-key.extras").expand.win()
        end,
        mode = { "n", "v" }
    },

    -- Misc
    { "z", group = "Fold", mode = { "n", "v" } },
    { "g", group = "Goto", mode = { "n", "v" } },
    { "gs", group = "Surround", mode = { "n", "v" } },
    { "gx", desc = "Open with system app", mode = { "n", "v" } },

    -- Other
    { "Q", "gwap", desc = "reformat paragraph", mode = { "n", "v" } },
    { "<leader>L", "<cmd>Lazy<CR>", desc = "Lazy Package Manager", mode = { "n", "v" } },
    { "<leader>M", "<cmd>Mason<CR>", desc = "Mason LSP Package Manager", icon = { icon = "📦" }, mode = { "n", "v" } },
    { "<leader>z", function() Snacks.zen() end, desc = "Toggle Zen Mode", mode = { "n", "v" } },
    { "<leader>Z", function() Snacks.zen.zoom() end, desc = "Toggle Zoom", mode = { "n", "v" } },
    { "<leader>n", function() Snacks.notifier.show_history() end, desc = "Notification History", mode = { "n", "v" } },
    { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse", mode = { "n", "v" } },
    { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit", mode = { "n", "v" } },
    { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications", mode = { "n", "v" } },
    { "<c-/>", function() Snacks.terminal() end, desc = "Toggle Terminal", mode = { "n", "v" } },
    { "<c-_>", function() Snacks.terminal() end, desc = "which_key_ignore", mode = { "n", "v" } },
    { "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" } },
    { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
    {
        "<leader>N",
        desc = "Neovim News",
        icon = { icon = "󱀁", color = "grey" },
        function()
            Snacks.win({
                file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
                width = 0.6,
                height = 0.6,
                wo = {
                    spell = false,
                    wrap = false,
                    signcolumn = "yes",
                    statuscolumn = " ",
                    conceallevel = 3,
                },
            })
        end,
        mode = { "n", "v" }
    },
    { "<leader>p",  "_dP",                   desc = "paste without copying deleted text to clipboard", mode = { "v" } },

    { "<leader>d",  group = "Diff",          mode = { "v" } },
    { "<leader>dg", "<cmd>'<,'>diffget<cr>", desc = "get",                                             mode = { "v" } },
    { "<leader>dp", "<cmd>'<,'>diffput<cr>", desc = "put",                                             mode = { "v" } },
}

vim.g.mapleader = " "

vim.env.LAZY_STDPATH = ".nvim"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

-- Your CodeCompanion setup
local plugins = {
    {
        "EdenEast/nightfox.nvim",
        lazy = false,    -- make sure we load this during startup if it is your main colorscheme
        priority = 1000, -- make sure to load this before all the other start plugins
        opts = {
            options = {
                -- transparent = true,
                styes = {
                    strings = "italic,bold",
                    comments = "italic",
                },
                inverse = { -- Inverse highlight for different types
                    match_paren = false,
                    visual = true,
                    search = false,
                },
                modules = {
                    -- ["dap-ui"] = true,
                    gitsigns = true,
                    lsp_saga = true,
                    modes = true,
                    navic = true,
                    nvimtree = true,
                    -- telescope = true,
                    treesitter = true,
                    whichkey = true,
                    notify = true,
                    hop = true,
                    diagnostic = true,
                },
            },
        },
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            laststatus = 3,
            options = {
                -- https://github.com/nvim-lualine/lualine.nvim/blob/master/THEMES.md
                theme = "nightfox",
            },
        },
    },
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            bigfile = { enabled = true },
            dashboard = { enabled = true },
            explorer = { enabled = true },
            indent = { enabled = true },
            input = { enabled = true },
            notifier = {
                enabled = true,
                timeout = 3000,
            },
            picker = { enabled = true },
            quickfile = { enabled = true },
            lazygit = { enabled = true },
            scope = { enabled = true },
            scroll = { enabled = true },
            statuscolumn = { enabled = true },
            words = { enabled = true },
            styles = {
                notification = {
                    -- wo = { wrap = true } -- Wrap notifications
                }
            }
        },
        init = function()
            vim.api.nvim_create_autocmd("User", {
                pattern = "VeryLazy",
                callback = function()
                    -- Setup some globals for debugging (lazy-loaded)
                    _G.dd = function(...)
                        Snacks.debug.inspect(...)
                    end
                    _G.bt = function()
                        Snacks.debug.backtrace()
                    end
                    vim.print = _G.dd -- Override print to use snacks for `:=` command

                    -- Create some toggle mappings
                    Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
                    Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
                    Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
                    Snacks.toggle.diagnostics():map("<leader>ud")
                    Snacks.toggle.line_number():map("<leader>ul")
                    Snacks.toggle.option("conceallevel",
                        { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
                        :map("<leader>uc")
                    Snacks.toggle.treesitter():map("<leader>uT")
                    Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map(
                        "<leader>ub")
                    Snacks.toggle.inlay_hints():map("<leader>uh")
                    Snacks.toggle.indent():map("<leader>ug")
                    Snacks.toggle.dim():map("<leader>uD")
                end,
            })
        end,
    },
    {
        "folke/trouble.nvim",
        cmd = "Trouble",
    },
    {
        "mason-org/mason.nvim",
        dependencies = {
            -- { "mason-org/mason-lspconfig.nvim" },
            { "mfussenegger/nvim-lint" },
        },
        cmd = "Mason",
        build = ":MasonUpdate",
        opts_extend = { "ensure_installed" },
        opts = {
            ensure_installed = {
                "stylua",
                "shfmt",
                "pyright",
                "json-lsp",
                "lua-language-server",
                "taplo",
            },
        },
        config = function(_, opts)
            require("mason").setup(opts)
            local mr = require("mason-registry")
            mr:on("package:install:success", function()
                vim.defer_fn(function()
                    -- trigger FileType event to possibly load this newly installed LSP server
                    require("lazy.core.handler.event").trigger({
                        event = "FileType",
                        buf = vim.api.nvim_get_current_buf(),
                    })
                end, 100)
            end)

            mr.refresh(function()
                for _, tool in ipairs(opts.ensure_installed) do
                    local p = mr.get_package(tool)
                    if not p:is_installed() then
                        p:install()
                    end
                end
            end)
        end,
    },
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        config = function()
            vim.lsp.enable("v_analyzer")
        end,
    },
    {
        "mason-org/mason-lspconfig.nvim",
        -- lazy = false,
        -- opts = {},
        dependencies = {
            { "mason-org/mason.nvim" },
            "neovim/nvim-lspconfig",
        },
        config = function(_, opts)
            require("mason-lspconfig").setup(opts)
        end,
    },
    {
        "olimorris/codecompanion.nvim",
        dependencies = {
            { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
            { "nvim-lua/plenary.nvim" },
            -- Test with blink.cmp (delete if not required)
            {
                "saghen/blink.cmp",
                lazy = false,
                version = "*",
                opts = {
                    keymap = {
                        preset = "enter",
                        ["<S-Tab>"] = { "select_prev", "fallback" },
                        ["<Tab>"] = { "select_next", "fallback" },
                    },
                    cmdline = { sources = { "cmdline" } },
                    sources = {
                        default = { "lazydev", "lsp", "path", "snippets", "buffer", "codecompanion" },
                        providers = {
                            lazydev = {
                                name = "LazyDev",
                                module = "lazydev.integrations.blink",
                                -- make lazydev completions top priority (see `:h blink.cmp`)
                                score_offset = 100,
                            },
                        },
                    },
                },
            },
            {
                "MeanderingProgrammer/render-markdown.nvim",
                ft = { "markdown", "codecompanion" }
            },
            {
                "HakonHarnes/img-clip.nvim",
                opts = {
                    filetypes = {
                        codecompanion = {
                            prompt_for_file_name = false,
                            template = "[Image]($FILE_PATH)",
                            use_absolute_path = true,
                        },
                    },
                },
            },
        },
        opts = {
            --Refer to: https://github.com/olimorris/codecompanion.nvim/blob/main/lua/codecompanion/config.lua
            strategies = {
                --NOTE: Change the adapter as required
                chat = { adapter = "anthropic" },
                inline = { adapter = "anthropic" },
            },
            opts = {
                log_level = "DEBUG",
            },
        },
    },
    {
        {
            "folke/which-key.nvim",
            dependencies = {
                { "echasnovski/mini.icons" },
            },
            lazy = false,
            opts_extend = { "spec" },
            opts = {
                defaults = {},
                sort = { "manual", "local", "order", "group", "alphanum", "mod" },
                plugins = {
                    marks = true,     -- shows a list of your marks on ' and `
                    registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
                    spelling = {
                        enabled = true,
                        suggestions = 20, -- how many suggestions should be shown in the list?
                    },
                    -- the presets plugin, adds help for a bunch of default keybindings in Neovim
                    -- No actual key bindings are created
                    presets = {
                        operators = true,    -- adds help for operators like d, y, ... and registers them for motion / text object completion
                        motions = true,      -- adds help for motions
                        text_objects = true, -- help for text objects triggered after entering an operator
                        windows = true,      -- default bindings on <c-w>
                        nav = true,          -- misc bindings to work with windows
                        z = true,            -- bindings for folds, spelling and others prefixed with z
                        g = true,            -- bindings for prefixed with g
                    },
                },
                spec = keymaps_spec,
            },
        },
    },
    {
        "mhartington/formatter.nvim",
        dependencies = {
            { "mason-org/mason.nvim" },
            "neovim/nvim-lspconfig",
        },
        opts = function()
            vim.api.nvim_create_user_command("ToggleLspFormatter", function()
                local exists, _ = pcall(vim.api.nvim_get_autocmds, { group = "LspFormatting" })
                if not exists then
                    -- install_lsp_formatter_group()
                    print("LSP Formatter enabled")
                    return
                end
                vim.api.nvim_del_augroup_by_name("LspFormatting")
                print("LSP Formatter Disabled")
            end, {})

            return {
                -- Enable or disable logging
                logging = true,
                -- Set the log level
                log_level = vim.log.levels.WARN,
                -- All formatter configurations are opt-in
                -- https://github.com/mhartington/formatter.nvim/tree/master/lua/formatter/filetypes
                filetype = {
                    lua = { require("formatter.filetypes.lua").stylua },
                    python = { require("formatter.filetypes.python").ruff },
                    toml = { require("formatter.filetypes.toml").taplo },
                    json = { require("formatter.filetypes.json").jq },
                    markdown = { require("formatter.filetypes.markdown").prettier },
                },
            }
        end,

    },
    {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
            library = {
                -- See the configuration section for more details
                -- Load luvit types when the `vim.uv` word is found
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },
}

require("lazy.minit").repro({ spec = plugins })

-- Setup Tree-sitter
local ts_status, treesitter = pcall(require, "nvim-treesitter.configs")
if ts_status then
    treesitter.setup({
        ensure_installed = { "lua", "markdown", "markdown_inline", "yaml", "diff", "regex" },
        highlight = { enable = true },
        playground = { enable = true },
        sync_install = true,
        auto_install = true,
        autotag = {
            enable = true,
        },
        rainbow = {
            enable = true,
            extended_mode = true,
            max_file_lines = nil,
        },
        autopairs = {
            enable = true,
        },
    })
    local parser_configs = require("nvim-treesitter.parsers").get_parser_configs()

    parser_configs["v"] = {
        install_info = {
            url = "~/code/v/v-analyzer",
            location = "tree_sitter_v",
            files = { "src/parser.c" },
            branch = "main",
            requires_generate_from_grammar = true,
            filetype = "v",
        },
    }
end
