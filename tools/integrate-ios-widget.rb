# Integrate only the disposable simulator scaffold. No Apple registration or signing.
require 'xcodeproj'
require 'fileutils'
root = File.expand_path('..', __dir__)
ios = File.join(root, '.codemagic-ios', 'ios')
raise 'Generate the isolated Flutter scaffold first' unless File.directory?(File.join(ios, 'Runner.xcodeproj'))
project = Xcodeproj::Project.open(File.join(ios, 'Runner.xcodeproj'))
runner = project.targets.find { |t| t.name == 'Runner' }
raise 'Runner target missing' unless runner
raise 'Widget already integrated; regenerate the isolated scaffold' if project.targets.any? { |t| t.name == 'AuryaLockScreen' }

source = File.join(root, 'ios_integration')
%w[Shared Runner Widget].each do |folder|
  dest = File.join(ios, 'AuryaNative', folder)
  FileUtils.mkdir_p(dest)
  Dir[File.join(source, folder, '*.swift')].each { |path| FileUtils.cp(path, dest) }
end
FileUtils.cp(File.join(source, 'Runner', 'AppDelegate.swift'), File.join(ios, 'Runner', 'AppDelegate.swift'))
# AppDelegate already belongs to Runner; never add a second @main source.
FileUtils.rm(File.join(ios, 'AuryaNative', 'Runner', 'AppDelegate.swift'))
widget = project.new_target(:app_extension, 'AuryaLockScreen', :ios, '16.0')
widget.product_reference.path = 'AuryaLockScreen.appex'
group = project.main_group.new_group('AuryaNative', 'AuryaNative')
shared = group.new_group('Shared', 'Shared')
store = shared.new_file('AuryaWidgetStore.swift')
timeline = shared.new_file('AuryaTimelineEngine.swift')
runner_group = group.new_group('Runner', 'Runner')
bridge = runner_group.new_file('AuryaWidgetBridge.swift')
widget_group = group.new_group('Widget', 'Widget')
view = widget_group.new_file('AuryaLockScreenWidget.swift')
runner.source_build_phase.add_file_reference(store)
runner.source_build_phase.add_file_reference(bridge)
[store, timeline, view].each { |ref| widget.source_build_phase.add_file_reference(ref) }
runner.add_dependency(widget)
embed = runner.new_copy_files_build_phase('Embed App Extensions')
embed.dst_subfolder_spec = '13'
build_file = embed.add_file_reference(widget.product_reference)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
# Embed before Flutter's Thin Binary script to avoid an extension dependency cycle.
runner.build_phases.delete(embed)
runner.build_phases.insert(runner.build_phases.index(runner.resources_build_phase) + 1, embed)

app_group = 'group.app.aurya.simulator'
plist_path = File.join(ios, 'Runner', 'Info.plist')
info = Xcodeproj::Plist.read_from_path(plist_path)
info['CFBundleDisplayName'] = 'AURYA'
info['AuryaAppGroup'] = app_group
info['FlutterDeepLinkingEnabled'] = false
info['CFBundleURLTypes'] = [{ 'CFBundleURLName' => 'AURYA reflections', 'CFBundleURLSchemes' => ['aurya'] }]
Xcodeproj::Plist.write_to_path(info, plist_path)
widget_info = {
  'CFBundleDisplayName' => 'AURYA', 'CFBundleExecutable' => '$(EXECUTABLE_NAME)',
  'CFBundleIdentifier' => '$(PRODUCT_BUNDLE_IDENTIFIER)', 'CFBundleInfoDictionaryVersion' => '6.0',
  'CFBundleName' => '$(PRODUCT_NAME)', 'CFBundlePackageType' => 'XPC!',
  'CFBundleShortVersionString' => '$(MARKETING_VERSION)', 'CFBundleVersion' => '$(CURRENT_PROJECT_VERSION)',
  'AuryaAppGroup' => app_group,
  'NSExtension' => { 'NSExtensionPointIdentifier' => 'com.apple.widgetkit-extension' }
}
Xcodeproj::Plist.write_to_path(widget_info, File.join(ios, 'AuryaNative', 'Widget', 'Info.plist'))
entitlements = { 'com.apple.security.application-groups' => [app_group] }
Xcodeproj::Plist.write_to_path(entitlements, File.join(ios, 'AuryaNative', 'Simulator.entitlements'))
[runner, widget].each do |target|
  target.build_configurations.each do |config|
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'AuryaNative/Simulator.entitlements'
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['MARKETING_VERSION'] = '0.5.0'
    config.build_settings['CURRENT_PROJECT_VERSION'] = '5'
    config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  end
end
widget.build_configurations.each do |config|
  config.build_settings.merge!({
    'PRODUCT_BUNDLE_IDENTIFIER' => 'app.aurya.aurya.AuryaLockScreen',
    'PRODUCT_NAME' => 'AuryaLockScreen',
    'PRODUCT_MODULE_NAME' => 'AuryaLockScreen',
    'INFOPLIST_FILE' => 'AuryaNative/Widget/Info.plist',
    'GENERATE_INFOPLIST_FILE' => 'NO', 'SKIP_INSTALL' => 'YES',
    'APPLICATION_EXTENSION_API_ONLY' => 'YES',
    'LD_RUNPATH_SEARCH_PATHS' => ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  })
end
project.save
puts 'Integrated widget target, shared store, engine bridge and reflection links in simulator scaffold.'
puts 'Simulator-only group is not registered with Apple; real-device signing remains pending.'
