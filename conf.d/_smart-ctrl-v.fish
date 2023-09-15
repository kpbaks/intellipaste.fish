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

function __smart-ctrl-v.fish::filter::dollar
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

function __smart_paste
    set --local buffer (commandline)
    set --local cb (fish_clipboard_paste)
    for i in (seq (count $cb))
        set --local line $cb[$i]
        if string match --regex --quiet "^\s*\\\$\s+" $line
            # Remove the leading $ from the clipboard content, so
            # that the command can be executed.
            # This is useful when pasting a command from guides that use
            # a $ to indicate that the command should be run in the terminal.
            set line (string replace --regex "^\s*\\\$\s+" "" -- $line)
            set cb[$i] $line
        end
    end
    # TODO: <kpbaks 2023-09-14 18:53:52> remove leading whitespace, by
    # finding the minimum common leading whitespace of all lines
    # and then removing that from all lines.
    set --local content_to_paste $cb
    if string match --regex --quiet "^\s*gh repo clone" $cb
        # TODO: <kpbaks 2023-09-14 21:40:37> handle case where (path basename $PWD) == $repo
        string match --regex --groups-only "^\s*gh repo clone ([^/]+)/(.+)" $cb \
            | read --line owner repo
        set content_to_paste "$content_to_paste && cd $repo && gh repo view --web"
    else if string match --regex --quiet "^\s*git clone" $cb
        # TODO: <kpbaks 2023-09-14 21:37:56> see `abbr_git_clone`
    end
    # TODO: <kpbaks 2023-09-14 18:59:39> check if the content of the `content_to_paste` is
    # syntactically correct. If it is not, then ...
    # TODO: <kpbaks 2023-09-14 21:32:46> handle multiline commands formatting better
    commandline --insert $content_to_paste
    commandline --function repaint
end

# $ cmake --version

bind \cv __smart_paste
