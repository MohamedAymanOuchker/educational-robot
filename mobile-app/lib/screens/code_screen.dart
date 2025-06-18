import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/levels_service.dart';
import '../services/block_editor_service.dart';
import '../widgets/block_editor/block_editor_widget.dart';
import '../widgets/block_editor/block_types.dart';
import './run_screen.dart';

class CodeScreen extends StatefulWidget {
  const CodeScreen({Key? key}) : super(key: key);

  @override
  _CodeScreenState createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  // FIXED: Updated to match actual generated code patterns
  Future<bool> _validateLevelCompletion(String code, int levelId) async {
    print('Validating level $levelId completion with code: $code');

    switch (levelId) {
      case 1: // Basic Movement - just need any movement command
        bool hasMovement = code.contains('sendCommand("F"') ||
            code.contains('sendCommand("B"') ||
            code.contains('sendCommand("L"') ||
            code.contains('sendCommand("R"');
        print('Level 1 - Has movement: $hasMovement');
        return hasMovement;

      case 2: // Path Planning - need movement + wait
        bool hasMovement = code.contains('sendCommand("F"') ||
            code.contains('sendCommand("B"') ||
            code.contains('sendCommand("L"') ||
            code.contains('sendCommand("R"');
        bool hasWait = code.contains('Future.delayed');
        print('Level 2 - Has movement: $hasMovement, Has wait: $hasWait');
        return hasMovement && hasWait;

      case 3: // Sensor Integration - need sensor usage
        bool hasSensor =
            code.contains('getDistance()') || code.contains('if (');
        print('Level 3 - Has sensor: $hasSensor');
        return hasSensor;

      case 4: // Auto Mode - need auto navigation
        bool hasAuto = code.contains('sendCommand("AUTO_NAV")');
        print('Level 4 - Has auto: $hasAuto');
        return hasAuto;

      case 5: // Advanced Navigation - complex behaviors
        bool hasAdvanced = code.contains('sendCommand("AUTO_NAV")') ||
            code.contains('sendCommand("PATROL")') ||
            code.contains('sendCommand("MAP")');
        print('Level 5 - Has advanced: $hasAdvanced');
        return hasAdvanced;

      default:
        return false;
    }
  }

  // ENHANCED: Better completion validation using blocks directly
  Future<bool> _validateLevelCompletionByBlocks(
      List<Block> blocks, int levelId) async {
    print('Validating level $levelId completion with ${blocks.length} blocks');

    // Get all blocks including nested ones
    List<Block> allBlocks = [];
    void collectBlocks(Block block) {
      allBlocks.add(block);
      for (var child in block.children) {
        collectBlocks(child);
      }
    }

    for (var block in blocks) {
      collectBlocks(block);
    }

    print('Total blocks (including nested): ${allBlocks.length}');
    for (var block in allBlocks) {
      print('Block type: ${block.type}');
    }

    switch (levelId) {
      case 1: // Basic Movement
        bool hasMovement = allBlocks.any((b) =>
            b.type == BlockType.moveForward ||
            b.type == BlockType.moveBackward ||
            b.type == BlockType.turnLeft ||
            b.type == BlockType.turnRight);
        return hasMovement;

      case 2: // Path Planning
        bool hasMovement = allBlocks.any((b) =>
            b.type == BlockType.moveForward ||
            b.type == BlockType.moveBackward ||
            b.type == BlockType.turnLeft ||
            b.type == BlockType.turnRight);
        bool hasWait = allBlocks.any((b) => b.type == BlockType.wait);
        return hasMovement && hasWait;

      case 3: // Sensor Integration
        bool hasSensor = allBlocks.any((b) => b.type == BlockType.ifDistance);
        return hasSensor;

      case 4: // Auto Mode
        bool hasAuto = allBlocks.any((b) => b.type == BlockType.autoNavigate);
        return hasAuto;

      case 5: // Advanced Navigation
        bool hasAdvanced =
            allBlocks.any((b) => b.type == BlockType.autoNavigate) &&
                allBlocks.any((b) => b.type == BlockType.ifDistance);
        return hasAdvanced;

      default:
        return false;
    }
  }

  void _showLevelCompletionMessage(int levelId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🎉 Congratulations!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Level $levelId completed! Next level unlocked!',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'NEXT LEVEL',
          textColor: Colors.white,
          onPressed: () {
            final appState = Provider.of<AppState>(context, listen: false);
            if (levelId < 5) {
              appState.setCurrentLevel(levelId + 1);
              // Also show a message about the new level
              Future.delayed(Duration(milliseconds: 500), () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Level ${levelId + 1} is now available!'),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 2),
                  ),
                );
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) => Column(
        children: [
          RepaintBoundary(
            child: _LevelCard(levelId: appState.currentLevel),
          ),
          Expanded(
            child: BlockEditorWidget(
              currentLevel: appState.currentLevel,
              onSave: (blocks) async {
                try {
                  // Check level completion using blocks directly (more reliable)
                  bool isCompleted = await _validateLevelCompletionByBlocks(
                      blocks, appState.currentLevel);

                  if (isCompleted &&
                      !appState.isLevelCompleted(appState.currentLevel)) {
                    await appState.completeLevel(appState.currentLevel);
                    _showLevelCompletionMessage(appState.currentLevel);
                  } else if (isCompleted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  'Level already completed! Great work! 🌟'),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    // Show what's needed for completion
                    String hint =
                        _getLevelCompletionHint(appState.currentLevel);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Progress saved! Hint: $hint',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Error saving program: $e',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              onRun: (blocks) async {
                try {
                  if (blocks.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.info, color: Colors.white),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  'Add some blocks to your workspace first!'),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    );
                    return;
                  }

                  if (!BlockEditorService.validateBlockSequence(blocks)) {
                    String errorMessage =
                        BlockEditorService.getValidationErrorMessage(blocks);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.help_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 4),
                      ),
                    );
                    return;
                  }

                  final code =
                      BlockEditorService.generateCodeFromBlocks(blocks);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RunScreen(generatedCode: code),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Error running program: ${e.toString()}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              onClear: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.delete_sweep, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(child: Text('Workspace cleared')),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Provide hints for level completion
  String _getLevelCompletionHint(int levelId) {
    switch (levelId) {
      case 1:
        return 'Add a movement block (Move Forward, Move Backward, Turn Left, or Turn Right)';
      case 2:
        return 'Use both movement blocks AND a Wait block';
      case 3:
        return 'Try using the "If Distance" block to react to obstacles';
      case 4:
        return 'Use the "Auto Navigate" block for advanced movement';
      case 5:
        return 'Combine "Auto Navigate" with sensor blocks for advanced autonomous behavior';
      default:
        return 'Keep experimenting with different blocks!';
    }
  }
}

class _LevelCard extends StatelessWidget {
  final int levelId;

  const _LevelCard({Key? key, required this.levelId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentLevel = LevelsService.getLevelById(levelId);
    return Card(
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.code,
                size: 30,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentLevel.name,
                    style: GoogleFonts.comicNeue(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    currentLevel.description,
                    style: GoogleFonts.comicNeue(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
