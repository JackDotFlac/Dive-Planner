import 'dart:math';
import 'gases.dart';
import 'waypoints.dart';

class DecompressionPlan {
  late String icon;
  late String depth;
  late String duration;
  late String runtime;
  late String gas;
  late String info;

  DecompressionPlan(this.icon, this.depth, this.duration, this.runtime, this.gas, this.info);
}

class GasMix {
  double oxygen;
  double helium;
  double nitrogen;

  GasMix(this.oxygen, this.helium, this.nitrogen);
}

GasMix gasMixFromGas(Gas gas) {
  double oxygen = double.parse(gas.oxygenController.text) / 100;
  double helium = double.parse(gas.heliumController.text) / 100;
  double nitrogen = 1 - oxygen - helium;

  return GasMix(oxygen, helium, nitrogen);
}

class DecoWaypoint{
  double time;
  double pressure;

  DecoWaypoint(this.time, this.pressure);
}

DecoWaypoint decoWaypointFromWaypoint(Waypoint waypoint) {
  double time = double.parse(waypoint.timeController.text);
  double pressure = (double.parse(waypoint.depthController.text) + 10) / 10;

  return DecoWaypoint(time, pressure);
}

class TissueCompartments {
  double helium;
  double nitrogen;

  TissueCompartments(this.helium, this.nitrogen);
}

class CompartmentGasParameters {
  double halfTime;
  double aValue;
  double bValue;

  CompartmentGasParameters(this.halfTime, this.aValue, this.bValue);
}

class CompartmentParameters {
  late CompartmentGasParameters nitrogen;
  late CompartmentGasParameters helium;

  CompartmentParameters(nitrogenHalfTime, nitrogenAValue, nitrogenBValue, heliumHalfTime, heliumAValue, heliumBValue) {
    nitrogen = CompartmentGasParameters(nitrogenHalfTime, nitrogenAValue, nitrogenBValue);
    helium = CompartmentGasParameters(heliumHalfTime, heliumAValue, heliumBValue);
  }
}

class Buhlmann {
  List<DecompressionPlan> plan = [];
  // Placeholder
  List<double> nitrogenHalfTime = [5.0000, 8.0000, 12.500, 18.500, 27.000, 38.300, 54.300, 77.000, 109.00, 146.00, 187.00, 239.00, 305.00, 390.00, 498.00, 635.00];
  List<double> nitrogenAValue = [1.1696, 1.0000, 0.8618, 0.7562, 0.6200, 0.5043, 0.4410, 0.4000, 0.3750, 0.3500, 0.3295, 0.3065, 0.2835, 0.2610, 0.2480, 0.2327];
  List<double> nitrogenBValue = [0.5578, 0.6514, 0.7222, 0.7825, 0.8126, 0.8434, 0.8693, 0.8910, 0.9092, 0.9222, 0.9319, 0.9403, 0.9477, 0.9544, 0.9602, 0.9653];
  List<double> halfTime = [1.8800, 3.0200, 4.7200, 6.9900, 10.210, 14.480, 20.530, 29.110, 41.200, 55.190, 70.690, 90.340, 115.20, 147.42, 188.24, 240.03];
  List<double> heliumAValue = [1.6189, 1.3830, 1.1919, 1.0458, 0.9220, 0.8205, 0.7305, 0.6502, 0.5950, 0.5545, 0.5333, 0.5189, 0.5181, 0.5176, 0.5172, 0.5119];
  List<double> heliumBValue = [0.4770, 0.5747, 0.6527, 0.7223, 0.7582, 0.7957, 0.8279, 0.8553, 0.8757, 0.8903, 0.8997, 0.9073, 0.9122, 0.9171, 0.9217, 0.9267];
  List<CompartmentParameters> compartmentParameters = [];
  List<TissueCompartments> tissueCompartments = [];

  // Placeholder variables, these should go info their own settings class ASAP
  static const waterVapourPressure = 0.0627;
  static const log2 = 0.69314718056;
  static const surfacePressure = 1.0;

  Buhlmann() {
    for (var i = 0; i < 16; i++) {
      compartmentParameters.add(
        CompartmentParameters(
          nitrogenHalfTime[i], nitrogenAValue[i], nitrogenBValue[i], halfTime[i], heliumAValue[i], heliumBValue[i]
        )
      );
    }
    for (var i = 0; i < 16; i++) {
      tissueCompartments.add(
        // Also a placeholder, impliment a way to load tissue... loading...
        TissueCompartments(0.0, 0.79)
      );
    }
  }

