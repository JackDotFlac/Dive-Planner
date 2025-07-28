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

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainApp();
}

class _MainApp extends State<MainApp> {
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
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: Scaffold(
        body: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return MainWindowDesktop(calculatePlan: _calculatePlan);
            } else {
             //  return const MainWindowMobile();
             return MainWindowMobile(calculatePlan: _calculatePlan);
            }
          }
        ),
      ),
      title: 'Dive Planner',
    );
  }
}

class MainWindowMobile extends StatefulWidget {
  final VoidCallback calculatePlan;

  const MainWindowMobile({
    super.key,
    required this.calculatePlan,
  });

  @override
  State<MainWindowMobile> createState() => _MainWindowMobile();
}

class _MainWindowMobile extends State<MainWindowMobile> {
  int currentPageIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
          widget.calculatePlan();
        },
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.air),
            label: 'Gases',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on),
            label: 'Waypoints',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            label: 'Result',
          ),
        ],
      ),
      body: <Widget>[
        FormattedGasManager(),
        FormattedWaypointManager(),
        Column(
          children: [
            Expanded(
              flex: 2,
              child: PlanChart(),
            ),
            Expanded(
              flex: 3,
              child: PlanTable(),
            ),
          ],
        )
      ].elementAt(currentPageIndex),
    );
  }
}

class MainWindowDesktop extends StatelessWidget {
  final VoidCallback calculatePlan;

  const MainWindowDesktop({
    super.key,
    required this.calculatePlan,
  });

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
                child: FormattedGasManager(),
              ),
              Expanded(
                flex: 10,
                child: FormattedWaypointManager(),
              ),
              Expanded(
                flex: 1,
                child: FormattedCalculateButton(calculatePlan: calculatePlan),
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

class FormattedCalculateButton extends StatelessWidget {
  final VoidCallback calculatePlan;

  const FormattedCalculateButton({
    super.key,
    required this.calculatePlan,
  });

  @override build(BuildContext context) {
    return Container(
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
                    onPressed: calculatePlan, 
                    child: const Text('Calculate'),
                  ),
                ),
              )
            ),
          ),
        ]
      )
    );
  }
}

class FormattedWaypointManager extends StatelessWidget {
  const FormattedWaypointManager({super.key});

  @override 
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      color: Colors.blue[800],
      child: Theme(
        data: ThemeData.dark(),
        child: WaypointManager(),
      ),
    );
  }
}

class FormattedGasManager extends StatelessWidget {
  const FormattedGasManager({super.key});

  @override 
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      color: Colors.blue[900],
      child: Theme(
        data: ThemeData.dark(),
        child: GasManager(),
      ),
    );
  }
}