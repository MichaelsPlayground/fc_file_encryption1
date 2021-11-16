import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:fc_file_encryption1/aes_cbc_large_files_pc_2.dart';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:pointycastle/export.dart' as pc;

List listFiles = List.empty(growable: true);

_runAesCbcEncryption() async {
  print('AES CBC large file encryption');

  Directory directory = await getApplicationDocumentsDirectory();
  final String sourceFilePath = '${directory.path}/source.txt';
  final String cipherIvPbkdf2FilePath =
      '${directory.path}/cipher_iv_pbkdf2.txt';
  final String cipherIvFilePath = '${directory.path}/cipher_iv.txt';
  final String cipherNewFilePath = '${directory.path}/cipher_new.txt';
  final String cipherOldFilePath = '${directory.path}/cipher_old.txt';
  final String decryptOldFilePath = '${directory.path}/decrypt_old.txt';
  final String decryptIvPbkdf2FilePath =
      '${directory.path}/decrypt_iv_pbkdf2.txt';
  final String decryptIvFilePath = '${directory.path}/decrypt_iv.txt';
  final String decryptNewFilePath = '${directory.path}/decrypt_new.txt';

  // fixed key and iv - this is just for testing purposes
  String keyString = '12345678123456781234567812345678'; // 32 chars
  String ivString = '7654321076543210'; // 16 chars
  Uint8List key = createUint8ListFromString(keyString);
  Uint8List iv = createUint8ListFromString(ivString);
  if (_fileExistsSync(sourceFilePath)) {
    _deleteFileSync(sourceFilePath);
  }

  // generate a 'large' file with random content
  //final int testDataLength = (1024 * 1024); // 1 mb
  final int testDataLength = (1024 * 7 - 1);
  final step1 = Stopwatch()..start();
  Uint8List randomData = _generateRandomByte(testDataLength);
  _generateLargeFileSync(sourceFilePath, randomData, 1);
  /*
          Uint8List randomData = _generateRandomByte(testDataLength);
          //Uint8List randomData = _generateRandomByte((5));
          // write data to file
          _writeUint8ListSync(sourceFilePath, randomData);
           */
  var step1Elapsed = step1.elapsed;

  print('\ndata for reference');
  // for reference
  // get sha-256 of file
  Uint8List sourceSha256 = await _getSha256File(sourceFilePath);
  int sourceFileLength = await _getFileLength(sourceFilePath);
  print('sourcePath fileLength: ' + sourceFileLength.toString());
  print('sourcePath SHA-256:     ' + bytesToHex(sourceSha256));
  // encrypt in one run
  final step2 = Stopwatch()..start();
  Uint8List plaintextLoad = _readUint8ListSync(sourceFilePath);
  Uint8List ciphertextOld = _encryptAesCbcMemory(plaintextLoad, key, iv);
  _writeUint8ListSync(cipherOldFilePath, ciphertextOld);
  var step2Elapsed = step2.elapsed;
  Uint8List cipherOldSha256 = await _getSha256File(cipherOldFilePath);
  int cipherOldFileLength = await _getFileLength(cipherOldFilePath);
  print('cipherOldPath fileLength: ' + cipherOldFileLength.toString());
  print('cipherOldPath SHA-256:  ' + bytesToHex(cipherOldSha256));
  // decrypt in one run
  final step3 = Stopwatch()..start();
  Uint8List ciphertextOldLoad = await _readUint8ListSync(cipherOldFilePath);
  Uint8List decrypttextOld = _decryptAesCbcMemory(ciphertextOldLoad, key, iv);
  _writeUint8ListSync(decryptOldFilePath, decrypttextOld);
  var step3Elapsed = step3.elapsed;
  Uint8List decryptOldSha256 = await _getSha256File(decryptOldFilePath);
  int decryptOldFileLength = await _getFileLength(decryptOldFilePath);
  print('decryptOldPath fileLength: ' + decryptOldFileLength.toString());
  print('decryptOldPath SHA-256: ' + bytesToHex(decryptOldSha256));

  // delete new file if exist
  //_deleteFileSync(cipherNewFilePath);
  //print('\nfile ' + cipherNewFilePath + ' deleted if existed');

  print('\ndata encryption using RAF and chunks');
  // now encryption using chunks
  final step4 = Stopwatch()..start();
  await _encryptAesCbc(sourceFilePath, cipherNewFilePath, key, iv);
  var step4Elapsed = step4.elapsed;
  // check the data
  Uint8List cipherNewSha256 = await _getSha256File(cipherNewFilePath);
  int cipherNewFileLength = await _getFileLength(cipherNewFilePath);
  print('cipherNewPath fileLength: ' + cipherNewFileLength.toString());
  print('cipherNewPath SHA-256:  ' + bytesToHex(cipherNewSha256));

  // now decryption using chunks
  print('\ndata decryption using RAF and chunks');
  final step5 = Stopwatch()..start();
  await _decryptAesCbc(cipherNewFilePath, decryptNewFilePath, key, iv);
  var step5Elapsed = step5.elapsed;
  // check the data
  Uint8List decryptNewSha256 = await _getSha256File(decryptNewFilePath);
  int decryptNewFileLength = await _getFileLength(decryptNewFilePath);
  print('decryptNewPath fileLength: ' + decryptNewFileLength.toString());
  print('decryptNewPath SHA-256:  ' + bytesToHex(decryptNewSha256));

  print(
      '\ndata encryption using RAF and chunks with random iv stored in file');
  // now encryption using chunks
  final step6 = Stopwatch()..start();
  await _encryptAesCbcRandomIv(sourceFilePath, cipherIvFilePath, key);
  var step6Elapsed = step6.elapsed;
  // check the data
  Uint8List cipherIvSha256 = await _getSha256File(cipherIvFilePath);
  int cipherIvFileLength = await _getFileLength(cipherIvFilePath);
  print('cipherIvPath fileLength: ' + cipherIvFileLength.toString());
  print('cipherIvPath SHA-256:   ' + bytesToHex(cipherIvSha256));

  // now decryption using chunks
  print(
      '\ndata decryption using RAF and chunks with random iv stored in file');
  final step7 = Stopwatch()..start();
  await _decryptAesCbcRandomIv(cipherIvFilePath, decryptIvFilePath, key);
  var step7Elapsed = step7.elapsed;
  // check the data
  Uint8List decryptIvSha256 = await _getSha256File(decryptIvFilePath);
  int decryptIvFileLength = await _getFileLength(decryptIvFilePath);
  print('decryptIvPath fileLength: ' + decryptIvFileLength.toString());
  print('decryptIvPath SHA-256:   ' + bytesToHex(decryptIvSha256));

  print(
      '\ndata encryption using RAF and chunks with random iv stored in file and PBKDF2 key derivation');
  // now encryption using chunks
  String password = 'secret password';
  final step8 = Stopwatch()..start();
  await _encryptAesCbcRandomIvPbkdf2(
      sourceFilePath, cipherIvPbkdf2FilePath, password);
  var step8Elapsed = step8.elapsed;
  // check the data
  Uint8List cipherIvPbkdf2Sha256 =
  await _getSha256File(cipherIvPbkdf2FilePath);
  int cipherIvPbkdf2FileLength = await _getFileLength(cipherIvPbkdf2FilePath);
  print('cipherIvPbkdf2Path fileLength: ' +
      cipherIvPbkdf2FileLength.toString());
  print('cipherIvPbkdf2Path SHA-256:   ' + bytesToHex(cipherIvPbkdf2Sha256));

  // now decryption using chunks
  print(
      '\ndata decryption using RAF and chunks with random iv stored in file and PBKDF2 key derivation');
  final step9 = Stopwatch()..start();
  await _decryptAesCbcRandomIvPbkdf2(
      cipherIvPbkdf2FilePath, decryptIvPbkdf2FilePath, password);
  var step9Elapsed = step9.elapsed;
  // check the data
  Uint8List decryptIvPbkdf2Sha256 =
  await _getSha256File(decryptIvPbkdf2FilePath);
  int decryptIvPbkdf2FileLength =
  await _getFileLength(decryptIvPbkdf2FilePath);
  print('decryptIvPbkdf2Path fileLength: ' +
      decryptIvPbkdf2FileLength.toString());
  print(
      'decryptIvPbkdf2Path SHA-256:   ' + bytesToHex(decryptIvPbkdf2Sha256));

  // print out all again
  print('');
  print('*********** benchmark all steps ************');

  print('step 1 generate data:       ' +
      step1Elapsed.inMicroseconds.toString());
  print(
      'testDataLength:             ' + testDataLength.toString() + ' bytes');
  print('step 2 encrypt in memory:   ' +
      step2Elapsed.inMicroseconds.toString());
  print('step 3 decrypt in memory:   ' +
      step3Elapsed.inMicroseconds.toString());
  print('step 4 encrypt raf/chunked: ' +
      step4Elapsed.inMicroseconds.toString());
  print('step 5 decrypt raf/chunked: ' +
      step5Elapsed.inMicroseconds.toString());
  print('step 6 encrypt raf/chun iv: ' +
      step6Elapsed.inMicroseconds.toString());
  print('step 7 decrypt raf/chun iv: ' +
      step7Elapsed.inMicroseconds.toString());
  print('step 8 encrypt raf/chu PBK: ' +
      step8Elapsed.inMicroseconds.toString());
  print('step 9 decrypt raf/chu PBK: ' +
      step9Elapsed.inMicroseconds.toString());

  // get list of files
  print('alle Dateien:\n');
  listFiles = await _getFiles();
  for (var i = 0; i < listFiles.length; i++) {
    print(listFiles[i]);
  }

  print('*********** benchmark all steps finished ************');
}

