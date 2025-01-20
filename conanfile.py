from conan import ConanFile

class PythonDeps(ConanFile):
  settings = 'os', 'compiler', 'build_type', 'arch'
  generators = [ 'PkgConfigDeps', 'AutotoolsToolchain' ]

  def requirements(self):
    self.requires('zlib/1.3.1')
    self.requires('xz_utils/5.4.5')
    self.requires('bzip2/1.0.8')
    self.requires('openssl/3.3.2')
    self.requires('libgettext/0.22')

    # These libraries are part of the OS on macOS, but are optional on Linux
    if self.settings.os == 'Linux':
      self.requires('sqlite3/3.46.1')
      self.requires('readline/8.2')

    if self.settings.os == 'Macos':
      self.requires('mpdecimal/4.0.0')

  def configure(self):
    self.options['sqlite3'].enable_fts3 = True
    self.options['sqlite3'].enable_fts4 = True
