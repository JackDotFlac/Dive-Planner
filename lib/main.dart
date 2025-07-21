import 'package:flutter/material.dart';
import './gases.dart';
import './waypoints.dart';
import './buhlmann.dart';

void main() {
  final List<Waypoint> waypoints = [];
  final List<Gas> gases = [];
  final Buhlmann decompressionState = Buhlmann();

  runApp(
    AppData(
      waypoints: waypoints,
      gases: gases,
      decompressionState: decompressionState,
      child: const MainApp()
    )
  );
}

class AppData extends InheritedWidget {
  final List<Waypoint> waypoints;
  final List<Gas> gases;
  final Buhlmann decompressionState;

  const AppData({
    super.key,
    required this.waypoints,
    required this.gases,
    required this.decompressionState,
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
      AppData.of(context).decompressionState.calculatePlan(
        AppData.of(context).gases,
        AppData.of(context).waypoints,
      );
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
                child: TextButton(
                  onPressed: _calculatePlan, 
                  child: const Text('Calculate')
                )
              )
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: PlanItem(),
        ),
      ],
    );
  }
}

class PlanItem extends StatelessWidget {
  const PlanItem({super.key});

  @override
  Widget build(BuildContext context) {
    final planData = AppData.of(context).decompressionState.plan;

    return SelectionArea(
      child: Table (
        border: const TableBorder(horizontalInside: BorderSide(width: 0.1)),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          const TableRow (
            decoration: BoxDecoration(
              color: Colors.blueAccent,
            ),
            children: [
              TableCell(child: Padding(padding: EdgeInsets.all(9.0), child: Text(''))),
              TableCell(child: Padding(padding: EdgeInsets.all(9.0), child: Text('Depth'))),
              TableCell(child: Padding(padding: EdgeInsets.all(9.0), child: Text('Duration'))),
              TableCell(child: Padding(padding: EdgeInsets.all(9.0), child: Text('Runtime'))),
              TableCell(child: Padding(padding: EdgeInsets.all(9.0), child: Text('Gas'))),
              TableCell(child: Padding(padding: EdgeInsets.all(9.0), child: Text('Info'))),
            ]
          ),
          ...planData.map((step) {
            return TableRow(
              children: [
                TableCell(child: Padding(padding: const EdgeInsets.all(7.0), child: Text(step.icon, textAlign: TextAlign.center,))),
                TableCell(child: Padding(padding: const EdgeInsets.all(7.0), child: Text(step.depth))),
                TableCell(child: Padding(padding: const EdgeInsets.all(7.0), child: Text(step.duration))),
                TableCell(child: Padding(padding: const EdgeInsets.all(7.0), child: Text(step.runtime))),
                TableCell(child: Padding(padding: const EdgeInsets.all(7.0), child: Text(step.gas))),
                TableCell(child: Padding(padding: const EdgeInsets.all(7.0), child: Text(step.info))),
              ],
            );
          })
        ]
      )
    );
  }
}