// using random access file, iv is stored in the destination file
_encryptAesCbcRandomIvPbkdf2(String sourceFilePath,
    String destinationFilePath, String password) async {
  final int bufferLength = 2048;
  final int saltLength = 32; // salt for pbkdf2
  final int PBKDF2_ITERATIONS = 15000;
  final int ivLength = 16; // initialization vector length
  File fileSourceRaf = File(sourceFilePath);
  File fileDestRaf = File(destinationFilePath);
  RandomAccessFile rafR = await fileSourceRaf.open(mode: FileMode.read);
  RandomAccessFile rafW = await fileDestRaf.open(mode: FileMode.write);
  var fileRLength = await rafR.length();
  print('bufferLength: ' +
      bufferLength.toString() +
      ' fileRLength: ' +
      fileRLength.toString());
  await rafR.setPosition(0); // from position 0
  int fullRounds = fileRLength ~/ bufferLength;
  int remainderLastRound = (fileRLength % bufferLength) as int;
  print('fullRounds: ' +
      fullRounds.toString() +
      ' remainderLastRound: ' +
      remainderLastRound.toString());
  // derive key from password
  var passphrase = createUint8ListFromString(password);
  final salt = _generateRandomByte(saltLength);
  // generate and store salt in destination file
  await rafW.writeFrom(salt);
  pc.KeyDerivator derivator =
  new pc.PBKDF2KeyDerivator(new pc.HMac(new pc.SHA256Digest(), 64));
  pc.Pbkdf2Parameters params =
  new pc.Pbkdf2Parameters(salt, PBKDF2_ITERATIONS, 32);
  derivator.init(params);
  final key = derivator.process(passphrase);
  // generate and store iv in destination file
  final Uint8List iv = _generateRandomByte(ivLength);
  await rafW.writeFrom(iv);
  // pointycastle cipher setup
  final pc.CBCBlockCipher cipher = new pc.CBCBlockCipher(new pc.AESEngine());
  pc.ParametersWithIV<pc.KeyParameter> cbcParams =
  new pc.ParametersWithIV<pc.KeyParameter>(new pc.KeyParameter(key), iv);
  pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>
  paddingParams = new pc.PaddedBlockCipherParameters<
      pc.ParametersWithIV<pc.KeyParameter>, Null>(cbcParams, null);
  pc.PaddedBlockCipherImpl paddingCipher =
  new pc.PaddedBlockCipherImpl(new pc.PKCS7Padding(), cipher);
  paddingCipher.init(true, paddingParams); // true = encryption
  // now we are running the full rounds
  for (int rounds = 0; rounds < fullRounds; rounds++) {
    Uint8List bytesLoad = await rafR.read(bufferLength);
    Uint8List bytesLoadEncrypted = _processBlocks(paddingCipher, bytesLoad);
    await rafW.writeFrom(bytesLoadEncrypted);
  }
  // last round
  if (remainderLastRound > 0) {
    Uint8List bytesLoadLast = await rafR.read(remainderLastRound);
    Uint8List bytesLoadEncrypted = paddingCipher.process(bytesLoadLast);
    await rafW.writeFrom(bytesLoadEncrypted);
  } else {
    Uint8List bytesLoadEncrypted =
    new Uint8List(16); // append one block with padding
    int lastRoundEncryptLength =
    paddingCipher.doFinal(Uint8List(0), 0, bytesLoadEncrypted, 0);
    await rafW.writeFrom(bytesLoadEncrypted);
  }
  // close all files
  await rafW.flush();
  await rafW.close();
  await rafR.close();
}

