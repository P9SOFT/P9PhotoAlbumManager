Pod::Spec.new do |s|

  s.name         = "P9PhotoAlbumManager"
  s.version      = "1.1.0"
  s.summary      = "Easy, and quick library for handling iOS Photo Album."
  s.homepage     = "https://github.com/P9SOFT/P9PhotoAlbumManager"
  s.license      = { :type => 'MIT' }
  s.author       = { "Tae Hyun Na" => "taehyun.na@gmail.com" }

  s.ios.deployment_target = '8.0'
  s.requires_arc = true

  s.source       = { :git => "https://github.com/P9SOFT/P9PhotoAlbumManager.git", :tag => "1.1.0" }
  s.swift_version = "4.2"
  s.source_files  = "Sources/*.swift"

end
