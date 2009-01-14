spec = Gem::Specification.new do |s|
  s.name = 'ranno'
  s.version = '0.1'
  s.has_rdoc = false
  s.extra_rdoc_files = ['LICENSE']
  s.summary = 'Lets you add useful annotations to your Ruby libraries!'
  s.description = s.summary
  s.author = 'Max "Nanodeath" Aller'
  s.email = 'nanodeath@gmail.com'
  # s.executables = ['your_executable_here']
  s.files = %w(LICENSE README.textile Rakefile) + Dir.glob("{bin,lib,spec}/**/*")
  s.require_path = "lib"
  s.bindir = "bin"
  s.add_dependency("extlib", ">= 0.9.0", "< 1.0")
  s.add_dependency("json", ">= 1.1", "< 1.2")
end