// using random access file, iv is stored in sourceFilePath
_decryptAesCbcRandomIvPbkdf2(String sourceFilePath,
    String destinationFilePath, String password) async {
  final int bufferLength = 2048;
  final int saltLength = 32; // salt for pbkdf2
  final int PBKDF2_ITERATIONS = 15000;
  final int ivLength = 16; // initialization vector length
  File fileSourceRaf = File(sourceFilePath);
  File fileDestRaf = File(destinationFilePath);
  RandomAccessFile rafR = await fileSourceRaf.open(mode: FileMode.read);
  RandomAccessFile rafW = await fileDestRaf.open(mode: FileMode.write);
  var fileRLength = await rafR.length();
  print('bufferLength: ' +
      bufferLength.toString() +
      ' fileRLength: ' +
      fileRLength.toString());
  await rafR.setPosition(0); // from position 0
  int fullRounds = fileRLength ~/ bufferLength;
  int remainderLastRound = (fileRLength % bufferLength) as int;
  print('fullRounds: ' +
      fullRounds.toString() +
      ' remainderLastRound: ' +
      remainderLastRound.toString());
  // derive key from password
  // load salt from file
  final Uint8List salt = await rafR.read(saltLength);
  // load iv from file
  final Uint8List iv = await rafR.read(ivLength);
  var passphrase = createUint8ListFromString(password);
  pc.KeyDerivator derivator =
  new pc.PBKDF2KeyDerivator(new pc.HMac(new pc.SHA256Digest(), 64));
  pc.Pbkdf2Parameters params =
  new pc.Pbkdf2Parameters(salt, PBKDF2_ITERATIONS, 32);
  derivator.init(params);
  final key = derivator.process(passphrase);
  // pointycastle cipher setup
  final pc.CBCBlockCipher cipher = new pc.CBCBlockCipher(new pc.AESEngine());
  pc.ParametersWithIV<pc.KeyParameter> cbcParams =
  new pc.ParametersWithIV<pc.KeyParameter>(new pc.KeyParameter(key), iv);
  pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>
  paddingParams = new pc.PaddedBlockCipherParameters<
      pc.ParametersWithIV<pc.KeyParameter>, Null>(cbcParams, null);
  pc.PaddedBlockCipherImpl paddingCipher =
  new pc.PaddedBlockCipherImpl(new pc.PKCS7Padding(), cipher);
  paddingCipher.init(false, paddingParams); // false = decryption
  // now we are running the full rounds
  // correct number of full rounds if remaininderLastRound == 0
  if (remainderLastRound == 0) {
    fullRounds = fullRounds - 1;
    remainderLastRound = bufferLength;
  }
  for (int rounds = 0; rounds < fullRounds; rounds++) {
    Uint8List bytesLoad = await rafR.read(bufferLength);
    Uint8List bytesLoadDecrypted = _processBlocks(paddingCipher, bytesLoad);
    await rafW.writeFrom(bytesLoadDecrypted);
  }
  // last round
  if (remainderLastRound > 0) {
    Uint8List bytesLoadLast = await rafR.read(remainderLastRound);
    Uint8List bytesLoadDecrypted = paddingCipher.process(bytesLoadLast);
    await rafW.writeFrom(bytesLoadDecrypted);
  } else {
    /*
      do nothing
    */
  }
  // close all files
  await rafW.flush();
  await rafW.close();
  await rafR.close();
}

