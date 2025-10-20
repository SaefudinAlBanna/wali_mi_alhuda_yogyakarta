// lib/app/models/onboarding_item_model.dart
import 'package:flutter/material.dart';

class OnboardingItemModel {
  final String title;
  final String description;
  final String imagePath;
  final bool isLottie;
  final IconData? icon;

  OnboardingItemModel({
    required this.title,
    required this.description,
    required this.imagePath,
    this.isLottie = false,
    this.icon,
  });
}