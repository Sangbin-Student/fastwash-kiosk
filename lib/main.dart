import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:bluez/bluez.dart';
import 'package:fastwash_kiosk/HTTPClient.dart';
import 'package:fastwash_kiosk/toast.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:process_run/process_run.dart';
//import 'package:quick_blue/quick_blue.dart';

import 'Modal.dart';

void main() {
  runApp(MaterialApp(
    builder: FToastBuilder(),
    home: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'NotoSansCJK'
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const int WASHER_ID = 1;

  FToast fToast = FToast();

  bool inited = false;
  bool modalOpened = false;
  bool _isSleeping = true;
  String time = "사용가능 시간 없음";
  List<User> users = [];
  Set<int> checkedIds = Set();
  DateTime lastInteractive = DateTime.now();

  void modalOffed() {
    setState(() {
      modalOpened = false;
    });
  }

  void _turnOnScreen() {
    setState(() {
      _isSleeping = false;
    });
  }

  void _turnOffScreen() {
    setState(() {
      _isSleeping = true;
    });
  }

  Widget _userListElement(String name, {Color color = Colors.white}) {
    return Column(
        children: [
          SizedBox(height: 5,),
          Text(
              name,
              style: TextStyle(color: color, decoration: TextDecoration.none, fontSize: 30, fontFamily: 'NotoSansCJK')
          ),
        ]
    );
  }

  Widget _sleepingScreen() {
    return GestureDetector(
      onTap: () {
        _turnOnScreen();
      },
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                  "$WASHER_ID",
                  style: TextStyle(color: Colors.blue, decoration: TextDecoration.none, fontSize: 100)
              ), const SizedBox(width: 80,), Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text(
                      "기숙사 3층",
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.none, fontSize: 55, fontFamily: 'NotoSansCJK')
                  ), SizedBox(width: 15,),
                    Text(
                      "(좌측 세면실)",
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.none, fontSize: 35, fontFamily: 'NotoSansCJK')
                  )],),
                  Column(
                    children: users.map((user) => _userListElement(user.name)).toList(),
                  ),
                  Text("시간대: ${time}~",
                      style: TextStyle(color: Colors.white, decoration: TextDecoration.none, fontSize: 35, fontFamily: 'NotoSansCJK')),
                  Text(" "),
                  Text("Tap to start / 시작하려면 터치하세요",
                      style: TextStyle(color: Colors.white, decoration: TextDecoration.none, fontSize: 20, fontFamily: 'NotoSansCJK'))
                ],
              ),
            ],
          ),
        ),
      )
    );
  }

  Widget _kioskScreen(BuildContext context) {
    return GestureDetector(
        onTap: () {
          lastInteractive = DateTime.now();
        },
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text(
                          "기숙사 3층",
                          style: TextStyle(color: Colors.blue, decoration: TextDecoration.none, fontSize: 55)
                      ), SizedBox(width: 15,),
                        Text(
                            "(좌측 세면실)",
                            style: TextStyle(color: Colors.blue, decoration: TextDecoration.none, fontSize: 35)
                        )],),
                  ],
                ),
                /*Column(
                  children: users.map((e) => _userListElement(e, color: Colors.black)).toList(),
                )*/
                ...users.map((user) => _userListElement("${user.name} ${checkedIds.contains(user.id) ? "[O]" : "[X]"}", color: Colors.black)).toList(),
                Text(""),
                OutlinedButton(onPressed: () => {
                  openModal(context, fToast, users, checkedIds, modalOffed),
                  setState(() {
                    modalOpened = true;
                  })
                }, child: Text(
                    "인증코드 직접 입력하기",
                    style: TextStyle(color: Colors.black, decoration: TextDecoration.none, fontSize: 18)
                ))
              ],
            ),
          )
        )
    );

  }

  @override
  Widget build(BuildContext context) {
    fToast.init(context);

    if(!inited) {
      Timer.periodic(const Duration(seconds: 5), (timer) async {
        fetchData(WASHER_ID).then((tuple) => {
          print(tuple),
          setState(() {
            users = tuple.item2;

            if(time != tuple.item1) {
              time = tuple.item1;
              checkedIds.clear();
            }

            var command = 'python door.py ${(checkedIds.length == users.length) ? "OPEN" : "CLOSE"}';
            var shell = Shell();
            shell.run(command).then((value) => print(value)).onError((error, stackTrace) => print(error));
          }),
        });
      });



      /*QuickBlue.scanResultStream.listen((device) {
        Iterable<User> founds = users.where((e) => e.bluetoothDeviceName != null && e.bluetoothDeviceName == device.name);
        if (founds.isNotEmpty) {
          print('Matched device: \'${device.name}\' - RSSI ${device.rssi}');
          if (device.rssi.abs() < 45) {
            checkedIds.add(founds.first.id);
          } else {
            checkedIds.remove(founds.first.id);
          }
        }
      });

      QuickBlue.startScan();*/

      final client = BlueZClient();
      void registerBle () {
        Timer.periodic(const Duration(seconds: 1), (timer) {
          print(client.devices);
          for (final device in client.devices) {
            Iterable<User> founds = users.where((e) => e.bluetoothDeviceName != null && e.bluetoothDeviceName == device.name);
            print("${device.name} / RSSI POS ${device.rssi.abs()}");
            if(device.rssi.abs() < 45) {
              checkedIds.add(founds.first.id);
            } else {
              checkedIds.remove(founds.first.id);
            }
          }
        });
      }

      client.connect().then((value) => {
        print("BLUEZ Enabled"),
        registerBle(),
        null
      });

      setState(() {
        inited = true;
      });

      const TIMEOUT = 30;
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isSleeping) {
          lastInteractive = DateTime.now();
        } else {
          if (DateTime.now().difference(lastInteractive).inSeconds == TIMEOUT - 10) {
            ToastUtil.toast(fToast, "10초 뒤 화면이 꺼집니다");
          }

          if (DateTime.now().difference(lastInteractive).inSeconds > TIMEOUT) {
            if(modalOpened) {
              //Navigator.pop(context); temporary disabled..
              modalOpened = false;
            }

            _turnOffScreen();
          }
        }
      });
    }

    return _isSleeping ? _sleepingScreen() : _kioskScreen(context);
  }
}