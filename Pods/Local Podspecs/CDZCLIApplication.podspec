Pod::Spec.new do |s|
  s.name               = "CDZCLIApplication"
  s.version            = "0.1.0"
  s.summary            = "Useful framework for building nontrivial CLI applications."
  s.homepage           = "https://github.com/cdzombak/CDZCLIApplication"
  s.license            = 'MIT'
  s.author             = { "Chris Dzombak" => "chris@chrisdzombak.net" }
  s.source             = { :git => "https://github.com/cdzombak/CDZCLIApplication.git", :tag => s.version.to_s }

  s.platform           = :osx
  s.osx.deployment_target = '10.8'
  s.requires_arc       = true
  s.frameworks         = 'Foundation'

  s.source_files       = 'Classes/**/*.{h,m}'
  s.prefix_header_contents = '#import "CDZCLIPrint.h"'
end
