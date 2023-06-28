import 'package:fastwash_kiosk/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:new_virtual_keyboard/virtual_keyboard.dart';

import 'HTTPClient.dart';

class Modal extends StatefulWidget {
  dynamic context;
  dynamic ftoast;
  List<User> users;
  Set<int> checked;
  void Function() modalOff;

  Modal(this.context, this.ftoast, this.users, this.checked, this.modalOff, {super.key});

  @override
  State<Modal> createState() => _ModalState(context, ftoast, users, checked, modalOff);
}

class _ModalState extends State<Modal> {
  dynamic ctx;
  dynamic ftoast;
  List<User> users;
  Set<int> checked;
  void Function() modalOff;

  String password = "";

  _ModalState(this.ctx, this.ftoast, this.users, this.checked, this.modalOff);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 900,
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30)
          ),
          color: Colors.white
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('OTP로 인증', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),),
            const Text('앱에서 표시되는 OTP 번호를 입력하세요', style: TextStyle(fontSize: 13, color: Colors.grey)),
            Container(height: 10,),
            Container(width: 300,child: Text(password, textAlign: TextAlign.center, style: const TextStyle(letterSpacing: 8, fontWeight: FontWeight.w900, fontSize: 30, color: Colors.indigoAccent))),
            Container(height: 10,),
            Container(
              width: 400,
              color: Colors.indigoAccent,
              child: VirtualKeyboard(
                  height: 150,
                  textColor: Colors.white,
                  fontSize: 20,
                  type: VirtualKeyboardType.Numeric,
                  onKeyPress: (VirtualKeyboardKey key) {
                    setState(() {
                      if(VirtualKeyboardKeyAction.Backspace == key.action) {
                        password = password.substring(0, password.length - 1);
                      }else if (password.length < 6 && key.text != "."){
                        password = password + key.text!;
                      }

                      if(password.length >= 6) {
                        bool found = false;
                        users.where((element) => generateOTP(element.webOtpSeed) == password).forEach((user) {
                          checked.add(user.id);
                          ToastUtil.toast(ftoast, "등록했습니다");
                          found = true;
                        });

                        if(found) {
                          Navigator.pop(ctx);
                          modalOff();
                        }else {
                          ToastUtil.toast(ftoast, "일치하는 장치가 없습니다");
                          setState(() {
                            password = "";
                          });
                        }
                      }
                    });
                  }),
            ),
          ],
        ),
      ),
    );
  }

}

void openModal(dynamic context, dynamic ftoast, List<User> users, Set<int> checked, void Function() modalOff) {
  showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext context) {
      return Modal(context, ftoast, users, checked, modalOff);
    },
  );
}

String generateOTP(int seed) {
  int timeStamp = (DateTime.now().millisecondsSinceEpoch / 10000).floor();

  int value = seed ^ timeStamp;

  StringBuffer appender = StringBuffer();
  for(int i = 1; i <= 6; i++) {
    int source = (timeStamp % 2 == 0) ? ((i % 2 == 1) ? value : value % timeStamp) : ((i % 2 == 0) ? value : value % timeStamp);
    appender.write("${((source / i).floor() % 9) + 1}");
  }

  return appender.toString();
}