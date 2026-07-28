# Twist

## Rugged with SSH support

The `rugged` gem bundles `libgit2`, but by default it is compiled without SSH
transport support. If you need to clone or fetch over `git@`/`ssh://` remotes,
`rugged` must be recompiled against `libssh2`.

### Prerequisites (macOS / Homebrew)

```sh
brew install libssh2 openssl@3 cmake
```

### Recompile rugged with SSH

Reinstall the gem, forcing a vendored `libgit2` build with `--with-ssh`. Point
`pkg-config` and CMake at the Homebrew `libssh2`/`openssl` so the build can find
them:

```sh
export PKG_CONFIG_PATH="/opt/homebrew/opt/libssh2/lib/pkgconfig:/opt/homebrew/opt/openssl@3/lib/pkgconfig"
export CMAKE_FLAGS="-DCMAKE_PREFIX_PATH=/opt/homebrew/opt/libssh2"

gem install rugged --version 1.9.0 --force -- --with-ssh
```

Notes:

- Do **not** pass `--use-system-libraries`. Any value (even `false`) is treated
  as truthy and makes rugged link against a system `libgit2`, which may not have
  SSH enabled and can fail a version check.
- SSH is toggled by the `--with-ssh` config flag (`with_config("ssh")` in the
  gem's `extconf.rb`), which turns on `-DUSE_SSH=ON` for the vendored `libgit2`.

### Verify

```sh
ruby -e "require 'rugged'; puts Rugged.features.inspect"
# => [:threads, :https, :ssh]
```

`:ssh` in the list confirms SSH transport is compiled in.
