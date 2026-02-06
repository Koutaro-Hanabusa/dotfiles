return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "ts_ls",
          "pyright",
          "gopls",
          "intelephense",
        },
        automatic_installation = true,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Lua LSP
      vim.lsp.config.lua_ls = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml", ".git" },
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      }

      -- TypeScript/JavaScript
      vim.lsp.config.ts_ls = {
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
        root_markers = { "tsconfig.json", "package.json", "jsconfig.json", ".git" },
        capabilities = capabilities,
      }

      -- Python
      vim.lsp.config.pyright = {
        cmd = { "pyright-langserver", "--stdio" },
        filetypes = { "python" },
        root_markers = { "setup.py", "setup.cfg", "requirements.txt", "Pipfile", "pyproject.toml", ".git" },
        capabilities = capabilities,
      }

      -- Go
      vim.lsp.config.gopls = {
        cmd = { "gopls" },
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        root_markers = { "go.work", "go.mod", ".git" },
        capabilities = capabilities,
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
            },
            staticcheck = true,
            gofumpt = true,
          },
        },
      }

      -- PHP (Laravel)
      vim.lsp.config.intelephense = {
        cmd = { "intelephense", "--stdio" },
        filetypes = { "php" },
        root_markers = { "composer.json", ".git" },
        capabilities = capabilities,
        settings = {
          intelephense = {
            stubs = {
              "apache", "bcmath", "bz2", "calendar", "com_dotnet", "Core", "ctype",
              "curl", "date", "dba", "dom", "enchant", "exif", "FFI", "fileinfo",
              "filter", "fpm", "ftp", "gd", "gettext", "gmp", "hash", "iconv", "imap",
              "intl", "json", "ldap", "libxml", "mbstring", "meta", "mysqli", "oci8",
              "odbc", "openssl", "pcntl", "pcre", "PDO", "pdo_ibm", "pdo_mysql",
              "pdo_pgsql", "pdo_sqlite", "pgsql", "Phar", "posix", "pspell", "readline",
              "Reflection", "session", "shmop", "SimpleXML", "snmp", "soap", "sockets",
              "sodium", "SPL", "sqlite3", "standard", "superglobals", "sysvmsg",
              "sysvsem", "sysvshm", "tidy", "tokenizer", "xml", "xmlreader", "xmlrpc",
              "xmlwriter", "xsl", "Zend OPcache", "zip", "zlib",
              "wordpress", "laravel",
            },
            files = {
              maxSize = 5000000,
            },
          },
        },
      }

      -- Enable LSPs
      vim.lsp.enable({ "lua_ls", "ts_ls", "pyright", "gopls", "intelephense" })

      -- Key mappings
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
      vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
      vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Find references" })
    end,
  },
}