  instantSchreiner(GasMix gas, double deltaTime, double ambientPressure) {
    for (var i = 0; i < 16; i++) {
      double nitrogenPressure = (ambientPressure - waterVapourPressure) * gas.nitrogen;
      tissueCompartments[i].nitrogen = tissueCompartments[i].nitrogen + ((nitrogenPressure - tissueCompartments[i].nitrogen) * (1 - pow(2, (-deltaTime / compartmentParameters[i].nitrogen.halfTime))));
      double heliumPressure = (ambientPressure - waterVapourPressure) * gas.helium;
      tissueCompartments[i].helium = tissueCompartments[i].helium + ((heliumPressure - tissueCompartments[i].helium) * (1 - pow(2, (-deltaTime / compartmentParameters[i].helium.halfTime))));
    }
  }

  schreinerAscentDescent(GasMix gas, double ascentRate, double deltaTime, double ambientPressure) {
    for (var i = 0; i < 16; i++) {
        // nitrogen
        double nitrogenPressure = (ambientPressure - waterVapourPressure) * gas.nitrogen;
        double nitrogenR = gas.nitrogen * -1 * ascentRate;
        double nitrogenk = log2 / compartmentParameters[i].nitrogen.halfTime;
        tissueCompartments[i].nitrogen = nitrogenPressure + (nitrogenR * (deltaTime - (1.0 / nitrogenk))) - ((nitrogenPressure - tissueCompartments[i].nitrogen - (nitrogenR / nitrogenk)) * exp(-nitrogenk * deltaTime));
        // helium
        double heliumPressure = (ambientPressure - waterVapourPressure) * gas.helium;
        double heliumR = gas.helium * -1 * ascentRate;
        double heliumk = log2 / compartmentParameters[i].helium.halfTime;
        tissueCompartments[i].helium = heliumPressure + (heliumR * (deltaTime - (1.0 / heliumk))) - ((heliumPressure - tissueCompartments[i].helium - (heliumR / heliumk)) * exp(-heliumk * deltaTime));
    }
  }

  double stopTime(GasMix gas, double ambientPressure, double targetPressure) {
    double time = 0.0;
    for (var i = 0; i < 16; i++) {
        // nitrogen
        double nitrogenPressure = (ambientPressure - waterVapourPressure) * gas.nitrogen;
        double mValueN2 = compartmentParameters[i].nitrogen.aValue + (targetPressure / compartmentParameters[i].nitrogen.bValue);
        if (nitrogenPressure < mValueN2 && mValueN2 < tissueCompartments[i].nitrogen) {
            double k = log2 / compartmentParameters[i].nitrogen.halfTime;
            double stopTimeN2 = (-1.0 / k) * log((nitrogenPressure - mValueN2) / (nitrogenPressure - tissueCompartments[i].nitrogen));
            if (stopTimeN2 > time) {
                time = stopTimeN2;
            }
        }
        // helium
        double heliumPressure = (ambientPressure - waterVapourPressure) * gas.helium;
        double mValueHE = compartmentParameters[i].helium.aValue + (targetPressure / compartmentParameters[i].helium.bValue);
        if (heliumPressure < mValueHE && mValueHE < tissueCompartments[i].helium) {
            double k = log2 / compartmentParameters[i].helium.halfTime;
            double stopTimeHE = (-1.0 / k) * log((heliumPressure - mValueHE) / (heliumPressure - tissueCompartments[i].helium));
            if (stopTimeHE > time) {
                time = stopTimeHE;
            }
        }
    }
    return time;
  }

