import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'block_types.dart';
import 'block_widget.dart';
import '../../services/levels_service.dart';

class BlockEditorWidget extends StatefulWidget {
  final FutureOr<void> Function(List<Block>) onSave;
  final FutureOr<void> Function(List<Block>) onRun;
  final Future<List<Block>?> Function(List<Block>)? onOpen;
  final Future<bool> Function(List<Block>)? confirmClear;
  final List<Block> initialBlocks;
  final VoidCallback onClear;
  final int currentLevel;

  const BlockEditorWidget({
    super.key,
    required this.onSave,
    required this.onRun,
    required this.onClear,
    required this.currentLevel,
    this.onOpen,
    this.confirmClear,
    this.initialBlocks = const [],
  });

  @override
  State<BlockEditorWidget> createState() => _BlockEditorWidgetState();
}

class _BlockEditorWidgetState extends State<BlockEditorWidget> {
  final List<Block> workspaceBlocks = [];
  final _workspaceKey = GlobalKey();
  List<Block> toolboxBlocks = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    workspaceBlocks.addAll(widget.initialBlocks.map((block) => block.clone()));
    _initializeToolboxBlocks();
  }

  @override
  void didUpdateWidget(BlockEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLevel != widget.currentLevel) {
      _initializeToolboxBlocks();
    }
  }

  void _initializeToolboxBlocks() {
    toolboxBlocks = [
      for (final type in LevelsService.getLevelById(widget.currentLevel).blocks)
        Block(type: type, position: Offset.zero, color: _colorForType(type)),
    ];
  }

  Color _colorForType(BlockType type) {
    switch (type) {
      case BlockType.wait:
        return Colors.orange;
      case BlockType.ifDistance:
        return Colors.purple;
      case BlockType.stop:
        return Colors.red;
      case BlockType.autoNavigate:
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  void _handleBlockSnapped(Block block) {
    setState(
      () => workspaceBlocks.removeWhere((root) => identical(root, block)),
    );
  }

  Widget _buildToolboxBlock(Block template) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Tooltip(
        message: 'Hold and drag into the workspace',
        child: LongPressDraggable<Block>(
          // The toolbox is a template. Each successful drop triggers a rebuild
          // and the next drag gets a new independent model, including defaults.
          data: template.clone(),
          maxSimultaneousDrags: 1,
          feedback: Material(
            child: SizedBox(
              width: 260,
              child: BlockWidget(block: template, isDraggable: false),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: BlockWidget(block: template, isDraggable: false),
          ),
          child: BlockWidget(block: template, isDraggable: false),
        ),
      ),
    );
  }

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final blockWidth = math.min(300.0, constraints.maxWidth - 16);
        final bottom = workspaceBlocks.fold<double>(
          0,
          (value, block) =>
              math.max(value, block.position.dy + _blockHeight(block)),
        );
        final canvasHeight = math.max(
          constraints.maxHeight,
          math.max(1200.0, bottom + 200),
        );
        return SingleChildScrollView(
          child: DragTarget<Block>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (details) {
              final renderBox =
                  _workspaceKey.currentContext!.findRenderObject() as RenderBox;
              final local = renderBox.globalToLocal(details.offset);
              final block = details.data;
              setState(() {
                block.detach();
                workspaceBlocks.removeWhere((root) => identical(root, block));
                block.position = Offset(
                  local.dx.clamp(
                    8.0,
                    math.max(8.0, constraints.maxWidth - blockWidth - 8),
                  ),
                  local.dy.clamp(8.0, canvasHeight - 60),
                );
                workspaceBlocks.add(block);
              });
            },
            builder: (context, candidates, rejected) => SizedBox(
              key: _workspaceKey,
              width: constraints.maxWidth,
              height: canvasHeight,
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: GridPainter())),
                  if (workspaceBlocks.isEmpty)
                    const Positioned(
                      top: 20,
                      left: 16,
                      right: 16,
                      child: Text(
                        'Hold a block, then drag it here.\nPrograms run from top to bottom.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  for (final block in workspaceBlocks)
                    Positioned(
                      key: ObjectKey(block),
                      left: block.position.dx.clamp(
                        0.0,
                        math.max(0.0, constraints.maxWidth - blockWidth),
                      ),
                      top: block.position.dy,
                      width: blockWidth,
                      child: BlockWidget(
                        block: block,
                        onBlockSnapped: _handleBlockSnapped,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _blockHeight(Block block) =>
      80 +
      (block.isContainer
          ? block.children.fold<double>(
              60,
              (height, child) => height + _blockHeight(child),
            )
          : 0);

  Future<void> _action(FutureOr<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<Block> _snapshot() =>
      workspaceBlocks.map((block) => block.clone()).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              _buildToolbarButton(
                icon: Icons.save_rounded,
                label: 'Save',
                color: Colors.green,
                onPressed: () => _action(() => widget.onSave(_snapshot())),
              ),
              if (widget.onOpen != null)
                _buildToolbarButton(
                  icon: Icons.folder_open,
                  label: 'Open',
                  color: Colors.blue,
                  onPressed: () => _action(() async {
                    final blocks = await widget.onOpen!(_snapshot());
                    if (blocks != null && mounted) {
                      setState(() {
                        workspaceBlocks.clear();
                        workspaceBlocks.addAll(
                          blocks.map((block) => block.clone()),
                        );
                      });
                    }
                  }),
                ),
              _buildToolbarButton(
                icon: Icons.play_circle_filled,
                label: 'Run',
                color: Colors.orange,
                onPressed: () => _action(
                  () => widget.onRun(List<Block>.of(workspaceBlocks)),
                ),
              ),
              _buildToolbarButton(
                icon: Icons.delete,
                label: 'Clear',
                color: Colors.red,
                onPressed: () => _action(() async {
                  if (widget.confirmClear != null &&
                      !await widget.confirmClear!(_snapshot()))
                    return;
                  if (!mounted) return;
                  setState(() => workspaceBlocks.clear());
                  widget.onClear();
                }),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 650;
              final toolbox = ColoredBox(
                color: Colors.grey.shade100,
                child: ListView(
                  scrollDirection: narrow ? Axis.horizontal : Axis.vertical,
                  children: [
                    for (final block in toolboxBlocks)
                      SizedBox(
                        width: narrow ? 230 : null,
                        child: _buildToolboxBlock(block),
                      ),
                  ],
                ),
              );
              if (narrow) {
                return Column(
                  children: [
                    SizedBox(height: 108, child: toolbox),
                    Expanded(child: _buildWorkspace()),
                  ],
                );
              }
              return Row(
                children: [
                  SizedBox(width: 230, child: toolbox),
                  Expanded(child: _buildWorkspace()),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) => TextButton.icon(
    onPressed: _busy ? null : onPressed,
    icon: Icon(icon, color: color),
    label: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.bold),
    ),
    style: TextButton.styleFrom(backgroundColor: color.withValues(alpha: 0.1)),
  );
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
