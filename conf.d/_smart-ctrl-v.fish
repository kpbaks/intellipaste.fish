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
        set --local line_without_dollar_prefix (string replace --regex "^\s*\\\$\s+" "" -- $line)
        printf "%s\n" $line_without_dollar_prefix
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
        set --local line_without_common_leading_whitespace (string sub --start=$minimum_common_leading_whitespace $line)
        printf "%s\n" $line_without_common_leading_whitespace
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
        string escape -- $line
        # set --local line_escaped (string replace --regex "https?://[^ ]+" "<a href=\"\\0\">\\0</a>" -- $line)
        # printf "%s\n" $line_escaped
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
        if string match --regex --groups-only "^\s*gh repo clone ([^/]+)/(.+)" $cb \
                | read --line owner repo
            printf "%s\n" "gh repo clone $owner/$repo && cd $repo && gh repo view --web"
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
    set --local buffer (commandline)
    printf "%s\n" $lines
    # for line in $lines
    #
    #     # You ctrl+l && ctrl+c a git url
    #     if string match --quiet --regex "^(https?|git)://.*\.git\$" -- $line
    #         # Parse the directory name from the url
    #         set --append postfix_args (string replace --all --regex '^.*/(.*)\.git$' '$1' $clipboard)
    #     else if string match --quiet --regex "^git clone .*\.git\$" -- "$clipboard"
    #         # example: git clone https://github.com/nushell/nushell.git
    #         set -l url (string replace --all --regex '^git clone (.*)\.git$' '$1' $clipboard)
    #         set -l reponame (string split --max=1 --right / $url)[-1]
    #         set -a postfix_args $url
    #         set -a postfix_args "&& cd $reponame"
    #     end
    # end
end

function __smart_paste
    set --local buffer (commandline)
    commandline --insert (fish_clipboard_paste \
        | __smart-ctrl-v.fish::filter::common-leading-whitespace \
        | __smart-ctrl-v.fish::filter::command-indicating-leading-dollar \
        | __smart-ctrl-v.fish::mutate::escape-dollar-and-questionmark \
        | __smart-ctrl-v.fish::mutate::gh-repo-clone \
        | __smart-ctrl-v.fish::mutate::git-clone)
    commandline --function repaint
    return

    #
    # set --local clipboard_content_modified
    # # Remove leading whitespace, by finding the minimum common leading whitespace of all lines
    # # and then removing that from all lines.
    #
    # set --local length_of_leading_whitespace_of_each_line
    # for i in (seq (count $clipboard_content))
    #     set --local line $clipboard_content[$i]
    #     # TODO: <kpbaks 2023-09-15 08:41:52> handle empty lines
    #     set --local leading_whitespace (string match --regex --groups-only "^(\s*)" $line)
    #     set --append length_of_leading_whitespace_of_each_line (string length $leading_whitespace)
    # end
    #
    # set --local minimum_common_leading_whitespace (math min "$(string join "," $length_of_leading_whitespace_of_each_line)")
    # if test $minimum_common_leading_whitespace -gt 0
    #     for i in (seq (count $clipboard_content))
    #         set --local line $clipboard_content[$i]
    #         set --local line_without_common_leading_whitespace (string sub --start $minimum_common_leading_whitespace $line)
    #         set --append clipboard_content_modified $line_without_common_leading_whitespace
    #     end
    # else
    #     set clipboard_content_modified $clipboard_content
    # end
    #
    # for i in (seq (count $clipboard_content_modified))
    #     set --local line $clipboard_content_modified[$i]
    #     # Remove the leading $ from the clipboard content, so
    #     # that the command can be executed.
    #     # This is useful when pasting a command from guides that use
    #     # a $ to indicate that the command should be run in the terminal.
    #     set --local line_without_dollar_prefix (string replace --regex "^\s*\\\$\s+" "" -- $line)
    #     set clipboard_content_modified[$i] $line_without_dollar_prefix
    # end
    # # set --local content_to_paste $cb
    # # set --local content_to_paste (string join " && " $cb)
    # set --local content_to_paste $clipboard_content_modified
    # # echo $content_to_paste
    # # TODO: <kpbaks 2023-09-14 18:59:39> check if the content of the `content_to_paste` is
    # # syntactically correct. If it is not, then ...
    # # TODO: <kpbaks 2023-09-14 21:32:46> handle multiline commands formatting better
    # commandline --insert $content_to_paste
    # commandline --function repaint
end

# $ cmake --version

bind \cv __smart_paste
