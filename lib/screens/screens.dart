import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:geolocator/geolocator.dart'; 
import 'package:animate_do/animate_do.dart'; 
import 'package:google_fonts/google_fonts.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/data_providers.dart';
import '../../services/mpesa_service.dart'; 
import '../../services/sound_service.dart'; 
import '../../services/receipt_service.dart'; 
import 'delivery_map_screen.dart'; 

// =====================================================================
// 🎨 HELPER METHODS
// =====================================================================

Widget _buildTextField({
  required TextEditingController controller, 
  required String label, 
  required IconData icon, 
  bool isPassword = false, 
  bool isPhone = false
}) {
  return TextFormField(
    controller: controller,
    obscureText: isPassword,
    keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green[700]),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
    validator: (v) => v?.isEmpty ?? true ? '$label is required' : null,
  );
}

Widget _buildContactFooter(BuildContext context) {
  final String phoneNumber = '0791547051';
  final String email = 'muirujames5@gmail.com';
  final String mpesaLink = 'tel:$phoneNumber'; 

  Future<void> launchLink(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open ${uri.scheme}')));
    }
  }

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 20),
    color: const Color(0xFF1B5E20).withOpacity(0.95),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Developer & Support: James Muiru", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(
              onPressed: () => launchLink(Uri.parse(mpesaLink)),
              icon: const Icon(Icons.phone, size: 18),
              style: IconButton.styleFrom(backgroundColor: Colors.green),
              tooltip: 'Call Support',
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: () => launchLink(Uri.parse('mailto:$email?subject=AgriConnect Support')),
              icon: const Icon(Icons.mail, size: 18),
              style: IconButton.styleFrom(backgroundColor: Colors.blue),
              tooltip: 'Email Support',
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: () => launchLink(Uri.parse('https://github.com/muirujames5')), 
              icon: const Icon(Icons.code, size: 18),
              style: IconButton.styleFrom(backgroundColor: Colors.grey[800]),
              tooltip: 'GitHub',
            ),
          ],
        ),
      ],
    ),
  );
}

// =====================================================================
// 1. LOGIN SCREEN
// =====================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLogin = true;
  UserRole _selectedRole = UserRole.customer;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, 
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1B5E20), Color(0xFF4CAF50), Color(0xFF81C784)]))),
          Positioned(top: -50, left: -50, child: FadeInDown(duration: const Duration(milliseconds: 1200), child: Container(width: 200, height: 200, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle)))),
          Positioned(bottom: -30, right: -30, child: FadeInUp(duration: const Duration(milliseconds: 1200), child: Container(width: 150, height: 150, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle)))),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  FadeInDown(duration: const Duration(milliseconds: 800), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]), child: Icon(Icons.agriculture, size: 60, color: Theme.of(context).primaryColor))),
                  const SizedBox(height: 20),
                  FadeInDown(delay: const Duration(milliseconds: 200), child: const Text('AgriConnect', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2))),
                  const SizedBox(height: 8),
                  FadeInDown(delay: const Duration(milliseconds: 400), child: Text('Farm to Fork, Simplified.', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16))),
                  const SizedBox(height: 40),
                  
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, spreadRadius: 5, offset: const Offset(0, 15))]),
                      child: Form(
                        key: _formKey,
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Column(
                            children: [
                              Text(_isLogin ? 'Welcome Back' : 'Create Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                              const SizedBox(height: 20),
                              if (!_isLogin) ...[
                                _buildTextField(controller: _nameController, label: 'Full Name', icon: Icons.person), 
                                const SizedBox(height: 16)
                              ],
                              _buildTextField(controller: _emailController, label: 'Email', icon: Icons.email),
                              const SizedBox(height: 16),
                              _buildTextField(controller: _passwordController, label: 'Password', icon: Icons.lock, isPassword: true),
                              if (!_isLogin) ...[
                                const SizedBox(height: 16),
                                _buildTextField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone, isPhone: true),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<UserRole>(
                                  value: _selectedRole, 
                                  decoration: const InputDecoration(labelText: 'I am a', prefixIcon: Icon(Icons.work), filled: true, fillColor: Color(0xFFF5F5F5), border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12)))),
                                  items: UserRole.values.map((role) => DropdownMenuItem(value: role, child: Text(role.toString().split('.').last.toUpperCase()))).toList(), 
                                  onChanged: (v) => setState(() => _selectedRole = v!)
                                ),
                              ],
                              const SizedBox(height: 30),
                              SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _isLoading ? null : _handleSubmit, style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isLogin ? 'LOGIN' : 'SIGN UP', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)))),
                              const SizedBox(height: 20),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(_isLogin ? "New here? " : "Has account? ", style: TextStyle(color: Colors.grey[600])), 
                                  GestureDetector(onTap: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? "Sign Up" : "Login", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)))
                                ]
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60), 
                ],
              ),
            ),
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildContactFooter(context)),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    FocusScope.of(context).unfocus();
    String? error;
    if (_isLogin) {
      error = await auth.signIn(_emailController.text.trim(), _passwordController.text);
    } else {
      error = await auth.signUp(email: _emailController.text.trim(), password: _passwordController.text, name: _nameController.text.trim(), role: _selectedRole, phoneNumber: _phoneController.text.trim());
    }
    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
  }
}

