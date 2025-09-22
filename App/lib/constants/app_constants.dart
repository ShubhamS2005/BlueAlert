import 'package:flutter/material.dart';

// --- NEW BRAND COLORS ---
const kPrimaryColor = Color(0xFF2DC5F7);   // Your primary cyan
const kSecondaryColor = Color(0xFF000000); // Your black background, used for text
const kAccentColor = Color(0xFF01FFFF);    // Your secondary, brighter cyan for accents
const kLightColor = Color(0xFFE3F8FF);     // A very light, complementary cyan-tinted white
const kBlueLinkColor = kPrimaryColor;      // Use brand color for links for consistency

// --- PADDING & MARGINS (Unchanged) ---
const double kDefaultPadding = 20.0;

// --- BORDER RADIUS (Unchanged) ---
const double kDefaultBorderRadius = 12.0;

// --- TEXT STYLES (Updated with new colors) ---
const kHeadlineTextStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: kSecondaryColor,
);

// --- API CONSTANT ---
const String kApiBaseUrl = "http://10.100.159.54:8000/api/v1";

const kSubheadlineTextStyle = TextStyle(
  fontSize: 16,
  color: Colors.white,
);

const kButtonTextStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.black,
);

// --- INPUT DECORATION (Updated with new colors) ---
InputDecoration kDefaultInputDecoration({required String hintText, IconData? icon}) {
  return InputDecoration(
    hintText: hintText,
    prefixIcon: icon != null ? Icon(icon, color: kPrimaryColor) : null, // Uses primary cyan for icons
    filled: true,
    fillColor: kLightColor.withOpacity(0.5), // Uses the new light cyan tint
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      borderSide: const BorderSide(color: kPrimaryColor, width: 2), // Uses primary cyan for focus border
    ),
  );
}