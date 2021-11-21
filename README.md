# fc_file_encryption1

first: Write and read a large file

second: encrypt and decrypt the the data 
```plaintext

```

```plaintext

convert: ^3.0.1

path_provider: ^2.0.6

pointycastle: ^3.3.5

sodium: 

https://pub.dev/packages/flutter_sodium
flutter_sodium: ^0.2.0
https://github.com/firstfloorsoftware/flutter_sodium

https://pub.dev/packages/pbkdf2_dart *** nicht null safety
pbkdf2_dart: ^2.1.0

```

For building on MacOS Chip 1
ACHTUNG: in ISO/Podfile ergänzen und Podfile.lock löschen

```plaintext
post_install do |installer|
installer.pods_project.targets.each do |target|
flutter_additional_ios_build_settings(target)
# 兼容 Flutter 2.5
target.build_configurations.each do |config|
#       config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'i386 arm64'
end
end
end
```



A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