// using random access file, iv is stored in the destination file
_encryptAesCbcRandomIv(
    String sourceFilePath, String destinationFilePath, Uint8List key) async {
  final int bufferLength = 2048;
  final int ivLength = 16; // initialization vector length
  File fileSourceRaf = File(sourceFilePath);
  File fileDestRaf = File(destinationFilePath);
  RandomAccessFile rafR = await fileSourceRaf.open(mode: FileMode.read);
  RandomAccessFile rafW = await fileDestRaf.open(mode: FileMode.write);
  var fileRLength = await rafR.length();
  print('bufferLength: ' +
      bufferLength.toString() +
      ' fileRLength: ' +
      fileRLength.toString());
  await rafR.setPosition(0); // from position 0
  int fullRounds = fileRLength ~/ bufferLength;
  int remainderLastRound = (fileRLength % bufferLength) as int;
  print('fullRounds: ' +
      fullRounds.toString() +
      ' remainderLastRound: ' +
      remainderLastRound.toString());
  // generate and store iv in destination file
  final Uint8List iv = _generateRandomByte(ivLength);
  await rafW.writeFrom(iv);

  // pointycastle cipher setup
  final pc.CBCBlockCipher cipher = new pc.CBCBlockCipher(new pc.AESEngine());
  pc.ParametersWithIV<pc.KeyParameter> cbcParams =
  new pc.ParametersWithIV<pc.KeyParameter>(new pc.KeyParameter(key), iv);
  pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>
  paddingParams = new pc.PaddedBlockCipherParameters<
      pc.ParametersWithIV<pc.KeyParameter>, Null>(cbcParams, null);
  pc.PaddedBlockCipherImpl paddingCipher =
  new pc.PaddedBlockCipherImpl(new pc.PKCS7Padding(), cipher);
  paddingCipher.init(true, paddingParams); // true = encryption
  // now we are running the full rounds
  for (int rounds = 0; rounds < fullRounds; rounds++) {
    Uint8List bytesLoad = await rafR.read(bufferLength);
    Uint8List bytesLoadEncrypted = _processBlocks(paddingCipher, bytesLoad);
    await rafW.writeFrom(bytesLoadEncrypted);
  }
  // last round
  if (remainderLastRound > 0) {
    Uint8List bytesLoadLast = await rafR.read(remainderLastRound);
    Uint8List bytesLoadEncrypted = paddingCipher.process(bytesLoadLast);
    await rafW.writeFrom(bytesLoadEncrypted);
  } else {
    Uint8List bytesLoadEncrypted =
    new Uint8List(16); // append one block with padding
    int lastRoundEncryptLength =
    paddingCipher.doFinal(Uint8List(0), 0, bytesLoadEncrypted, 0);
    await rafW.writeFrom(bytesLoadEncrypted);
  }
  // close all files
  await rafW.flush();
  await rafW.close();
  await rafR.close();
}

