# 2025-07-04

- Point the default directory for OpenSSL on macOS to the system root certificates in `/etc/ssl`

# 2025-07-04

- Avoid any homebrew libraries on macOS

# 2025-07-02

- Get OpenSSL from conan and include root CA certificates from the CURL project
- Support Windows and Linux arm64

# 2024-07-01

- [#3](https://github.com/mmomtchev/static-portable-python/issues/3), on Linux, avoid dependencies on `sqlite3.so` and `libreadline.so.8`

# 2024-07-01

- [#1](https://github.com/mmomtchev/static-portable-python/pull/1), on Linux and macOS, build with static versions of the compression libraries obtained from `conan`
