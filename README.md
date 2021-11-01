# fc_file_encryption1

first: Write and read a large file

second: encrypt and decrypt the the data 

convert: ^3.0.1

path_provider: ^2.0.6

pointycastle: ^3.3.5

The benchmark shows: it takes much to long to read and write the data in chunks

// read & write all data in one step for 1 mb file

flutter: step 6 load data RAF elapsed: 4597

flutter: step 7 write data RAF elapsed: 1742

flutter: step 9 read - write in chunks RAF elapsed: 6089843

This version uses additionally https://pub.dev/packages/aes_crypt but this is not null safety

Someone added support for this: https://pub.dev/packages/aes_crypt_null_safe

file encryption runs but on Asynchronus mode it runs into error

Unhandled Exception: type 'Future<int?>' is not a subtype of type 'FutureOr<int>' in type cast

#0      _Cryptor._readKeys (package:aes_crypt_null_safe/src/cryptor.dart:1279:56)
<asynchronous suspension>

#1      _Cryptor.decryptFile (package:aes_crypt_null_safe/src/cryptor.dart:588:34)
<asynchronous suspension>

#2      AesCrypt.decryptFile (package:aes_crypt_null_safe/src/aescrypt.dart:356:12)
<asynchronous suspension>

aes_crypt_null_safe: ^2.0.1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
