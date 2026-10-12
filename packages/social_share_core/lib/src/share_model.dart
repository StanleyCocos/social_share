// ignore_for_file: avoid_print, constant_identifier_names

class ShareModel {
  SharePlatform? platform;
  String text;
  String image;

  ShareModel({this.platform, this.text = "", this.image = ""});
}

enum SharePlatform { Line, Facebook }
