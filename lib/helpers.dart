import 'package:delta_e/delta_e.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imgLib;

Color getAverageRBG(imgLib.Image image) {
  int redBucket = 0;
  int greenBucket = 0;
  int blueBucket = 0;
  int pixelCount = 0;

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      int c = image.getPixel(x, y);

      pixelCount++;
      redBucket += imgLib.getRed(c);
      greenBucket += imgLib.getGreen(c);
      blueBucket += imgLib.getBlue(c);
    }
  }
  Color averageColor = Color.fromRGBO(redBucket ~/ pixelCount,
      greenBucket ~/ pixelCount, blueBucket ~/ pixelCount, 1);

  return averageColor;
}

double getDeltaE(Color color1, Color color2) {
  LabColor lab1 = LabColor.fromRGB(color1.red, color1.green, color1.blue);
  LabColor lab2 = LabColor.fromRGB(color2.red, color2.green, color2.blue);
  return deltaE(lab1, lab2, algorithm: DeltaEAlgorithm.cie76);
}
