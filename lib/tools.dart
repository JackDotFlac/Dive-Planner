enum DisplayUnits {
  metric,
  imperial
}

const depthUnit = DisplayUnits.metric;

int pressureToDisplay(double pressure) {
  if (depthUnit == DisplayUnits.metric) {
    return ((pressure - 1) * 10).round();
  } else {
    return ((pressure - 1) * 33.455).round();
  }
}

int timeToDisplay(double time) {
  return time.ceil();
}

int percentageToDisplay(double percentage) {
  return (percentage * 100).ceil();
}