// =====================================================================
// 2. CUSTOMER DASHBOARD
// =====================================================================
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({Key? key}) : super(key: key);
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  void _refreshProducts() => context.read<ProductProvider>().loadProducts();

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().userProfile;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Search Header
          SliverAppBar(
            expandedHeight: 170.0,
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF43A047), Color(0xFF2E7D32)])),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), child: Text("Hello, ${user?.name.split(' ')[0] ?? 'Guest'}", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                          decoration: const InputDecoration(hintText: "Search fresh produce...", prefixIcon: Icon(Icons.search, color: Colors.green), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.history, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerOrdersScreen()))),
              PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle, color: Colors.white),
                onSelected: (v) { if(v == 'logout') context.read<AuthProvider>().signOut(); },
                itemBuilder: (ctx) => [
                  PopupMenuItem<String>(enabled: false, child: Text("Signed in as ${user?.name}", style: const TextStyle(fontSize: 12, color: Colors.grey))),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 8), Text('Logout', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
          
          // Product Grid
          Consumer<ProductProvider>(
            builder: (context, provider, _) {
              final filteredProducts = provider.products.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();
              
              if (filteredProducts.isEmpty) {
                return SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.search_off, size: 80, color: Colors.grey[300]), const SizedBox(height: 16), const Text("No products found.")])));
              }

              return SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.68, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  delegate: SliverChildBuilderDelegate((context, i) {
                      final product = filteredProducts[i];
                      final double stock = product.quantity ?? 0;
                      final bool isOutOfStock = stock <= 0;

                      return FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))]),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(children: [
                                  ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: SizedBox(width: double.infinity, child: product.imageUrls.isNotEmpty ? Image.network(product.imageUrls.first, fit: BoxFit.cover) : Container(color: Colors.green[50], child: const Center(child: Icon(Icons.agriculture, size: 40, color: Colors.green))))),
                                  Positioned(top: 12, right: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: isOutOfStock ? Colors.red : Colors.green, borderRadius: BorderRadius.circular(20)), child: Text(isOutOfStock ? "SOLD OUT" : "${stock.toInt()} LEFT", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                                ]),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text('\$${product.pricePerUnit}/${product.unit.toString().split('.').last}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text("Stock: ${stock.toInt()}", style: TextStyle(color: isOutOfStock ? Colors.red : Colors.grey, fontSize: 11)),
                                    Text("By: ${product.farmerName}", style: const TextStyle(color: Colors.blueGrey, fontSize: 11, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 8),
                                    SizedBox(width: double.infinity, height: 32, child: ElevatedButton(onPressed: isOutOfStock ? null : () => _showBuyDialog(context, product), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("ADD", style: TextStyle(fontSize: 12)))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: filteredProducts.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showBuyDialog(BuildContext context, Product product) {
    final qtyController = TextEditingController(text: '1');
    final phoneController = TextEditingController(text: context.read<AuthProvider>().userProfile?.phoneNumber ?? '');
    final msgController = TextEditingController();
    bool isPaying = false;
    bool needsDelivery = true; 
    String statusMessage = "";

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(children: [const Icon(Icons.shopping_cart, color: Colors.green, size: 40), const SizedBox(height: 10), Text('Buy ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('Seller: ${product.farmerName}', style: const TextStyle(fontSize: 12, color: Colors.blue))]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
              Text('Price: \$${product.pricePerUnit} / unit', style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 16),
              TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Quantity', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              SwitchListTile(title: const Text("Request Delivery?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), value: needsDelivery, activeColor: Colors.green, contentPadding: EdgeInsets.zero, onChanged: (val) => setDialogState(() => needsDelivery = val)),
              const SizedBox(height: 12),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'My Contact Phone', prefixIcon: const Icon(Icons.phone), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              const Text("Already Paid? Paste Message:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(controller: msgController, maxLines: 2, decoration: InputDecoration(hintText: "Paste M-Pesa Message (Optional)", filled: true, fillColor: Colors.green[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              if (isPaying) Padding(padding: const EdgeInsets.only(top: 16), child: Column(children: [const CircularProgressIndicator(), const SizedBox(height: 8), Text(statusMessage, style: const TextStyle(fontSize: 12))])),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          
          // Pay on Delivery
          OutlinedButton(onPressed: isPaying ? null : () async {
             final qty = double.tryParse(qtyController.text) ?? 0;
             if (qty <= 0) return;
             if (qty > (product.quantity ?? 0)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity exceeds stock!'))); return; }
             
             setDialogState(() { isPaying = true; statusMessage = "Fetching location..."; });
             
             // ⭐️ SAFE: Use Position type
             final pos = await context.read<AuthProvider>().getCurrentLocation();
             
             Navigator.pop(ctx);
             _placeOrder(product, qty, needsDelivery, phoneController.text, pos, msgController.text);
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Placed! Pay upon receipt.')));
          }, child: const Text("Pay on Delivery")),

          // M-Pesa
          ElevatedButton(onPressed: isPaying ? null : () async {
             final qty = double.tryParse(qtyController.text) ?? 0;
             final phone = phoneController.text.trim();
             if (qty <= 0 || phone.isEmpty) return;
             
             setDialogState(() { isPaying = true; statusMessage = "Sending M-Pesa Request..."; });
             
             final pos = await context.read<AuthProvider>().getCurrentLocation();

             final mpesa = MpesaService();
             bool success = await mpesa.startSTKPush(phone, qty * product.pricePerUnit);
             
             if (success) {
               setDialogState(() { isPaying = false; statusMessage = "Check phone!"; });
               ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('M-Pesa Sent! Check phone.')));
             } else {
               setDialogState(() => isPaying = false);
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Failed. Try COD.')));
             }
          }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text("M-Pesa")),

          // Confirm
          if (msgController.text.isNotEmpty)
            ElevatedButton(onPressed: () async {
                final qty = double.tryParse(qtyController.text) ?? 0;
                final pos = await context.read<AuthProvider>().getCurrentLocation();
                Navigator.pop(ctx);
                _placeOrder(product, qty, needsDelivery, phoneController.text, pos, msgController.text);
            }, child: const Text("Confirm")),
        ],
      );
    }));
  }

  // ⭐️ CORRECT: Accepting Position? to match AuthProvider
  Future<void> _placeOrder(Product product, double qty, bool needsDelivery, String contactPhone, Position? currentPos, String msg) async {
    final auth = context.read<AuthProvider>();
    final user = auth.userProfile!;
    
    // Convert Position to Map here
    Map<String, double> finalLocation = {};
    if (currentPos != null) {
        finalLocation = {'lat': currentPos.latitude, 'lng': currentPos.longitude};
    } else if (user.location != null) {
        finalLocation = user.location!;
    } else {
        finalLocation = {'lat': -1.2921, 'lng': 36.8219}; // Default
    }

    final newOrder = Order(
      customerId: user.uid, customerName: user.name, customerPhone: contactPhone,
      farmerId: product.farmerId, farmerName: product.farmerName, 
      productId: product.id!, productName: product.name,
      quantity: qty, totalPrice: qty * product.pricePerUnit, unit: product.unit,
      status: OrderStatus.pending,
      deliveryPersonId: needsDelivery ? null : 'SELF_PICKUP', deliveryPersonName: needsDelivery ? null : 'Customer Pickup',
      deliveryLocation: finalLocation, createdAt: DateTime.now(), paymentRef: msg.isEmpty ? (needsDelivery ? 'PENDING_DELIVERY' : 'COD') : msg
    );
    
    final error = await context.read<OrderProvider>().placeOrder(newOrder);
    if (mounted) {
      if (error != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error'))); } 
      else { context.read<ProductProvider>().loadProducts(); }
    }
  }
}

// =====================================================================
// 3. CUSTOMER ORDERS HISTORY
// =====================================================================
class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({Key? key}) : super(key: key);
  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}
