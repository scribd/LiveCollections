Pod::Spec.new do |s|
  s.name                  = "LiveCollections"
  s.version               = "0.9.8"
  s.summary               = "Automatically perform UITableView and UICollectionView animations with immutable data sets."
  s.description           = "An open source iOS framework that automatically performs UITableView and UICollectionView animations between two sets of immutable data. It supports generic data types and is thread-safe."
  s.homepage              = "https://github.com/scribd/LiveCollections"
  s.license               = "MIT"
  s.author                = { "Stephane Magne" => "stephane@scribd.com" }
  s.source                = { :git => "https://github.com/scribd/LiveCollections.git", :tag => "beta_0.9.8" }
  s.source_files          = "LiveCollectionsFramework/LiveCollections/**/*.swift"
  s.exclude_files         = "LiveCollectionsFramework/LiveCollections/Info.plist", "LiveCollectionsSample/LiveCollectionsSample/Info.plist"
  s.swift_version         = "4.2"
  s.platform              = :ios, "9.0"
  s.ios.deployment_target = "9.0"
end
