import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'dart:async'; 

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../services/sound_service.dart';
import 'add_product_screen.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({Key? key}) : super(key: key);

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  int _selectedIndex = 0;
  StreamSubscription? _orderSubscription;
  bool _isSilentMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeNotifications();
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    if (auth.userProfile != null) {
      context.read<ProductProvider>().loadFarmerProducts(auth.userProfile!.uid);
      context.read<OrderProvider>().loadFarmerOrders(auth.userProfile!.uid);
    }
  }

  void _setupRealtimeNotifications() {
    final auth = context.read<AuthProvider>();
    if (auth.userProfile == null) return;

    final uid = auth.userProfile!.uid;

    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('farmerId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      
      bool hasNewOrder = snapshot.docChanges.any((change) => change.type == DocumentChangeType.added);

      if (hasNewOrder) {
        context.read<OrderProvider>().loadFarmerOrders(uid);

        if (!_isSilentMode) SoundService.playNotification();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Row(children: [Icon(Icons.notifications_active, color: Colors.white), SizedBox(width: 10), Text("New Order Received!", style: TextStyle(fontWeight: FontWeight.bold))]), backgroundColor: Colors.green[700], behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 4)),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      FarmerHomeTab(isSilent: _isSilentMode, onToggleSilent: () => setState(() => _isSilentMode = !_isSilentMode)),
      const FarmerOrdersTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: Colors.green.shade100,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'My Farm'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddProductScreen()),
              ).then((_) => _loadData()),
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              label: const Text('New Product'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class FarmerHomeTab extends StatelessWidget {
  final bool isSilent;
  final VoidCallback onToggleSilent;

  const FarmerHomeTab({Key? key, required this.isSilent, required this.onToggleSilent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().userProfile;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200.0,
          floating: false,
          pinned: true,
          backgroundColor: const Color(0xFF2E7D32),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF66BB6A)])),
              child: const EarningsSummaryCard(), 
            ),
          ),
          actions: [
            IconButton(icon: Icon(isSilent ? Icons.notifications_off : Icons.notifications_active), color: Colors.white, tooltip: isSilent ? "Unmute Alerts" : "Mute Alerts", onPressed: onToggleSilent),
            PopupMenuButton<String>(
              offset: const Offset(0, 50),
              child: Container(margin: const EdgeInsets.only(right: 16, left: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white30)), child: Row(children: [const Icon(Icons.person, size: 18, color: Colors.white), const SizedBox(width: 8), Text(user?.name.split(' ')[0] ?? 'Farmer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const Icon(Icons.arrow_drop_down, color: Colors.white70)])),
              onSelected: (value) { if (value == 'logout') context.read<AuthProvider>().signOut(); },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(enabled: false, child: Text("Signed in as ${user?.name}", style: const TextStyle(fontSize: 12, color: Colors.grey))),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 10), Text('Logout', style: TextStyle(color: Colors.red))])),
              ],
            ),
          ],
        ),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16.0), child: Row(children: [Text("My Inventory", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), const Spacer(), const Icon(Icons.sort, color: Colors.grey)]))),
        const FarmerProductList(),
      ],
    );
  }
}

class EarningsSummaryCard extends StatelessWidget {
  const EarningsSummaryCard({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        double totalEarnings = 0;
        int pendingOrders = 0;
        for (var order in provider.orders) {
          if (order.status == OrderStatus.delivered) totalEarnings += order.totalPrice;
          else if (order.status == OrderStatus.pending) pendingOrders++;
        }
        return SafeArea(
          child: Padding(padding: const EdgeInsets.all(24.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              FadeInDown(child: const Text("Total Revenue", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500))),
              const SizedBox(height: 8),
              FadeInDown(delay: const Duration(milliseconds: 200), child: Text(NumberFormat.currency(symbol: 'KES ').format(totalEarnings), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))),
              const SizedBox(height: 16),
              FadeInUp(delay: const Duration(milliseconds: 400), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.notifications_active, color: Colors.white, size: 16), const SizedBox(width: 8), Text("$pendingOrders Pending Orders", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))),
            ])),
        );
      },
    );
  }
}

