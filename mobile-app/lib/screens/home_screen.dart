import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(
                      'https://images.pexels.com/photos/2085831/pexels-photo-2085831.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.purple.withOpacity(0.7),
                    BlendMode.overlay,
                  ),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.purple[300]!.withOpacity(0.9),
                    Colors.purple[400]!.withOpacity(0.9)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.waving_hand_rounded,
                        color: Colors.yellow,
                        size: 32,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Hi there!',
                        style: GoogleFonts.comicNeue(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ready to program your robot?',
                    style: GoogleFonts.comicNeue(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Level Progress
          Text(
            'Your Progress',
            style: GoogleFonts.comicNeue(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo[900],
            ),
          ),
          SizedBox(height: 16),
          _buildLevelCard(
            level: 1,
            title: 'Basic Movement',
            description:
                'Learn to move your robot forward, backward, left, and right!',
            isCompleted: appState.isLevelCompleted(1),
            isActive: appState.currentLevel == 1,
            isLocked: !appState.isLevelUnlocked(1),
            icon: Icons.directions_walk_rounded,
            color: Colors.green,
            onTap: () {
              if (appState.isLevelUnlocked(1)) {
                appState.setCurrentLevel(1);
                final parentState =
                    context.findAncestorStateOfType<RoboCodeHomePageState>();
                if (parentState != null) {
                  parentState.onItemTapped(2); // Index of Code tab
                } else {
                  debugPrint(
                      "Error: RoboCodeHomePageState not found. Navigation aborted.");
                }
              }
            },
          ),
          _buildLevelCard(
            level: 2,
            title: 'Path Planning',
            description: 'Create sequences of moves to reach your goal!',
            isCompleted: appState.isLevelCompleted(2),
            isActive: appState.currentLevel == 2,
            isLocked: !appState.isLevelUnlocked(2),
            icon: Icons.route_rounded,
            color: Colors.blue,
            onTap: () {
              if (appState.isLevelUnlocked(2)) {
                appState.setCurrentLevel(2);
                int codeTabIndex = 2;
                (context.findAncestorStateOfType<RoboCodeHomePageState>())
                    ?.onItemTapped(codeTabIndex);
              }
            },
          ),
          _buildLevelCard(
            level: 3,
            title: 'Sensor Magic',
            description: 'Use sensors to detect obstacles and react!',
            isCompleted: appState.isLevelCompleted(3),
            isActive: appState.currentLevel == 3,
            isLocked: !appState.isLevelUnlocked(3),
            icon: Icons.sensors_rounded,
            color: Colors.orange,
            onTap: () {
              if (appState.isLevelUnlocked(3)) {
                appState.setCurrentLevel(3);
                int codeTabIndex = 2;
                (context.findAncestorStateOfType<RoboCodeHomePageState>())
                    ?.onItemTapped(codeTabIndex);
              }
            },
          ),
          _buildLevelCard(
            level: 4,
            title: 'Auto Mode',
            description: 'Make your robot navigate on its own!',
            isCompleted: appState.isLevelCompleted(4),
            isActive: appState.currentLevel == 4,
            isLocked: !appState.isLevelUnlocked(4),
            icon: Icons.auto_awesome_rounded,
            color: Colors.purple,
            onTap: () {
              if (appState.isLevelUnlocked(4)) {
                appState.setCurrentLevel(4);
                int codeTabIndex = 2;
                (context.findAncestorStateOfType<RoboCodeHomePageState>())
                    ?.onItemTapped(codeTabIndex);
              }
            },
          ),
          _buildLevelCard(
            level: 5,
            title: 'Advanced Navigation',
            description: 'Master complex autonomous robot behaviors!',
            isCompleted: appState.isLevelCompleted(5),
            isActive: appState.currentLevel == 5,
            isLocked: !appState.isLevelUnlocked(5),
            icon: Icons.psychology_rounded,
            color: Colors.deepPurple,
            onTap: () {
              if (appState.isLevelUnlocked(5)) {
                appState.setCurrentLevel(5);
                int codeTabIndex = 2;
                (context.findAncestorStateOfType<RoboCodeHomePageState>())
                    ?.onItemTapped(codeTabIndex);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard({
    required int level,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    bool isCompleted = false,
    bool isActive = false,
    bool isLocked = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Card(
          elevation: isActive ? 12 : 8,
          shadowColor:
              isLocked ? Colors.grey.withOpacity(0.3) : color.withOpacity(0.3),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isLocked
                  ? LinearGradient(
                      colors: [Colors.grey[100]!, Colors.grey[200]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color:
                        isLocked ? Colors.grey[300] : color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isLocked
                        ? []
                        : [
                            BoxShadow(
                              color: color.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Icon(
                      isLocked ? Icons.lock_rounded : icon,
                      size: 36,
                      color: isLocked ? Colors.grey : color,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Level $level: $title',
                            style: GoogleFonts.comicNeue(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  isLocked ? Colors.grey : Colors.indigo[900],
                              height: 1.2,
                            ),
                          ),
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Completed',
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: GoogleFonts.comicNeue(
                          fontSize: 15,
                          color: isLocked ? Colors.grey : Colors.indigo[700],
                          height: 1.3,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 16),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          child: ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 4,
                              shadowColor: color.withOpacity(0.4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Start Level',
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.play_arrow_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
