import 'package:flutter/material.dart';
import 'block_types.dart';

/// Only the workspace positions roots; nested blocks use normal Column layout.
class BlockWidget extends StatefulWidget {
  final Block block;
  final VoidCallback? onTap;
  final bool isDraggable;
  final Function(Offset)? onPositionChanged;
  final Function(Block)? onBlockSnapped;
  final Function(Block)? onBlockUnsnapped;

  const BlockWidget({
    super.key,
    required this.block,
    this.onTap,
    this.isDraggable = true,
    this.onPositionChanged,
    this.onBlockSnapped,
    this.onBlockUnsnapped,
  });

  @override
  State<BlockWidget> createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget> {
  @override
  Widget build(BuildContext context) {
    final content = Material(
      color: widget.block.color,
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              widget.onTap?.call();
              if (widget.isDraggable) _editParameters(context);
            },
            borderRadius: BorderRadius.circular(8),
            child: _buildBlockHeader(),
          ),
          if (widget.block.isContainer && widget.isDraggable)
            _buildContainerBody(),
        ],
      ),
    );
    if (!widget.isDraggable) return content;
    return Draggable<Block>(
      data: widget.block,
      maxSimultaneousDrags: 1,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        color: widget.block.color,
        child: SizedBox(width: 280, child: _buildBlockHeader()),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: content),
      child: content,
    );
  }

  Future<void> _editParameters(BuildContext context) async {
    final parameter = BlockParameter.forType(widget.block.type);
    if (parameter == null) return;
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _ParameterDialog(
        parameter: parameter,
        value: widget.block.parameters[parameter.key],
      ),
    );
    if (result != null && mounted) {
      setState(() => widget.block.parameters[parameter.key] = result);
    }
  }

  Widget _buildBlockHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Icon(_icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              widget.block.getDisplayName(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (BlockParameter.forType(widget.block.type) != null) ...[
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: Text(
                _parameterPreview,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContainerBody() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 8, bottom: 8),
      child: DragTarget<Block>(
        onWillAcceptWithDetails: (details) =>
            widget.block.canAcceptChild(details.data),
        onAcceptWithDetails: (details) {
          if (widget.block.addChild(details.data)) {
            setState(() {});
            widget.onBlockSnapped?.call(details.data);
          }
        },
        builder: (context, candidates, rejected) => Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: candidates.isNotEmpty
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final child in widget.block.children)
                Padding(
                  key: ObjectKey(child),
                  padding: const EdgeInsets.only(bottom: 6),
                  child: BlockWidget(
                    block: child,
                    onBlockSnapped: widget.onBlockSnapped,
                    onBlockUnsnapped: widget.onBlockUnsnapped,
                  ),
                ),
              if (widget.block.children.isEmpty || candidates.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(6),
                  child: Text(
                    'Drop blocks here',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _icon {
    switch (widget.block.type) {
      case BlockType.moveForward:
        return Icons.arrow_upward;
      case BlockType.moveBackward:
        return Icons.arrow_downward;
      case BlockType.turnLeft:
        return Icons.arrow_back;
      case BlockType.turnRight:
        return Icons.arrow_forward;
      case BlockType.stop:
        return Icons.stop;
      case BlockType.wait:
        return Icons.timer;
      case BlockType.ifDistance:
        return Icons.sensors;
      case BlockType.autoNavigate:
        return Icons.auto_mode;
    }
  }

  String get _parameterPreview {
    final parameter = BlockParameter.forType(widget.block.type)!;
    return '${widget.block.parameters[parameter.key]} ${parameter.unit}';
  }
}

class _ParameterDialog extends StatefulWidget {
  final BlockParameter parameter;
  final dynamic value;

  const _ParameterDialog({required this.parameter, required this.value});

  @override
  State<_ParameterDialog> createState() => _ParameterDialogState();
}

class _ParameterDialogState extends State<_ParameterDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, int.parse(_controller.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final parameter = widget.parameter;
    return AlertDialog(
      title: Text('Set ${parameter.label.toLowerCase()}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: parameter.label,
            helperText:
                '${parameter.minimum}–${parameter.maximum} ${parameter.unit}',
            suffixText: parameter.unit,
            border: const OutlineInputBorder(),
          ),
          validator: (text) =>
              parameter.isValid(int.tryParse(text?.trim() ?? ''))
              ? null
              : 'Enter a whole number from ${parameter.minimum} to ${parameter.maximum}',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('OK')),
      ],
    );
  }
}

class ConnectionPoint extends StatelessWidget {
  final bool isInput;
  final bool isConnected;
  final VoidCallback? onTap;

  const ConnectionPoint({
    super.key,
    this.isInput = true,
    this.isConnected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isConnected ? Colors.green : Colors.grey[400],
        border: Border.all(color: Colors.white, width: 2),
      ),
    ),
  );
}
