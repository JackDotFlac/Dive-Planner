import 'package:flutter/material.dart';
import 'main.dart';

class Waypoint {
  final Key key;
  final TextEditingController depthController = TextEditingController(text: '0');
  final TextEditingController timeController = TextEditingController(text: '0');

  Waypoint({
      Key? key,
      depthController = '0.0',
      timeController = '0.0',
  }) :
    key = key ?? UniqueKey();

  void dispose() {
    depthController.dispose();
    timeController.dispose();
  }
}

class WaypointManager extends StatefulWidget {
  const WaypointManager({super.key});

  @override
  State<WaypointManager> createState() => _WaypointManager();
}

class _WaypointManager extends State<WaypointManager> {
  List<Waypoint> _waypoints = [];

  void _addWaypoint() {
    setState(() {
      _waypoints.add(Waypoint());
    });
  }

  void _removeWaypoint(Key key) {
    setState(() {
      final waypointToRemove = _waypoints.firstWhere((item) => item.key == key);
      waypointToRemove.depthController.dispose();
      waypointToRemove.timeController.dispose();
      _waypoints.removeWhere((item) => item.key == key);
      
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _waypoints = AppData.of(context).waypoints;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('Waypoints', style: TextStyle(fontSize: 24, color: Colors.white)),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: _waypoints.length,
          itemBuilder: (context, index) {
            final waypoint = _waypoints[index];
            return WaypointItem(
              key: waypoint.key,
              waypoint: waypoint,
              onRemove: () => _removeWaypoint(waypoint.key),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: OutlinedButton(onPressed: _addWaypoint, child: Text('+ Add Waypoint')),
      )
    ]);
  }
}

class WaypointItem extends StatelessWidget {
  final Waypoint waypoint;
  final VoidCallback onRemove;

  const WaypointItem({
    super.key,
    required this.waypoint,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: waypoint.depthController,
              decoration: InputDecoration(
                  border: OutlineInputBorder(), labelText: 'Depth')),
          ),
          // Add some spacing between the text fields
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: waypoint.timeController,
              decoration: InputDecoration(
                  border: OutlineInputBorder(), labelText: 'Time')),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete),
            tooltip: 'Remove Waypoint'
          )
        ],
      ),
    );
  }
}
