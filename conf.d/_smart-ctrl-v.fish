status is-interactive; or return

function _smart-ctrl-v_install --on-event _smart-ctrl-v_install
    # Set universal variables, create bindings, and other initialization logic.
end

function _smart-ctrl-v_update --on-event _smart-ctrl-v_update
    # Migrate resources, print warnings, and other update logic.
end

function _smart-ctrl-v_uninstall --on-event _smart-ctrl-v_uninstall
    # Erase "private" functions, variables, bindings, and other uninstall logic.
end

function __smart-ctrl-v.fish::filter::command-indicating-leading-dollar
    set --local lines
    if isatty stdin
        set lines $argv
    else
        while read line
            set --append lines $line
        end
    end
    for line in $lines
        # Remove the leading $ from the clipboard content, so
        # that the command can be executed.
        # This is useful when pasting a command from guides that use
        # a $ to indicate that the command should be run in the terminal.
        string replace --regex "^\s*\\\$\s+" "" -- $line
        # set --local line_without_dollar_prefix (string replace --regex "^\s*\\\$\s+" "" -- $line)
        # printf "%s\n" $line_without_dollar_prefix
    end
end

function __smart-ctrl-v.fish::utils::get-common-leading-whitespace-length
    set --local lines
    if isatty stdin
        set lines $argv
    else
        while read line
            set --append lines $line
        end
    end

    set --local leading_whitespace_lengths
    for line in $lines
        test -z $line; and continue # skip empty lines
        set --local leading_whitespace (string match --regex --groups-only "^(\s*)" $line)
        set --append leading_whitespace_lengths (string length $leading_whitespace)
    end

    # If there are no lines, with leading whitespace, then return 0
    test (count $leading_whitespace_lengths) -eq 0; and printf "0\n"; and return 0

    set --local minimum_common_leading_whitespace (math min "$(string join "," $leading_whitespace_lengths)")
    echo $minimum_common_leading_whitespace
end

function __smart-ctrl-v.fish::filter::common-leading-whitespace
    set --local lines
    if isatty stdin
        set lines $argv
    else
        while read line
            set --append lines $line
        end
    end

    set --local minimum_common_leading_whitespace (__smart-ctrl-v.fish::utils::get-common-leading-whitespace-length $lines)
    set minimum_common_leading_whitespace (math "$minimum_common_leading_whitespace + 1") # `string sub --start=<n>` indexes from 1
    for line in $lines
        string sub --start=$minimum_common_leading_whitespace -- $line
    end
end


function __smart-ctrl-v.fish::mutate::escape-dollar-and-questionmark
    set --local lines
    if isatty stdin
        set lines $argv
    else
        while read line
            set --append lines $line
        end
    end
    for line in $lines
        # string escape -- $line
        string replace --regex \
            "(https?://[^ ]+)" \
            "'\$1'" \
            -- $line
    end
end

function __smart-ctrl-v.fish::mutate::gh-repo-clone
    set --local lines
    if isatty stdin
        set lines $argv
    else
        while read line
            set --append lines $line
        end
    end
    for line in $lines

        # TODO: <kpbaks 2023-09-14 21:40:37> handle case where (path basename $PWD) == $repo
        if string match --regex --groups-only "^\s*gh repo clone ([^/]+)/(.+)" $line \
                | read --line owner repo
            # printf "%s\n" "gh repo clone $owner/$repo && cd $repo && gh repo view --web"
            printf "%s\n" "gh repo clone $owner/$repo && cd $repo"
        else
            printf "%s\n" $line
        end
    end

end

function __smart-ctrl-v.fish::mutate::git-clone
    set --local lines
    if isatty stdin
        set lines $argv
    else
        while read line
            set --append lines $line
        end
    end
    # set --local buffer (commandline)

    if test (commandline | string trim) != ""
        # The commandline is not empty, so we do not want to mutate the clipboard
        printf "%s\n" $lines
        return
    end

    for line in $lines
        # You press the "Clone, open or download" button on github
        if string match --quiet --regex "^'*(https?|git)://.*\.git'*\$" -- $line
            # Parse the directory name from the url
            # example: https://github.com/nushell/nushell.git
            set --local reponame (string split --max=1 --right / $line \
			| string replace --all "'" "" \
			| string sub --end=-4)[-1]
            # printf "%s\n" "git clone --recursive $line && cd $reponame && git show"
            printf "%s\n" "git clone --recursive $line && cd $reponame && git branch"
            # You ctrl+l && ctrl+c a git url
        else if string match --regex --groups-only "^'*https?://git(hub|lab).com/([^/]+)/([^/']+)'*" -- $line | read --line owner reponame
            # https://github.com/gbprod/yanky.nvim
            printf "%s\n" "git clone --recursive $line && cd $reponame && git branch"
        else
            printf "%s\n" $line
        end
    end
end

function __smart-ctrl-v.fish::paste
    set --local buffer (commandline)
    commandline --insert (fish_clipboard_paste \
        | __smart-ctrl-v.fish::filter::common-leading-whitespace \
        | __smart-ctrl-v.fish::filter::command-indicating-leading-dollar \
        | __smart-ctrl-v.fish::mutate::escape-dollar-and-questionmark \
        | __smart-ctrl-v.fish::mutate::gh-repo-clone \
        | __smart-ctrl-v.fish::mutate::git-clone)
    commandline --function repaint
end

bind \cv __smart-ctrl-v.fish::paste
