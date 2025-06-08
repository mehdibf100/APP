import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  final String text;

  HeaderWidget(String s, {required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 50),
          SizedBox(height: 15),
          Text(
            text,
            style: TextStyle(
              color: Colors.black,
              fontFamily: "Urbanist-SemiBold",
              fontSize: 30,
            ),
          ),
        ],
      ),
    );
  }
}
