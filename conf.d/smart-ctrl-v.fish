status is-interactive; or return

function __smart-ctrl-v::filter::command-indicating-leading-dollar
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
    end
end

function __smart-ctrl-v::utils::get-common-leading-whitespace-length
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

function __smart-ctrl-v::filter::common-leading-whitespace
    set --local lines
    if isatty stdin
        set lines $argv
    else
        while read line
            set --append lines $line
        end
    end

    # TODO: shorten var names
    set -l minimum_common_leading_whitespace (__smart-ctrl-v::utils::get-common-leading-whitespace-length $lines)
    set minimum_common_leading_whitespace (math "$minimum_common_leading_whitespace + 1") # `string sub --start=<n>` indexes from 1
    for line in $lines
        string sub --start=$minimum_common_leading_whitespace -- $line
    end
end

function __smart-ctrl-v::mutate::escape-dollar-and-questionmark
    if isatty stdin
        printf "%serror in %s:%s%s stdin cannot be a tty\n" (set_color red) (status filename) (status function) (set_color normal) >&2
    end
    while read line
        # string escape -- $line
        string replace --regex \
            "(https?://[^ ]+)" \
            "'\$1'" \
            -- $line
    end
end

function __smart-ctrl-v::mutate::gh-repo-clone
    if isatty stdin
        printf "%serror in %s:%s%s stdin cannot be a tty\n" (set_color red) (status filename) (status function) (set_color normal) >&2
    end

    # if test (commandline | string trim) != ""
    #     # The commandline is not empty, so we do not want to mutate the clipboard
    #     printf "%s\n" $lines
    #     return
    # end

    while read line
        if string match --regex --groups-only "^\s*gh repo clone ([^/]+)/(.+)" $line \
                | read --line owner repo
            if test -d $repo
                echo "cd $repo # github repository `$repo` already exist!"
            else
                echo "gh repo clone $owner/$repo && cd $repo"
            end
        else
            printf "%s\n" $line # Do nothing, pipe it forward to next filter
        end
    end
end

function __smart-ctrl-v::mutate::github-download-file
    # https://github.com/Pipshag/dotfiles_nord/blob/master/.config/waybar/config
    # https://raw.githubusercontent.com/Pipshag/dotfiles_nord/master/.config/waybar/config

    # TODO: maybe check if a file with the same name exists and ask before overwriting
    while read line
        if string match --regex --groups-only "^'https://github.com/([^/]+)/([^/]+)/blob/([^/]+)/(.+)'" -- $line | read --line owner repo branch file
            # printf "wget -O %s https://raw.githubusercontent.com/%s/%s/%s/%s\n" $file $owner $repo $branch $file
            printf "wget --no-verbose https://raw.githubusercontent.com/%s/%s/%s/%s\n" $owner $repo $branch $file
        else if string match --regex --groups-only "^'https://raw.githubusercontent.com/([^/]+)/([^/]+)/([^/]+)/(.+)'" -- $line | read --line owner repo branch file
            printf "wget --no-verbose https://raw.githubusercontent.com/%s/%s/%s/%s\n" $owner $repo $branch $file
        else
            printf "%s\n" $line # Do nothing, pipe it forward to next filter
        end
    end
end

function __smart-ctrl-v::mutate::git-clone
    if isatty stdin
        printf "%serror in %s:%s%s stdin cannot be a tty\n" (set_color red) (status filename) (status function) (set_color normal) >&2
    end

    if test (commandline | string trim) != ""
        # The commandline is not empty, so we do not want to mutate the clipboard
        printf "%s\n" $lines
        return
    end

    while read line # read from stdin
        # You press the "Clone, open or download" button on github
        if string match --quiet --regex "^'*(https?|git)://.*\.git'*\$" -- $line
            # Parse the directory name from the url
            # example: https://github.com/nushell/nushell.git
            set -l repo (string split --max=1 --right / $line \
			| string replace --all "'" "" \
			| string sub --end=-4)[-1]

            if test -d $repo
                echo "cd $repo # github repository `$repo` already exist!"
            else
                echo "git clone --recurse-submodules $line && cd $repo && git branch"
            end
            # You ctrl+l && ctrl+c a git url
            # TODO: handle cases like "https://github.com/kpbaks/scripts" properly

        else if string match --regex --groups-only "^'*https?://git(hub|lab).com/([^/]+)/([^/']+)'*" -- $line | read --line owner repo
            if test -d $repo
                echo "cd $repo # github repository `$repo` already exist!"
            else
                echo "git clone --recurse-submodules $line && cd $repo && git branch"
            end
        else
            printf "%s\n" $line # Do nothing, pipe it forward to next filter
        end
    end
end

function smart-ctrl-v::paste
    commandline --insert (
        fish_clipboard_paste \
        | __smart-ctrl-v::filter::common-leading-whitespace \
        | __smart-ctrl-v::filter::command-indicating-leading-dollar \
        | __smart-ctrl-v::mutate::escape-dollar-and-questionmark \
        | __smart-ctrl-v::mutate::gh-repo-clone \
        | __smart-ctrl-v::mutate::github-download-file \
        | __smart-ctrl-v::mutate::git-clone
    )
    commandline --function repaint
end

# create keybinding
bind \cv smart-ctrl-v::paste
