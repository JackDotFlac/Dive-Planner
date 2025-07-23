import 'package:flutter/material.dart';
import './gases.dart';
import './waypoints.dart';
import './plan.dart';

void main() {
  final List<Waypoint> waypoints = [];
  final List<Gas> gases = [];
  final DecompressionPlan plan = DecompressionPlan([], []);

  runApp(
    AppData(
      waypoints: waypoints,
      gases: gases,
      plan: plan,
      child: const MainApp()
    )
  );
}

class AppData extends InheritedWidget {
  final List<Waypoint> waypoints;
  final List<Gas> gases;
  final DecompressionPlan plan;

  const AppData({
    super.key,
    required this.waypoints,
    required this.gases,
    required this.plan,
    required super.child,
  });

  static AppData of(BuildContext context) {
    final AppData? result = context.dependOnInheritedWidgetOfExactType<AppData>();
    assert(result != null, 'No AppData found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppData old) {
    return waypoints != old.waypoints || gases != old.gases;
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: Scaffold(
        body: MainWindowDesktop(),
      ),
      title: 'Dive Planner',
    );
  }
}

class MainWindowDesktop extends StatefulWidget {
  const MainWindowDesktop({super.key});

  @override
  State<MainWindowDesktop> createState() => _MainWindowDesktopState();
}

class _MainWindowDesktopState extends State<MainWindowDesktop> {
  void _calculatePlan() {
    setState(() {
      AppData.of(context).plan.copy(calculatePlan(
        AppData.of(context).gases,
        AppData.of(context).waypoints,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Expanded(
                flex: 10,
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  color: Colors.blue[900],
                  child: Theme(
                    data: ThemeData.dark(),
                    child: GasManager(),
                  ),
                )
              ),
              Expanded(
                flex: 10,
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  color: Colors.blue[800],
                  child: Theme(
                    data: ThemeData.dark(),
                    child: WaypointManager(),
                  ),
                )
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.all(0.0),
                  color: Colors.blue[900],
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: EdgeInsets.all(0.0),
                          color: Colors.blue[900],
                          child: Theme(
                            data: ThemeData.dark(),
                            child: Expanded(
                              child: TextButton(
                                onPressed: _calculatePlan, 
                                child: const Text('Calculate'),
                              ),
                            ),
                          )
                        ),
                      ),
                    ]
                  )
                )
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(flex: 1, child: PlanChart()),
              Expanded(flex: 1, child: PlanTable()),
            ],
          ),
        ),
      ],
    );
  }
}