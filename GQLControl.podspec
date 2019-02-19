Pod::Spec.new do |s|

  s.name         = "GQLControl"
  s.version      = "0.0.1"
  s.summary      = "Apollo wrapper library to manage queries."

  s.description  = "Make apollo queries with Result pattern that return custom objects."

  s.homepage     = "https://github.com/Aldoukfm/GQLControl"

  s.license      = { :type => "MIT", :file => "LICENSE" }


  s.author             = { "Aldo Fuentes" => "aldo.k.fuentes@gmail.com" }

  s.platform     = :ios, "11.0"

  #  When using multiple platforms
  # s.ios.deployment_target = "5.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"

  s.source = { :git => "https://github.com/Aldoukfm/GQLControl.git",
      :tag => "#{s.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  s.source_files  = "GQLControl/*.{swift}"
  s.dependency 'Apollo', '~> 0.9.4'

  s.swift_version = "4.2"

end
