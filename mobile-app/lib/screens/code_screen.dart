import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/levels_service.dart';
import '../services/practice_progress.dart';
import '../services/program_executor.dart';
import '../services/program_store.dart';
import '../services/robot_client.dart';
import '../widgets/block_editor/block_editor_widget.dart';
import '../widgets/block_editor/block_types.dart';
import 'run_screen.dart';

class CodeScreen extends StatefulWidget {
  const CodeScreen({super.key, this.store, this.robot});
  final ProgramStore? store;
  final RobotClient? robot;

  @override
  State<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen>
    with AutomaticKeepAliveClientMixin {
  late final ProgramStore _store = widget.store ?? ProgramStore();
  String? _name;
  String _savedFingerprint = '[]';
  int? _savedLevel;

  @override
  bool get wantKeepAlive => true;

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  bool _hasChanges(List<Block> blocks) =>
      BlockCodec.fingerprint(blocks) != _savedFingerprint ||
      (_name != null && context.read<AppState>().currentLevel != _savedLevel);

  Future<void> _save(List<Block> blocks) async {
    final level = context.read<AppState>().currentLevel;
    try {
      final name = await showDialog<String>(
        context: context,
        builder: (_) => _ProgramNameDialog(initialName: _name ?? ''),
      );
      if (name == null || !mounted) return;
      final programs = await _store.load();
      if (!mounted) return;
      final exists = programs.any(
        (p) => p.name.trim().toLowerCase() == name.toLowerCase(),
      );
      if (exists &&
          !await _confirm(
            'Replace saved program?',
            'Replace "$name" with this workspace? Use a different name to keep both.',
            'Replace',
          ))
        return;
      final saved = await _store.save(
        name: name,
        level: level,
        blocks: blocks,
        replace: exists,
      );
      if (!mounted) return;
      setState(() {
        _name = saved.name;
        _savedFingerprint = BlockCodec.fingerprint(blocks);
        _savedLevel = level;
      });
      _message('Saved "${saved.name}" on this device.');
    } catch (_) {
      _message(
        'Program could not be saved. Your workspace is still here; existing saved data has been kept.',
      );
    }
  }

  Future<List<Block>?> _open(List<Block> workspace) async {
    try {
      final programs = await _store.load();
      if (!mounted) return null;
      if (programs.isEmpty) {
        _message('No saved programs yet. Use Save first.');
        return null;
      }
      final appState = context.read<AppState>();
      final selected = await showDialog<SavedProgram>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Open program'),
          children: [
            for (final program in programs)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, program),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${program.name}\nLevel ${program.level} · ${program.savedAt.toLocal().toString().substring(0, 16)}',
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      if (selected == null || !mounted) return null;
      if (!appState.isLevelUnlocked(selected.level)) {
        _message(
          'Complete the previous practice level before opening this program.',
        );
        return null;
      }
      if (_hasChanges(workspace) &&
          !await _confirm(
            'Unsaved changes',
            'Opening another program will replace changes in this workspace. Cancel to save them first.',
            'Open anyway',
          ))
        return null;
      if (!mounted) return null;
      final blocks = selected.blocks;
      appState.setCurrentLevel(selected.level);
      setState(() {
        _name = selected.name;
        _savedLevel = selected.level;
        _savedFingerprint = BlockCodec.fingerprint(blocks);
      });
      _message('Opened "${selected.name}".');
      return blocks;
    } catch (_) {
      _message(
        'Saved programs could not be read. Existing data and your workspace have been kept.',
      );
      return null;
    }
  }

  Future<void> _run(List<Block> blocks) async {
    final error = ProgramExecutor.validationError(blocks);
    if (error != null) {
      _message(error);
      return;
    }
    final appState = context.read<AppState>();
    final level = appState.currentLevel;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => RunScreen(
          blocks: blocks,
          robot: widget.robot,
          onCompleted: (result) async {
            if (!PracticeProgress.qualifies(level, result)) {
              return 'Practice check not yet met. ${PracticeProgress.hint(level)}';
            }
            final newlyCompleted = await appState.recordPracticeRun(
              level,
              result,
            );
            if (!newlyCompleted)
              return 'Level $level practice was already recorded.';
            if (appState.completedLevels.length == 5) {
              return 'Level $level practice recorded. All five practice levels are complete.';
            }
            return level < 5
                ? 'Level $level practice recorded. Level ${level + 1} is available on Home.'
                : 'Level 5 practice recorded.';
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (!appState.isLoaded)
          return const Center(child: CircularProgressIndicator());
        return Column(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Level ${appState.currentLevel}: ${LevelsService.getLevelById(appState.currentLevel).name}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(PracticeProgress.hint(appState.currentLevel)),
                    Text(
                      _name == null
                          ? 'Untitled · Save to keep your work'
                          : 'Program: $_name · Save to keep changes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (appState.storageError != null)
                      Text(
                        appState.storageError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: BlockEditorWidget(
                currentLevel: appState.currentLevel,
                onSave: _save,
                onOpen: _open,
                onRun: _run,
                confirmClear: (blocks) async =>
                    blocks.isEmpty ||
                    await _confirm(
                      'Clear workspace?',
                      'Remove all blocks from this workspace? Saved programs will remain available in Open.',
                      'Clear workspace',
                    ),
                onClear: () {
                  setState(() {
                    _name = null;
                    _savedLevel = null;
                    _savedFingerprint = '[]';
                  });
                  _message('Workspace cleared.');
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProgramNameDialog extends StatefulWidget {
  const _ProgramNameDialog({required this.initialName});
  final String initialName;
  @override
  State<_ProgramNameDialog> createState() => _ProgramNameDialogState();
}

class _ProgramNameDialogState extends State<_ProgramNameDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate())
      Navigator.pop(context, _name.text.trim());
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Save program'),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _name,
        autofocus: true,
        maxLength: 64,
        decoration: const InputDecoration(
          labelText: 'Program name',
          helperText: 'A new name saves a separate copy.',
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Enter a name.' : null,
        onFieldSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Save program')),
    ],
  );
}