class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().userProfile?.uid;
    if (uid != null) context.read<OrderProvider>().loadCustomerOrders(uid);
  }

  Widget _buildTimeline(OrderStatus status) {
    int currentStep = 0;
    switch (status) { case OrderStatus.pending: currentStep = 1; break; case OrderStatus.accepted: currentStep = 2; break; case OrderStatus.inTransit: currentStep = 3; break; case OrderStatus.delivered: currentStep = 4; break; default: currentStep = -1; break; }
    Widget step(String label, int stepNum, bool isLast) {
      bool isActive = currentStep >= stepNum;
      return Expanded(child: Column(children: [
        Row(children: [Expanded(child: Container(height: 2, color: stepNum==1?Colors.transparent:(isActive?Colors.green:Colors.grey[300]))), Icon(isActive?Icons.check_circle:Icons.radio_button_unchecked, color: isActive?Colors.green:Colors.grey, size: 16), Expanded(child: Container(height: 2, color: isLast?Colors.transparent:(currentStep>stepNum?Colors.green:Colors.grey[300])))]),
        const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 9, color: isActive?Colors.black:Colors.grey))
      ]));
    }
    return Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [step("Placed", 1, false), step("Accepted", 2, false), step("On Way", 3, false), step("Delivered", 4, true)]));
  }

  Future<void> _launchContact(String scheme, String path) async {
      final Uri launchUri = Uri(scheme: scheme, path: path);
      if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: Consumer<OrderProvider>(builder: (context, provider, _) {
        if (provider.orders.isEmpty) return const Center(child: Text('No orders yet.'));
        return ListView.builder(itemCount: provider.orders.length, itemBuilder: (context, i) {
            final order = provider.orders[i];
            final isSelfPickup = order.deliveryPersonId == 'SELF_PICKUP';
            final paymentRef = order.paymentRef ?? "N/A";
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ExpansionTile(
                leading: CircleAvatar(backgroundColor: _getStatusColor(order.status), child: const Icon(Icons.shopping_bag, color: Colors.white, size: 18)),
                title: Text(order.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${order.quantity} units • KES ${order.totalPrice.toStringAsFixed(0)}'),
                trailing: Text(order.status.toString().split('.').last.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(order.status))),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTimeline(order.status),
                        const Divider(),
                        Text("Payment Ref: $paymentRef", style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text("Delivery: ${isSelfPickup ? 'Self Pickup' : 'Requested'}", style: TextStyle(color: Colors.blue[700])),
                        const SizedBox(height: 16),
                        const Text("Contacts:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                             Text("Farmer (${order.farmerName}):", style: TextStyle(color: Colors.grey[700])),
                             Row(children: [
                                IconButton.filledTonal(onPressed: () => _launchContact('tel', '0791547051'), icon: const Icon(Icons.call, size: 16, color: Colors.green), tooltip: "Call Farmer"),
                             ]),
                        ]),
                        if (!isSelfPickup && order.deliveryPersonId != null)
                           Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text("Driver (${order.deliveryPersonName}):", style: TextStyle(color: Colors.grey[700])),
                              IconButton.filledTonal(onPressed: () => _launchContact('tel', '0791547051'), icon: const Icon(Icons.local_shipping, size: 16, color: Colors.blue), tooltip: "Call Driver"),
                           ]),
                        const SizedBox(height: 16),
                        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => ReceiptService.generateAndPrint(order), icon: const Icon(Icons.receipt_long), label: const Text("Download Receipt PDF"))),
                      ],
                    ),
                  )
                ],
              ),
            );
        });
      }),
    );
  }
  Color _getStatusColor(OrderStatus status) {
    switch (status) { case OrderStatus.pending: return Colors.orange; case OrderStatus.accepted: return Colors.blue; case OrderStatus.inTransit: return Colors.purple; case OrderStatus.delivered: return Colors.green; default: return Colors.grey; }
  }
}

