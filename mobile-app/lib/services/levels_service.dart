class Level {
  final int id;
  final String name;
  final String description;
  final String toolboxXml;
  final bool isLocked;
  final bool isCompleted;

  Level({
    required this.id,
    required this.name,
    required this.description,
    required this.toolboxXml,
    this.isLocked = true,
    this.isCompleted = false,
  });
}

class LevelsService {
  static final List<Level> levels = [
    Level(
      id: 1,
      name: 'Basic Movement',
      description:
          'Learn to move your robot forward, backward, left, and right!',
      isLocked: false,
      toolboxXml: '''
        <xml id="toolbox" style="display: none">
          <category name="Movement" colour="120">
            <block type="move_forward">
              <value name="DISTANCE">
                <shadow type="math_number">
                  <field name="NUM">100</field>
                </shadow>
              </value>
            </block>
            <block type="move_backward">
              <value name="DISTANCE">
                <shadow type="math_number">
                  <field name="NUM">100</field>
                </shadow>
              </value>
            </block>
            <block type="turn_left">
              <value name="ANGLE">
                <shadow type="math_number">
                  <field name="NUM">90</field>
                </shadow>
              </value>
            </block>
            <block type="turn_right">
              <value name="ANGLE">
                <shadow type="math_number">
                  <field name="NUM">90</field>
                </shadow>
              </value>
            </block>
            <block type="stop"></block>
          </category>
        </xml>
      ''',
    ),
    Level(
      id: 2,
      name: 'Path Planning',
      description: 'Create sequences of moves to reach your goal!',
      toolboxXml: '''
        <xml id="toolbox" style="display: none">
          <category name="Movement" colour="120">
            <block type="move_forward">
              <value name="DISTANCE">
                <shadow type="math_number">
                  <field name="NUM">100</field>
                </shadow>
              </value>
            </block>
            <block type="move_backward">
              <value name="DISTANCE">
                <shadow type="math_number">
                  <field name="NUM">100</field>
                </shadow>
              </value>
            </block>
            <block type="turn_left">
              <value name="ANGLE">
                <shadow type="math_number">
                  <field name="NUM">90</field>
                </shadow>
              </value>
            </block>
            <block type="turn_right">
              <value name="ANGLE">
                <shadow type="math_number">
                  <field name="NUM">90</field>
                </shadow>
              </value>
            </block>
            <block type="stop"></block>
          </category>
          <category name="Control" colour="160">
            <block type="controls_repeat_ext">
              <value name="TIMES">
                <shadow type="math_number">
                  <field name="NUM">10</field>
                </shadow>
              </value>
            </block>
            <block type="wait">
              <value name="TIME">
                <shadow type="math_number">
                  <field name="NUM">1000</field>
                </shadow>
              </value>
            </block>
          </category>
        </xml>
      ''',
    ),
    Level(
      id: 3,
      name: 'Sensor Integration',
      description: 'Use sensors to detect obstacles and react!',
      toolboxXml: '''
        <xml id="toolbox" style="display: none">
          <category name="Movement" colour="120">
            <block type="move_forward">
              <value name="DISTANCE">
                <shadow type="math_number">
                  <field name="NUM">100</field>
                </shadow>
              </value>
            </block>
            <block type="move_backward">
              <value name="DISTANCE">
                <shadow type="math_number">
                  <field name="NUM">100</field>
                </shadow>
              </value>
            </block>
            <block type="turn_left">
              <value name="ANGLE">
                <shadow type="math_number">
                  <field name="NUM">90</field>
                </shadow>
              </value>
            </block>
            <block type="turn_right">
              <value name="ANGLE">
                <shadow type="math_number">
                  <field name="NUM">90</field>
                </shadow>
              </value>
            </block>
            <block type="stop"></block>
          </category>
          <category name="Control" colour="160">
            <block type="controls_repeat_ext">
              <value name="TIMES">
                <shadow type="math_number">
                  <field name="NUM">10</field>
                </shadow>
              </value>
            </block>
            <block type="wait">
              <value name="TIME">
                <shadow type="math_number">
                  <field name="NUM">1000</field>
                </shadow>
              </value>
            </block>
          </category>
          <category name="Logic" colour="210">
            <block type="controls_if"></block>
            <block type="logic_compare"></block>
            <block type="math_number"></block>
          </category>
          <category name="Sensors" colour="45">
            <block type="check_distance"></block>
            <block type="if_distance_less">
              <value name="DISTANCE">
                <shadow type="math_number">
                  <field name="NUM">20</field>
                </shadow>
              </value>
            </block>
          </category>
        </xml>
      ''',
    ),
    Level(
      id: 4,
      name: 'Auto Mode',
      description: 'Make your robot navigate on its own!',
      toolboxXml: '''
        <xml id="toolbox" style="display: none">
          <category name="Movement" colour="120">
            <block type="move_forward">
              <value name="DISTANCE">
                <shadow type="math_number">
                  <field name="NUM">100</field>
                </shadow>
              </value>
            </block>
            <block type="move_backward">
              <value name="DISTANCE">
                <shadow type="math_number">
                  <field name="NUM">100</field>
                </shadow>
              </value>
            </block>
            <block type="turn_left">
              <value name="ANGLE">
                <shadow type="math_number">
                  <field name="NUM">90</field>
                </shadow>
              </value>
            </block>
            <block type="turn_right">
              <value name="ANGLE">
                <shadow type="math_number">
                  <field name="NUM">90</field>
                </shadow>
              </value>
            </block>
            <block type="stop"></block>
          </category>
          <category name="Control" colour="160">
            <block type="controls_repeat_ext">
              <value name="TIMES">
                <shadow type="math_number">
                  <field name="NUM">10</field>
                </shadow>
              </value>
            </block>
            <block type="wait">
              <value name="TIME">
                <shadow type="math_number">
                  <field name="NUM">1000</field>
                </shadow>
              </value>
            </block>
          </category>
          <category name="Logic" colour="210">
            <block type="controls_if"></block>
            <block type="logic_compare"></block>
            <block type="math_number"></block>
          </category>
          <category name="Sensors" colour="45">
            <block type="check_distance"></block>
            <block type="if_distance_less">
              <value name="DISTANCE">
                <shadow type="math_number">
                  <field name="NUM">20</field>
                </shadow>
              </value>
            </block>
          </category>
          <category name="Auto" colour="290">
            <block type="auto_navigate"></block>
            <block type="avoid_obstacles"></block>
            <block type="follow_path"></block>
          </category>
        </xml>
      ''',
    ),
    Level(
      id: 5,
      name: 'Advanced Navigation',
      description: 'Master complex autonomous robot behaviors!',
      toolboxXml: '''
        <xml id="toolbox" style="display: none">
          <category name="Movement" colour="120">
            <block type="move_forward">
              <value name="DISTANCE">
                <shadow type="math_number">
                  <field name="NUM">100</field>
                </shadow>
              </value>
            </block>
            <block type="move_backward">
              <value name="DISTANCE">
                <shadow type="math_number">
                  <field name="NUM">100</field>
                </shadow>
              </value>
            </block>
            <block type="turn_left">
              <value name="ANGLE">
                <shadow type="math_number">
                  <field name="NUM">90</field>
                </shadow>
              </value>
            </block>
            <block type="turn_right">
              <value name="ANGLE">
                <shadow type="math_number">
                  <field name="NUM">90</field>
                </shadow>
              </value>
            </block>
            <block type="stop"></block>
          </category>
          <category name="Control" colour="160">
            <block type="controls_repeat_ext">
              <value name="TIMES">
                <shadow type="math_number">
                  <field name="NUM">10</field>
                </shadow>
              </value>
            </block>
            <block type="wait">
              <value name="TIME">
                <shadow type="math_number">
                  <field name="NUM">1000</field>
                </shadow>
              </value>
            </block>
            <block type="controls_whileUntil">
              <field name="MODE">WHILE</field>
            </block>
          </category>
          <category name="Logic" colour="210">
            <block type="controls_if"></block>
            <block type="logic_compare"></block>
            <block type="logic_operation"></block>
            <block type="logic_negate"></block>
            <block type="math_number"></block>
          </category>
          <category name="Sensors" colour="45">
            <block type="check_distance"></block>
            <block type="if_distance_less">
              <value name="DISTANCE">
                <shadow type="math_number">
                  <field name="NUM">20</field>
                </shadow>
              </value>
            </block>
            <block type="check_battery"></block>
            <block type="get_compass"></block>
          </category>
          <category name="Auto" colour="290">
            <block type="auto_navigate"></block>
            <block type="avoid_obstacles"></block>
            <block type="follow_path"></block>
            <block type="patrol_area"></block>
            <block type="return_home"></block>
          </category>
          <category name="Advanced" colour="330">
            <block type="map_environment"></block>
            <block type="learn_behavior"></block>
            <block type="collaborative_task"></block>
          </category>
        </xml>
      ''',
    ),
  ];

  static Level getCurrentLevel() {
    // In a real app, this would be stored in SharedPreferences
    return levels[0];
  }

  static String getToolboxXml(int levelId) {
    try {
      return levels.firstWhere((level) => level.id == levelId).toolboxXml;
    } catch (e) {
      print("Error: Level $levelId not found, returning default toolbox XML.");
      return levels[0].toolboxXml;
    }
  }

  static Level getLevelById(int levelId) {
    try {
      return levels.firstWhere((level) => level.id == levelId);
    } catch (e) {
      print("Error: Level $levelId not found, returning level 1.");
      return levels[0];
    }
  }
}
