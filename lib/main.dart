import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:aes_crypt_null_safe/aes_crypt_null_safe.dart';

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
      home: const MyHomePage(title: 'Flutter Demo Home Page 3'),
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
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
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
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          //_incrementCounter

          Directory directory = await getApplicationDocumentsDirectory();
          File file = File('${directory.path}/file1.txt');

          print('1 generate data');
          // here is the 1000 byte long random data
          final step1 = Stopwatch()..start();
          //Uint8List data1000 = generateRandom1000Byte();
          Uint8List data1000 = generateRandomByte(1024 * 1024); // 1 mb
          //Uint8List data1000 = generateRandomByte(1024);
          var step1Elapsed = step1.elapsed;
          print('data1000 length: ' + data1000.length.toString());
          //print('data:\n' + bytesToHex(data1000));
          print('step 1 elapsed: ' + step1Elapsed.inMicroseconds.toString());

          print('\n2 write data to file using file.io');
          // write the file
          final step2 = Stopwatch()..start();
          await _writeUint8List(file, data1000);
          var step2Elapsed = step2.elapsed;
          print('step 2 elapsed: ' + step2Elapsed.inMicroseconds.toString());

          print('\n3 load data from file using file.io');
          // read the file
          final step3 = Stopwatch()..start();
          var step3Elapsed;
          try {
            Uint8List bytesLoad;
            //String myPath= 'MyPath/abc.png';
            _readUint8List(file).then((bytesData) {
              bytesLoad = bytesData;
              //do your task here
              step3Elapsed = step3.elapsed;
              print('bytesLoad length: ' + bytesLoad.length.toString());
              //print('data:\n' + bytesToHex(bytesLoad));
              print(
                  'step 3 elapsed: ' + step3Elapsed.inMicroseconds.toString());
            });
          } catch (e) {
            // if path invalid or not able to read
            print(e);
          }

          // encrypt the data in one round with aes cbc
          print('\n4 encrypt the data with aes cbc in one round');
          String keyString = '12345678123456781234567812345678'; // 32 chars
          String ivString = '7654321076543210'; // 16 chars
          Uint8List key = createUint8ListFromString(keyString);
          Uint8List iv = createUint8ListFromString(ivString);
          final step4 = Stopwatch()..start();
          Uint8List ct = aesCbcEncryptionToUint8List(key, iv, data1000);
          var step4Elapsed = step4.elapsed;
          print('ct length: ' + ct.length.toString());
          print('step 4 elapsed: ' + step4Elapsed.inMicroseconds.toString());

          // decrypt the data
          print('\n5 decrypt the data with aes cbc in one round');
          final step5 = Stopwatch()..start();
          Uint8List dt = aesCbcDecryptionToUint8List(key, iv, ct);
          var step5Elapsed = step5.elapsed;
          print('dt length: ' + dt.length.toString());
          print('step 5 elapsed: ' + step5Elapsed.inMicroseconds.toString());

          // load the data through RandomAccessFile
          print('\n6 load the data using RandomAccessFile');
          File fileRAF = File('${directory.path}/file1.txt');
          final step6 = Stopwatch()..start();
          RandomAccessFile raf = await fileRAF.open(mode: FileMode.read);
          var fileRLength = await fileRAF.length();
          print('fileR length: ' + fileRLength.toString());
          await raf.setPosition(0); // from position 0
          Uint8List bytesLoad =
              await raf.read(fileRLength); // reading all bytes
          var step6Elapsed = step6.elapsed;
          print('bytesLoad length: ' + bytesLoad.length.toString());
          print('step 6 elapsed: ' + step6Elapsed.inMicroseconds.toString());

          // write the data through RandomAccessFile
          print('\n7 write the data using RandomAccessFile');
          File file2RAF = File('${directory.path}/file2.txt');
          final step7 = Stopwatch()..start();
          RandomAccessFile raf2 = await file2RAF.open(mode: FileMode.write);
          await raf2.writeFrom(data1000);
          await raf2.flush();
          await raf2.close();
          var step7Elapsed = step7.elapsed;
          print('step 7 elapsed: ' + step7Elapsed.inMicroseconds.toString());

          // todo manual ECB/CBC encryption in chunks
          print('step 8 calculate number of operations');
          var dataLength = data1000.length;
          print('dataLength: ' + dataLength.toString());
          int fullRounds =
              dataLength ~/ 16; // gives an integer value, does not round up
          print('full rounds: ' + fullRounds.toString());
          var remainder = dataLength % 16;
          print('remainder: ' + remainder.toString());
          // calculate how many times we need to run ECB and how many CBC with padding
          // if fullRounds = 1 and remainder = 0 then just one CBC round
          // if remainder = 0 it's meaning the last one has to be the CBC
          // if remainder > 0 all full rounds were used with ECB and the remainder one with CBCpadding
          var ecbRounds = 0;
          var cbcRounds = 0;
          if (dataLength < 16) {
            ecbRounds = 0;
            cbcRounds = 1;
          } else {
            ecbRounds = fullRounds; // to start with
            if (remainder == 0) {
              ecbRounds = ecbRounds - 1;
              cbcRounds = 1;
            } else {
              cbcRounds = 1;
            }
          }
          print('ecbRounds: ' + ecbRounds.toString());
          print('cbcRounds: ' + cbcRounds.toString());

          int positionToRead = 0; // starting at position 0 on file
          int numberToRead = 16; // needs to get changed when file size < 16

          print('step 9 read and write the data in chunks');
          print('*** skipped ***');
          /*
          // setup the RAFs to read the data and write the encrypted data
          File fileRAFRead = File('${directory.path}/file1.txt');
          File fileRAFWrite = File('${directory.path}/file1enc.txt');
          final step9 = Stopwatch()..start();
          RandomAccessFile rafRead =
              await fileRAFRead.open(mode: FileMode.read);
          RandomAccessFile rafWrite =
              await fileRAFWrite.open(mode: FileMode.write);

          print('ECB rounds starting');
          for (var rounds = 0; rounds < ecbRounds; rounds++) {
            await rafRead.setPosition(positionToRead); // from position 0
            Uint8List bytesLoad16 =
                await rafRead.read(numberToRead); // reading all bytes
            // here the ecb encryption will run
            await rafWrite.writeFrom(bytesLoad16);
            positionToRead =
                positionToRead + numberToRead; // add 16 for each round
          }
          numberToRead = (dataLength - (ecbRounds * 16));
          print('remaining bytes to load: ' + numberToRead.toString());
          print('CBC round starting');
          for (var rounds = 0; rounds < cbcRounds; rounds++) {
            await rafRead.setPosition(positionToRead); // from position 0
            Uint8List bytesLoad16 =
                await rafRead.read(numberToRead); // reading all bytes
            // here the ecb encryption will run
            await rafWrite.writeFrom(bytesLoad16);
            positionToRead = positionToRead + numberToRead;
          }
          //await rafWrite.flush();
          //await rafWrite.close();
          //await rafRead.close();
          var step9Elapsed = step9.elapsed;
          print('step 9 elapsed: ' + step9Elapsed.inMicroseconds.toString());

          var fileReadLength = await fileRAFRead.length();
          print('fileReadLength:  ' + fileReadLength.toString());
          var fileWriteLength = await fileRAFWrite.length();
          print('fileWriteLength: ' + fileWriteLength.toString());
           */

          // step 10
          print('10 run complete file encryption');
          print('*** skipped ***');
          /*
          String sourcePath = '${directory.path}/file1.txt';
          String destPath = '${directory.path}/file10.txt';
          aesFileEncryption(sourcePath, destPath);
           */

          // step 11 single file encryption
          String sourcePath = '${directory.path}/file1.txt';
          String destPath = '${directory.path}/file11.txt';
          final step11 = Stopwatch()..start();
          String resultEnc = aesFileEncryptionOwnSync(sourcePath, destPath);
          print('*** fileEncryption name: ' + resultEnc);
          var step11Elapsed = step11.elapsed;
          print('step 11 elapsed: ' + step11Elapsed.inMicroseconds.toString());

          // step 12 single file decryption
          //sourcePath = '${directory.path}/file11.txt';
          sourcePath = resultEnc;
          destPath = '${directory.path}/file12.txt';
          final step12 = Stopwatch()..start();
          String resultDec = aesFileDecryptionOwnSync(sourcePath, destPath);
          print('*** fileDecryption name: ' + resultDec);
          var step12Elapsed = step12.elapsed;
          print('step 12 elapsed: ' + step12Elapsed.inMicroseconds.toString());

          // step 13 single file encryption ASYNC
          String sourcePathA = '${directory.path}/file1.txt';
          String destPathA = '${directory.path}/file11.txt';
          final step13 = Stopwatch()..start();
          String resultEncA = await aesFileEncryptionOwn(sourcePathA, destPathA);
          print('*** fileEncryption name: ' + resultEncA);
          var step13Elapsed = step13.elapsed;
          print('step 13 elapsed: ' + step13Elapsed.inMicroseconds.toString());

          // step 14 single file decryption ASYNC
          //sourcePath = '${directory.path}/file11.txt';
          sourcePathA = resultEnc;
          destPathA = '${directory.path}/file12.txt';
          final step14 = Stopwatch()..start();
          String resultDecA = await aesFileDecryptionOwn(sourcePathA, destPathA);
          print('*** fileDecryption name: ' + resultDecA);
          var step14Elapsed = step14.elapsed;
          print('step 14 elapsed: ' + step14Elapsed.inMicroseconds.toString());


          // print out all again
          print('');
          print('*********** benchmark all steps ************');
          print('step 1 generate data elapsed: ' +
              step1Elapsed.inMicroseconds.toString());
          print('step 1 data size generated:   ' +
              data1000.length.toString() +
              ' bytes');
          print('step 2 write data file.io elapsed: ' +
              step2Elapsed.inMicroseconds.toString());
          print('step 3 load data file.io elapsed: ' +
              step3Elapsed.inMicroseconds.toString());
          print('step 4 encrypt all elapsed: ' +
              step4Elapsed.inMicroseconds.toString());
          print('step 5 decrypt all elapsed: ' +
              step5Elapsed.inMicroseconds.toString());
          print('step 6 load data RAF elapsed: ' +
              step6Elapsed.inMicroseconds.toString());
          print('step 7 write data RAF elapsed: ' +
              step7Elapsed.inMicroseconds.toString());

          //print('step 9 read - write in chunks RAF elapsed: ' + step9Elapsed.inMicroseconds.toString());
          print('step 9 read - write in chunks RAF elapsed: skipped');
          print('step 11 file encryption aes_crypt elapsed SYNC: ' +
              step11Elapsed.inMicroseconds.toString());
          print('step 12 file decryption aes_crypt elapsed SYNC: ' +
              step12Elapsed.inMicroseconds.toString());

          print('step 13 file encryption aes_crypt elapsed ASYNC: ' +
              step13Elapsed.inMicroseconds.toString());
          print('step 14 file decryption aes_crypt elapsed ASYNC: ' +
              step14Elapsed.inMicroseconds.toString());

          print('*********** benchmark all steps finished ************');
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  // just encryption, return encFilepath
  Future<String> aesFileEncryptionOwn(String sourcePath, String destPath) async {
    String encFilepath;
    String decFilepath;

    // The file to be encrypted
    //String srcFilepath = './example/testfile.txt';
    String srcFilepath = sourcePath;
    //decFilepath = dest;
    print('Unencrypted source file: $srcFilepath');
    //print('File content: ' + File(srcFilepath).readAsStringSync() + '\n');

    // Creates an instance of AesCrypt class.
    var crypt = AesCrypt();

    // Sets encryption password.
    // Optionally you can specify the password when creating an instance
    // of AesCrypt class like:
    // var crypt = AesCrypt('my cool password');
    crypt.setPassword('my cool password');

    // Sets overwrite mode.
    // It's optional. By default the mode is 'AesCryptOwMode.warn'.
    //crypt.setOverwriteMode(AesCryptOwMode.warn);
    crypt.setOverwriteMode(AesCryptOwMode.on); // to overwrite a former one

    try {
      // Encrypts './example/testfile.txt' file and save encrypted file to a file with
      // '.aes' extension added. In this case it will be './example/testfile.txt.aes'.
      // It returns a path to encrypted file.
      //encFilepath = crypt.encryptFileSync('./example/testfile.txt');
      encFilepath = await crypt.encryptFile(srcFilepath);
      print('The encryption has been completed successfully.');
      print('Encrypted file: $encFilepath');
    } on AesCryptException catch (e) {
      // It goes here if overwrite mode set as 'AesCryptFnMode.warn'
      // and encrypted file already exists.
      if (e.type == AesCryptExceptionType.destFileExists) {
        print('The encryption has been completed unsuccessfully.');
        print(e.message);
      }
      return '';
    }
    return encFilepath;
  }

  // just decryption, return decFilepath
  Future<String> aesFileDecryptionOwn(String sourcePath, String destPath) async {
    String encFilepath;
    String decFilepath = '';

    // The file to be encrypted
    //String srcFilepath = './example/testfile.txt';
    encFilepath = sourcePath;
    //decFilepath = dest;

    print('Encrypted source file: $encFilepath');

    // Creates an instance of AesCrypt class.
    var crypt = AesCrypt();

    // Sets encryption password.
    // Optionally you can specify the password when creating an instance
    // of AesCrypt class like:
    // var crypt = AesCrypt('my cool password');
    crypt.setPassword('my cool password');

    // Sets overwrite mode.
    // It's optional. By default the mode is 'AesCryptOwMode.warn'.
    //crypt.setOverwriteMode(AesCryptOwMode.warn);
    crypt.setOverwriteMode(AesCryptOwMode.on); // to overwrite a former one

    try {
      // Decrypts the file which has been just encrypted and tries to save it under
      // another name than source file name.
      //decFilepath = crypt.decryptFileSync(encFilepath, './example/testfile_new.txt');
      decFilepath = await crypt.decryptFile(encFilepath, destPath);
      print('The decryption has been completed successfully.');
      print('Decrypted file 2: $decFilepath');
      //print('File content: ' + File(decFilepath).readAsStringSync());
    } on AesCryptException catch (e) {
      if (e.type == AesCryptExceptionType.destFileExists) {
        print('The decryption has been completed unsuccessfully.');
        print(e.message);
        return '';
      }
    }
    return decFilepath;
  }


  // just encryption, return encFilepath
  String aesFileEncryptionOwnSync(String sourcePath, String destPath) {
    String encFilepath;
    String decFilepath;

    // The file to be encrypted
    //String srcFilepath = './example/testfile.txt';
    String srcFilepath = sourcePath;
    //decFilepath = dest;
    print('Unencrypted source file: $srcFilepath');
    //print('File content: ' + File(srcFilepath).readAsStringSync() + '\n');

    // Creates an instance of AesCrypt class.
    var crypt = AesCrypt();

    // Sets encryption password.
    // Optionally you can specify the password when creating an instance
    // of AesCrypt class like:
    // var crypt = AesCrypt('my cool password');
    crypt.setPassword('my cool password');

    // Sets overwrite mode.
    // It's optional. By default the mode is 'AesCryptOwMode.warn'.
    //crypt.setOverwriteMode(AesCryptOwMode.warn);
    crypt.setOverwriteMode(AesCryptOwMode.on); // to overwrite a former one

    try {
      // Encrypts './example/testfile.txt' file and save encrypted file to a file with
      // '.aes' extension added. In this case it will be './example/testfile.txt.aes'.
      // It returns a path to encrypted file.
      //encFilepath = crypt.encryptFileSync('./example/testfile.txt');
      encFilepath = crypt.encryptFileSync(srcFilepath);
      print('The encryption has been completed successfully.');
      print('Encrypted file: $encFilepath');
    } on AesCryptException catch (e) {
      // It goes here if overwrite mode set as 'AesCryptFnMode.warn'
      // and encrypted file already exists.
      if (e.type == AesCryptExceptionType.destFileExists) {
        print('The encryption has been completed unsuccessfully.');
        print(e.message);
      }
      return '';
    }
    return encFilepath;
  }

  // just decryption, return decFilepath
  String aesFileDecryptionOwnSync(String sourcePath, String destPath) {
    String encFilepath;
    String decFilepath = '';

    // The file to be encrypted
    //String srcFilepath = './example/testfile.txt';
    encFilepath = sourcePath;
    //decFilepath = dest;

    print('Encrypted source file: $encFilepath');

    // Creates an instance of AesCrypt class.
    var crypt = AesCrypt();

    // Sets encryption password.
    // Optionally you can specify the password when creating an instance
    // of AesCrypt class like:
    // var crypt = AesCrypt('my cool password');
    crypt.setPassword('my cool password');

    // Sets overwrite mode.
    // It's optional. By default the mode is 'AesCryptOwMode.warn'.
    //crypt.setOverwriteMode(AesCryptOwMode.warn);
    crypt.setOverwriteMode(AesCryptOwMode.on); // to overwrite a former one

    try {
      // Decrypts the file which has been just encrypted and tries to save it under
      // another name than source file name.
      //decFilepath = crypt.decryptFileSync(encFilepath, './example/testfile_new.txt');
      decFilepath = crypt.decryptFileSync(encFilepath, destPath);
      print('The decryption has been completed successfully.');
      print('Decrypted file 2: $decFilepath');
      //print('File content: ' + File(decFilepath).readAsStringSync());
    } on AesCryptException catch (e) {
      if (e.type == AesCryptExceptionType.destFileExists) {
        print('The decryption has been completed unsuccessfully.');
        print(e.message);
        return '';
      }
    }
    return decFilepath;
  }


  // this is the full example
  void aesFileEncryption(String sourcePath, String destPath) {
    String encFilepath;
    String decFilepath;

    // The file to be encrypted
    //String srcFilepath = './example/testfile.txt';
    String srcFilepath = sourcePath;
    //decFilepath = dest;

    print('Unencrypted source file: $srcFilepath');
    //print('File content: ' + File(srcFilepath).readAsStringSync() + '\n');

    // Creates an instance of AesCrypt class.
    var crypt = AesCrypt();

    // Sets encryption password.
    // Optionally you can specify the password when creating an instance
    // of AesCrypt class like:
    // var crypt = AesCrypt('my cool password');
    crypt.setPassword('my cool password');

    // Sets overwrite mode.
    // It's optional. By default the mode is 'AesCryptOwMode.warn'.
    //crypt.setOverwriteMode(AesCryptOwMode.warn);
    crypt.setOverwriteMode(AesCryptOwMode.on); // to overwrite a former one

    try {
      // Encrypts './example/testfile.txt' file and save encrypted file to a file with
      // '.aes' extension added. In this case it will be './example/testfile.txt.aes'.
      // It returns a path to encrypted file.
      //encFilepath = crypt.encryptFileSync('./example/testfile.txt');
      encFilepath = crypt.encryptFileSync(srcFilepath);
      print('The encryption has been completed successfully.');
      print('Encrypted file: $encFilepath');
    } on AesCryptException catch (e) {
      // It goes here if overwrite mode set as 'AesCryptFnMode.warn'
      // and encrypted file already exists.
      if (e.type == AesCryptExceptionType.destFileExists) {
        print('The encryption has been completed unsuccessfully.');
        print(e.message);
      }
      return;
    }
    print('');
    try {
      // Decrypts the file which has been just encrypted.
      // It returns a path to decrypted file.
      decFilepath = crypt.decryptFileSync(encFilepath);
      print('The decryption has been completed successfully.');
      print('Decrypted file 1: $decFilepath');
      //print('File content: ' + File(decFilepath).readAsStringSync() + '\n');
    } on AesCryptException catch (e) {
      // It goes here if the file naming mode set as AesCryptFnMode.warn
      // and decrypted file already exists.
      if (e.type == AesCryptExceptionType.destFileExists) {
        print('The decryption has been completed unsuccessfully.');
        print(e.message);
      }
    }
    print('');
    try {
      // Decrypts the file which has been just encrypted and tries to save it under
      // another name than source file name.
      //decFilepath = crypt.decryptFileSync(encFilepath, './example/testfile_new.txt');
      decFilepath = crypt.decryptFileSync(encFilepath, destPath);
      print('The decryption has been completed successfully.');
      print('Decrypted file 2: $decFilepath');
      //print('File content: ' + File(decFilepath).readAsStringSync());
    } on AesCryptException catch (e) {
      if (e.type == AesCryptExceptionType.destFileExists) {
        print('The decryption has been completed unsuccessfully.');
        print(e.message);
      }
    }
    print('');
    try {
      // Decrypts the file to the same name as previous one but before sets
      // another overwrite mode 'AesCryptFnMode.auto'. See what will happens.
      crypt.setOverwriteMode(AesCryptOwMode.rename);
      //decFilepath = crypt.decryptFileSync(encFilepath, './example/testfile_new.txt');
      decFilepath = crypt.decryptFileSync(encFilepath, destPath);
      print('The decryption has been completed successfully.');
      print('Decrypted file 3: $decFilepath');
      //print('File content: ' + File(decFilepath).readAsStringSync() + '\n');
    } on AesCryptException catch (e) {
      if (e.type == AesCryptExceptionType.destFileExists) {
        print('The decryption has been completed unsuccessfully.');
        print(e.message);
      }
    }
    print('Done.');
  }

  Uint8List aesCbcEncryptionToUint8List(
      Uint8List key, Uint8List iv, Uint8List plaintextUint8) {
    final pc.CBCBlockCipher cipher =
        new pc.CBCBlockCipher(new pc.AESFastEngine());
    pc.ParametersWithIV<pc.KeyParameter> cbcParams =
        new pc.ParametersWithIV<pc.KeyParameter>(new pc.KeyParameter(key), iv);
    pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>
        paddingParams = new pc.PaddedBlockCipherParameters<
            pc.ParametersWithIV<pc.KeyParameter>, Null>(cbcParams, null);
    pc.PaddedBlockCipherImpl paddingCipher =
        new pc.PaddedBlockCipherImpl(new pc.PKCS7Padding(), cipher);
    paddingCipher.init(true, paddingParams);
    final ciphertext = paddingCipher.process(plaintextUint8);
    return ciphertext;
  }

  Uint8List aesCbcDecryptionToUint8List(
      Uint8List key, Uint8List iv, Uint8List ciphertextUint8) {
    final pc.CBCBlockCipher cipher =
        new pc.CBCBlockCipher(new pc.AESFastEngine());
    pc.ParametersWithIV<pc.KeyParameter> cbcParams =
        new pc.ParametersWithIV<pc.KeyParameter>(new pc.KeyParameter(key), iv);
    pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>
        paddingParams = new pc.PaddedBlockCipherParameters<
            pc.ParametersWithIV<pc.KeyParameter>, Null>(cbcParams, null);
    pc.PaddedBlockCipherImpl paddingCipher =
        new pc.PaddedBlockCipherImpl(new pc.PKCS7Padding(), cipher);
    paddingCipher.init(false, paddingParams);
    final plaintext = paddingCipher.process(ciphertextUint8);
    return plaintext;
  }

  Uint8List aesEcbEncryptionNoPaddingToUint8List(
      Uint8List key, Uint8List plaintextUint8) {
    // no padding
    pc.BlockCipher cipher = pc.ECBBlockCipher(pc.AESFastEngine());
    cipher.init(
      true,
      pc.KeyParameter(key),
    );
    Uint8List cipherText = cipher.process(plaintextUint8);
    return cipherText;
  }

  Uint8List aesEcbDecryptionNoPaddingToUint8List(
      Uint8List key, Uint8List ciphertextUint8) {
    // no padding
    pc.BlockCipher cipher = pc.ECBBlockCipher(pc.AESFastEngine());
    cipher.init(
      false,
      pc.KeyParameter(key),
    );
    Uint8List plainText = cipher.process(ciphertextUint8);
    return plainText;
  }

  Uint8List generateRandom1000Byte() {
    final _sGen = Random.secure();
    final _seed =
        Uint8List.fromList(List.generate(32, (n) => _sGen.nextInt(255)));
    pc.SecureRandom sec = pc.SecureRandom("Fortuna")
      ..seed(pc.KeyParameter(_seed));
    return sec.nextBytes(1000);
  }

  Uint8List generateRandom100000Byte() {
    final _sGen = Random.secure();
    final _seed =
        Uint8List.fromList(List.generate(32, (n) => _sGen.nextInt(255)));
    pc.SecureRandom sec = pc.SecureRandom("Fortuna")
      ..seed(pc.KeyParameter(_seed));
    return sec.nextBytes(100000);
  }

  Uint8List generateRandomByte(int length) {
    // maximum 1 mb of data
    // Unhandled Exception: Invalid argument(s): Fortuna PRNG cannot generate more than 1MB of random data per invocation
    final _sGen = Random.secure();
    final _seed =
        Uint8List.fromList(List.generate(32, (n) => _sGen.nextInt(255)));
    pc.SecureRandom sec = pc.SecureRandom("Fortuna")
      ..seed(pc.KeyParameter(_seed));
    return sec.nextBytes(length);
  }

  String bytesToHex(Uint8List data) {
    return hex.encode(data);
  }

  Uint8List createUint8ListFromString(String s) {
    var ret = new Uint8List(s.length);
    for (var i = 0; i < s.length; i++) {
      ret[i] = s.codeUnitAt(i);
    }
    return ret;
  }

  // Writing to a text file
  _writeText(File file, String text) async {
    //final Directory directory = await getApplicationDocumentsDirectory();
    //final File file = File('${directory.path}/my_file.txt');
    await file.writeAsString(text);
  }

  _writeUint8List(File file, Uint8List data) async {
    await file.writeAsBytes(data);
  }

  // Reading from a text file
  Future<String> _readText(File file) async {
    String text = '';
    try {
      //final Directory directory = await getApplicationDocumentsDirectory();
      //final File file = File('${directory.path}/my_file.txt');
      text = await file.readAsString();
    } catch (e) {
      print("Couldn't read file");
    }
    return text;
  }

  // Reading from a text file
  Future<Uint8List> _readUint8List(File file) async {
    Uint8List bytes = new Uint8List(0);
    await file.readAsBytes().then((value) {
      bytes = Uint8List.fromList(value);
      print('reading of bytes is completed');
    }).catchError((onError) {
      print('Exception Error while reading audio from path:' +
          onError.toString());
    });
    return bytes;
  }
}
