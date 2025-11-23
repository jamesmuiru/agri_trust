import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:animate_do/animate_do.dart'; 
import 'package:google_fonts/google_fonts.dart'; 

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
   
  MeasurementUnit _selectedUnit = MeasurementUnit.kg;
  String _selectedCategory = "Vegetables"; 
  bool _isLoading = false;
  String _loadingMessage = ""; 
  double _estimatedEarnings = 0.0; 

  final List<String> _categories = ["Vegetables", "Fruits", "Grains", "Dairy", "Other"];

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_calculateEarnings);
    _quantityController.addListener(_calculateEarnings);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _calculateEarnings() {
    double price = double.tryParse(_priceController.text) ?? 0;
    double qty = double.tryParse(_quantityController.text) ?? 0;
    setState(() {
      _estimatedEarnings = price * qty;
    });
  }

  InputDecoration _buildDecoration(String label, IconData icon, {String? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
      suffixText: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2)),
      floatingLabelStyle: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
    );
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = "📍 Getting Farm Location...";
    });

    try {
      final auth = context.read<AuthProvider>();
      final farmerProfile = auth.userProfile!;

      // 1. GET LOCATION (With Timeout Safety)
      Position? position;
      try {
        position = await auth.getCurrentLocation().timeout(
          const Duration(seconds: 5),
          onTimeout: () => null, // Return null on timeout
        );
      } catch (e) {
        print("GPS Error: $e");
      }
      
      Map<String, double> productLocation = {};
      if (position != null) {
        productLocation = {'lat': position.latitude, 'lng': position.longitude};
      } else {
        // Default to Nairobi if GPS fails
        productLocation = farmerProfile.location ?? {'lat': -1.2921, 'lng': 36.8219};
      }

      setState(() => _loadingMessage = "💾 Saving to Market...");

      final newProduct = Product(
        farmerId: farmerProfile.uid,
        farmerName: farmerProfile.name,
        name: _nameController.text.trim(),
        description: "$_selectedCategory: ${_descriptionController.text.trim()}", 
        pricePerUnit: double.tryParse(_priceController.text) ?? 0.0,
        unit: _selectedUnit,
        imageUrls: const [], 
        quantity: double.tryParse(_quantityController.text),
        location: productLocation, 
        createdAt: DateTime.now(),
      );

      final error = await context.read<ProductProvider>().addProduct(newProduct, []);

      if (mounted) {
        setState(() => _isLoading = false);
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red));
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 10), const Text("Product Live!")]),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('New Listing', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                child: Text("Sell your Produce", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32))),
              ),
              const SizedBox(height: 5),
              FadeInDown(delay: const Duration(milliseconds: 100), child: const Text("Fill in the details to reach customers instantly.", style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 30),

              // CATEGORY CHIPS
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_,__) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: const Color(0xFF2E7D32),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                        onSelected: (val) => setState(() => _selectedCategory = cat),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: _buildDecoration('Product Name', Icons.eco),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: _buildDecoration('Description', Icons.description),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                     
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: _buildDecoration('Price', Icons.attach_money),
                            validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: _buildDecoration('Quantity', Icons.scale),
                            validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Unit Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      child: DropdownButtonFormField<MeasurementUnit>(
                        value: _selectedUnit,
                        decoration: const InputDecoration(icon: Icon(Icons.balance, color: Color(0xFF2E7D32)), labelText: 'Unit', border: InputBorder.none),
                        items: MeasurementUnit.values.map((unit) => DropdownMenuItem(value: unit, child: Text(unit.toString().split('.').last.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                        onChanged: (v) => setState(() => _selectedUnit = v!),
                      ),
                    ),
                  ],
                ),
              ),
               
              const SizedBox(height: 30),

              // EARNINGS CARD
              if (_estimatedEarnings > 0)
                FadeInUp(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Potential Revenue:", style: TextStyle(fontWeight: FontWeight.w600)),
                        Text("KES ${_estimatedEarnings.toStringAsFixed(0)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              // ACTION BUTTON
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitProduct,
                    icon: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.rocket_launch),
                    label: Text(
                      _isLoading ? _loadingMessage : 'PUBLISH PRODUCT',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30), 
            ],
          ),
        ),
      ),
    );
  }
}