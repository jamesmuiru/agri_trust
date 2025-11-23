import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserProfile? _userProfile;

  UserProfile? get userProfile => _userProfile;
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userProfile = UserProfile.fromMap(doc.data()!, uid);
        notifyListeners();
      } else {
        print("Waiting for profile creation...");
      }
    } catch (e) {
      print("Error loading profile: $e");
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phoneNumber,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Use simplified location getter to avoid freeze
      final position = await getCurrentLocation();
      
      final profile = UserProfile(
        uid: credential.user!.uid,
        email: email,
        name: name,
        role: role,
        phoneNumber: phoneNumber,
        location: position != null
            ? {'lat': position.latitude, 'lng': position.longitude}
            : null,
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(profile.toMap());

      _userProfile = profile;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _userProfile = null;
    notifyListeners();
  }

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      // Try cached first (Instant)
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;

      // Then try real GPS with timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), 
      );
    } catch (e) {
      return null;
    }
  }
}