class FarmerProductList extends StatelessWidget {
  const FarmerProductList({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.products.isEmpty) return SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.eco_outlined, size: 60, color: Colors.grey[300]), const SizedBox(height: 16), const Text("No products listed yet.")])));
        return SliverList(delegate: SliverChildBuilderDelegate((context, index) {
          final product = provider.products[index];
          final bool isLowStock = (product.quantity ?? 0) < 10;
          final bool isOutOfStock = (product.quantity ?? 0) <= 0;
          return FadeInUp(duration: const Duration(milliseconds: 500), delay: Duration(milliseconds: index * 50), child: Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]), child: ListTile(contentPadding: const EdgeInsets.all(12), leading: ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(width: 70, height: 70, color: Colors.grey[100], child: product.imageUrls.isNotEmpty ? Image.network(product.imageUrls.first, fit: BoxFit.cover) : const Icon(Icons.agriculture, color: Colors.green))), title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 4), Text('\$${product.pricePerUnit} / ${product.unit.toString().split('.').last}'), const SizedBox(height: 6), Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: isOutOfStock ? Colors.red[50] : (isLowStock ? Colors.orange[50] : Colors.green[50]), borderRadius: BorderRadius.circular(6), border: Border.all(color: isOutOfStock ? Colors.red[200]! : (isLowStock ? Colors.orange[200]! : Colors.green[200]!))), child: Text(isOutOfStock ? "Out of Stock" : "Stock: ${product.quantity?.toInt()}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isOutOfStock ? Colors.red : (isLowStock ? Colors.orange : Colors.green))))])]), trailing: IconButton(icon: const CircleAvatar(backgroundColor: Colors.blue, radius: 18, child: Icon(Icons.edit, size: 18, color: Colors.white)), onPressed: () => _showEditStockDialog(context, product)))));
        }, childCount: provider.products.length));
      },
    );
  }
  void _showEditStockDialog(BuildContext context, Product product) {
    final qtyController = TextEditingController(text: product.quantity?.toStringAsFixed(0));
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text('Update ${product.name}'), content: TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'New Stock Quantity', border: OutlineInputBorder())), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () async { final newQty = double.tryParse(qtyController.text); if (newQty != null) { await context.read<ProductProvider>().updateProductStock(product.id!, newQty); if (context.mounted) Navigator.pop(ctx); } }, child: const Text('Save'))]));
  }
}

class FarmerOrdersTab extends StatelessWidget {
  const FarmerOrdersTab({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(appBar: AppBar(title: const Text('Manage Orders'), backgroundColor: Colors.white, surfaceTintColor: Colors.white, bottom: const TabBar(indicatorColor: Color(0xFF2E7D32), labelColor: Color(0xFF2E7D32), tabs: [Tab(text: 'New Requests'), Tab(text: 'History')])), body: const TabBarView(children: [OrdersList(statusFilter: OrderStatus.pending), OrdersList(isHistory: true)])));
  }
}

class OrdersList extends StatelessWidget {
  final OrderStatus? statusFilter;
  final bool isHistory;
  const OrdersList({Key? key, this.statusFilter, this.isHistory = false}) : super(key: key);
  Future<void> _makePhoneCall(String phoneNumber) async { final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber); if (await canLaunchUrl(launchUri)) await launchUrl(launchUri); }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        final orders = provider.orders.where((order) { if (isHistory) return order.status != OrderStatus.pending; return order.status == statusFilter; }).toList();
        if (orders.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isHistory ? Icons.history : Icons.inbox, size: 60, color: Colors.grey[300]), const SizedBox(height: 16), Text(isHistory ? "No order history" : "No pending requests")]));
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: orders.length, itemBuilder: (context, i) {
            final order = orders[i];
            final bool isDelivery = order.deliveryPersonId != 'SELF_PICKUP';
            return Card(elevation: 2, margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), color: Colors.white, child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(DateFormat('MMM d, h:mm a').format(order.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 12))]),
              const Divider(),
              Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.shopping_bag, color: Colors.green)), const SizedBox(width: 16), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${order.quantity} x ${order.productName}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)), Text("Total: KES ${order.totalPrice.toStringAsFixed(0)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))])]),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isDelivery ? Colors.blue[50] : Colors.orange[50], borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(isDelivery ? Icons.local_shipping : Icons.store, size: 16, color: isDelivery ? Colors.blue : Colors.orange), const SizedBox(width: 8), Text(isDelivery ? "Delivery Requested" : "Customer Pick-up", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDelivery ? Colors.blue[800] : Colors.orange[800]))])),
              if (order.status == OrderStatus.pending) ...[const SizedBox(height: 16), Row(children: [IconButton.filledTonal(onPressed: () => _makePhoneCall(order.customerPhone), icon: const Icon(Icons.call)), const SizedBox(width: 8), Expanded(child: ElevatedButton(onPressed: () => _acceptOrder(context, order), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Accept & Prepare")))])] else ...[const SizedBox(height: 8), Align(alignment: Alignment.centerRight, child: Text("Status: ${order.status.toString().split('.').last.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))]
            ])));
        });
      },
    );
  }
  Future<void> _acceptOrder(BuildContext context, Order order) async {
    final error = await context.read<OrderProvider>().updateOrderStatus(order.id!, OrderStatus.accepted);
    if (error != null && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    else if (context.mounted) { final auth = context.read<AuthProvider>(); context.read<OrderProvider>().loadFarmerOrders(auth.userProfile!.uid); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Accepted!'))); }
  }
}