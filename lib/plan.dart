import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import './tools.dart';
import './gases.dart';
import './buhlmann.dart';
import './waypoints.dart';
import './main.dart';

class DecompressionPlanTable {
  late String icon;
  late String depth;
  late String duration;
  late String runtime;
  late String gas;

  DecompressionPlanTable(this.icon, this.depth, this.duration, this.runtime, this.gas);
}

class DecompressionPlanGraph {
  late double depth;
  late double runtime;

  DecompressionPlanGraph(this.depth, this.runtime);
}

class DecompressionPlan {
  List<DecompressionPlanTable> decoPlanTable;
  List<DecompressionPlanGraph> decoPlanGraph;

  DecompressionPlan(this.decoPlanTable, this.decoPlanGraph);

  copy(var newDecompressionPlan) {
    decoPlanTable = newDecompressionPlan.decoPlanTable;
    decoPlanGraph = newDecompressionPlan.decoPlanGraph;
  }
}

DecompressionPlan calculatePlan(List<Gas> gases, List<Waypoint> waypoints) {
  Buhlmann decoState = Buhlmann();
  DecompressionPlan plan = DecompressionPlan([], []);
  List<GasMix> gasMixes = [];
  List<DecoWaypoint> decoWaypoints = [];

  for (var gas in gases) {
    gasMixes.add(gasMixFromGas(gas));
  }

  for (var waypoint in waypoints) {
    decoWaypoints.add(decoWaypointFromWaypoint(waypoint));
  }

  if (gasMixes.isEmpty || decoWaypoints.isEmpty) {
    // Add more error stuff
    // return plan;
    return plan;
  }

  double runtime = 0;
  GasMix bestMix = gasMixes[0];
  double currentPressure = 1.0;

  // currently does not take into account travel time between waypoints
  for (var waypoint in decoWaypoints) {
    double timeDescending = (currentPressure - waypoint.pressure).abs() / 1.0;
    decoState.schreinerAscentDescent(bestMix, 1.0, timeDescending, currentPressure);

    plan.decoPlanGraph.add(DecompressionPlanGraph(pressureToDisplay(currentPressure).toDouble(), runtime));
    runtime = runtime + timeDescending;
    plan.decoPlanTable.add(DecompressionPlanTable('↘️ ', '${pressureToDisplay(currentPressure)} → ${pressureToDisplay(waypoint.pressure)}',
      '${timeToDisplay(timeDescending)}', '${timeToDisplay(runtime)}',
      '${percentageToDisplay(bestMix.oxygen)}/${percentageToDisplay(bestMix.helium)} '));
    plan.decoPlanGraph.add(DecompressionPlanGraph(pressureToDisplay(waypoint.pressure).toDouble(), runtime));

    currentPressure = waypoint.pressure;
    bestMix = getBestMix(gasMixes, currentPressure);
    decoState.instantSchreiner(bestMix, waypoint.time, currentPressure);
    runtime = runtime + waypoint.time;
    
    plan.decoPlanTable.add(DecompressionPlanTable('➡️ ', '${pressureToDisplay(currentPressure)}',
      '${timeToDisplay(waypoint.time)}', '${timeToDisplay(runtime)}',
      '${percentageToDisplay(bestMix.oxygen)}/${percentageToDisplay(bestMix.helium)} '));
    plan.decoPlanGraph.add(DecompressionPlanGraph(pressureToDisplay(currentPressure).toDouble(), runtime));
  }

  while (decoState.calculateCeiling() > surfacePressure + 0.1) {
    // Ascent Portion
    double ceiling = decoState.calculateCeiling();
    double roundedCeiling = ceiling - ((ceiling - 1) % 0.3) + 0.3;
    double timeAscending = (currentPressure - ceiling) / 1.0;
    decoState.schreinerAscentDescent(bestMix, 1.0, timeAscending, currentPressure);

    plan.decoPlanGraph.add(DecompressionPlanGraph(pressureToDisplay(currentPressure).toDouble(), runtime));
    runtime = runtime + timeAscending;
    plan.decoPlanTable.add(DecompressionPlanTable('↗️ ', '${pressureToDisplay(currentPressure)} → ${pressureToDisplay(roundedCeiling)}',
      '${timeToDisplay(timeAscending)}', '${timeToDisplay(runtime)}',
      '${percentageToDisplay(bestMix.oxygen)}/${percentageToDisplay(bestMix.helium)} '));
    currentPressure = roundedCeiling;
    plan.decoPlanGraph.add(DecompressionPlanGraph(pressureToDisplay(currentPressure).toDouble(), runtime));

    // Stop Portion
    bestMix = getBestMix(gasMixes, currentPressure);
    double stopDuration = decoState.stopTime(bestMix, currentPressure, currentPressure - 0.31);
    decoState.instantSchreiner(bestMix, stopDuration, currentPressure);
    runtime = runtime + stopDuration;

    plan.decoPlanTable.add(DecompressionPlanTable('🛑 ', '${pressureToDisplay(currentPressure)}',
    '${timeToDisplay(stopDuration)}', '${timeToDisplay(runtime)}',
    '${percentageToDisplay(bestMix.oxygen)}/${percentageToDisplay(bestMix.helium)} '));
    plan.decoPlanGraph.add(DecompressionPlanGraph(pressureToDisplay(currentPressure).toDouble(), runtime));
  }

  return plan;
}

