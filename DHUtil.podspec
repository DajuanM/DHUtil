Pod::Spec.new do |s|
s.name         = "DHUtil"
s.version      = "1.0.0"
s.summary      = "工具"
s.description  = <<-DESC
智控车云工具
DESC
s.homepage     = "https://github.com/DajuanM/DHUtil"
s.license      = "MIT"
s.author       = { "Aiden" => "252289287@qq.com" }
s.source       = { :git => "https://github.com/DajuanM/DHUtil.git", :tag => "#{s.version}" }
s.source_files  = "DHUtil","DHUtil/*.swift", "DHUtil/Source/*.swift"
s.requires_arc = true
s.ios.deployment_target = '10.0'
s.dependency = "MBProgressHUD"
s.dependency = "CryptoSwift"
end