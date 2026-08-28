return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
      servers = {
        qmlls = {
          cmd = { "qmlls6", "--no-cmake-calls", "-I", "/usr/lib/qt6/qml" },
          filetypes = { "qml", "qmljs" },
          root_markers = { ".qmlls.ini", "shell.qml", ".git" },
        },
      },
    },
  },
}