  double noDecompressionLimit(GasMix gas, double ambientPressure) {
    double time = 999.0; // If NDL is higher than this, it's not worth knowing
    for (var i = 0; i < 16; i++) {
        // nitrogen
        double nitrogenPressure = (ambientPressure - waterVapourPressure) * gas.nitrogen;
        double mValue0N2 = compartmentParameters[i].nitrogen.aValue + (surfacePressure / compartmentParameters[i].nitrogen.bValue);
        if (nitrogenPressure > mValue0N2 && mValue0N2 > tissueCompartments[i].nitrogen) {
            double k = log2 / compartmentParameters[i].nitrogen.halfTime;
            double noDecompressionLimitTime = (-1.0 / k) * log((nitrogenPressure - mValue0N2) / (nitrogenPressure - tissueCompartments[i].nitrogen));
            if (noDecompressionLimitTime < time) {
                time = noDecompressionLimitTime;
            }
        }
        // helium
        double heliumPressure = (ambientPressure - waterVapourPressure) * gas.helium;
        double mValue0HE = compartmentParameters[i].helium.aValue + (surfacePressure / compartmentParameters[i].helium.bValue);
        if (heliumPressure > mValue0HE && mValue0HE > tissueCompartments[i].helium) {
            double k = log2 / compartmentParameters[i].helium.halfTime;
            double noDecoLimit = (-1.0 / k) * log((heliumPressure - mValue0HE) / (heliumPressure - tissueCompartments[i].helium));
            if (noDecoLimit < time) {
                time = noDecoLimit;
            }
        }
    }
    return time;
  }

  double calculateCeiling() {
      double maxCeiling = 0.0;
      for (var i = 0; i < 16; i++) {
          double A = ((compartmentParameters[i].nitrogen.aValue * tissueCompartments[i].nitrogen) + (compartmentParameters[i].helium.aValue * tissueCompartments[i].helium)) / (tissueCompartments[i].nitrogen + tissueCompartments[i].helium);
          double B = ((compartmentParameters[i].nitrogen.bValue * tissueCompartments[i].nitrogen) + (compartmentParameters[i].helium.bValue * tissueCompartments[i].helium)) / (tissueCompartments[i].nitrogen + tissueCompartments[i].helium);
          double ceiling = ((tissueCompartments[i].nitrogen + tissueCompartments[i].helium) - A) * B;
          if (ceiling > maxCeiling) maxCeiling = ceiling;
      }
      return maxCeiling;
  }

  GasMix getBestMix(List<GasMix> gasMixes, ambientPressure) {
    GasMix bestMix = gasMixes[0];
    for (var gas in gasMixes) {
      if (gas.oxygen > bestMix.oxygen && gas.oxygen * ambientPressure < 1.6) {
        bestMix = gas;
      }
    }
    return bestMix;
  }

  void resetDecompressionState() {
    Buhlmann();
  }

  void calculatePlan(List<Gas> gases, List<Waypoint> waypoints) {
    plan.clear();
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
      return;
    }

    double runtime = 0;
    GasMix bestMix = gasMixes[0];
    double currentPressure = -1.0;

    // currently does not take into account travel time between waypoints
    for (var waypoint in decoWaypoints) {
      double waypointTime = waypoint.time;
      currentPressure = waypoint.pressure;
      bestMix = getBestMix(gasMixes, currentPressure);
      instantSchreiner(bestMix, waypointTime, currentPressure);
      runtime = runtime + waypointTime;
      double ceiling = calculateCeiling();
      plan.add(DecompressionPlan('↗️', '${(currentPressure - 1) * 10} → ${(ceiling - 1) * 10}', runtime.toString(), runtime.toString(), '${bestMix.oxygen * 100}/${bestMix.helium * 100}', ''));
    }

    while (calculateCeiling() > surfacePressure + 0.1) {
      // Ascent Portion
      double ceiling = calculateCeiling();
      double roundedCeiling = ceiling - ((ceiling - 1) % 0.3) + 0.3;
      double timeAscending = (currentPressure - ceiling) / 1.0;
      schreinerAscentDescent(bestMix, 1.0, timeAscending, currentPressure);
      runtime = runtime + timeAscending;
      plan.add(DecompressionPlan('↗️', '${(currentPressure - 1)* 10} → ${(roundedCeiling - 1) * 10}', timeAscending.toString(), runtime.toString(), '${bestMix.oxygen * 100}/${bestMix.helium * 100}', ''));
      currentPressure = roundedCeiling;
      // Stop Portion
      bestMix = getBestMix(gasMixes, currentPressure);
      double stopDuration = stopTime(bestMix, currentPressure, currentPressure - 0.31);
      instantSchreiner(bestMix, stopDuration, currentPressure);
      runtime = runtime + stopDuration;
      plan.add(DecompressionPlan('🛑', '${(currentPressure - 1) * 10}', stopDuration.toString(), runtime.toString(), '${bestMix.oxygen * 100}/${bestMix.helium * 100}', ''));
    }
  }
}

// ➡️🔄↗️↘️🛑