import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import 'change_password_screen.dart';
import 'package:image_picker/image_picker.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  void _showPhotoPicker(BuildContext context) {
    final auth = Get.find<AuthController>();
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
              "Change Profile Photo",
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
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.camera, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    await auth.updateAvatar(bytes, image.name);
                  }
                } catch (e) {
                  Get.snackbar("Error", "Could not pick image: $e");
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: context.primaryNav),
              title: Text("Choose from Gallery", style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    await auth.updateAvatar(bytes, image.name);
                  }
                } catch (e) {
                  Get.snackbar("Error", "Could not pick image: $e");
                }
              },
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final countryCtrl = TextEditingController(text: user?.country ?? '');

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: context.surfaceBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.all(24.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Edit Profile Information",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: context.primaryNav,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                "Display Name",
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: context.textSecondaryColor),
              ),
              SizedBox(height: 6.h),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: context.textPrimaryColor, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: "Enter full name",
                  filled: true,
                  fillColor: context.cardBg,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                "Phone Number",
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: context.textSecondaryColor),
              ),
              SizedBox(height: 6.h),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: context.textPrimaryColor, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: "+1 555-0199",
                  filled: true,
                  fillColor: context.cardBg,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                "Country / Region",
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: context.textSecondaryColor),
              ),
              SizedBox(height: 6.h),
              TextField(
                controller: countryCtrl,
                style: TextStyle(color: context.textPrimaryColor, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: "e.g. United States, Switzerland",
                  filled: true,
                  fillColor: context.cardBg,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () async {
                    final dName = nameCtrl.text.trim();
                    final dPhone = phoneCtrl.text.trim();
                    final dCountry = countryCtrl.text.trim();
                    debugPrint("📱 [ACCOUNT SETTINGS] User clicked Save Profile -> Name: '$dName', Phone: '$dPhone', Country: '$dCountry'");
                    Get.back();
                    await auth.updateProfile(
                      displayName: dName,
                      phone: dPhone,
                      country: dCountry,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryNav,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showDeleteAccountConfirm(BuildContext context) {
    final auth = Get.find<AuthController>();
    Get.dialog(
      AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          "Delete Account",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: const Color(0xFFEF4444),
            fontSize: 18.sp,
          ),
        ),
        content: Text(
          "Are you sure you want to permanently delete your account? All active sessions, preferences, and stored profile data will be permanently wiped.",
          style: TextStyle(fontSize: 13.5.sp, color: context.textSecondaryColor, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel", style: TextStyle(color: context.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              debugPrint("📱 [ACCOUNT SETTINGS] User confirmed account deletion.");
              Get.back();
              auth.deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: const Text("Delete Permanently"),
          ),
        ],
      ),
    );
  }

  void _showInfoBottomSheet(BuildContext context, String title) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: context.surfaceBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: context.primaryNav),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              "This is the official $title section for The Watch Box precision marketplace.",
              style: TextStyle(fontSize: 14.sp, color: context.textSecondaryColor, height: 1.5),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Account Settings",
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
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        children: [
          // 1. Live Profile Summary Card
          Obx(() {
            final user = auth.currentUser.value;
            final name = user?.name.isNotEmpty == true ? user!.name : (user != null ? "Collector" : "Not signed in");
            final email = user?.email.isNotEmpty == true ? user!.email : "Not specified";
            final phone = user?.phone?.isNotEmpty == true ? user!.phone! : "Not specified";
            final country = user?.country?.isNotEmpty == true ? user!.country! : "Not specified";

            return Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Profile Details",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: context.primaryNav,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showEditProfileSheet(context),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text("Edit"),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0064D2),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Center(
                    child: GestureDetector(
                      onTap: () => _showPhotoPicker(context),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 76.w,
                            height: 76.h,
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: context.primaryNav, width: 2),
                            ),
                            child: ClipOval(
                              child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                                  ? Image.network(
                                      user.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Center(
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : "U",
                                          style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold, color: context.primaryNav),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : "U",
                                        style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold, color: context.primaryNav),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(5.w),
                              decoration: BoxDecoration(
                                color: context.primaryNav,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  _buildProfileRow(context, "Name", name),
                  SizedBox(height: 8.h),
                  _buildProfileRow(context, "Email", email),
                  SizedBox(height: 8.h),
                  _buildProfileRow(context, "Phone", phone),
                  SizedBox(height: 8.h),
                  _buildProfileRow(context, "Country", country),
                ],
              ),
            );
          }),

          SizedBox(height: 18.h),

          // 2. Settings Options Card
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: context.borderColor),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16.r),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded, color: Color(0xFF07274C)),
                    title: Text(
                      "Change Password",
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: context.textPrimaryColor),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: context.textSecondaryColor),
                    onTap: () => Get.to(() => const ChangePasswordScreen()),
                  ),
                  Divider(height: 1, indent: 16.w, endIndent: 16.w),
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: Color(0xFF64748B)),
                    title: Text(
                      "Terms of Services",
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: context.textPrimaryColor),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: context.textSecondaryColor),
                    onTap: () => _showInfoBottomSheet(context, "Terms of Services"),
                  ),
                  Divider(height: 1, indent: 16.w, endIndent: 16.w),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF64748B)),
                    title: Text(
                      "Privacy Policy",
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: context.textPrimaryColor),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: context.textSecondaryColor),
                    onTap: () => _showInfoBottomSheet(context, "Privacy Policy"),
                  ),
                  Divider(height: 1, indent: 16.w, endIndent: 16.w),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B)),
                    title: Text(
                      "About us",
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: context.textPrimaryColor),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: context.textSecondaryColor),
                    onTap: () => _showInfoBottomSheet(context, "About us"),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // 3. Danger Zone: Delete Account
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFFEE2E2)),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16.r),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                title: Text(
                  "Delete Account",
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444)),
                ),
                subtitle: Text(
                  "Permanently remove your account and all data",
                  style: TextStyle(fontSize: 12.sp, color: context.textSecondaryColor),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFEF4444)),
                onTap: () => _showDeleteAccountConfirm(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13.sp, color: context.textSecondaryColor, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13.5.sp, color: context.textPrimaryColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
