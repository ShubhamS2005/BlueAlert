import 'package:flutter/material.dart';

// --- COLORS ---
const kPrimaryColor = Color(0xFF395B64);
const kSecondaryColor = Color(0xFF2C3333);
const kAccentColor = Color(0xFFA5C9CA);
const kLightColor = Color(0xFFE7F6F2);
const kBlueLinkColor = Colors.blue;

// --- PADDING & MARGINS ---
const double kDefaultPadding = 20.0;

// --- BORDER RADIUS ---
const double kDefaultBorderRadius = 12.0;

// --- TEXT STYLES ---
const kHeadlineTextStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: kSecondaryColor,
);
// --- API CONSTANT ---
const String kApiBaseUrl = "http://10.100.159.54:8000/api/v1";

const kSubheadlineTextStyle = TextStyle(
  fontSize: 16,
  color: Colors.grey,
);

const kButtonTextStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

// --- INPUT DECORATION ---
InputDecoration kDefaultInputDecoration({required String hintText, IconData? icon}) {
  return InputDecoration(
    hintText: hintText,
    prefixIcon: icon != null ? Icon(icon, color: kPrimaryColor) : null,
    filled: true,
    fillColor: kLightColor.withOpacity(0.5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      borderSide: const BorderSide(color: kPrimaryColor, width: 2),
    ),
  );
}