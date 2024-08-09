set -l c complete -c intellipaste

$c -f # Disable file completion


set -l subcommands list reset
set -l cond "not __fish_seen_subcommand_from $subcommands"

$c -n $cond -a list
$c -n $cond -a reset
