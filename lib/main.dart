import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:pointycastle/export.dart' as pc;
import 'package:flutter_sodium/flutter_sodium.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'fc_file_encryption9_pc_sodium'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List listFiles = List.empty(growable: true);

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      //_counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              'hier steht der Counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // AES CBC
          //await _runAesCbcEncryption();
          //print('');
          // AES GCM
          //await _runAesGcmEncryption();

          // Chacha20
          //await _runChacha20Encryption();

          // Chacha20 sodium
          await _runXChacha20Poly1305EncryptionSodium();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  _runXChacha20Poly1305EncryptionSodium() async {
    print('XChacha20 large file encryption SODIUM');

    Sodium.init();

    Directory directory = await getApplicationDocumentsDirectory();
    final String sourceFilePath = '${directory.path}/source_c.txt';
    final String cipherIvPbkdf2FilePath =
        '${directory.path}/cipher_iv_pbkdf2_c.txt';
    final String cipherIvFilePath = '${directory.path}/cipher_iv_c.txt';
    final String cipherNewFilePath = '${directory.path}/cipher_new_c.txt';
    final String cipherOldFilePath = '${directory.path}/cipher_old_c.txt';
    final String decryptOldFilePath = '${directory.path}/decrypt_old_c.txt';
    final String decryptIvPbkdf2FilePath =
        '${directory.path}/decrypt_iv_pbkdf2_c.txt';
    final String decryptIvFilePath = '${directory.path}/decrypt_iv_c.txt';
    final String decryptNewFilePath = '${directory.path}/decrypt_new_c.txt';

    // fixed key and iv - this is just for testing purposes
    String keyString = '12345678123456781234567812345678'; // 32 chars
    //String nonceString = '76543210'; // 8 chars
    Uint8List key = createUint8ListFromString(keyString);
    //Uint8List nonce = createUint8ListFromString(nonceString);
    if (_fileExistsSync(sourceFilePath)) {
      _deleteFileSync(sourceFilePath);
    }

    // generate a 'large' file with random content
    final int testDataLength = (1024 * 1024); // 1 mb
    //final int testDataLength = (1024 * 7 + 0);
    final step1 = Stopwatch()..start();
    Uint8List randomData = _generateRandomByte(testDataLength);
    //_generateLargeFileSync(sourceFilePath, randomData, 1);
    _generateLargeFileSync(sourceFilePath, randomData, 50);

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
    //print('content source: ' + bytesToHex(plaintextLoad));
    //Uint8List ciphertextOld = Uint8List(1);
    /* out of memory 50 mb */
    EncryptionResult encResultCiphertextOld = await _encryptXChacha20Poly1305MemorySodium(plaintextLoad, key);
    _writeUint8ListSync(cipherOldFilePath, encResultCiphertextOld.encryptedData);
    var step2Elapsed = step2.elapsed;
    Uint8List cipherOldSha256 = await _getSha256File(cipherOldFilePath);
    int cipherOldFileLength = await _getFileLength(cipherOldFilePath);
    print('cipherOldPath fileLength: ' + cipherOldFileLength.toString());
    print('cipherOldPath SHA-256:  ' + bytesToHex(cipherOldSha256));
    // decrypt in one run
    final step3 = Stopwatch()..start();
    Uint8List ciphertextOldLoad = await _readUint8ListSync(cipherOldFilePath);
    //Uint8List decrypttextOld = Uint8List(1);
    /* out of memory error 50 mb*/
    Uint8List decrypttextOld = await _decryptXChacha20Poly1305MemorySodium(ciphertextOldLoad, key, encResultCiphertextOld.header);
    _writeUint8ListSync(decryptOldFilePath, decrypttextOld);
    var step3Elapsed = step3.elapsed;
    Uint8List decryptOldSha256 = await _getSha256File(decryptOldFilePath);
    int decryptOldFileLength = await _getFileLength(decryptOldFilePath);
    print('decryptOldPath fileLength: ' + decryptOldFileLength.toString());
    print('decryptOldPath SHA-256: ' + bytesToHex(decryptOldSha256));

    // delete new file if exist
    //_deleteFileSync(cipherNewFilePath);
    //print('\nfile ' + cipherNewFilePath + ' deleted if existed');

    print('\ndata encryption using SODIUM');
    // important: delete destinationFile before encryption
    if (_fileExistsSync(cipherNewFilePath)) _deleteFileSync(cipherNewFilePath);
    //print('\nfile ' + cipherNewFilePath + ' deleted if existed');

    // now encryption using chunks
    final step4 = Stopwatch()..start();
    Uint8List encHeader = await _encryptXChacha20Poly1305Sodium(
        sourceFilePath, cipherNewFilePath, key);
    var step4Elapsed = step4.elapsed;
    // check the data
    Uint8List cipherNewSha256S = await _getSha256File(cipherNewFilePath);
    int cipherNewFileLengthS = await _getFileLength(cipherNewFilePath);
    print('cipherNewPath fileLength: ' + cipherNewFileLengthS.toString());
    print('cipherNewPath SHA-256:  ' + bytesToHex(cipherNewSha256S));
    //Uint8List cipherNewS = _readUint8ListSync(cipherNewFilePath);

    // now decryption using chunks
    print('\ndata decryption using Sodium');
    // important: delete destinationFile before encryption
    if (_fileExistsSync(decryptNewFilePath)) _deleteFileSync(decryptNewFilePath);
    final step5 = Stopwatch()..start();
    // get nonce from header
    var nonceSodiumHeader = encHeader;
    print('SODIUM header nonce: ' + bytesToHex(nonceSodiumHeader));

    await _decryptXChacha20Poly1305Sodium(
        cipherNewFilePath, decryptNewFilePath, key, nonceSodiumHeader);
    var step5Elapsed = step5.elapsed;
    // check the data
    Uint8List decryptNewSha256S = await _getSha256File(decryptNewFilePath);
    int decryptNewFileLengthS = await _getFileLength(decryptNewFilePath);
    print('decryptNewPath fileLength: ' + decryptNewFileLengthS.toString());
    print('decryptNewPath SHA-256:  ' + bytesToHex(decryptNewSha256S));

    print(
        '\ndata encryption using RAF and chunks with random iv stored in file SODIUM');

    // important: delete destinationFile before encryption
    if (_fileExistsSync(cipherIvFilePath)) _deleteFileSync(cipherIvFilePath);

    // now encryption using chunks
    final step6 = Stopwatch()..start();
    //await _encryptChacha20RandomNonce(sourceFilePath, cipherIvFilePath, key);
    await _encryptXChacha20Poly1305RandomNonceSodium(sourceFilePath, cipherIvFilePath, key);
    var step6Elapsed = step6.elapsed;
    // check the data
    Uint8List cipherIvSha256 = await _getSha256File(cipherIvFilePath);
    int cipherIvFileLength = await _getFileLength(cipherIvFilePath);
    print('cipherIvPath fileLength: ' + cipherIvFileLength.toString());
    print('cipherIvPath SHA-256:   ' + bytesToHex(cipherIvSha256));

    // now decryption using chunks
    print(
        '\ndata decryption using RAF and chunks with random iv stored in file');

    // important: delete destinationFile before encryption
    if (_fileExistsSync(decryptIvFilePath)) _deleteFileSync(decryptIvFilePath);

    final step7 = Stopwatch()..start();
    await _decryptXChacha20Poly1305RandomNonceSodium(cipherIvFilePath, decryptIvFilePath, key);
    var step7Elapsed = step7.elapsed;
    // check the data
    Uint8List decryptIvSha256 = await _getSha256File(decryptIvFilePath);
    int decryptIvFileLength = await _getFileLength(decryptIvFilePath);
    print('decryptIvPath fileLength: ' + decryptIvFileLength.toString());
    print('decryptIvPath SHA-256:   ' + bytesToHex(decryptIvSha256));

    print(
        '\ndata encryption using RAF and chunks with random iv stored in file and PBKDF2 key derivation');
    // now encryption using chunks
    // important: delete destinationFile before encryption
    if (_fileExistsSync(cipherIvPbkdf2FilePath)) _deleteFileSync(cipherIvPbkdf2FilePath);
    String password = 'secret password';
    final step8 = Stopwatch()..start();
    await _encryptXChacha20Poly1305RandomNoncePbkdf2Sodium(
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
    // important: delete destinationFile before encryption
    if (_fileExistsSync(decryptIvPbkdf2FilePath)) _deleteFileSync(decryptIvPbkdf2FilePath);
    final step9 = Stopwatch()..start();
    await _decryptXChacha20Poly1305RandomNoncePbkdf2Sodium(
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
    //print('testDataLength:             ' + testDataLength.toString() + ' bytes');
    print('step 2 encrypt in memory:   ' +
        step2Elapsed.inMicroseconds.toString());
    print('step 3 decrypt in memory:   ' +
        step3Elapsed.inMicroseconds.toString());
    print('step 4 encrypt chunked:     ' +
        step4Elapsed.inMicroseconds.toString());
    print('step 5 decrypt chunked:     ' +
        step5Elapsed.inMicroseconds.toString());
    print('step 6 encrypt chunked iv:  ' +
        step6Elapsed.inMicroseconds.toString());
    print('step 7 decrypt chunked iv:  ' +
        step7Elapsed.inMicroseconds.toString());
    print('step 8 encrypt chu PBKDF2:  ' +
        step8Elapsed.inMicroseconds.toString());
    print('step 9 decrypt chu PBKDF2:  ' +
        step9Elapsed.inMicroseconds.toString());
    // get list of files
    print('alle Dateien:\n');
    listFiles = await _getFiles();
    for (var i = 0; i < listFiles.length; i++) {
      print(listFiles[i]);
    }
  }

  /*
   * sodium methods start
   */

  Future<void> _encryptXChacha20Poly1305RandomNoncePbkdf2Sodium(String sourceFilePath, String destinationFilePath, String password) async {
    //final int encryptionChunkSize = 4 * 1024 * 1024; // 4 mb
    final int encryptionChunkSize = 2048;
    final int decryptionChunkSize = encryptionChunkSize + Sodium.cryptoSecretstreamXchacha20poly1305Abytes;

    // pbkdf2 key derivation
    // sodium lib does not provide pbkdf2, using pointycastle for this task
    final int saltLength = 32; // salt for pbkdf2
    final int PBKDF2_ITERATIONS = 15000;
    // derive key from password
    var passphrase =  createUint8ListFromString(password);
    final salt = _generateRandomByte(saltLength);
    // generate and store salt in destination file
    pc.KeyDerivator derivator = new pc.PBKDF2KeyDerivator(new pc.HMac(new pc.SHA256Digest(), 64));
    pc.Pbkdf2Parameters params = new pc.Pbkdf2Parameters(salt, PBKDF2_ITERATIONS, 32);
    derivator.init(params);
    final key = derivator.process(passphrase);

    final sourceFile = File(sourceFilePath);
    final destinationFile = File(destinationFilePath);
    final sourceFileLength = await sourceFile.length();
    final inputFile = sourceFile.openSync(mode: FileMode.read);
    final initPushResult =
    Sodium.cryptoSecretstreamXchacha20poly1305InitPush(key);
    // write salt and nonce to file
    await destinationFile.writeAsBytes(salt, mode: FileMode.append);
    await destinationFile.writeAsBytes(initPushResult.header, mode: FileMode.append);

    var bytesRead = 0;
    var tag = Sodium.cryptoSecretstreamXchacha20poly1305TagMessage;
    while (tag != Sodium.cryptoSecretstreamXchacha20poly1305TagFinal) {
      var chunkSize = encryptionChunkSize;
      if (bytesRead + chunkSize >= sourceFileLength) {
        chunkSize = sourceFileLength - bytesRead;
        tag = Sodium.cryptoSecretstreamXchacha20poly1305TagFinal;
      }
      final buffer = inputFile.readSync(chunkSize);
      bytesRead += chunkSize;
      final encryptedData = Sodium.cryptoSecretstreamXchacha20poly1305Push(
          initPushResult.state, buffer, null, tag);
      await destinationFile.writeAsBytes(encryptedData, mode: FileMode.append);
    }
    inputFile.closeSync();
    return;
  }

  Future<void> _decryptXChacha20Poly1305RandomNoncePbkdf2Sodium(String sourceFilePath, String destinationFilePath, String password) async {
    //final int encryptionChunkSize = 4 * 1024 * 1024; // 4 mb
    final int encryptionChunkSize = 2048;
    final int decryptionChunkSize =
        encryptionChunkSize + Sodium.cryptoSecretstreamXchacha20poly1305Abytes;
    final int nonceLength = Sodium.cryptoSecretstreamXchacha20poly1305Headerbytes;
    final decryptionStartTime = DateTime.now().millisecondsSinceEpoch;
    final sourceFile = File(sourceFilePath);
    final destinationFile = File(destinationFilePath);
    int sourceFileLength = await sourceFile.length();
    print("Decrypting file of size " + sourceFileLength.toString());
    final inputFile = sourceFile.openSync(mode: FileMode.read);
    // get salt and nonce from file
    final int saltLength = 32; // salt for pbkdf2
    final salt = inputFile.readSync(saltLength);
    final nonce = inputFile.readSync(nonceLength);
    // pbkdf2 key derivation
    // sodium lib does not provide pbkdf2, using pointycastle for this task
    final int PBKDF2_ITERATIONS = 15000;
    // derive key from password
    var passphrase =  createUint8ListFromString(password);
    // generate and store salt in destination file
    pc.KeyDerivator derivator = new pc.PBKDF2KeyDerivator(new pc.HMac(new pc.SHA256Digest(), 64));
    pc.Pbkdf2Parameters params = new pc.Pbkdf2Parameters(salt, PBKDF2_ITERATIONS, 32);
    derivator.init(params);
    final key = derivator.process(passphrase);
    final pullState = Sodium.cryptoSecretstreamXchacha20poly1305InitPull(nonce, key);
    var bytesRead = 0;
    // correct sourceFileLength for saltLength and nonceLength
    sourceFileLength = sourceFileLength - saltLength - nonceLength;
    var tag = Sodium.cryptoSecretstreamXchacha20poly1305TagMessage;
    while (tag != Sodium.cryptoSecretstreamXchacha20poly1305TagFinal) {
      var chunkSize = decryptionChunkSize;
      if (bytesRead + chunkSize >= sourceFileLength) {
        chunkSize = sourceFileLength - bytesRead;
      }
      final buffer = inputFile.readSync(chunkSize);
      bytesRead += chunkSize;
      final pullResult =
      Sodium.cryptoSecretstreamXchacha20poly1305Pull(pullState, buffer, null);
      await destinationFile.writeAsBytes(pullResult.m, mode: FileMode.append);
      tag = pullResult.tag;
    }
    inputFile.closeSync();
  }

  Future<void> _encryptXChacha20Poly1305RandomNonceSodium(String sourceFilePath, String destinationFilePath, Uint8List key) async {
    //final int encryptionChunkSize = 4 * 1024 * 1024; // 4 mb
    final int encryptionChunkSize = 2048;
    final int decryptionChunkSize = encryptionChunkSize + Sodium.cryptoSecretstreamXchacha20poly1305Abytes;
    final sourceFile = File(sourceFilePath);
    final destinationFile = File(destinationFilePath);
    final sourceFileLength = await sourceFile.length();
    final inputFile = sourceFile.openSync(mode: FileMode.read);
    final initPushResult =
    Sodium.cryptoSecretstreamXchacha20poly1305InitPush(key);
    await destinationFile.writeAsBytes(initPushResult.header, mode: FileMode.append);

    var bytesRead = 0;
    var tag = Sodium.cryptoSecretstreamXchacha20poly1305TagMessage;
    while (tag != Sodium.cryptoSecretstreamXchacha20poly1305TagFinal) {
      var chunkSize = encryptionChunkSize;
      if (bytesRead + chunkSize >= sourceFileLength) {
        chunkSize = sourceFileLength - bytesRead;
        tag = Sodium.cryptoSecretstreamXchacha20poly1305TagFinal;
      }
      final buffer = inputFile.readSync(chunkSize);
      bytesRead += chunkSize;
      final encryptedData = Sodium.cryptoSecretstreamXchacha20poly1305Push(
          initPushResult.state, buffer, null, tag);
      await destinationFile.writeAsBytes(encryptedData, mode: FileMode.append);
    }
    inputFile.closeSync();
    return;
  }

  Future<void> _decryptXChacha20Poly1305RandomNonceSodium(String sourceFilePath, String destinationFilePath, Uint8List key) async {
    //final int encryptionChunkSize = 4 * 1024 * 1024; // 4 mb
    final int encryptionChunkSize = 2048;
    final int decryptionChunkSize =
        encryptionChunkSize + Sodium.cryptoSecretstreamXchacha20poly1305Abytes;
    final int nonceLength = Sodium.cryptoSecretstreamXchacha20poly1305Headerbytes;
    final sourceFile = File(sourceFilePath);
    final destinationFile = File(destinationFilePath);
    int sourceFileLength = await sourceFile.length();
    final inputFile = sourceFile.openSync(mode: FileMode.read);
    // get nonce from file
    final nonce = inputFile.readSync(nonceLength);
    final pullState = Sodium.cryptoSecretstreamXchacha20poly1305InitPull(nonce, key);

    // correct sourceFileLength for nonceLength
    sourceFileLength = sourceFileLength - nonceLength;

    var bytesRead = 0;
    var tag = Sodium.cryptoSecretstreamXchacha20poly1305TagMessage;
    while (tag != Sodium.cryptoSecretstreamXchacha20poly1305TagFinal) {
      var chunkSize = decryptionChunkSize;
      if (bytesRead + chunkSize >= sourceFileLength) {
        chunkSize = sourceFileLength - bytesRead;
      }
      final buffer = inputFile.readSync(chunkSize);
      bytesRead += chunkSize;
      final pullResult =
      Sodium.cryptoSecretstreamXchacha20poly1305Pull(pullState, buffer, null);
      await destinationFile.writeAsBytes(pullResult.m, mode: FileMode.append);
      tag = pullResult.tag;
    }
    inputFile.closeSync();
  }

  Future<Uint8List> _encryptXChacha20Poly1305Sodium(String sourceFilePath, String destinationFilePath, Uint8List key) async {
    //final int encryptionChunkSize = 4 * 1024 * 1024; // 4 mb
    final int encryptionChunkSize = 2048;
    final int decryptionChunkSize = encryptionChunkSize + Sodium.cryptoSecretstreamXchacha20poly1305Abytes;
    final sourceFile = File(sourceFilePath);
    final destinationFile = File(destinationFilePath);
    final sourceFileLength = await sourceFile.length();
    final inputFile = sourceFile.openSync(mode: FileMode.read);
    final initPushResult =
    Sodium.cryptoSecretstreamXchacha20poly1305InitPush(key);
    var bytesRead = 0;
    var tag = Sodium.cryptoSecretstreamXchacha20poly1305TagMessage;
    while (tag != Sodium.cryptoSecretstreamXchacha20poly1305TagFinal) {
      var chunkSize = encryptionChunkSize;
      if (bytesRead + chunkSize >= sourceFileLength) {
        chunkSize = sourceFileLength - bytesRead;
        tag = Sodium.cryptoSecretstreamXchacha20poly1305TagFinal;
      }
      final buffer = inputFile.readSync(chunkSize);
      bytesRead += chunkSize;
      final encryptedData = Sodium.cryptoSecretstreamXchacha20poly1305Push(
          initPushResult.state, buffer, null, tag);
      await destinationFile.writeAsBytes(encryptedData, mode: FileMode.append);
    }
    inputFile.closeSync();
    return initPushResult.header;
  }

  Future<void> _decryptXChacha20Poly1305Sodium(String sourceFilePath, String destinationFilePath, Uint8List key, Uint8List nonce) async {
    //final int encryptionChunkSize = 4 * 1024 * 1024; // 4 mb
    final int encryptionChunkSize = 2048;
    final int decryptionChunkSize =
        encryptionChunkSize + Sodium.cryptoSecretstreamXchacha20poly1305Abytes;
    final sourceFile = File(sourceFilePath);
    final destinationFile = File(destinationFilePath);
    final sourceFileLength = await sourceFile.length();
    final inputFile = sourceFile.openSync(mode: FileMode.read);
    final pullState = Sodium.cryptoSecretstreamXchacha20poly1305InitPull(nonce, key);

    var bytesRead = 0;
    var tag = Sodium.cryptoSecretstreamXchacha20poly1305TagMessage;
    while (tag != Sodium.cryptoSecretstreamXchacha20poly1305TagFinal) {
      var chunkSize = decryptionChunkSize;
      if (bytesRead + chunkSize >= sourceFileLength) {
        chunkSize = sourceFileLength - bytesRead;
      }
      final buffer = inputFile.readSync(chunkSize);
      bytesRead += chunkSize;
      final pullResult =
      Sodium.cryptoSecretstreamXchacha20poly1305Pull(pullState, buffer, null);
      await destinationFile.writeAsBytes(pullResult.m, mode: FileMode.append);
      tag = pullResult.tag;
    }
    inputFile.closeSync();
  }

  Future<EncryptionResult> _encryptXChacha20Poly1305MemorySodium(Uint8List sourceData, Uint8List key) async {
    final initPushResult =
    Sodium.cryptoSecretstreamXchacha20poly1305InitPush(key);
    final encryptedData = Sodium.cryptoSecretstreamXchacha20poly1305Push(
        initPushResult.state,
        sourceData,
        null,
        Sodium.cryptoSecretstreamXchacha20poly1305TagFinal);
    return EncryptionResult(encryptedData: encryptedData, header: initPushResult.header, key: Uint8List(0), nonce: Uint8List(0));
  }

  Future<Uint8List> _decryptXChacha20Poly1305MemorySodium(Uint8List sourceData, Uint8List key, Uint8List header) async {
    final pullState = Sodium.cryptoSecretstreamXchacha20poly1305InitPull(header, key);
    final pullResult = Sodium.cryptoSecretstreamXchacha20poly1305Pull(
        pullState, sourceData, null);
    return pullResult.m;
  }

  /*
   * sodium methods end
   */


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



}

class EncryptionResult {
  final Uint8List encryptedData;
  final Uint8List key;
  final Uint8List header;
  final Uint8List nonce;

  EncryptionResult({required this.encryptedData, required this.key, required this.header, required this.nonce});
}


/* AES CBC
android:
I/flutter ( 9757): step 1 generate data:       9242
I/flutter ( 9757): testDataLength:             6144 bytes
I/flutter ( 9757): step 2 encrypt in memory:   4801
I/flutter ( 9757): step 3 decrypt in memory:   6460
I/flutter ( 9757): step 4 encrypt raf/chunked: 11621
I/flutter ( 9757): step 5 decrypt raf/chunked: 12489

I/flutter ( 9757): step 1 generate data:       294846
I/flutter ( 9757): testDataLength:             1048576 bytes
I/flutter ( 9757): step 2 encrypt in memory:   261027
I/flutter ( 9757): step 3 decrypt in memory:   273930
I/flutter ( 9757): step 4 encrypt raf/chunked: 410935
I/flutter ( 9757): step 5 decrypt raf/chunked: 411664

I/flutter ( 4964): step 1 generate data:       308176
I/flutter ( 4964): testDataLength:             1048576 bytes * 50  = 50 mb
I/flutter ( 4964): step 2 encrypt in memory:   12044373
I/flutter ( 4964): step 3 decrypt in memory:   12264161
I/flutter ( 4964): step 4 encrypt raf/chunked: 18006684
I/flutter ( 4964): step 5 decrypt raf/chunked: 17755318

iOS
flutter: step 1 generate data:       268435
flutter: testDataLength:             1048576 bytes
flutter: step 2 encrypt in memory:   255502
flutter: step 3 decrypt in memory:   255485
flutter: step 4 encrypt raf/chunked: 296151
flutter: step 5 decrypt raf/chunked: 288059

flutter: step 1 generate data:       278231
flutter: testDataLength:             1048576 bytes * 50 = 50 mb
flutter: step 2 encrypt in memory:   12222507
flutter: step 3 decrypt in memory:   12468845
flutter: step 4 encrypt raf/chunked: 13956907
flutter: step 5 decrypt raf/chunked: 13823063
 */

/* AES GCM
Android:
I/flutter ( 7563): step 1 generate data:       376656
I/flutter ( 7563): testDataLength:             1048576 bytes * 50 = 50 mb
I/flutter ( 7563): step 2 encrypt in memory:   60047688
I/flutter ( 7563): step 3 decrypt in memory:   59728562
I/flutter ( 7563): step 4 encrypt raf/chunked: 66000410
I/flutter ( 7563): step 5 decrypt raf/chunked: 78055319
I/flutter ( 7563): step 6 encrypt raf/chun iv: 65984245
I/flutter ( 7563): step 7 decrypt raf/chun iv: 66000033
I/flutter ( 7563): step 8 encrypt raf/chu PBK: 68384344
I/flutter ( 7563): step 9 decrypt raf/chu PBK: 66723630

iOS
flutter: step 1 generate data:       286738
flutter: testDataLength:             1048576 bytes * 50 = 50 mb
flutter: step 2 encrypt in memory:   57683540
flutter: step 3 decrypt in memory:   58623742
flutter: step 4 encrypt raf/chunked: 59721613
flutter: step 5 decrypt raf/chunked: 59710413
flutter: step 6 encrypt raf/chun iv: 59769021
flutter: step 7 decrypt raf/chun iv: 59678958
flutter: step 8 encrypt raf/chu PBK: 60551892
flutter: step 9 decrypt raf/chu PBK: 60435652
 */

/* Chacha20Poly1305
Android:
I/flutter ( 4963): step 1 generate data:       315153
flutter: testDataLength:             1048576 bytes * 50 = 50 mb
I/flutter ( 4963): step 2 encrypt in memory:   6742542
I/flutter ( 4963): step 3 decrypt in memory:   6856612
I/flutter ( 4963): step 4 encrypt raf/chunked: 12979434
I/flutter ( 4963): step 5 decrypt raf/chunked: 12950157
I/flutter ( 4963): step 6 encrypt raf/chun iv: 12944215
I/flutter ( 4963): step 7 decrypt raf/chun iv: 12988857
I/flutter ( 4963): step 8 encrypt raf/chu PBK: 13712064
I/flutter ( 4963): step 9 decrypt raf/chu PBK: 17621770

iOS
flutter: step 1 generate data:       270184
flutter: testDataLength:             1048576 bytes * 50 = 50 mb
flutter: step 2 encrypt in memory:   10177113
flutter: step 3 decrypt in memory:   6655068
flutter: step 4 encrypt raf/chunked: 8523476
flutter: step 5 decrypt raf/chunked: 8721167
flutter: step 6 encrypt raf/chun iv: 8435973
flutter: step 7 decrypt raf/chun iv: 8528780
flutter: step 8 encrypt raf/chu PBK: 9275988
flutter: step 9 decrypt raf/chu PBK: 9346414
*/

/* XChacha20Poly1305 sodium
Android:
I/flutter ( 7579): step 1 generate data:       231547
flutter: testDataLength:             1048576 bytes * 50 = 50 mb
I/flutter ( 7579): step 2 encrypt in memory:   952089
I/flutter ( 7579): step 3 decrypt in memory:   1040524
I/flutter ( 7579): step 4 encrypt chunked:     9983348
I/flutter ( 7579): step 5 decrypt chunked:     9984282
I/flutter ( 7579): step 6 encrypt chunked iv:  10041586
I/flutter ( 7579): step 7 decrypt chunked iv:  10578522
I/flutter ( 7579): step 8 encrypt chu PBKDF2:  10374414
I/flutter ( 7579): step 9 decrypt chu PBKDF2:  10593808

iOS:
flutter: step 1 generate data:       326920
flutter: testDataLength:             1048576 bytes * 50 = 50 mb
flutter: step 2 encrypt in memory:   798152
flutter: step 3 decrypt in memory:   762671
flutter: step 4 encrypt chunked:     4960497
flutter: step 5 decrypt chunked:     4821315
flutter: step 6 encrypt chunked iv:  4742871
flutter: step 7 decrypt chunked iv:  4851293
flutter: step 8 encrypt chu PBKDF2:  5434428
flutter: step 9 decrypt chu PBKDF2:  9218499
*/

/*
chacha20Poly1305 pc
flutter: step 4 encrypt raf/chunked: 8523476
flutter: step 5 decrypt raf/chunked: 8721167

xChacha20Poly1305 2048 byte buffer
flutter: step 4 encrypt raf/chunked: 4901964
flutter: step 5 decrypt raf/chunked: 4990996

xChacha20Poly1305 4 mb buffer
flutter: step 4 encrypt raf/chunked: 988920
flutter: step 5 decrypt raf/chunked: 1071354

 */
