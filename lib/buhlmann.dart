import 'dart:math';
import 'gases.dart';
import 'waypoints.dart';

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

class DecoWaypoint {
  double time;
  double pressure;

  DecoWaypoint(this.time, this.pressure);
}

DecoWaypoint decoWaypointFromWaypoint(Waypoint waypoint) {
  double time = double.parse(waypoint.timeController.text);
  double pressure = (double.parse(waypoint.depthController.text) + 10) / 10;

  return DecoWaypoint(time, pressure);
}

// delete above this line

class DecompressionSettings {
  double waterVapourPressure;
  double surfacePressure;
  double ascentRate;
  double gfLow;
  double gfHigh;
  double maxNDL; // breaks formatting as can be weird to read otherwise
  double firstStopRaw = -1;

  DecompressionSettings(
    this.waterVapourPressure,
    this.surfacePressure,
    this.ascentRate,
    this.gfLow,
    this.gfHigh,
    this.maxNDL,
  );

  void updateFirstStop(double rawCeiling) {
    if (rawCeiling > firstStopRaw) firstStopRaw = rawCeiling;
  }

  double gradientFactor(double ambientPressure) {
    if (firstStopRaw <= surfacePressure) return gfHigh;

    double stopFraction =
        (ambientPressure - surfacePressure) / (firstStopRaw - surfacePressure);
    stopFraction = stopFraction.clamp(0.0, 1.0);
    return gfHigh + ((gfLow - gfHigh) * stopFraction);
  }
}

class CompartmentGas {
  double halftime;
  double aValue;
  double bValue;
  double tissueLoading;
  DecompressionSettings decoSettings;

  CompartmentGas(
    this.halftime,
    this.aValue,
    this.bValue,
    this.tissueLoading,
    this.decoSettings,
  );

  // might be worth moving this function elsewhere for the sake of organisation.
  double gasPressure(gasFraction, ambientPressure) {
    return (ambientPressure - decoSettings.waterVapourPressure) * gasFraction;
  }

  double loadingAfterInstant(
    double gasFraction,
    double duration,
    double ambientPressure,
  ) {
    return tissueLoading +
        ((gasPressure(gasFraction, ambientPressure) - tissueLoading) *
            (1 - pow(2, (-duration / halftime))));
  }

  void instantSchreiner(
    double gasFraction,
    double duration,
    double ambientPressure,
  ) {
    tissueLoading = loadingAfterInstant(gasFraction, duration, ambientPressure);
  }

  // full form of the schreiner equation
  void slopedSchreiner(
    double gasFraction,
    double duration,
    double ambientPressure,
    bool ascending,
  ) {
    double R = gasFraction * decoSettings.ascentRate;
    if (ascending) R = R * -1;
    double k = ln2 / halftime;
    double currentGasPressure = gasPressure(gasFraction, ambientPressure);
    tissueLoading =
        currentGasPressure +
        (R * (duration - (1.0 / k))) -
        ((currentGasPressure - tissueLoading - (R / k)) * exp(-k * duration));
  }

  double stopTime(
    double gasFraction,
    double ambientPressure,
    double targetPressure,
  ) {
    double gf = decoSettings.gradientFactor(targetPressure);
    double mValue =
        targetPressure +
        (gf * (aValue + (targetPressure / bValue) - targetPressure));
    double currentGasPressure = gasPressure(gasFraction, ambientPressure);
    if (currentGasPressure < mValue && mValue < tissueLoading) {
      double k = ln2 / halftime;
      return (-1.0 / k) *
          log(
            (currentGasPressure - mValue) /
                (currentGasPressure - tissueLoading),
          );
    }
    return 0.0;
  }

  // add gradient factors
  double noDecompressionLimit(double gasFraction, double ambientPressure) {
    double currentGasPressure = gasPressure(gasFraction, ambientPressure);
    double mValue0 =
        decoSettings.surfacePressure +
        (decoSettings.gfHigh *
            (aValue +
                (decoSettings.surfacePressure / bValue) -
                decoSettings.surfacePressure));
    if (currentGasPressure > mValue0 && mValue0 > tissueLoading) {
      double k = ln2 / halftime;
      return (-1.0 / k) *
          log(
            (currentGasPressure - mValue0) /
                (currentGasPressure - tissueLoading),
          );
    }
    return decoSettings.maxNDL;
  }
}