// =====================================================================
// 4. DELIVERY DASHBOARD
// =====================================================================
class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({Key? key}) : super(key: key);
  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  int _selectedIndex = 0;
  StreamSubscription? _jobSubscription;
  bool _isSilentMode = false; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
    _setupRealtimeJobs();
  }

  void _refreshData() {
    final auth = context.read<AuthProvider>();
    final deliveryId = auth.userProfile?.uid;
    if (_selectedIndex == 0) context.read<OrderProvider>().loadAvailableDeliveries();
    else if (deliveryId != null) context.read<OrderProvider>().loadDeliveryPersonOrders(deliveryId);
  }

  void _setupRealtimeJobs() {
    _jobSubscription = FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'accepted').where('deliveryPersonId', isNull: true).snapshots().listen((snapshot) {
      if (snapshot.docChanges.any((change) => change.type == DocumentChangeType.added)) {
        if (_selectedIndex == 0) context.read<OrderProvider>().loadAvailableDeliveries();
        if (!_isSilentMode) SoundService.playNotification();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("New Delivery Job! 🚚"), backgroundColor: Colors.blue[800], behavior: SnackBarBehavior.floating));
      }
    });
  }
  @override
  void dispose() { _jobSubscription?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().userProfile;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0, backgroundColor: Colors.blue[800],
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Driver: ${user?.name.split(' ')[0] ?? 'User'}", style: const TextStyle(fontSize: 14, color: Colors.white70)), Text(_selectedIndex == 0 ? 'New Opportunities' : 'My Active Jobs', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))]),
        actions: [
          IconButton(icon: Icon(_isSilentMode ? Icons.notifications_off : Icons.notifications_active, color: Colors.white), onPressed: () { setState(() => _isSilentMode = !_isSilentMode); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isSilentMode ? "Silent Mode On" : "Sound On"), duration: const Duration(milliseconds: 500))); }),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _refreshData),
          PopupMenuButton<String>(icon: const Icon(Icons.account_circle, color: Colors.white), onSelected: (v) { if(v == 'logout') context.read<AuthProvider>().signOut(); }, itemBuilder: (ctx) => [PopupMenuItem(enabled: false, child: Text(user?.name ?? "")), const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 8), Text("Logout", style: TextStyle(color: Colors.red))]))])
        ],
      ),
      body: _selectedIndex == 0 ? const AvailableJobsList() : const MyActiveDeliveriesList(),
      bottomNavigationBar: NavigationBar(selectedIndex: _selectedIndex, onDestinationSelected: (i) { setState(() => _selectedIndex = i); _refreshData(); }, destinations: const [NavigationDestination(icon: Icon(Icons.notifications_none), label: 'Available'), NavigationDestination(icon: Icon(Icons.local_shipping), label: 'My Active')]),
    );
  }
}

