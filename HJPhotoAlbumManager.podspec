Pod::Spec.new do |s|

  s.name         = "HJPhotoAlbumManager"
  s.version      = "1.1.0"
  s.summary      = "Photo Album handling module based on Hydra framework."
  s.homepage     = "https://github.com/P9SOFT/HJPhotoAlbumManager"
  s.license      = { :type => 'MIT' }
  s.author       = { "Tae Hyun Na" => "taehyun.na@gmail.com" }

  s.ios.deployment_target = '8.0'
  s.requires_arc = true

  s.source       = { :git => "https://github.com/P9SOFT/HJPhotoAlbumManager.git", :tag => "1.1.0" }
  s.swift_version = "4.2"
  s.source_files  = "Sources/*.swift"

end
