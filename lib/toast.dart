import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'HTTPClient.dart';

class ToastUtil {
  static void toast(FToast toast, String message) {
    Widget toastWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.greenAccent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message)
        ],
      ),
    );

    toast.showToast(child: toastWidget, toastDuration: Duration(seconds: 3), gravity: ToastGravity.BOTTOM);
  }


}