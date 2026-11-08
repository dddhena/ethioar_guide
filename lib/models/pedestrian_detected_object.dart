import 'package:flutter/material.dart';

enum PedestrianObjectType {
  door,
  gate,
  stairsUp,
  stairsDown,
  crosswalk,
  corridor,
  elevator,
  obstacle,
}

/// Represents an environmental object recognized in real-time by computer vision
/// during live pedestrian AR navigation (e.g. doors, stairs, crosswalks, obstacles).
class PedestrianDetectedObject {
  final String id;
  final PedestrianObjectType type;
  final String label;
  final double confidence;
  final double distanceMeters;
  /// Normalized coordinates [0.0 - 1.0] across the camera viewfinder (left, top, right, bottom)
  final Rect normalizedRect;
  final bool isNavigationTarget;
  final String actionGuidance;
  final DateTime detectedAt;

  PedestrianDetectedObject({
    required this.id,
    required this.type,
    required this.label,
    required this.confidence,
    required this.distanceMeters,
    required this.normalizedRect,
    this.isNavigationTarget = false,
    required this.actionGuidance,
    DateTime? detectedAt,
  }) : detectedAt = detectedAt ?? DateTime.now();

  String get formattedDistance {
    if (distanceMeters < 1.0) {
      return '< 1 m';
    } else if (distanceMeters < 10.0) {
      return '${distanceMeters.toStringAsFixed(1)} m';
    }
    return '${distanceMeters.round()} m';
  }

  IconData get iconData {
    switch (type) {
      case PedestrianObjectType.door:
        return Icons.door_front_door_outlined;
      case PedestrianObjectType.gate:
        return Icons.fence_rounded;
      case PedestrianObjectType.stairsUp:
        return Icons.stairs_rounded;
      case PedestrianObjectType.stairsDown:
        return Icons.stairs_outlined;
      case PedestrianObjectType.crosswalk:
        return Icons.directions_walk_rounded;
      case PedestrianObjectType.corridor:
        return Icons.door_sliding_outlined;
      case PedestrianObjectType.elevator:
        return Icons.elevator_rounded;
      case PedestrianObjectType.obstacle:
        return Icons.warning_amber_rounded;
    }
  }

  Color get accentColor {
    switch (type) {
      case PedestrianObjectType.door:
      case PedestrianObjectType.gate:
        return isNavigationTarget ? Colors.greenAccent : Colors.cyanAccent;
      case PedestrianObjectType.stairsUp:
      case PedestrianObjectType.stairsDown:
        return Colors.amberAccent;
      case PedestrianObjectType.crosswalk:
        return Colors.lightBlueAccent;
      case PedestrianObjectType.corridor:
        return Colors.tealAccent;
      case PedestrianObjectType.elevator:
        return Colors.purpleAccent;
      case PedestrianObjectType.obstacle:
        return Colors.redAccent;
    }
  }

  /// Calculates the screen center point for arrow magnetic snapping
  Offset getNormalizedCenter() {
    return Offset(
      (normalizedRect.left + normalizedRect.right) / 2.0,
      (normalizedRect.top + normalizedRect.bottom) / 2.0,
    );
  }
}