class AvailableJobsList extends StatelessWidget {
  const AvailableJobsList({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(builder: (context, provider, _) {
        if (provider.orders.isEmpty) return const Center(child: Text('No new jobs available.'));
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: provider.orders.length, itemBuilder: (context, i) {
            final order = provider.orders[i];
            return FadeInRight(delay: Duration(milliseconds: i * 100), child: Card(elevation: 2, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: ListTile(contentPadding: const EdgeInsets.all(16), leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle), child: const Icon(Icons.inventory_2, color: Colors.green)), title: Text('Pickup: ${order.productName}', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Qty: ${order.quantity} • To: ${order.customerName}'), trailing: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: () => _acceptDelivery(context, order.id!), child: const Text('ACCEPT')))));
        });
      },
    );
  }
  Future<void> _acceptDelivery(BuildContext context, String orderId) async {
    final user = context.read<AuthProvider>().userProfile!;
    await context.read<OrderProvider>().updateOrderStatus(orderId, OrderStatus.inTransit, deliveryPersonId: user.uid, deliveryPersonName: user.name);
    if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Accepted!'))); context.read<OrderProvider>().loadAvailableDeliveries(); }
  }
}

class MyActiveDeliveriesList extends StatefulWidget {
  const MyActiveDeliveriesList({Key? key}) : super(key: key);
  @override
  State<MyActiveDeliveriesList> createState() => _MyActiveDeliveriesListState();
}

class _MyActiveDeliveriesListState extends State<MyActiveDeliveriesList> {
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _currentPosition = pos);
    } catch (e) {
      print("Error getting location: $e");
    }
  }
  
  Future<void> _makePhoneCall(String phoneNumber) async { final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber); if (await canLaunchUrl(launchUri)) await launchUrl(launchUri); }
  Future<void> _sendSms(String phoneNumber) async { final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber); if (await canLaunchUrl(launchUri)) await launchUrl(launchUri); }

  String _calculateDistance(Map<String, double> destLocation) {
    final pos = _currentPosition;
    
    if (pos == null || destLocation.isEmpty) return "Calc distance...";
    
    final destLat = destLocation['lat'];
    final destLng = destLocation['lng'];
    
    if (destLat == null || destLng == null) return "Unknown";

    double distInMeters = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      destLat,
      destLng,
    );
    double distInKm = distInMeters / 1000;
    return "${distInKm.toStringAsFixed(1)} km away";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(builder: (context, provider, _) {
        final activeOrders = provider.orders.where((o) => o.status == OrderStatus.inTransit).toList();
        if (activeOrders.isEmpty) return const Center(child: Text('No active deliveries.'));
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: activeOrders.length, itemBuilder: (context, i) {
            final order = activeOrders[i];
            final distance = _calculateDistance(order.deliveryLocation);
            return FadeInUp(child: Card(elevation: 4, margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [const Icon(Icons.local_shipping, color: Colors.blue), const SizedBox(width: 8), const Text('IN TRANSIT', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))]), Text(distance, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))]),
                    const Divider(),
                    Text('Product: ${order.productName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Deliver to: ${order.customerName}\nPhone: ${order.customerPhone}'),
                    const SizedBox(height: 16),
                    Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => _makePhoneCall(order.customerPhone), icon: const Icon(Icons.call), label: const Text("Call"))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: () => _sendSms(order.customerPhone), icon: const Icon(Icons.message), label: const Text("SMS")))]),
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeliveryMapScreen(order: order))), icon: const Icon(Icons.map), label: const Text("NAVIGATE"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white))),
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _completeDelivery(context, order.id!), icon: const Icon(Icons.check_circle), label: const Text("MARK DELIVERED"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white))),
            ]))));
        });
      },
    );
  }
  Future<void> _completeDelivery(BuildContext context, String orderId) async {
    final auth = context.read<AuthProvider>();
    await context.read<OrderProvider>().updateOrderStatus(orderId, OrderStatus.delivered);
    if (context.mounted) context.read<OrderProvider>().loadDeliveryPersonOrders(auth.userProfile!.uid);
  }
}