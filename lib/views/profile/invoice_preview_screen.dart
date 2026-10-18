import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../models/watch_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../controllers/auth_controller.dart';

class InvoicePreviewScreen extends StatefulWidget {
  final WatchModel watch;
  final Map<String, dynamic> invoiceData;

  const InvoicePreviewScreen({
    super.key,
    required this.watch,
    required this.invoiceData,
  });

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  bool _isExporting = false;

  void _simulateExport(String type) {
    setState(() {
      _isExporting = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        Get.snackbar(
          "Success",
          "Invoice ${type == 'print' ? 'sent to printer' : 'downloaded as PDF'} successfully!",
          backgroundColor: context.primaryNav,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final sellerName = widget.invoiceData['seller_name'] ?? widget.invoiceData['sellerName'] ?? auth.currentUser.value?.name ?? 'Dealer';
    final sellerEmail = widget.invoiceData['seller_email'] ?? widget.invoiceData['sellerEmail'] ?? auth.currentUser.value?.email ?? '';
    final buyerName = widget.invoiceData['buyer_name'] ?? widget.invoiceData['buyerName'] ?? 'Customer';
    final buyerEmail = widget.invoiceData['buyer_email'] ?? widget.invoiceData['buyerEmail'] ?? '';
    final invoiceNo = widget.invoiceData['invoice_no'] ?? widget.invoiceData['invoiceNo'] ?? 'INV-${widget.watch.id ?? DateTime.now().millisecondsSinceEpoch % 1000000}';
    final date = widget.invoiceData['date'] ?? widget.invoiceData['createdAt'] ?? DateTime.now().toIso8601String().split('T').first;
    final price = widget.invoiceData['price'] ?? widget.watch.price;

    final formattedPrice = '\$${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    )}';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Standard Invoice",
          style: TextStyle(color: context.primaryNav, fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.primaryNav),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 100.h),
            physics: const BouncingScrollPhysics(),
            child: Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: context.borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: context.isDarkTheme
                        ? Colors.white.withValues(alpha: 0.01)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invoice Header Dial Accent
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 24.w),
                    decoration: BoxDecoration(
                      color: context.isDarkTheme ? AppColors.surfaceDark : const Color(0xFF002952),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "THE WATCH BOX",
                              style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.5),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(color: const Color(0xFF10B981), width: 1),
                              ),
                              child: Text(
                                "PAID",
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: const Color(0xFF34D399),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "INVOICE NUMBER",
                                  style: TextStyle(fontSize: 9.sp, color: Colors.white54, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  invoiceNo,
                                  style: TextStyle(fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "DATE OF ISSUE",
                                  style: TextStyle(fontSize: 9.sp, color: Colors.white54, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  date,
                                  style: TextStyle(fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  // Billing Parties details
                  Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "FROM (SELLER)",
                                    style: TextStyle(fontSize: 9.sp, color: context.textSecondaryColor, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    sellerName,
                                    style: TextStyle(fontSize: 14.sp, color: context.textPrimaryColor, fontWeight: FontWeight.w900),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    sellerEmail,
                                    style: TextStyle(fontSize: 12.sp, color: context.textSecondaryColor),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "TO (BUYER)",
                                    style: TextStyle(fontSize: 9.sp, color: context.textSecondaryColor, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    buyerName,
                                    style: TextStyle(fontSize: 14.sp, color: context.textPrimaryColor, fontWeight: FontWeight.w900),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    buyerEmail,
                                    style: TextStyle(fontSize: 12.sp, color: context.textSecondaryColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        Divider(height: 1, color: context.borderColor),
                        SizedBox(height: 24.h),

                        // Item Table Header
                        Text(
                          "PURCHASED SPECIFICATION",
                          style: TextStyle(fontSize: 9.sp, color: context.textSecondaryColor, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        SizedBox(height: 12.h),

                        // Watch description Row Card
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: context.chipBg,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 64.w,
                                height: 64.h,
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: context.surfaceBg,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: context.borderColor),
                                ),
                                child: widget.watch.imageUrl.startsWith('http')
                                    ? Image.network(
                                        widget.watch.imageUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => Image.asset(
                                          'assets/images/8.png',
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                    : Image.asset(widget.watch.imageUrl, fit: BoxFit.contain),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.watch.brand.toUpperCase(),
                                      style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w900, color: context.textSecondaryColor),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      widget.watch.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      "Year: ${widget.watch.year} • Condition: ${widget.watch.condition}",
                                      style: TextStyle(fontSize: 11.sp, color: context.textSecondaryColor),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),

                        SizedBox(height: 24.h),
                        Divider(height: 1, color: context.borderColor),
                        SizedBox(height: 24.h),

                        // Pricing calculation block
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Subtotal",
                              style: TextStyle(fontSize: 13.sp, color: context.textSecondaryColor),
                            ),
                            Text(
                              formattedPrice,
                              style: TextStyle(fontSize: 13.sp, color: context.textPrimaryColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "VAT / Sales Tax (0%)",
                              style: TextStyle(fontSize: 13.sp, color: context.textSecondaryColor),
                            ),
                            Text(
                              "\$0",
                              style: TextStyle(fontSize: 13.sp, color: context.textPrimaryColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Divider(height: 1, color: context.borderColor),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total Amount",
                              style: TextStyle(fontSize: 15.sp, color: context.textPrimaryColor, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              formattedPrice,
                              style: TextStyle(fontSize: 20.sp, color: const Color(0xFFCA8A04), fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Mock Action Drawer Bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: context.surfaceBg,
                boxShadow: [
                  BoxShadow(
                    color: context.isDarkTheme
                        ? Colors.white.withValues(alpha: 0.02)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide(color: context.primaryNav, width: 1.5),
                      ),
                      onPressed: () => _simulateExport('print'),
                      icon: Icon(Icons.print_rounded, color: context.primaryNav),
                      label: Text(
                        "Print Invoice",
                        style: TextStyle(color: context.primaryNav, fontWeight: FontWeight.bold, fontSize: 13.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryNav,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        elevation: 0,
                      ),
                      onPressed: () => _simulateExport('download'),
                      icon: const Icon(Icons.download_rounded),
                      label: Text("Download PDF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading Overlay during print/download simulation
          if (_isExporting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(color: context.surfaceBg, borderRadius: BorderRadius.circular(16.r)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(context.primaryNav)),
                        SizedBox(height: 16.h),
                        Text(
                          "Compiling PDF metadata...",
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: context.primaryNav),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
