// main.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '午餐選擇器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WheelPage(),
    );
  }
}

class WheelPage extends StatefulWidget {
  const WheelPage({super.key});

  @override
  State<WheelPage> createState() => _WheelPageState();
}

class _WheelPageState extends State<WheelPage> with SingleTickerProviderStateMixin {
  late List<WheelItem> items;
  late AnimationController _controller;
  double _startRotation = 0.0;
  double _endRotation = 0.0;
  bool isSpinning = false;
  String? selectedItem; // 儲存選中的項目

  // 預設轉盤項目列表
  final List<WheelItem> defaultItems = [
    WheelItem(
      id: '1',
      text: '火鍋',
      color: Colors.red.shade300,
    ),
    WheelItem(
      id: '2',
      text: '牛排',
      color: Colors.blue.shade300,
    ),
    WheelItem(
      id: '3',
      text: '披薩',
      color: Colors.green.shade300,
    ),
    WheelItem(
      id: '4',
      text: '咖哩',
      color: Colors.orange.shade300,
    ),
    WheelItem(
      id: '5',
      text: '壽司',
      color: Colors.purple.shade300,
    ),
    WheelItem(
      id: '6',
      text: '炒麵',
      color: Colors.yellow.shade300,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 初始化項目列表為預設值
    items = List.from(defaultItems);

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          isSpinning = false;
          _startRotation = _endRotation;
          _updateSelectedItem();
        });
      }
    });
  }

  // 計算選中的項目
  void _updateSelectedItem() {
    if (items.isEmpty) return;

    // 計算最終角度（標準化到 0-2π）
    double normalizedAngle = _endRotation % (2 * math.pi);
    if (normalizedAngle < 0) normalizedAngle += 2 * math.pi;

    // 計算選中的部分（注意：轉盤順時針旋轉，所以要用 2π 減去角度）
    double sectionAngle = 2 * math.pi / items.length;
    int selectedIndex = (items.length - ((2 * math.pi - normalizedAngle) / sectionAngle).floor() - 1) % items.length;

    setState(() {
      selectedItem = items[selectedIndex].text;
    });

    // 顯示結果對話框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('結果'),
        content: Text('選中了：$selectedItem'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  // 重置為預設值的方法
  void _resetToDefault() {
    setState(() {
      items = List.from(defaultItems);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增項目'),
        content: TextField(
          decoration: const InputDecoration(labelText: '項目名稱'),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                items.add(WheelItem(
                  id: DateTime.now().toString(),
                  text: value,
                  color: Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
                ));
              });
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  void _editItem(WheelItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('編輯項目'),
        content: TextField(
          decoration: const InputDecoration(labelText: '項目名稱'),
          controller: TextEditingController(text: item.text),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                final index = items.indexWhere((element) => element.id == item.id);
                items[index] = WheelItem(
                  id: item.id,
                  text: value,
                  color: item.color,
                );
              });
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  void _deleteItem(String id) {
    setState(() {
      items.removeWhere((item) => item.id == id);
    });
  }

  void _spinWheel() {
    if (items.isEmpty || isSpinning) return;

    setState(() {
      isSpinning = true;
      selectedItem = null;
      _endRotation = _startRotation +
          (math.Random().nextDouble() * 10 + 5) *
              math.pi * 2; // 5-15 圈

      _controller
        ..reset()
        ..forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('午餐選擇器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToDefault,
            tooltip: '重置為預設值',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addItem,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _startRotation +
                            (_endRotation - _startRotation) *
                                _controller.value,
                        child: CustomPaint(
                          painter: WheelPainter(items),
                          size: const Size(300, 300),
                        ),
                      );
                    },
                  ),
                  // 添加指針
                  Container(
                    width: 5,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 顯示當前選中項目
          if (selectedItem != null && !isSpinning)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '選中：$selectedItem',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _spinWheel,
              child: Text(isSpinning ? '旋轉中...' : '開始旋轉'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.color,
                  ),
                  title: Text(
                    item.text,
                    style: TextStyle(
                      fontWeight: item.text == selectedItem ?
                      FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editItem(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteItem(item.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WheelItem {
  final String id;
  final String text;
  final Color color;

  WheelItem({
    required this.id,
    required this.text,
    required this.color,
  });
}

class WheelPainter extends CustomPainter {
  final List<WheelItem> items;

  WheelPainter(this.items);

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sectionAngle = 2 * math.pi / items.length;

    for (var i = 0; i < items.length; i++) {
      final paint = Paint()..color = items[i].color;
      final startAngle = i * sectionAngle;

      canvas.drawArc(
        rect,
        startAngle,
        sectionAngle,
        true,
        paint,
      );

      // 繪製文字
      final textPainter = TextPainter(
        text: TextSpan(
          text: items[i].text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // 計算文字位置
      final textAngle = startAngle + sectionAngle / 2;
      final textRadius = radius * 0.7;
      final dx = center.dx + textRadius * math.cos(textAngle);
      final dy = center.dy + textRadius * math.sin(textAngle);
      final textCenter = Offset(dx, dy);

      canvas.save();
      canvas.translate(textCenter.dx, textCenter.dy);
      canvas.rotate(textAngle + math.pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // 繪製中心點
    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}