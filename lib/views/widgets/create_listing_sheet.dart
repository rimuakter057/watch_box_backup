import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/search_controller.dart';
import '../../core/theme/app_colors.dart';

class CreateListingSheet extends StatefulWidget {
  final VoidCallback? onListingCreated;

  const CreateListingSheet({super.key, this.onListingCreated});

  static Future<void> show(BuildContext context, {VoidCallback? onListingCreated}) {
    return Get.bottomSheet<void>(
      CreateListingSheet(onListingCreated: onListingCreated),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<CreateListingSheet> createState() => _CreateListingSheetState();
}

class _CreateListingSheetState extends State<CreateListingSheet> {
  final WatchSearchController _searchCtrl = Get.find<WatchSearchController>();
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _yearCtrl = TextEditingController(text: DateTime.now().year.toString());
  final _descCtrl = TextEditingController();

  String _selectedCondition = 'Mint';
  String _selectedCurrency = 'USD';

  final List<String> _conditions = ['New', 'Mint', 'Very Good', 'Good', 'Fair'];
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'CHF', 'JPY', 'AED'];

  Uint8List? _imageBytes;
  String? _imageName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _refCtrl.dispose();
    _priceCtrl.dispose();
    _yearCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = file.name;
        });
      }
    } catch (e) {
      debugPrint("❌ [CREATE LISTING] Error picking image: $e");
      Get.snackbar("Image Error", "Could not pick image: $e");
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: context.surfaceBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "Select Watch Photo",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            SizedBox(height: 16.h),
            ListTile(
              leading: Icon(Icons.photo_camera_rounded, color: context.primaryNav),
              title: Text("Take Photo", style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: context.primaryNav),
              title: Text("Choose from Gallery", style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    final double? price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) {
      Get.snackbar("Validation Error", "Please provide a valid price.");
      return;
    }

    final int? year = int.tryParse(_yearCtrl.text.trim());

    setState(() => _isSubmitting = true);
    try {
      final success = await _searchCtrl.createCustomListing(
        title: _titleCtrl.text.trim(),
        brand: _brandCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        referenceNumber: _refCtrl.text.trim().isNotEmpty ? _refCtrl.text.trim() : null,
        price: price,
        currency: _selectedCurrency,
        year: year,
        condition: _selectedCondition,
        description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        imageBytes: _imageBytes,
        imageName: _imageName,
      );

      if (success) {
        if (Get.isBottomSheetOpen == true) {
          Get.back(result: true);
        } else if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }

        widget.onListingCreated?.call();

        Get.snackbar(
          "Success",
          "Listing created successfully.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(
        20.w,
        16.h,
        20.w,
        MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sheet Header
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "List a Timepiece",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: context.primaryNav,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "Directly publish to WatchBox marketplace API",
                        style: TextStyle(fontSize: 11.5.sp, color: context.textSecondaryColor),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // 2. Watch Photo Uploader
              _buildPhotoPicker(context),
              SizedBox(height: 16.h),

              // 3. Listing Title
              Text(
                "Listing Title *",
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: context.textSecondaryColor),
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _titleCtrl,
                style: TextStyle(color: context.textPrimaryColor, fontSize: 13.5.sp),
                decoration: InputDecoration(
                  hintText: "e.g. Rolex Submariner Date 126610LN",
                  hintStyle: TextStyle(color: context.textSecondaryColor.withOpacity(0.5), fontSize: 13.sp),
                  filled: true,
                  fillColor: context.cardBg,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? "Title is required" : null,
              ),
              SizedBox(height: 14.h),

              // 4. Brand & Model
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Brand *",
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: context.textSecondaryColor),
                        ),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _brandCtrl,
                          style: TextStyle(color: context.textPrimaryColor, fontSize: 13.5.sp),
                          decoration: InputDecoration(
                            hintText: "e.g. Rolex",
                            hintStyle: TextStyle(color: context.textSecondaryColor.withOpacity(0.5), fontSize: 13.sp),
                            filled: true,
                            fillColor: context.cardBg,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? "Brand is required" : null,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Model *",
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: context.textSecondaryColor),
                        ),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _modelCtrl,
                          style: TextStyle(color: context.textPrimaryColor, fontSize: 13.5.sp),
                          decoration: InputDecoration(
                            hintText: "e.g. Submariner",
                            hintStyle: TextStyle(color: context.textSecondaryColor.withOpacity(0.5), fontSize: 13.sp),
                            filled: true,
                            fillColor: context.cardBg,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? "Model is required" : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // 5. Reference Number
              Text(
                "Reference Number",
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: context.textSecondaryColor),
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _refCtrl,
                style: TextStyle(color: context.textPrimaryColor, fontSize: 13.5.sp),
                decoration: InputDecoration(
                  hintText: "e.g. 126610LN",
                  hintStyle: TextStyle(color: context.textSecondaryColor.withOpacity(0.5), fontSize: 13.sp),
                  filled: true,
                  fillColor: context.cardBg,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                ),
              ),
              SizedBox(height: 14.h),

              // 6. Price & Currency
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Price *",
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: context.textSecondaryColor),
                        ),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: context.textPrimaryColor, fontSize: 13.5.sp),
                          decoration: InputDecoration(
                            hintText: "e.g. 14250",
                            hintStyle: TextStyle(color: context.textSecondaryColor.withOpacity(0.5), fontSize: 13.sp),
                            filled: true,
                            fillColor: context.cardBg,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return "Price is required";
                            if (double.tryParse(val.trim()) == null) return "Invalid price";
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Currency",
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: context.textSecondaryColor),
                        ),
                        SizedBox(height: 6.h),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCurrency,
                          dropdownColor: context.surfaceBg,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: context.cardBg,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                          ),
                          items: _currencies
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 13.sp, color: context.textPrimaryColor))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCurrency = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // 7. Year & Condition
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Production Year",
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: context.textSecondaryColor),
                        ),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _yearCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: context.textPrimaryColor, fontSize: 13.5.sp),
                          decoration: InputDecoration(
                            hintText: "e.g. 2023",
                            hintStyle: TextStyle(color: context.textSecondaryColor.withOpacity(0.5), fontSize: 13.sp),
                            filled: true,
                            fillColor: context.cardBg,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                          ),
                          validator: (val) {
                            if (val != null && val.trim().isNotEmpty && int.tryParse(val.trim()) == null) {
                              return "Invalid year";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Condition",
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: context.textSecondaryColor),
                        ),
                        SizedBox(height: 6.h),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCondition,
                          dropdownColor: context.surfaceBg,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: context.cardBg,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                          ),
                          items: _conditions
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 13.sp, color: context.textPrimaryColor))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCondition = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // 8. Description
              Text(
                "Description / Included Items",
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: context.textSecondaryColor),
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: TextStyle(color: context.textPrimaryColor, fontSize: 13.sp),
                decoration: InputDecoration(
                  hintText: "e.g. Full set with original box, warranty card, and papers.",
                  hintStyle: TextStyle(color: context.textSecondaryColor.withOpacity(0.5), fontSize: 12.5.sp),
                  filled: true,
                  fillColor: context.cardBg,
                  contentPadding: EdgeInsets.all(12.w),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: context.borderColor)),
                ),
              ),
              SizedBox(height: 20.h),

              // 9. Submit Button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryNav,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submitListing,
                  child: _isSubmitting
                      ? SizedBox(
                          width: 22.w,
                          height: 22.h,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                        )
                      : Text(
                          "Post Listing",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5.sp),
                        ),
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker(BuildContext context) {
    if (_imageBytes != null) {
      return Container(
        height: 120.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: context.borderColor),
        ),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.memory(
                  _imageBytes!,
                  height: 120.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 8.h,
              right: 8.w,
              child: GestureDetector(
                onTap: () => setState(() {
                  _imageBytes = null;
                  _imageName = null;
                }),
                child: Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _showImagePickerSheet,
      child: Container(
        height: 80.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: context.borderColor, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: context.primaryNav, size: 24.sp),
            SizedBox(width: 10.w),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Upload Watch Photo",
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                ),
                Text(
                  "Supports camera or gallery",
                  style: TextStyle(fontSize: 11.sp, color: context.textSecondaryColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