// ➡️🔄↗️↘️🛑

// Keep way to handle to currentDepth -> targetDepth display

class PlanTable extends StatelessWidget {
  const PlanTable({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SelectionArea(
        child: Table (
          columnWidths: {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(8),
            2: FlexColumnWidth(8),
            3: FlexColumnWidth(8),
            4: FlexColumnWidth(8),
            5: FlexColumnWidth(1),
          },
          border: const TableBorder(horizontalInside: BorderSide(width: 0.1)),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            const TableRow (
              decoration: BoxDecoration(
                color: Colors.blueAccent,
              ),
              children: [
                TableCell(child: Padding(padding: EdgeInsets.all(9.0), child: Text('', textAlign: TextAlign.center))),
                TableCell(child: Padding(padding: EdgeInsets.all(9.0), child: Text('Depth ', textAlign: TextAlign.center))),
                TableCell(child: Padding(padding: EdgeInsets.all(9.0), child: Text('Duration ', textAlign: TextAlign.center))),
                TableCell(child: Padding(padding: EdgeInsets.all(9.0), child: Text('Runtime ', textAlign: TextAlign.center))),
                TableCell(child: Padding(padding: EdgeInsets.all(9.0), child: Text('Gas ', textAlign: TextAlign.center))),
                TableCell(child: Padding(padding: EdgeInsets.all(9.0), child: Text('', textAlign: TextAlign.center))),
              ]
            ),
            ...AppData.of(context).plan.decoPlanTable.map((step) {
              return TableRow(
                children: [
                  TableCell(child: Container(padding: const EdgeInsets.all(7.0), child: Text(step.icon, textAlign: TextAlign.center))),
                  TableCell(child: Container(color: Colors.white24, padding: const EdgeInsets.all(7.0),  child: Text(step.depth, textAlign: TextAlign.center))),
                  TableCell(child: Container(padding: const EdgeInsets.all(7.0), child: Text(step.duration, textAlign: TextAlign.center))),
                  TableCell(child: Container(color: Colors.white24, padding: const EdgeInsets.all(7.0),  child: Text(step.runtime, textAlign: TextAlign.center))),
                  TableCell(child: Container(padding: const EdgeInsets.all(7.0), child: Text(step.gas, textAlign: TextAlign.center))),
                  TableCell(child: Container(padding: const EdgeInsets.all(7.0), child: Text('', textAlign: TextAlign.center))),
                ],
              );
            })
          ]
        )
      )
    );
  }
}

class PlanChart extends StatelessWidget{
  const PlanChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue[200],
      child: LineChart(
        LineChartData(
          minY: [...AppData.of(context).plan.decoPlanGraph.map((i) {return i.depth;}), 0].reduce(max).toDouble(),
          maxY: 0,
          lineBarsData: [
            LineChartBarData(
              color: Colors.white,
              spots: [
                ...AppData.of(context).plan.decoPlanGraph.map((step) {
                  return FlSpot(step.runtime, step.depth);
                })
              ],
              dotData: FlDotData(
                show: false
              ),
            )
          ],
        ),
      )
    );
  }
}