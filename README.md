# Homebrew Portable Ruby

Formulae and tools to build versions of Ruby that can be installed and run from anywhere on the filesystem.

## How do I install these formulae

Just `brew install homebrew-ppc64le/portable-ruby/<formula>`.

## How do I build packages for these formulae

Build a Docker image for your architecture by running one of the following commands.

- `docker build -f Dockerfile-ppc64le --platform linux/ppc64le --build-arg img=debian:buster -t homebrew-portable .`

Build the `portable-ruby` package using that Docker image.

```sh
docker run --name=homebrew-portable-ruby -w /bottle homebrew-portable brew portable-package ruby
docker cp homebrew-portable-ruby:/bottle .
```

## Current Status

Used in production for homebrew-ppc64le/brew.

### Linux

1. `irb` on Linux builds seems to fail to link to ncurses statically. If `portable-ncurses` is removed, `irb` will fail to handle left, right or backspace keystroke.

## License

Code is under the [BSD 2 Clause (NetBSD) license](https://github.com/homebrew-ppc64le/homebrew-portable-ruby/blob/master/LICENSE.txt).
