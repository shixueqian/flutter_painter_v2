import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';

/// 图片绘画页面
/// 提供在图片上进行绘画、添加形状、文本等功能
class ImagePainterPage extends StatefulWidget {
  const ImagePainterPage({super.key, required this.image});

  final ui.Image image;

  @override
  _ImagePainterPageState createState() => _ImagePainterPageState();
}

class _ImagePainterPageState extends State<ImagePainterPage> {
  // ==================== 常量定义 ====================
  static const Color _defaultColor = Color(0xFFFF0000);
  static const double _defaultStrokeWidth = 3.0;
  static const double _minStrokeWidth = 2.0;
  static const double _maxStrokeWidth = 25.0;
  static const double _minFontSize = 8.0;
  static const double _maxFontSize = 96.0;
  static const double _minScale = 1.0;
  static const double _maxScale = 5.0;

  // ==================== 控制器和状态 ====================
  late PainterController _controller;
  FocusNode _textFocusNode = FocusNode();
  ui.Image? _backgroundImage;

  // ==================== 画笔设置 ====================
  Paint _shapePaint = Paint()
    ..strokeWidth = _defaultStrokeWidth
    ..color = _defaultColor
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  // ==================== 生命周期方法 ====================
  @override
  void initState() {
    super.initState();
    _initializeController();
    _initializeBackground();
    _setupDefaultTool();
  }

  @override
  void dispose() {
    _textFocusNode.dispose();
    super.dispose();
  }

  // ==================== 初始化方法 ====================

  /// 初始化绘画控制器
  void _initializeController() {
    _controller = PainterController(
      settings: PainterSettings(
        text: TextSettings(
          focusNode: _textFocusNode,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: _defaultColor,
            fontSize: 18,
          ),
        ),
        freeStyle: const FreeStyleSettings(
          color: _defaultColor,
          strokeWidth: _defaultStrokeWidth,
        ),
        shape: ShapeSettings(
          paint: _shapePaint,
          drawOnce: false, // 画完形状后保持选中状态
        ),
        scale: const ScaleSettings(
          enabled: true,
          minScale: _minScale,
          maxScale: _maxScale,
        ),
      ),
    );

