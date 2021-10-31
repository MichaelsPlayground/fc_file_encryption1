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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
          try{
            Uint8List bytesLoad;
            //String myPath= 'MyPath/abc.png';
            _readUint8List(file).then((bytesData) {
              bytesLoad = bytesData;
              //do your task here
              var step3Elapsed = step3.elapsed;
              print('bytesLoad length: ' + bytesLoad.length.toString());
              //print('data:\n' + bytesToHex(bytesLoad));
              print('step 3 elapsed: ' + step3Elapsed.inMicroseconds.toString());
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
          Uint8List bytesLoad = await raf.read(fileRLength); // reading all bytes
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


        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Uint8List aesCbcEncryptionToUint8List(Uint8List key, Uint8List iv, Uint8List plaintextUint8) {
    final pc.CBCBlockCipher cipher = new pc.CBCBlockCipher(new pc.AESFastEngine());
    pc.ParametersWithIV<pc.KeyParameter> cbcParams = new pc.ParametersWithIV<pc.KeyParameter>(new pc.KeyParameter(key), iv);
    pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null> paddingParams = new pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>(cbcParams, null);
    pc.PaddedBlockCipherImpl paddingCipher = new pc.PaddedBlockCipherImpl(new pc.PKCS7Padding(), cipher);
    paddingCipher.init(true, paddingParams);
    final ciphertext = paddingCipher.process(plaintextUint8);
    return ciphertext;
  }

  Uint8List aesCbcDecryptionToUint8List(Uint8List key, Uint8List iv, Uint8List ciphertextUint8) {
    final pc.CBCBlockCipher cipher = new pc.CBCBlockCipher(new pc.AESFastEngine());
    pc.ParametersWithIV<pc.KeyParameter> cbcParams = new pc.ParametersWithIV<pc.KeyParameter>(new pc.KeyParameter(key), iv);
    pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null> paddingParams = new pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>(cbcParams, null);
    pc.PaddedBlockCipherImpl paddingCipher = new pc.PaddedBlockCipherImpl(new pc.PKCS7Padding(), cipher);
    paddingCipher.init(false, paddingParams);
    final plaintext = paddingCipher.process(ciphertextUint8);
    return plaintext;
  }

  Uint8List generateRandom1000Byte() {
    final _sGen = Random.secure();
    final _seed =
    Uint8List.fromList(List.generate(32, (n) => _sGen.nextInt(255)));
    pc.SecureRandom sec = pc.SecureRandom("Fortuna")..seed(pc.KeyParameter(_seed));
    return sec.nextBytes(1000);
  }

  Uint8List generateRandom100000Byte() {
    final _sGen = Random.secure();
    final _seed =
    Uint8List.fromList(List.generate(32, (n) => _sGen.nextInt(255)));
    pc.SecureRandom sec = pc.SecureRandom("Fortuna")..seed(pc.KeyParameter(_seed));
    return sec.nextBytes(100000);
  }

  Uint8List generateRandomByte(int length) {
    // maximum 1 mb of data
    // Unhandled Exception: Invalid argument(s): Fortuna PRNG cannot generate more than 1MB of random data per invocation
    final _sGen = Random.secure();
    final _seed =
    Uint8List.fromList(List.generate(32, (n) => _sGen.nextInt(255)));
    pc.SecureRandom sec = pc.SecureRandom("Fortuna")..seed(pc.KeyParameter(_seed));
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
