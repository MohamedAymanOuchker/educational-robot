import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'block_types.dart';

class BlockWidget extends StatefulWidget {
  final Block block;
  final VoidCallback? onTap;
  final bool isDraggable;
  final Function(Offset)? onPositionChanged;
  final Function(Block)? onBlockSnapped;
  final Function(Block)? onBlockUnsnapped;

  const BlockWidget({
    Key? key,
    required this.block,
    this.onTap,
    this.isDraggable = true,
    this.onPositionChanged,
    this.onBlockSnapped,
    this.onBlockUnsnapped,
  }) : super(key: key);

  @override
  _BlockWidgetState createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final blockContent = Container(
      constraints: BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: widget.block.color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(widget.block.isContainer ? 0 : 8),
          bottomRight: Radius.circular(widget.block.isContainer ? 0 : 8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (widget.onTap != null) {
              widget.onTap!();
            }
            // Only allow parameter editing if block is draggable (in workspace)
            if (widget.isDraggable) {
              _editParameters(context);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBlockHeader(),
                if (widget.block.isContainer) _buildContainerBody(),
              ],
            ),
          ),
        ),
      ),
    );

    if (!widget.isDraggable) {
      return blockContent;
    }

    return Positioned(
      left: widget.block.position.dx,
      top: widget.block.position.dy,
      child: SizedBox(
        width: 300,
        child: GestureDetector(
          onPanStart: (_) => setState(() => _isDragging = true),
          onPanUpdate: (details) {
            setState(() {
              widget.block.position += details.delta;
              if (widget.onPositionChanged != null) {
                widget.onPositionChanged!(widget.block.position);
              }
            });
          },
          onPanEnd: (_) => setState(() => _isDragging = false),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            transform: Matrix4.identity()
              ..translate(0.0, _isDragging ? -10.0 : 0.0, 0.0),
            child: blockContent,
          ),
        ),
      ),
    );
  }

  Future<void> _editParameters(BuildContext context) async {
    if (widget.block.type == BlockType.ifDistance) {
      final controller = TextEditingController(
          text: widget.block.parameters['distance']?.toString() ?? '20');

      final result = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Set Distance Threshold',
            style: GoogleFonts.comicNeue(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How close can objects get?',
                style: GoogleFonts.comicNeue(fontSize: 16),
              ),
              SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Distance in cm',
                  hintText: '1-200',
                  border: OutlineInputBorder(),
                  suffixText: 'cm',
                ),
                style: GoogleFonts.comicNeue(fontSize: 18),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null && value > 0 && value <= 200) {
                  Navigator.pop(context, value);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a number between 1 and 200'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: Text('OK'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

      if (result != null) {
        setState(() {
          widget.block.parameters['distance'] = result;
        });
      }
    }

    // Add similar dialogs for other block types
    else if (widget.block.type == BlockType.moveForward ||
        widget.block.type == BlockType.moveBackward) {
      // Similar dialog for distance parameter
    } else if (widget.block.type == BlockType.turnLeft ||
        widget.block.type == BlockType.turnRight) {
      // Similar dialog for angle parameter
    } else if (widget.block.type == BlockType.wait) {
      // Similar dialog for time parameter
    }
  }

  Widget _buildBlockHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              _getIconForBlock(widget.block.getDisplayName()),
              color: Colors.white,
              size: 16,
            ),
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.block.getDisplayName(),
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          if (widget.block.parameters.isNotEmpty) ...[
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getParameterPreview(),
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContainerBody() {
    return Container(
      margin: EdgeInsets.only(left: 24),
      padding: EdgeInsets.all(8),
      constraints: BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: widget.block.color.withOpacity(0.7),
        border: Border(
          left: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: DragTarget<Block>(
        builder: (context, candidateData, rejectedData) {
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: 50),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...widget.block.children.map((childBlock) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: BlockWidget(
                        block: childBlock,
                        onBlockSnapped: widget.onBlockSnapped,
                        onBlockUnsnapped: widget.onBlockUnsnapped,
                      ),
                    )),
                if (candidateData.isNotEmpty)
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
          );
        },
        onWillAccept: (block) => block != null && block != widget.block,
        onAccept: (block) {
          if (widget.onBlockSnapped != null) {
            block.parent = widget.block;
            widget.block.children.add(block);
            widget.onBlockSnapped!(block);
          }
        },
      ),
    );
  }

  IconData _getIconForBlock(String label) {
    switch (label.toLowerCase()) {
      case 'move forward':
        return Icons.arrow_upward;
      case 'move backward':
        return Icons.arrow_downward;
      case 'turn left':
        return Icons.arrow_back;
      case 'turn right':
        return Icons.arrow_forward;
      case 'stop':
        return Icons.stop;
      case 'wait':
        return Icons.timer;
      case 'if distance <':
        return Icons.sensors;
      case 'auto navigate':
        return Icons.auto_mode;
      default:
        return Icons.code;
    }
  }

  String _getParameterPreview() {
    if (widget.block.parameters.isEmpty) return '';

    if (widget.block.parameters.containsKey('distance')) {
      return '${widget.block.parameters['distance']}cm';
    }
    if (widget.block.parameters.containsKey('angle')) {
      return '${widget.block.parameters['angle']}°';
    }
    if (widget.block.parameters.containsKey('time')) {
      return '${widget.block.parameters['time']}ms';
    }

    return widget.block.parameters.values.first.toString();
  }
}

// Connection point widget for visual feedback
class ConnectionPoint extends StatelessWidget {
  final bool isInput;
  final bool isConnected;
  final VoidCallback? onTap;

  const ConnectionPoint({
    Key? key,
    this.isInput = true,
    this.isConnected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isConnected ? Colors.green : Colors.grey[400],
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