// using random access file, iv is stored in sourceFilePath
_decryptAesCbcRandomIv(
    String sourceFilePath, String destinationFilePath, Uint8List key) async {
  final int bufferLength = 2048;
  final int ivLength = 16;
  File fileSourceRaf = File(sourceFilePath);
  File fileDestRaf = File(destinationFilePath);
  RandomAccessFile rafR = await fileSourceRaf.open(mode: FileMode.read);
  RandomAccessFile rafW = await fileDestRaf.open(mode: FileMode.write);
  var fileRLength = await rafR.length();
  print('bufferLength: ' +
      bufferLength.toString() +
      ' fileRLength: ' +
      fileRLength.toString());
  await rafR.setPosition(0); // from position 0
  int fullRounds = fileRLength ~/ bufferLength;
  int remainderLastRound = (fileRLength % bufferLength) as int;
  print('fullRounds: ' +
      fullRounds.toString() +
      ' remainderLastRound: ' +
      remainderLastRound.toString());
  // load iv from file
  final Uint8List iv = await rafR.read(ivLength);
  // pointycastle cipher setup
  final pc.CBCBlockCipher cipher = new pc.CBCBlockCipher(new pc.AESEngine());
  pc.ParametersWithIV<pc.KeyParameter> cbcParams =
  new pc.ParametersWithIV<pc.KeyParameter>(new pc.KeyParameter(key), iv);
  pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>
  paddingParams = new pc.PaddedBlockCipherParameters<
      pc.ParametersWithIV<pc.KeyParameter>, Null>(cbcParams, null);
  pc.PaddedBlockCipherImpl paddingCipher =
  new pc.PaddedBlockCipherImpl(new pc.PKCS7Padding(), cipher);
  paddingCipher.init(false, paddingParams); // false = decryption
  // now we are running the full rounds
  // correct number of full rounds if remaininderLastRound == 0
  if (remainderLastRound == 0) {
    fullRounds = fullRounds - 1;
    remainderLastRound = bufferLength;
  }
  for (int rounds = 0; rounds < fullRounds; rounds++) {
    Uint8List bytesLoad = await rafR.read(bufferLength);
    Uint8List bytesLoadDecrypted = _processBlocks(paddingCipher, bytesLoad);
    //print('round ' + rounds.toString() + ' bytesLoadDecrypted Length: ' + bytesLoadDecrypted.length.toString());
    await rafW.writeFrom(bytesLoadDecrypted);
  }
  // last round
  if (remainderLastRound > 0) {
    Uint8List bytesLoadLast = await rafR.read(remainderLastRound);
    Uint8List bytesLoadDecrypted = paddingCipher.process(bytesLoadLast);
    await rafW.writeFrom(bytesLoadDecrypted);
  } else {
    /*
      do nothing
    */
  }
  // close all files
  await rafW.flush();
  await rafW.close();
  await rafR.close();
}

