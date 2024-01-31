set --local scriptdir (path dirname (status filename))
source $scriptdir/../conf.d/_smart-ctrl-v.fish

set --local clipboard "
    \$ cmake --version
      \$ cmake -S . -B build
    \$ cmake --build build

    gh repo clone ntk148v/habamax.nvim
"

@test "common leading whitespace"