class Compartment {
  late CompartmentGas nitrogen;
  late CompartmentGas helium;
  DecompressionSettings decoSettings;

  Compartment(
    halftimeN2,
    aValueN2,
    bValueN2,
    nitrogenLoading,
    halftimeHe,
    aValueHe,
    bValueHe,
    heliumLoading,
    this.decoSettings,
  ) {
    nitrogen = CompartmentGas(
      halftimeN2,
      aValueN2,
      bValueN2,
      nitrogenLoading,
      decoSettings,
    );
    helium = CompartmentGas(
      halftimeHe,
      aValueHe,
      bValueHe,
      heliumLoading,
      decoSettings,
    );
  }

  void instantSchreiner(GasMix gas, double duration, double ambientPressure) {
    nitrogen.instantSchreiner(gas.nitrogen, duration, ambientPressure);
    helium.instantSchreiner(gas.helium, duration, ambientPressure);
  }

  void slopedSchreiner(
    GasMix gas,
    double duration,
    double ambientPressure,
    bool ascending,
  ) {
    nitrogen.slopedSchreiner(
      gas.nitrogen,
      duration,
      ambientPressure,
      ascending,
    );
    helium.slopedSchreiner(gas.helium, duration, ambientPressure, ascending);
  }

  double toleratedInertGasPressure(double ambientPressure) {
    double ptIg = nitrogen.tissueLoading + helium.tissueLoading;
    if (ptIg <= 0) return 0.0;

    double gf = decoSettings.gradientFactor(ambientPressure);
    double A =
        ((nitrogen.aValue * nitrogen.tissueLoading) +
            (helium.aValue * helium.tissueLoading)) /
        ptIg;
    double B =
        ((nitrogen.bValue * nitrogen.tissueLoading) +
            (helium.bValue * helium.tissueLoading)) /
        ptIg;
    return ambientPressure +
        (gf * (A + (ambientPressure / B) - ambientPressure));
  }

  double stopTime(GasMix gas, double ambientPressure, double targetPressure) {
    double low = 0.0;
    double high = max(
      nitrogen.stopTime(gas.nitrogen, ambientPressure, targetPressure),
      helium.stopTime(gas.helium, ambientPressure, targetPressure),
    );

    bool canAscendAfter(double duration) {
      double currentNitrogenLoading = nitrogen.tissueLoading;
      double currentHeliumLoading = helium.tissueLoading;
      nitrogen.tissueLoading = nitrogen.loadingAfterInstant(
        gas.nitrogen,
        duration,
        ambientPressure,
      );
      helium.tissueLoading = helium.loadingAfterInstant(
        gas.helium,
        duration,
        ambientPressure,
      );

      double inertGasPressure = nitrogen.tissueLoading + helium.tissueLoading;
      double toleratedPressure = toleratedInertGasPressure(targetPressure);

      nitrogen.tissueLoading = currentNitrogenLoading;
      helium.tissueLoading = currentHeliumLoading;
      return inertGasPressure <= toleratedPressure;
    }

    if (canAscendAfter(low)) return low;
    while (!canAscendAfter(high) && high < decoSettings.maxNDL) {
      high = max(1.0, high * 2);
    }

    for (int i = 0; i < 32; i++) {
      double mid = (low + high) / 2;
      if (canAscendAfter(mid)) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return high;
  }

  double noDecompressionLimit(GasMix gas, double ambientPressure) {
    return min(
      nitrogen.noDecompressionLimit(gas.nitrogen, ambientPressure),
      helium.noDecompressionLimit(gas.helium, ambientPressure),
    );
  }

  double ceiling() {
    double ptIg =
        (nitrogen.tissueLoading + helium.tissueLoading); // Inert Gas Pressure
    double A =
        ((nitrogen.aValue * nitrogen.tissueLoading) +
            (helium.aValue * helium.tissueLoading)) /
        ptIg;
    double B =
        ((nitrogen.bValue * nitrogen.tissueLoading) +
            (helium.bValue * helium.tissueLoading)) /
        ptIg;
    double rawCeiling = (ptIg - A) * B;
    decoSettings.updateFirstStop(rawCeiling);
    double gf = decoSettings.gradientFactor(rawCeiling);
    return (ptIg - (gf * A)) / ((gf / B) - gf + 1);
  }
}

class Buhlmann {
  DecompressionSettings decoSettings = DecompressionSettings(
    0.0627,
    1,
    1,
    0.3,
    0.7,
    999,
  );
  List<Compartment> compartments = [];

