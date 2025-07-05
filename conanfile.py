from conan import ConanFile
import platform

class PythonDeps(ConanFile):
  settings = 'os', 'compiler', 'build_type', 'arch'
  generators = [ 'PkgConfigDeps', 'AutotoolsToolchain' ]

  def requirements(self):
    self.requires('zlib/1.3.1')
    self.requires('xz_utils/5.4.5')
    self.requires('bzip2/1.0.8')
    self.requires('openssl/3.3.2')
    self.requires('libuuid/1.0.3')
    self.requires('ncurses/6.5')
    self.requires('libgettext/0.22')
    self.requires('gdbm/1.23')

    # These libraries are part of the OS on macOS, but are optional on Linux
    if self.settings.os == 'Linux':
      self.requires('sqlite3/3.46.1')
      self.requires('readline/8.2')

    if self.settings.os == 'Macos':
      self.requires('mpdecimal/4.0.0')
      # libdb is not supported on Apple Silicon
      # however on macOS 14+ there is native ndb support
      if self.settings.arch != 'armv8' and platform.mac_ver()[0].split('.')[0] < 14:
        self.requires('libdb/5.3.28')

  def configure(self):
    self.options['sqlite3'].enable_fts3 = True
    self.options['sqlite3'].enable_fts4 = True

    if self.settings.os == 'Macos':
      self.options['gdbm'].libgdbm_compat = True