    // 监听文本焦点事件
    _textFocusNode.addListener(_onFocusChange);
  }

  /// 初始化背景图片
  void _initializeBackground() {
    setState(() {
      _backgroundImage = widget.image;
      _controller.background = _backgroundImage?.backgroundDrawable;
    });
  }

  /// 设置默认工具（矩形）
  void _setupDefaultTool() {
    _controller.shapeFactory = RectangleFactory();
  }

  // ==================== 事件处理方法 ====================

  /// 文本焦点变化处理
  void _onFocusChange() {
    setState(() {});
  }

  // ==================== 工具选择方法 ====================

  /// 选择矩形工具
  void _selectRectangle() {
    _clearOtherSelections();
    _controller.shapeFactory = _controller.shapeFactory is RectangleFactory
        ? null
        : RectangleFactory();
  }

  /// 选择箭头工具
  void _selectArrow() {
    _clearOtherSelections();
    _controller.shapeFactory =
        _controller.shapeFactory is ArrowFactory ? null : ArrowFactory();
  }

  /// 选择文本工具
  void _selectText() {
    _clearShapeAndFreeStyle();
    _controller.addText();
  }

  /// 选择自由绘制工具
  void _selectFreeStyleDraw() {
    _clearTextAndShape();
    _controller.freeStyleMode = _controller.freeStyleMode != FreeStyleMode.draw
        ? FreeStyleMode.draw
        : FreeStyleMode.none;
  }

  /// 选择橡皮擦工具
  void _selectFreeStyleErase() {
    _clearTextAndShape();
    _controller.freeStyleMode = _controller.freeStyleMode != FreeStyleMode.erase
        ? FreeStyleMode.erase
        : FreeStyleMode.none;
  }

  // ==================== 辅助方法 ====================

  /// 清除其他选择（文本焦点和自由绘制）
  void _clearOtherSelections() {
    _textFocusNode.unfocus();
    _controller.freeStyleMode = FreeStyleMode.none;
  }

  /// 清除形状和自由绘制选择
  void _clearShapeAndFreeStyle() {
    _controller.freeStyleMode = FreeStyleMode.none;
    _controller.shapeFactory = null;
  }

  /// 清除文本和形状选择
  void _clearTextAndShape() {
    _textFocusNode.unfocus();
    _controller.shapeFactory = null;
  }

  // ==================== 设置方法 ====================

  /// 统一设置线条宽度
  void _setStrokeWidth(double value) {
    // 设置自由绘制线条宽度
    _controller.freeStyleStrokeWidth = value;

    // 设置形状线条宽度
    _setShapeFactoryPaint(
      (_controller.shapePaint ?? _shapePaint).copyWith(strokeWidth: value),
    );
  }

  /// 统一设置颜色
  void _setColor(double hue) {
    final color = HSVColor.fromAHSV(1, hue, 1, 1).toColor();

    // 设置自由绘制颜色
    _controller.freeStyleColor = color;

    // 设置形状颜色
    _setShapeFactoryPaint(
      (_controller.shapePaint ?? _shapePaint).copyWith(color: color),
    );

    // 设置文本颜色
    setState(() {
      _controller.textStyle = _controller.textStyle.copyWith(color: color);
    });
  }

  /// 设置文本字体大小
  void _setTextFontSize(double size) {
    setState(() {
      _controller.textSettings = _controller.textSettings.copyWith(
        textStyle: _controller.textSettings.textStyle.copyWith(fontSize: size),
      );
    });
  }

  /// 设置形状工厂画笔
  void _setShapeFactoryPaint(Paint paint) {
    setState(() {
      _controller.shapePaint = paint;
    });
  }

  // ==================== 操作方法 ====================

  /// 撤销操作
  void _undo() {
    _controller.undo();
  }

  /// 重做操作
  void _redo() {
    _controller.redo();
  }

  /// 删除选中的对象
  void _removeSelectedDrawable() {
    final selectedDrawable = _controller.selectedObjectDrawable;
    if (selectedDrawable != null) {
      _controller.removeDrawable(selectedDrawable);
    }
  }

  /// 渲染图片
  Future<Uint8List?> renderImage() async {
    if (_backgroundImage == null) return null;

    final backgroundImageSize = Size(
      _backgroundImage!.width.toDouble(),
      _backgroundImage!.height.toDouble(),
    );

    final image = await _controller.renderImage(backgroundImageSize);
    return image.pngBytes;
  }

  // ==================== UI构建方法 ====================

  /// 显示设置对话框
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("设置"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStrokeWidthSetting(setDialogState),
                const SizedBox(height: 16),
                _buildColorSetting(setDialogState),
                const SizedBox(height: 16),
                _buildFontSizeSetting(setDialogState),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("关闭"),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建线条宽度设置
  Widget _buildStrokeWidthSetting(Function setDialogState) {
    return Row(
      children: [
        const Expanded(flex: 1, child: Text("线条宽度")),
        Expanded(
          flex: 3,
          child: Slider.adaptive(
            min: _minStrokeWidth,
            max: _maxStrokeWidth,
            value: _controller.freeStyleStrokeWidth,
            onChanged: (value) {
              _setStrokeWidth(value);
              setDialogState(() {});
            },
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            _controller.freeStyleStrokeWidth.toStringAsFixed(1),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// 构建颜色设置
  Widget _buildColorSetting(Function setDialogState) {
    return Row(
      children: [
        const Expanded(flex: 1, child: Text("颜色")),
        Expanded(
          flex: 3,
          child: Slider.adaptive(
            min: 0,
            max: 359.99,
            value: HSVColor.fromColor(_controller.freeStyleColor).hue,
            activeColor: _controller.freeStyleColor,
            onChanged: (value) {
              _setColor(value);
              setDialogState(() {});
            },
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            HSVColor.fromColor(_controller.freeStyleColor)
                .hue
                .toStringAsFixed(0),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// 构建字体大小设置
  Widget _buildFontSizeSetting(Function setDialogState) {
    return Row(
      children: [
        const Expanded(flex: 1, child: Text("字体大小")),
        Expanded(
          flex: 3,
          child: Slider.adaptive(
            min: _minFontSize,
            max: _maxFontSize,
            value: _controller.textStyle.fontSize ?? 14,
            onChanged: (value) {
              _setTextFontSize(value);
              setDialogState(() {});
            },
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            (_controller.textStyle.fontSize ?? 14).toStringAsFixed(0),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// 构建工具栏
  Widget _buildToolbar() {
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, _, __) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildToolButton(
            icon: Icons.rectangle_outlined,
            tooltip: "矩形工具",
            isSelected: _controller.shapeFactory is RectangleFactory,
            onPressed: _selectRectangle,
          ),
          _buildToolButton(
            icon: Icons.arrow_forward,
            tooltip: "箭头工具",
            isSelected: _controller.shapeFactory is ArrowFactory,
            onPressed: _selectArrow,
          ),
          _buildToolButton(
            icon: Icons.text_fields,
            tooltip: "文本工具",
            isSelected: _textFocusNode.hasFocus,
            onPressed: _selectText,
          ),
          _buildToolButton(
            icon: Icons.brush,
            tooltip: "自由绘制",
            isSelected: _controller.freeStyleMode == FreeStyleMode.draw,
            onPressed: _selectFreeStyleDraw,
          ),
          _buildToolButton(
            icon: Icons.auto_fix_high,
            tooltip: "橡皮擦",
            isSelected: _controller.freeStyleMode == FreeStyleMode.erase,
            onPressed: _selectFreeStyleErase,
          ),
          _buildToolButton(
            icon: Icons.settings,
            tooltip: "设置",
            isSelected: false,
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
    );
  }

  /// 构建工具按钮
  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[500],
        ),
        onPressed: onPressed,
      ),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size(double.infinity, kToolbarHeight),
      child: ValueListenableBuilder<PainterControllerValue>(
        valueListenable: _controller,
        child: const Text("Flutter 绘画示例"),
        builder: (context, _, child) {
          return AppBar(
            title: child,
            actions: [
              Tooltip(
                message: "删除选中对象",
                child: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _controller.selectedObjectDrawable == null
                      ? null
                      : _removeSelectedDrawable,
                ),
              ),
              Tooltip(
                message: "撤销",
                child: IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: _controller.canUndo ? _undo : null,
                ),
              ),
              Tooltip(
                message: "重做",
                child: IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: _controller.canRedo ? _redo : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建绘画区域
  Widget _buildPainterArea() {
    if (_backgroundImage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Positioned.fill(
      child: Center(
        child: AspectRatio(
          aspectRatio: _backgroundImage!.width / _backgroundImage!.height,
          child: FlutterPainter(controller: _controller),
        ),
      ),
    );
  }

  // ==================== 主构建方法 ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [_buildPainterArea()],
      ),
      bottomNavigationBar: _buildToolbar(),
    );
  }
}
