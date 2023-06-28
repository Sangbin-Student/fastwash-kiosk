import 'package:fastwash_kiosk/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'HTTPClient.dart';

void openModal(dynamic context, dynamic ftoast, List<User> users, Set<int> checked, void Function() modalOff) {
  String password = "";

  showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext context) {
      return Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30)
          ),
          color: Colors.white
        ),
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('OTP로 인증', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
              const Text('앱에서 표시되는 OTP 번호를 입력하세요', style: TextStyle(fontSize: 15, color: Colors.grey)),
              Container(height: 10,),
              Container(width: 300, child: TextField(onChanged: (text) => {
                password = text
              }, keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '6자리 숫자',
                  ))),
              Container(height: 10,),
              ElevatedButton(
                child: const Text('완료'),
                onPressed: () => {
                  users.where((element) => generateOTP(element.webOtpSeed) == password).forEach((user) {
                    checked.add(user.id);
                    ToastUtil.toast(ftoast, "등록했습니다");
                  }),
                  Navigator.pop(context),
                  modalOff()
                }
              )
            ],
          ),
        ),
      );
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