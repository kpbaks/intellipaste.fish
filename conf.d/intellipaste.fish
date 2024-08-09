status is-interactive; or return
# TODO: change plugin name to smart-paste.fish
# intellipaste.fish

# TODO:
# - gitlab
# - bitbucket
# - sourceberg


set -l log_prefix (printf '[%sintellipaste.fish%s]' (set_color blue) (set_color normal))

# TODO: come up with other useful substitutions
# - perhaps take the current prompt into context, or $PWD

set -g __intellipaste_builtin_filters \
    leading-dollar \
    common-leading-whitespace \
    escape-dollar-and-questionmark \
    gh-repo-clone \
    github-download-file \
    git-clone \
    quoted-string

# TODO: generate list automatically with `functions`

set -q intellipaste_filters
or set -U intellipaste_filters $__intellipaste_builtin_filters

function intellipaste -d "Manage `intellipaste.fish`"
    # TODO: list all active filters/substitutions and the order in which they are applied

    if not argparse h/help -- $argv
        eval (status function) --help
        return 2
    end

    if set -q _flag_help
        # TODO: print help
        return 0
    end

    set -l subcommand list
    if test (count $argv) -gt 0
        set subcommand $argv[1]
    end

    switch $subcommand
        case list
            set -l reset (set_color normal)
            set -l red (set_color red)
            set -l green (set_color green)
            set -l builtin_color (set_color cyan)
            set -l custom_color (set_color magenta)
            set -l disabled_color (set_color red --dim)
            set -l b (set_color --bold)

            set -l name_header NAME
            set -l name_max_width (string length $name_header)
            for f in $intellipaste_filters
                set -l w (string length -- $f)
                set name_max_width (math "max $name_max_width, $w")
            end
            set -l name_rpad (string repeat --count (math "$name_max_width - $(string length $name_header)") ' ')

            set -l header (printf ' KIND    | NAME%s' $name_rpad)
            printf '%s\n' $header
            string repeat --count (string length $header) -
            for f in $__intellipaste_builtin_filters
                set -l enabled_color $disabled_color
                if contains -- $f $intellipaste_filters
                    set enabled_color $green
                end
                printf ' %sbuiltin%s | %s%s%s\n' $builtin_color $reset $enabled_color $f$reset
            end

            for f in $intellipaste_filters
                set -l enabled_color $green
                contains -- $f $__intellipaste_builtin_filters; and continue
                printf ' %scustom%s  | %s%s%s\n' $custom_color $reset $enabled_color $f $reset
            end

        case reset
            set -U intellipaste_filters $__intellipaste_builtin_filters
            # TODO: print message
            eval (status function) list
        case toggle
            echo todo
            # command -q fzf
        case '*'
            eval (status function) --help
            return 2
    end

end

function __intellipaste::filter::leading-dollar
    if isatty stdin
        printf '%s: %sstdin cannot be a tty%s\n' (status function) (set_color red) (set_color normal) >&2
        return 2
    end
    while read line
        # Remove the leading $ from the clipboard content, so
        # that the command can be executed.
        # This is useful when pasting a command from guides that use
        # a $ to indicate that the command should be run in the terminal.
        string replace --regex "^\s*\\\$\s+" "" -- $line
    end
end

function __intellipaste::utils::get-common-leading-whitespace-length
    if isatty stdin
        printf '%s: %sstdin cannot be a tty%s\n' (status function) (set_color red) (set_color normal) >&2
        return 2
    end

    set -l leading_whitespace_lengths
    while read line
        test -z $line; and continue # skip empty lines
        set -l leading_whitespace (string match --regex --groups-only "^(\s*)" $line)
        set -a leading_whitespace_lengths (string length $leading_whitespace)
    end

    # If there are no lines, with leading whitespace, then return 0
    test (count $leading_whitespace_lengths) -eq 0; and printf "0\n"; and return 0

    set -l minimum_common_leading_whitespace (math min "$(string join "," $leading_whitespace_lengths)")
    echo $minimum_common_leading_whitespace
end

function __intellipaste::filter::common-leading-whitespace
    if isatty stdin
        printf '%s: %sstdin cannot be a tty%s\n' (status function) (set_color red) (set_color normal) >&2
        return 2
    end

    # TODO: shorten var names
    set -l minimum_common_leading_whitespace (__intellipaste::utils::get-common-leading-whitespace-length $lines)
    set minimum_common_leading_whitespace (math "$minimum_common_leading_whitespace + 1") # `string sub --start=<n>` indexes from 1
    while read line
        string sub --start=$minimum_common_leading_whitespace -- $line
    end
end

function __intellipaste::filter::escape-dollar-and-questionmark
    if isatty stdin
        printf '%s: %sstdin cannot be a tty%s\n' (status function) (set_color red) (set_color normal) >&2
        return 2
    end
    set -l pattern "(https?://[^ ]+)"
    set -l replacement "'\$1'"
    while read line
        string replace --regex $pattern $replacement -- $line
    end
end

function __intellipaste::filter::gh-repo-clone
    if isatty stdin
        printf '%s: %sstdin cannot be a tty%s\n' (status function) (set_color red) (set_color normal) >&2
        return 2
    end

    while read line
        if string match --regex --groups-only "^\s*gh repo clone ([^/]+)/(.+)" $line \
                | read --line owner repo
            # TODO: do check other place
            if test -d $repo
                echo "cd $repo # github repository `$repo` already exist!"
            else
                if set -q smart_paste_clone_dir_user
                    if not test -d $smart_paste_clone_dir_user
                        # create dir
                        command mkdir -p $smart_paste_clone_dir_user
                        # TODO: print message
                    end
                    set -l username (command git config --global --get user.name)

                    printf "cd $smart_paste_clone_dir;"
                end
                # TODO: check if repo already downloaded
                echo "gh repo clone $owner/$repo && cd $repo"
            end
        else
            printf "%s\n" $line # Do nothing, pipe it forward to next filter
        end
    end
end

function __intellipaste::filter::github-download-file
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

function __intellipaste::filter::git-clone
    if isatty stdin
        printf '%s: %sstdin cannot be a tty%s\n' (status function) (set_color red) (set_color normal) >&2
        return 2
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

function __intellipaste::filter::https-url
    while read line
        echo $line
    end
end


function __intellipaste::filter::quoted-string
    while read line
        echo $line
    end
end

function __intellipaste::paste -d 'TODO:'
    set -l filters
    for f in $intellipaste_filters
        if functions -q __intellipaste::filter::$f
            set -a filters __intellipaste::filter::$f
        else if functions -q $f
            set -a filters $f
        else
            printf '%serror%s: %s is not the name of a known function\n' (set_color red) (set_color normal) $f >&2
            return 2
            # TODO: improve error handling
        end
    end
    set -l pipeline (string join ' | ' -- fish_clipboard_paste $filters)
    echo $pipeline
    # set -l result (eval $pipeline)
    # if test $status -eq 0
    #     commandline --insert $result
    # end


    # commandline --function repaint
    commandline --function force-repaint
end



if test (count $intellipaste_filters) -eq 0
    printf '%s %sWARN%s: \$intellipaste_filters is empty, no keybind created\n' $log_prefix (set_color yellow) (set_color normal)
    return
end

# TODO: make configurable
# create keybinding
bind \cv __intellipaste::paste