// using random access file
_encryptAesCbc(String sourceFilePath, String destinationFilePath,
    Uint8List key, Uint8List iv) async {
  final int bufferLength = 2048;
  File fileSourceRaf = File(sourceFilePath);
  File fileDestRaf = File(destinationFilePath);
  RandomAccessFile rafR = await fileSourceRaf.open(mode: FileMode.read);
  RandomAccessFile rafW = await fileDestRaf.open(mode: FileMode.write);
  var fileRLength = await rafR.length();
  print('bufferLength: ' +
      bufferLength.toString() +
      ' fileRLength: ' +
      fileRLength.toString());
  await rafR.setPosition(0); // from position 0
  int fullRounds = fileRLength ~/ bufferLength;
  int remainderLastRound = (fileRLength % bufferLength) as int;
  print('fullRounds: ' +
      fullRounds.toString() +
      ' remainderLastRound: ' +
      remainderLastRound.toString());
  // pointycastle cipher setup
  final pc.CBCBlockCipher cipher = new pc.CBCBlockCipher(new pc.AESEngine());
  pc.ParametersWithIV<pc.KeyParameter> cbcParams =
  new pc.ParametersWithIV<pc.KeyParameter>(new pc.KeyParameter(key), iv);
  pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>
  paddingParams = new pc.PaddedBlockCipherParameters<
      pc.ParametersWithIV<pc.KeyParameter>, Null>(cbcParams, null);
  pc.PaddedBlockCipherImpl paddingCipher =
  new pc.PaddedBlockCipherImpl(new pc.PKCS7Padding(), cipher);
  paddingCipher.init(true, paddingParams); // true = encryption
  // now we are running the full rounds
  for (int rounds = 0; rounds < fullRounds; rounds++) {
    Uint8List bytesLoad = await rafR.read(bufferLength);
    Uint8List bytesLoadEncrypted = _processBlocks(paddingCipher, bytesLoad);
    await rafW.writeFrom(bytesLoadEncrypted);
  }
  // last round
  if (remainderLastRound > 0) {
    Uint8List bytesLoadLast = await rafR.read(remainderLastRound);
    Uint8List bytesLoadEncrypted = paddingCipher.process(bytesLoadLast);
    await rafW.writeFrom(bytesLoadEncrypted);
  } else {
    Uint8List bytesLoadEncrypted =
    new Uint8List(16); // append one block with padding
    int lastRoundEncryptLength =
    paddingCipher.doFinal(Uint8List(0), 0, bytesLoadEncrypted, 0);
    await rafW.writeFrom(bytesLoadEncrypted);
  }
  // close all files
  await rafW.flush();
  await rafW.close();
  await rafR.close();
}

