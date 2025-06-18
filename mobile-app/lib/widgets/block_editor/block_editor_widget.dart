import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/block_editor/block_types.dart';
import '../../widgets/block_editor/block_widget.dart';
import '../../services/levels_service.dart';

class BlockEditorWidget extends StatefulWidget {
  final Function(List<Block>) onSave;
  final Function(List<Block>) onRun;
  final VoidCallback onClear;
  final int currentLevel;

  const BlockEditorWidget({
    Key? key,
    required this.onSave,
    required this.onRun,
    required this.onClear,
    required this.currentLevel,
  }) : super(key: key);

  @override
  _BlockEditorWidgetState createState() => _BlockEditorWidgetState();
}

class _BlockEditorWidgetState extends State<BlockEditorWidget> {
  List<Block> workspaceBlocks = [];
  Block? selectedBlock;
  List<Block> toolboxBlocks = [];

  @override
  void initState() {
    super.initState();
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
    final level = LevelsService.getLevelById(widget.currentLevel);
    final toolboxXml = level.toolboxXml;

    // Parse toolbox XML to determine available blocks
    toolboxBlocks = _parseToolboxXml(toolboxXml);
  }

  List<Block> _parseToolboxXml(String xml) {
    List<Block> blocks = [];

    // Movement blocks (blue)
    if (xml.contains('type="move_forward"')) {
      blocks.add(Block(
        type: BlockType.moveForward,
        position: Offset.zero,
        color: Colors.blue,
        canHaveChildren: false,
      ));
    }
    if (xml.contains('type="move_backward"')) {
      blocks.add(Block(
        type: BlockType.moveBackward,
        position: Offset.zero,
        color: Colors.blue,
        canHaveChildren: false,
      ));
    }
    if (xml.contains('type="turn_left"')) {
      blocks.add(Block(
        type: BlockType.turnLeft,
        position: Offset.zero,
        color: Colors.blue,
        canHaveChildren: false,
      ));
    }
    if (xml.contains('type="turn_right"')) {
      blocks.add(Block(
        type: BlockType.turnRight,
        position: Offset.zero,
        color: Colors.blue,
        canHaveChildren: false,
      ));
    }

    // Control blocks (orange)
    if (xml.contains('type="wait"')) {
      blocks.add(Block(
        type: BlockType.wait,
        position: Offset.zero,
        color: Colors.orange,
        canHaveChildren: true,
      ));
    }

    // Logic blocks (purple)
    if (xml.contains('type="controls_if"')) {
      blocks.add(Block(
        type: BlockType.ifDistance,
        position: Offset.zero,
        color: Colors.purple,
        canHaveChildren: true,
      ));
    }

    // Stop block (red)
    if (xml.contains('type="stop"')) {
      blocks.add(Block(
        type: BlockType.stop,
        position: Offset.zero,
        color: Colors.red,
        canHaveChildren: false,
      ));
    }

    // Auto blocks (teal)
    if (xml.contains('type="auto_navigate"')) {
      blocks.add(Block(
        type: BlockType.autoNavigate,
        position: Offset.zero,
        color: Colors.teal,
        canHaveChildren: false,
      ));
    }

    return blocks;
  }

  void _handleBlockSnapped(Block block) {
    setState(() {
      // Remove the block from workspace blocks if it's being nested
      workspaceBlocks.remove(block);
    });
  }

  void _handleBlockUnsnapped(Block block) {
    setState(() {
      if (block.parent != null) {
        block.parent!.children.remove(block);
        block.parent = null;
      }
      workspaceBlocks.add(block);
    });
  }

  Widget _buildToolboxBlock(Block block) {
    return Draggable<Block>(
      data: block,
      feedback: Material(
        elevation: 4.0,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: block.color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            block.getDisplayName(),
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: BlockWidget(
          block: block,
          isDraggable: false,
        ),
      ),
      child: BlockWidget(
        block: block,
        isDraggable: false,
        onTap: null,
      ),
    );
  }

  Widget _buildWorkspaceBlock(Block block) {
    return BlockWidget(
      key: ValueKey(block),
      block: block,
      onBlockSnapped: _handleBlockSnapped,
      onBlockUnsnapped: _handleBlockUnsnapped,
      onPositionChanged: (position) {
        setState(() {
          block.position = position;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolbarButton(
                icon: Icons.save_rounded,
                label: 'Save',
                color: Colors.green,
                onPressed: () => widget.onSave(workspaceBlocks),
              ),
              _buildToolbarButton(
                icon: Icons.play_circle_filled,
                label: 'Run',
                color: Colors.orange,
                onPressed: () => widget.onRun(workspaceBlocks),
              ),
              _buildToolbarButton(
                icon: Icons.delete,
                label: 'Clear',
                color: Colors.red,
                onPressed: () {
                  setState(() {
                    workspaceBlocks.clear();
                  });
                  widget.onClear();
                },
              ),
            ],
          ),
        ),
        // Editor Area
        Expanded(
          child: Row(
            children: [
              // Toolbox Panel
              Container(
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16.0),
                    bottomRight: Radius.circular(16.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4.0,
                      offset: Offset(2, 0),
                    ),
                  ],
                ),
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  children: toolboxBlocks.map(_buildToolboxBlock).toList(),
                ),
              ),
              // Workspace Panel
              Expanded(
                child: DragTarget<Block>(
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      color: Colors.white,
                      child: Stack(
                        children: [
                          // Grid background
                          CustomPaint(
                            painter: GridPainter(),
                            size: Size.infinite,
                          ),
                          // Blocks
                          ...workspaceBlocks.map(_buildWorkspaceBlock),
                        ],
                      ),
                    );
                  },
                  onWillAccept: (block) => block != null,
                  onAccept: (block) {
                    setState(() {
                      // Create a new block instance
                      final newBlock = Block(
                        type: block.type,
                        position: block.position,
                        color: block.color,
                        canHaveChildren: block.canHaveChildren,
                      );
                      workspaceBlocks.add(newBlock);
                    });
                  },
                ),
              ),
            ],
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
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(
        label,
        style: GoogleFonts.roboto(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}

// Grid painter for workspace background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 1.0;

    const double spacing = 20.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
