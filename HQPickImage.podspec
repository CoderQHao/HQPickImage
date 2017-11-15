Pod::Spec.new do |s|

    s.name         = "HQPickImage"
    s.version      = "0.0.1"
    s.summary      = "A lightweight and pure Swift implemented library for downloading and cacheing image from the web."

    s.description  = <<-DESC
                     Kingfisher is a lightweight and pure Swift implemented library for downloading and cacheing image from the web. It provides you a chance to use pure Swift alternation in your next app.
                     DESC

    s.homepage     = "https://github.com/CoderQHao/HQPickImage"


    s.license      = { :type => "MIT", :file => "LICENSE" }

    s.authors            = { "CoderQHao" => "haoqing3059@icloud.com" }

    s.ios.deployment_target = "9.0"

    s.source       = { :git => "https://github.com/onevcat/Kingfisher.git", :tag => s.version }

s.source_files  = ["Sources/*.swift", "Sources/Kingfisher.h", "Sources/Kingfisher.swift"]
s.public_header_files = ["Sources/Kingfisher.h"]

s.osx.exclude_files = ["Sources/AnimatedImageView.swift", "Sources/UIButton+Kingfisher.swift"]
s.watchos.exclude_files = ["Sources/AnimatedImageView.swift",
"Sources/UIButton+Kingfisher.swift",
"Sources/ImageView+Kingfisher.swift",
"Sources/NSButton+Kingfisher.swift",
"Sources/Indicator.swift",
"Sources/Filter.swift",
"Sources/Placeholder.swift"
]
s.ios.exclude_files = "Sources/NSButton+Kingfisher.swift"
s.tvos.exclude_files = "Sources/NSButton+Kingfisher.swift"

s.requires_arc = true
s.framework = "CFNetwork"

s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }
end

