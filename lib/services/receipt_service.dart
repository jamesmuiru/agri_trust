import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class ReceiptService {
  static Future<void> generateAndPrint(Order order) async {
    final pdf = pw.Document();
    
    // Load a logo if you have one, otherwise use icon
    // final image = await imageFromAssetBundle('assets/logo.png');

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("AgriConnect", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                  pw.Text("RECEIPT", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ]
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),

              // Order Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Order ID: ${order.id?.substring(0, 8) ?? 'N/A'}"),
                      pw.Text("Date: ${DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt)}"),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Customer: ${order.customerName}"),
                      pw.Text("Farmer: ${order.farmerName}"),
                    ]
                  ),
                ]
              ),
              pw.SizedBox(height: 30),

              // Product Table
              pw.Table.fromTextArray(
                context: context,
                border: null,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
                headers: ['Product', 'Quantity', 'Unit Price', 'Total'],
                data: [
                  [
                    order.productName,
                    '${order.quantity}',
                    'KES ${order.totalPrice / order.quantity}',
                    'KES ${order.totalPrice}'
                  ]
                ]
              ),
              pw.Divider(),
              
              // Totals
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Total Paid: KES ${order.totalPrice}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    pw.SizedBox(height: 5),
                    pw.Text("Payment Ref: ${order.paymentRef ?? 'N/A'}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  ]
                )
              ),
              
              pw.Spacer(),
              pw.Divider(),
              pw.Center(child: pw.Text("Thank you for supporting local farmers!", style: const pw.TextStyle(color: PdfColors.grey))),
            ],
          );
        },
      ),
    );

    // Open the PDF preview/print dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}