import 'package:flutter/material.dart';
import 'package:social_share_facebook/social_share_facebook.dart';
import 'package:social_share_line/social_share_line.dart';

void main() => runApp(const ShareExampleApp());

class ShareExampleApp extends StatelessWidget {
  const ShareExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Social Share Bridge',
    theme: ThemeData(colorSchemeSeed: Colors.blue),
    home: const SharePage(),
  );
}

class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  final _text = TextEditingController(text: 'https://www.100.com.tw/');
  final _image = TextEditingController(
    text: 'https://www.baidu.com/img/bd_logo1.png',
  );
  String _result = '等待调用。state=0 的含义沿用旧插件，不代表已确认发布。';

  @override
  void dispose() {
    _text.dispose();
    _image.dispose();
    super.dispose();
  }

  Future<void> _share(SharePlatform platform, {required bool image}) async {
    setState(() => _result = '已调用，等待原实现返回…');
    try {
      final response = await FlutterShare.share(
        ShareModel(
          platform: platform,
          text: image ? '' : _text.text,
          image: image ? _image.text : '',
        ),
      );
      if (mounted) setState(() => _result = '$response');
    } catch (error) {
      if (mounted) setState(() => _result = '$error');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Social Share Bridge Example')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _text,
          decoration: const InputDecoration(labelText: '文字或链接'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _image,
          decoration: const InputDecoration(labelText: '网络图片 URL 或本地图片路径'),
        ),
        const SizedBox(height: 24),
        for (final platform in SharePlatform.values) ...[
          Text(platform.name, style: Theme.of(context).textTheme.titleLarge),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => _share(platform, image: false),
                child: Text(
                  platform == SharePlatform.Facebook ? '分享链接' : '分享文字 / 链接',
                ),
              ),
              ElevatedButton(
                onPressed: () => _share(platform, image: true),
                child: const Text('分享单图'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        const Text('Threads：第一版仅创建插件骨架，暂未接入分享。'),
        const SizedBox(height: 16),
        SelectableText(_result),
      ],
    ),
  );
}