  Buhlmann() {
    List<double> halftimeN2 = [
      5.0000,
      8.0000,
      12.500,
      18.500,
      27.000,
      38.300,
      54.300,
      77.000,
      109.00,
      146.00,
      187.00,
      239.00,
      305.00,
      390.00,
      498.00,
      635.00,
    ];
    List<double> aValueN2 = [
      1.1696,
      1.0000,
      0.8618,
      0.7562,
      0.6200,
      0.5043,
      0.4410,
      0.4000,
      0.3750,
      0.3500,
      0.3295,
      0.3065,
      0.2835,
      0.2610,
      0.2480,
      0.2327,
    ];
    List<double> bValueN2 = [
      0.5578,
      0.6514,
      0.7222,
      0.7825,
      0.8126,
      0.8434,
      0.8693,
      0.8910,
      0.9092,
      0.9222,
      0.9319,
      0.9403,
      0.9477,
      0.9544,
      0.9602,
      0.9653,
    ];
    List<double> halftimeHe = [
      1.8800,
      3.0200,
      4.7200,
      6.9900,
      10.210,
      14.480,
      20.530,
      29.110,
      41.200,
      55.190,
      70.690,
      90.340,
      115.20,
      147.42,
      188.24,
      240.03,
    ];
    List<double> aValueHe = [
      1.6189,
      1.3830,
      1.1919,
      1.0458,
      0.9220,
      0.8205,
      0.7305,
      0.6502,
      0.5950,
      0.5545,
      0.5333,
      0.5189,
      0.5181,
      0.5176,
      0.5172,
      0.5119,
    ];
    List<double> bValueHe = [
      0.4770,
      0.5747,
      0.6527,
      0.7223,
      0.7582,
      0.7957,
      0.8279,
      0.8553,
      0.8757,
      0.8903,
      0.8997,
      0.9073,
      0.9122,
      0.9171,
      0.9217,
      0.9267,
    ];

    for (int i = 0; i < 16; i++) {
      compartments.add(
        Compartment(
          halftimeN2[i],
          aValueN2[i],
          bValueN2[i],
          0.79, // PLACEHOLDER
          halftimeHe[i],
          aValueHe[i],
          bValueHe[i],
          0.0, // PLACEHOLDER
          decoSettings,
        ),
      );
    }
  }

  void instantSchreiner(GasMix gas, double duration, double ambientPressure) {
    for (var i in compartments) {
      i.instantSchreiner(gas, duration, ambientPressure);
    }
  }

  void slopedSchreiner(
    GasMix gas,
    double duration,
    double ambientPressure,
    bool ascending,
  ) {
    for (var i in compartments) {
      i.slopedSchreiner(gas, duration, ambientPressure, ascending);
    }
  }

  double stopTime(GasMix gas, double ambientPressure, double targetPressure) {
    double maxStopTime = 0.0;
    for (var i in compartments) {
      maxStopTime = max(
        maxStopTime,
        i.stopTime(gas, ambientPressure, targetPressure),
      );
    }
    return maxStopTime;
  }

  double noDecompressionLimit(gas, ambientPressure) {
    double minNDL = decoSettings.maxNDL;
    for (var i in compartments) {
      minNDL = min(minNDL, i.noDecompressionLimit(gas, ambientPressure));
    }
    return minNDL;
  }

  double ceiling() {
    double ceiling = 0.0;
    for (var i in compartments) {
      ceiling = max(ceiling, i.ceiling());
    }
    return ceiling;
    //return currentCeiling;
  }
}

GasMix getBestMix(List<GasMix> gasMixes, ambientPressure) {
  GasMix bestMix = gasMixes[0];
  for (var gas in gasMixes) {
    if (gas.oxygen >= bestMix.oxygen && gas.oxygen * ambientPressure <= 1.6) {
      bestMix = gas;
    }
  }
  return bestMix;
}
