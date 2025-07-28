import 'package:flutter/material.dart';
import 'main.dart';

class Gas {
  final Key key;
  final TextEditingController oxygenController = TextEditingController(text: '21');
  final TextEditingController heliumController = TextEditingController(text: '0');

  Gas() : key = UniqueKey();
}

class GasManager extends StatefulWidget {
  const GasManager({super.key});

  @override
  State<GasManager> createState() => _GasManager();
}

class _GasManager extends State<GasManager> {
  List<Gas> _gases = [];

  void _addGas() {
    setState(() {
      _gases.add(Gas());
    });
  }

  void _removeGas(Key key) {
    setState(() {
      final gasToRemove = _gases.firstWhere((item) => item.key == key);
      gasToRemove.oxygenController.dispose();
      gasToRemove.heliumController.dispose();
      _gases.removeWhere((item) => item.key == key);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _gases = AppData.of(context).gases;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('Gases', style: TextStyle(fontSize: 24, color: Colors.white)),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: _gases.length,
          itemBuilder: (context, index) {
            final gas = _gases[index];
            return GasItem(
              key: gas.key,
              gas: gas,
              onRemove: () => _removeGas(gas.key),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: OutlinedButton(onPressed: _addGas, child: Text('+ Add Gas')),
      )
    ]);
  }
}

class GasItem extends StatelessWidget {
  final Gas gas;
  final VoidCallback onRemove;

  const GasItem({
    super.key,
    required this.gas,
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
                controller: gas.oxygenController,
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Oxygen')),
          ),
          // Add some spacing between the text fields
          SizedBox(width: 8),
          Expanded(
            child: TextField(
                controller: gas.heliumController,
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Helium')),
          ),
          IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete),
              tooltip: 'Remove Gas')
        ],
      ),
    );
  }
}