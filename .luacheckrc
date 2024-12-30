exclude_files = { "**/lib/*.lua" }

std = "max+linncontrol+love"
stds.love = {
   globals = { "love" },
}
stds.linncontrol = {
   globals = {},
   read_globals = {},
}

ignore = {
   "212", -- unused function arg
   "213", -- unused loop variable
   "561", -- cyclomatic complexity
}

-- allow_defined_top = true