// using random access file
_decryptAesCbc(String sourceFilePath, String destinationFilePath,
    Uint8List key, Uint8List iv) async {
  final int bufferLength = 2048;
  File fileSourceRaf = File(sourceFilePath);
  File fileDestRaf = File(destinationFilePath);
  RandomAccessFile rafR = await fileSourceRaf.open(mode: FileMode.read);
  RandomAccessFile rafW = await fileDestRaf.open(mode: FileMode.write);
  var fileRLength = await rafR.length();
  print('bufferLength: ' +
      bufferLength.toString() +
      ' fileRLength: ' +
      fileRLength.toString());
  await rafR.setPosition(0); // from position 0
  int fullRounds = fileRLength ~/ bufferLength;
  int remainderLastRound = (fileRLength % bufferLength) as int;
  print('fullRounds: ' +
      fullRounds.toString() +
      ' remainderLastRound: ' +
      remainderLastRound.toString());
  // pointycastle cipher setup
  final pc.CBCBlockCipher cipher = new pc.CBCBlockCipher(new pc.AESEngine());
  pc.ParametersWithIV<pc.KeyParameter> cbcParams =
  new pc.ParametersWithIV<pc.KeyParameter>(new pc.KeyParameter(key), iv);
  pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>
  paddingParams = new pc.PaddedBlockCipherParameters<
      pc.ParametersWithIV<pc.KeyParameter>, Null>(cbcParams, null);
  pc.PaddedBlockCipherImpl paddingCipher =
  new pc.PaddedBlockCipherImpl(new pc.PKCS7Padding(), cipher);
  paddingCipher.init(false, paddingParams); // false = decryption
  // now we are running the full rounds
  // correct number of full rounds if remaininderLastRound == 0
  if (remainderLastRound == 0) {
    fullRounds = fullRounds - 1;
    remainderLastRound = bufferLength;
  }
  for (int rounds = 0; rounds < fullRounds; rounds++) {
    Uint8List bytesLoad = await rafR.read(bufferLength);
    Uint8List bytesLoadDecrypted = _processBlocks(paddingCipher, bytesLoad);
    await rafW.writeFrom(bytesLoadDecrypted);
  }
  // last round
  if (remainderLastRound > 0) {
    Uint8List bytesLoadLast = await rafR.read(remainderLastRound);
    Uint8List bytesLoadDecrypted = paddingCipher.process(bytesLoadLast);
    await rafW.writeFrom(bytesLoadDecrypted);
  } else {
    /*
      do nothing
    */
  }
  // close all files
  await rafW.flush();
  await rafW.close();
  await rafR.close();
}

// aes cbc encrypt in memory
Uint8List _encryptAesCbcMemory(
    Uint8List plaintext, Uint8List key, Uint8List iv) {
  pc.CBCBlockCipher cipher = new pc.CBCBlockCipher(new pc.AESEngine());
  pc.ParametersWithIV<pc.KeyParameter> params =
  new pc.ParametersWithIV<pc.KeyParameter>(new pc.KeyParameter(key), iv);
  pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>
  paddingParams = new pc.PaddedBlockCipherParameters<
      pc.ParametersWithIV<pc.KeyParameter>, Null>(params, null);
  pc.PaddedBlockCipherImpl paddingCipher =
  new pc.PaddedBlockCipherImpl(new pc.PKCS7Padding(), cipher);
  paddingCipher.init(true, paddingParams);
  return paddingCipher.process(plaintext);
}

