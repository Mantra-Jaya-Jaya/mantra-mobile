import 'package:flutter/material.dart';

import '../../core/widgets/base_header_widget.dart';
import 'widgets/order_tracking_section.dart';

class OrderTrackingPage extends StatefulWidget {
  final String noPesanan;

  const OrderTrackingPage({super.key, required this.noPesanan});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final GlobalKey<OrderTrackingSectionState> _trackingSectionKey =
      GlobalKey<OrderTrackingSectionState>();

  Future<void> _refresh() async {
    await (_trackingSectionKey.currentState?.refresh() ?? Future.value());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: BaseHeaderWidget(
        title: 'Lacak Pesanan',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFFAD510D),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: OrderTrackingSection(
            key: _trackingSectionKey,
            noPesanan: widget.noPesanan,
          ),
        ),
      ),
    );
  }
}
