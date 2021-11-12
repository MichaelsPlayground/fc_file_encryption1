import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:pointycastle/export.dart' as pc;

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
      home: const MyHomePage(title: 'fc_file_encryption5_pc'),
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
          Uint8List data1mb = generateRandomByte(1024 * 1024); // 1 mb
          //Uint8List data1000 = generateRandomByte(1024);
          var step1Elapsed = step1.elapsed;
          //print('data1000 length: ' + data1000.length.toString());
          print('data1mb length: ' + data1mb.length.toString());
          //print('data:\n' + bytesToHex(data1000));
          print('step 1 elapsed: ' + step1Elapsed.inMicroseconds.toString());

          print('\n2 write data to file using file.io');
          // write the file
          final step2 = Stopwatch()..start();
          await _writeUint8List(file, data1mb);
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
          Uint8List ct = aesCbcEncryptionToUint8List(key, iv, data1mb);
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
          //await raf2.writeFrom(data1mb);
          await raf2.writeFrom(ct);
          await raf2.flush();
          await raf2.close();
          var step7Elapsed = step7.elapsed;
          print('step 7 elapsed: ' + step7Elapsed.inMicroseconds.toString());

          // load file in chunks, encrypt, store to file
          print('\n8 load file in chunks, encrypt, store to file using RandomAccessFile');
          File fileRAFStep8R = File('${directory.path}/file1.txt');
          File fileRAFStep8W = File('${directory.path}/file8e.txt');
          final step8 = Stopwatch()..start();
          RandomAccessFile rafStep8R = await fileRAFStep8R.open(mode: FileMode.read);
          RandomAccessFile rafStep8W = await fileRAFStep8W.open(mode: FileMode.write);
          var fileRStep8Length = await fileRAFStep8R.length();
          print('fileRStep8 length: ' + fileRStep8Length.toString());
          await rafStep8R.setPosition(0); // from position 0
          // calculate rounds
          int bufferStep8Length = 2048;
          print('8 buffer size: ' + bufferStep8Length.toString());
          int fullRoundsStep8 = fileRStep8Length ~/ bufferStep8Length;
          print('8 fullRounds: ' + fullRoundsStep8.toString());
          int remainderLastRoundStep8 = (fileRStep8Length % bufferStep8Length) as int;
          print('8 remainderLastRoundStep8: ' + remainderLastRoundStep8.toString());
          String keyS8String = '12345678123456781234567812345678'; // 32 chars
          String ivS8String = '7654321076543210'; // 16 chars
          Uint8List keyS8 = createUint8ListFromString(keyS8String);
          Uint8List ivS8 = createUint8ListFromString(ivS8String);

          // pointycastle setup
          final pc.CBCBlockCipher cipher =
          new pc.CBCBlockCipher(new pc.AESEngine());
          pc.ParametersWithIV<pc.KeyParameter> cbcParams =
          new pc.ParametersWithIV<pc.KeyParameter>(new pc.KeyParameter(keyS8), ivS8);
          pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>
          paddingParams = new pc.PaddedBlockCipherParameters<
              pc.ParametersWithIV<pc.KeyParameter>, Null>(cbcParams, null);
          pc.PaddedBlockCipherImpl paddingCipher =
          new pc.PaddedBlockCipherImpl(new pc.PKCS7Padding(), cipher);
          paddingCipher.init(true, paddingParams);

          // now lets read in chunks
          for (int rounds = 0; rounds < fullRoundsStep8; rounds++) {
            Uint8List bytesLoadStep8 = await rafStep8R.read(bufferStep8Length);
            //print('8 round: ' + rounds.toString() + ' bytesLoadStep8 Length: ' + bytesLoadStep8.length.toString());
            //print('8 round: ' + rounds.toString() + ' bytesLoadStep8 hex: ' + bytesToHex(bytesLoadStep8));
            Uint8List bytesLoadStep8Encrypted = _processBlocks(paddingCipher, bytesLoadStep8);
            await rafStep8W.writeFrom(bytesLoadStep8Encrypted);
          }

          /* funktioniert nicht bei -1
          // last one
          print('8 remainderLastRoundStep8 Length: ' + remainderLastRoundStep8.toString());
          Uint8List bytesLoadStep8 = await rafStep8R.read(remainderLastRoundStep8);
          Uint8List bytesLoadStep8Encrypted = _processBlocks(paddingCipher, bytesLoadStep8);
          await rafStep8W.writeFrom(bytesLoadStep8Encrypted);

          Uint8List step8Final = Uint8List(16);
          step8Final = paddingCipher.process(Uint8List(0));
          await rafStep8W.writeFrom(bytesLoadStep8Encrypted);

           */

          /* funktioniert */
          // die ersten runden waren mit einem buffer von 2048 byte
          // die letzte runde wird in 16er blöcke geteilt

          int lastRoundsStep8 = remainderLastRoundStep8 ~/ 16;
          for (int rounds = 0; rounds < lastRoundsStep8; rounds++) {
            Uint8List bytesLoadStep8 = await rafStep8R.read(16);
            //print('8 round: ' + rounds.toString() + ' bytesLoadStep8 Length: ' + bytesLoadStep8.length.toString());
            //print('8 round: ' + rounds.toString() + ' bytesLoadStep8 hex: ' + bytesToHex(bytesLoadStep8));
            Uint8List bytesLoadStep8Encrypted = _processBlocks(paddingCipher, bytesLoadStep8);
            await rafStep8W.writeFrom(bytesLoadStep8Encrypted);
          }
          // now its time for the final step
          int bytesToLoadFinal = remainderLastRoundStep8 - (lastRoundsStep8 * 16);
          print('8 bytesToLoadFinal: ' + bytesToLoadFinal.toString());
          Uint8List bytesLoadStep8Final = await rafStep8R.read(bytesToLoadFinal);
          //Uint8List bytesLoadStep8Final = await rafStep8R.read(remainderLastRoundStep8);
          Uint8List bytesLoadStep8Encrypted = _processBlocks(paddingCipher, bytesLoadStep8Final);
          await rafStep8W.writeFrom(bytesLoadStep8Encrypted);
          Uint8List step8Final = Uint8List(16);
          int step8FinalLength = paddingCipher.doFinal(Uint8List(0), 0, step8Final, 0);
          await rafStep8W.writeFrom(step8Final);
          /* */

                     /*
          Uint8List bytesLoadStep8Encrypted = new Uint8List(16);
          int n = paddingCipher.doFinal(bytesLoadStep8Final, 0 ,bytesLoadStep8Encrypted, 0);
          await rafStep8W.writeFrom(bytesLoadStep8Encrypted);
           */

          /*
          // run the final encryption
          Uint8List bytesLoadStep8Last = await rafStep8R.read(bufferStep8Length);
          int bytesLoadStep8LastLength = bytesLoadStep8Last.length;
          Uint8List lastRoundEncrypt = new Uint8List(16);
          //Uint8List lastRoundEncrypt = new Uint8List(bufferStep8Length);
          print('8 encryption parameters doFinal');
          print('8 bytesLoadStep8Last: ' + bytesToHex(bytesLoadStep8Last));
          print('8 bytesLoadStep8LastLength: ' + bytesLoadStep8LastLength.toString());
          //int lastRoundEncryptLength = paddingCipher.doFinal(bytesLoadStep8Last, 0, lastRoundEncrypt, 0);
          int lastRoundEncryptLength = paddingCipher.doFinal(bytesLoadStep8Last, 0, lastRoundEncrypt, 0);
          print('8 lastRoundEncryptLength: ' + lastRoundEncryptLength.toString());
          //Uint8List lastRoundEncrypt = paddingCipher.process(bytesLoadStep8Last);
          //print('8 lastRoundDecryptLength: ' + lastRoundEncryptLength.toString());
          await rafStep8W.writeFrom(lastRoundEncrypt);
          */
          await rafStep8W.flush();
          await rafStep8W.close();
          await rafStep8R.close();

          var step8Elapsed = step8.elapsed;
          print('step 8 elapsed: ' + step8Elapsed.inMicroseconds.toString());

          print('\n9 load file in chunks, decrypt, store to file using RandomAccessFile');
          File fileRAFStep9R = File('${directory.path}/file8e.txt');
          File fileRAFStep9W = File('${directory.path}/file8d.txt');
          final step9 = Stopwatch()..start();
          RandomAccessFile rafStep9R = await fileRAFStep9R.open(mode: FileMode.read);
          RandomAccessFile rafStep9W = await fileRAFStep9W.open(mode: FileMode.write);
          var fileRStep9Length = await fileRAFStep9R.length();
          print('fileRStep9 length: ' + fileRStep9Length.toString());
          await rafStep9R.setPosition(0); // from position 0
          // calculate rounds
          int bufferStep9Length = 2048;
          print('9 buffer size: ' + bufferStep9Length.toString());
          int fullRoundsStep9 = fileRStep9Length ~/ bufferStep9Length;
          print('9 fullRounds: ' + fullRoundsStep9.toString());
          int remainderLastRoundStep9 = (fileRStep9Length % bufferStep9Length) as int;
          print('9 remainderLastRoundStep9: ' + remainderLastRoundStep9.toString());
          String keyS9String = '12345678123456781234567812345678'; // 32 chars
          String ivS9String = '7654321076543210'; // 16 chars
          Uint8List keyS9 = createUint8ListFromString(keyS9String);
          Uint8List ivS9 = createUint8ListFromString(ivS9String);

          // pointycastle setup
          final pc.CBCBlockCipher cipher9 =
          new pc.CBCBlockCipher(new pc.AESEngine());
          pc.ParametersWithIV<pc.KeyParameter> cbcParams9 =
          new pc.ParametersWithIV<pc.KeyParameter>(new pc.KeyParameter(keyS9), ivS9);
          pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>
          paddingParams9 = new pc.PaddedBlockCipherParameters<
              pc.ParametersWithIV<pc.KeyParameter>, Null>(cbcParams, null);
          pc.PaddedBlockCipherImpl paddingCipher9 =
          new pc.PaddedBlockCipherImpl(new pc.PKCS7Padding(), cipher9);
          paddingCipher9.init(false, paddingParams9);

          // now lets read in chunks
          for (int rounds = 0; rounds < fullRoundsStep9; rounds++) {
            Uint8List bytesLoadStep9 = await rafStep9R.read(bufferStep9Length);
            Uint8List bytesLoadStep9Decrypted = _processBlocks(paddingCipher9, bytesLoadStep9);
            await rafStep9W.writeFrom(bytesLoadStep9Decrypted);
          }

          // run the final decryption
          Uint8List bytesLoadStep9Last = await rafStep9R.read(bufferStep9Length);
          int bytesLoadStep9LastLength = bytesLoadStep9Last.length;
          print('9 bytesLoadStep9LastLength: ' + bytesLoadStep9LastLength.toString());
          //Uint8List lastRoundDecrypt = new Uint8List(bufferStep9Length);
          Uint8List lastRoundDecrypt = new Uint8List(remainderLastRoundStep9);
          int lastRoundDecryptLength = paddingCipher9.doFinal(bytesLoadStep9Last, 0, lastRoundDecrypt, 0);
          print('9 lastRoundDecryptLength: ' + lastRoundDecryptLength.toString());
          // write only the real decrypted data
          Uint8List lastRoundDecryptReal = Uint8List.sublistView(lastRoundDecrypt, 0, lastRoundDecryptLength);
          print('9 lastRoundDecryptRealLength: ' + lastRoundDecryptReal.length.toString());
          await rafStep9W.writeFrom(lastRoundDecryptReal);
          await rafStep9W.flush();
          await rafStep9W.close();
          await rafStep9R.close();

          var step9Elapsed = step9.elapsed;
          print('step 9 elapsed: ' + step9Elapsed.inMicroseconds.toString());

          // just checking file length
          File fileRAF8eLength = File('${directory.path}/file8e.txt');
          RandomAccessFile rafLength = await fileRAF8eLength.open(mode: FileMode.read);
          var fileRaf8eLength = await rafLength.length();
          print('8 fileRaf8e length: ' + fileRaf8eLength.toString());

          File fileRAF8dLength = File('${directory.path}/file8d.txt');
          RandomAccessFile raf8dLength = await fileRAF8dLength.open(mode: FileMode.read);
          var fileRaf8dLength = await raf8dLength.length();
          print('9 fileRaf8d length: ' + fileRaf8dLength.toString());

          // checking sha-256
          File file8Sha256 = File('${directory.path}/file1.txt');
          RandomAccessFile rafSha256 = await file8Sha256.open(mode: FileMode.read);
          await rafSha256.setPosition(0); // from position 0
          Uint8List bytesLoadSha256 = await rafSha256.read(fileRLength); // reading all bytes
          rafSha256.close();
          Uint8List file1Sha256 = calculateSha256FromUint8List(bytesLoadSha256);
          print('8 file1Sha256:    ' + bytesToHex(file1Sha256));

          file8Sha256 = File('${directory.path}/file8e.txt');
          rafSha256 = await file8Sha256.open(mode: FileMode.read);
          await rafSha256.setPosition(0); // from position 0
          bytesLoadSha256 = await rafSha256.read(fileRLength); // reading all bytes
          rafSha256.close();
          Uint8List file8eSha256 = calculateSha256FromUint8List(bytesLoadSha256);
          print('8 file8eSha256:   ' + bytesToHex(file8eSha256));

          file8Sha256 = File('${directory.path}/file8d.txt');
          rafSha256 = await file8Sha256.open(mode: FileMode.read);
          await rafSha256.setPosition(0); // from position 0
          bytesLoadSha256 = await rafSha256.read(fileRLength); // reading all bytes
          rafSha256.close();
          Uint8List file8dSha256 = calculateSha256FromUint8List(bytesLoadSha256);
          print('9 file8dSha256:   ' + bytesToHex(file8dSha256));

          file8Sha256 = File('${directory.path}/file2.txt');
          rafSha256 = await file8Sha256.open(mode: FileMode.read);
          await rafSha256.setPosition(0); // from position 0
          bytesLoadSha256 = await rafSha256.read(fileRLength); // reading all bytes
          rafSha256.close();
          Uint8List file2Sha256 = calculateSha256FromUint8List(bytesLoadSha256);
          print('9 file2Sha256:    ' + bytesToHex(file2Sha256));




          // print out all again
          print('');
          print('*********** benchmark all steps ************');
          print('step 1 generate data elapsed: ' +
              step1Elapsed.inMicroseconds.toString());
          print('step 1 data size generated:   ' +
              data1mb.length.toString() +
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

          print('step 8 read data in chunks, encrypt, write using RAF elapsed: ' +
              step8Elapsed.inMicroseconds.toString());
          print('step 9 read data in chunks, decrypt, write using RAF elapsed: ' +
              step9Elapsed.inMicroseconds.toString());

/*
          print('step 11 file encryption aes_crypt elapsed SYNC: ' +
              step11Elapsed.inMicroseconds.toString());
          print('step 12 file decryption aes_crypt elapsed SYNC: ' +
              step12Elapsed.inMicroseconds.toString());

          print('step 13 file encryption aes_crypt elapsed ASYNC: ' +
              step13Elapsed.inMicroseconds.toString());
          print('step 14 file decryption aes_crypt elapsed ASYNC: ' +
              step14Elapsed.inMicroseconds.toString());
*/
          print('*********** benchmark all steps finished ************');
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }


  Uint8List _processBlocks(pc.BlockCipher cipher, Uint8List inp) {
    var out = new Uint8List(inp.lengthInBytes);
    for (var offset = 0; offset < inp.lengthInBytes;) {
      var len = cipher.processBlock(inp, offset, out, offset);
      offset += len;
    }
    return out;
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

  Uint8List calculateSha256FromString(String data) {
    var dataToDigest = createUint8ListFromString(data);
    var d = pc.Digest('SHA-256');
    return d.process(dataToDigest);
  }

  Uint8List calculateSha256FromUint8List(Uint8List dataToDigest) {
    var d = pc.Digest('SHA-256');
    return d.process(dataToDigest);
  }



}