// aes cbc decrypt in memory
Uint8List _decryptAesCbcMemory(
    Uint8List ciphertext, Uint8List key, Uint8List iv) {
  pc.CBCBlockCipher cipher = new pc.CBCBlockCipher(new pc.AESEngine());
  pc.ParametersWithIV<pc.KeyParameter> params =
  new pc.ParametersWithIV<pc.KeyParameter>(new pc.KeyParameter(key), iv);
  pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>
  paddingParams = new pc.PaddedBlockCipherParameters<
      pc.ParametersWithIV<pc.KeyParameter>, Null>(params, null);
  pc.PaddedBlockCipherImpl paddingCipher =
  new pc.PaddedBlockCipherImpl(new pc.PKCS7Padding(), cipher);
  paddingCipher.init(false, paddingParams);
  return paddingCipher.process(ciphertext);
}

Uint8List _processBlocks(pc.BlockCipher cipher, Uint8List inp) {
  var out = new Uint8List(inp.lengthInBytes);
  for (var offset = 0; offset < inp.lengthInBytes;) {
    var len = cipher.processBlock(inp, offset, out, offset);
    offset += len;
  }
  return out;
}

Uint8List _generateRandomByte(int length) {
  final _sGen = Random.secure();
  final _seed =
  Uint8List.fromList(List.generate(32, (n) => _sGen.nextInt(255)));
  pc.SecureRandom sec = pc.SecureRandom("Fortuna")
    ..seed(pc.KeyParameter(_seed));
  return sec.nextBytes(length);
}

Future<int> _getFileLength(String path) async {
  File file = File(path);
  RandomAccessFile raf = await file.open(mode: FileMode.read);
  int fileLength = await raf.length();
  raf.close();
  return fileLength;
}

Future<Uint8List> _getSha256File(String path) async {
  File file = File(path);
  RandomAccessFile raf = await file.open(mode: FileMode.read);
  int fileLength = await raf.length();
  await raf.setPosition(0); // from position 0
  Uint8List fileConent = await raf.read(fileLength); // reading all bytes
  raf.close();
  return await calculateSha256FromUint8List(fileConent);
}

Future<Uint8List> calculateSha256FromUint8List(Uint8List dataToDigest) async {
  var d = pc.Digest('SHA-256');
  return await d.process(dataToDigest);
}

String bytesToHex(Uint8List data) {
  return hex.encode(data);
}

_deleteFileSync(String path) {
  File file = File(path);
  file.deleteSync();
}

Uint8List createUint8ListFromString(String s) {
  var ret = new Uint8List(s.length);
  for (var i = 0; i < s.length; i++) {
    ret[i] = s.codeUnitAt(i);
  }
  return ret;
}

bool _fileExistsSync(String path) {
  File file = File(path);
  return file.existsSync();
}

// reading from a file
Uint8List _readUint8ListSync(String path) {
  File file = File(path);
  return file.readAsBytesSync();
}

// writing to a file
_writeUint8ListSync(String path, Uint8List data) {
  File file = File(path);
  file.writeAsBytesSync(data);
}

// writing to a file
_writeUint8List(String path, Uint8List data) async {
  File file = File(path);
  await file.writeAsBytes(data);
}

// generate a large testfile with random data
_generateLargeFileSync(String path, Uint8List data, int numberWrite) {
  File file = File(path);
  for (int i = 0; i < numberWrite; i++) {
    file.writeAsBytesSync(data, mode: FileMode.writeOnlyAppend);
  }
}

Future<List> _getFiles() async {
  //String folderName="MyFiles";
  String folderName = '';
  final directory = await getApplicationDocumentsDirectory();
  final Directory _appDocDirFolder =
  Directory('${directory.path}/${folderName}/');
  if (await _appDocDirFolder.exists()) {
    //if folder already exists return path
    return _appDocDirFolder.listSync();
  }
  return List.empty(growable: true);
}



