#!/usr/bin/env ruby
# Wire the WallabagExpoArtifacts-release local Swift Package into
# wallabag.xcodeproj for the "wallabag" iOS app target. Idempotent.

require 'xcodeproj'

PROJ_PATH = File.expand_path('wallabag.xcodeproj', __dir__)
PKG_REL_PATH = 'expo-app/artifacts/WallabagExpoArtifacts-release'
PKG_PRODUCT = 'WallabagExpoArtifacts-release'
TARGET_NAME = 'wallabag'

project = Xcodeproj::Project.open(PROJ_PATH)
target = project.targets.find { |t| t.name == TARGET_NAME }
raise "Target #{TARGET_NAME} not found" unless target

# Brownfield needs IPHONEOS_DEPLOYMENT_TARGET >= 16.4 on SDK 56+.
target.build_configurations.each do |c|
  current = (c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] || '').to_s
  parts = current.split('.').map(&:to_i)
  needs_bump = parts.empty? || parts[0] < 16 || (parts[0] == 16 && (parts[1] || 0) < 4)
  if needs_bump
    c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.4'
    puts "✓ Bumped IPHONEOS_DEPLOYMENT_TARGET → 16.4 on [#{c.name}] (was #{current.inspect})"
  else
    puts "⊙ IPHONEOS_DEPLOYMENT_TARGET = #{current} on [#{c.name}] (kept)"
  end
end

# Add ExpoIntegration.swift to the App group + source build phase.
app_group = project.main_group.find_subpath('App', true)
expo_ref = app_group.files.find { |f| f.display_name == 'ExpoIntegration.swift' }
unless expo_ref
  expo_ref = app_group.new_reference('ExpoIntegration.swift')
  expo_ref.last_known_file_type = 'sourcecode.swift'
  puts "✓ Created file reference for ExpoIntegration.swift"
end
unless target.source_build_phase.files_references.include?(expo_ref)
  target.add_file_references([expo_ref])
  puts "✓ Added ExpoIntegration.swift to #{TARGET_NAME} source phase"
else
  puts "⊙ ExpoIntegration.swift already in source phase"
end

# Local Swift Package reference.
package_ref = project.root_object.package_references.find do |r|
  r.is_a?(Xcodeproj::Project::Object::XCLocalSwiftPackageReference) &&
    r.relative_path == PKG_REL_PATH
end
unless package_ref
  package_ref = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
  package_ref.relative_path = PKG_REL_PATH
  project.root_object.package_references << package_ref
  puts "✓ Added local Swift Package reference → #{PKG_REL_PATH}"
else
  puts "⊙ Local Swift Package reference already present"
end

# SDK 56+ canary bundles every framework under one aggregate product —
# single product link.
existing = target.package_product_dependencies.find { |d| d.product_name == PKG_PRODUCT }
if existing
  puts "⊙ #{PKG_PRODUCT} already linked"
else
  dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dep.package = package_ref
  dep.product_name = PKG_PRODUCT
  target.package_product_dependencies << dep

  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.product_ref = dep
  target.frameworks_build_phase.files << build_file
  puts "✓ Linked #{PKG_PRODUCT}"
end

project.save
puts "DONE"
