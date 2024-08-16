# intellipaste.fish

TODO: pitch

## Installation
```fish
fisher install kpbaks/intellipaste.fish
```

## Examples

### `leading-dollar`

...

```fish
$ git clone https://github.com/kpbaks/intellipaste.fish
```

Turns to:

```fish
git clone https://github.com/kpbaks/intellipaste.fish
```

### `common-leading-whitespace`

```fish
    stst
      stst
    stt
  st
```

```fish

```

### `escape-dollar-and-questionmark`

### `gh-repo-clone`


### `github-download-file`

### `git-clone`


### `quoted-string`

### `strip-comments`


## Configuration


```fish
intellipaste # [-h|--help]

intellipaste list

intellipaste reset

function my_filter
  while read line
    string upper -- $line
  end
end

function nothing
  while read line
    echo $line
  end
end

set -a $intellipaste_filters my_filter nothing
```
