import 'package:expanse_tracker_app/Screens/Auth_moduls/SignInScreen.dart';
import 'package:expanse_tracker_app/Screens/OnboardingScreens/onboardingscreens.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';

// ==== Dark Theme Colors ====
const Color kPrimaryDark1 = Color(0xFF1C1F26);
const Color kPrimaryDark2 = Color(0xFF2A2F3A);
const Color kPrimaryDark3 = Color(0xFF383C4C);
const Color kAccent = Color(0xFF00E676); // Accent for icons/buttons
const Color kCardColor = Color(0xFF2A2F3A);
const Color kCardTextColor = Colors.white;
const Color kBodyTextColor = Colors.white70;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final user = FirebaseAuth.instance.currentUser;
  String userName = '';
  String userEmail = '';
  String selectedCurrency = 'USD';
  String currencySymbol = '';
  String currencyFlag = '';

  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    if (user == null) return;
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      setState(() {
        userName = snapshot['name'] ?? 'No Name';
        userEmail = snapshot['email'] ?? user!.email ?? 'No Email';
        selectedCurrency = snapshot['currency'] ?? 'USD';
        currencySymbol = snapshot['currencySymbol'] ?? '';
        currencyFlag = snapshot['currencyFlag'] ?? '';
      });
    } catch (e) {
      debugPrint("Error loading user info: $e");
    }
  }

  Future<void> _updateField(String field, String value) async {
    if (user == null) return;
    try {
      if (field == 'name') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({'name': value});
        setState(() => userName = value);
      } else if (field == 'email') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({'email': value});
        await user!.updateEmail(value);
        setState(() => userEmail = value);
      } else if (field == 'password') {
        await user!.updatePassword(value);
        _showSnackbar('Password updated successfully.');
        return;
      }

      _showSnackbar('$field updated successfully.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showSnackbar("Please log in again to update $field.");
      } else {
        _showSnackbar("Error: ${e.message}");
      }
    } catch (e) {
      _showSnackbar("Unexpected error: $e");
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        backgroundColor: kAccent,
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  void _showEditDialog(
    String title,
    String currentValue,
    String field, {
    bool isPassword = false,
  }) {
    final controller = TextEditingController(text: currentValue);
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.poppins(color: kCardTextColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              obscureText: isPassword,
              style: GoogleFonts.poppins(color: kBodyTextColor),
              decoration: InputDecoration(
                hintText: "Enter $title",
                hintStyle: GoogleFonts.poppins(color: kBodyTextColor.withOpacity(0.6)),
              ),
            ),
            if (isPassword) const SizedBox(height: 10),
            if (isPassword)
              TextField(
                controller: confirmController,
                obscureText: true,
                style: GoogleFonts.poppins(color: kBodyTextColor),
                decoration: InputDecoration(
                  hintText: "Confirm Password",
                  hintStyle: GoogleFonts.poppins(color: kBodyTextColor.withOpacity(0.6)),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins(color: kAccent)),
          ),
          ElevatedButton(
            onPressed: () {
              if (isPassword && controller.text != confirmController.text) {
                _showSnackbar("Passwords do not match!");
                return;
              }
              _updateField(field, controller.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kAccent),
            child: Text("Save", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCurrency(Currency currency) async {
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'currency': currency.code,
      'currencySymbol': currency.symbol,
      'currencyFlag': currency.flag ?? '',
    });

    setState(() {
      selectedCurrency = currency.code;
      currencySymbol = currency.symbol;
      currencyFlag = currency.flag ?? '';
    });

    _showSnackbar('Currency updated to ${currency.code}');
  }

  void _showCurrencyPicker() {
    showCurrencyPicker(
      context: context,
      showFlag: true,
      showSearchField: true,
      theme: CurrencyPickerThemeData(
        backgroundColor: kCardColor,
        titleTextStyle: GoogleFonts.poppins(color: kAccent, fontSize: 18),
        subtitleTextStyle: GoogleFonts.poppins(color: kBodyTextColor),
        bottomSheetHeight: 400,
      ),
      onSelect: (Currency currency) {
        _updateCurrency(currency);
      },
    );
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Logout", style: GoogleFonts.poppins(color: kCardTextColor)),
        content: Text("Are you sure you want to logout?", style: GoogleFonts.poppins(color: kBodyTextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: GoogleFonts.poppins(color: kAccent)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text("Logout", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SigninScreen()));
    }
  }

  void _deleteAccount() async {
    final uid = user?.uid;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Account", style: GoogleFonts.poppins(color: kCardTextColor)),
        content: Text(
          "Are you sure you want to delete your account? This action is permanent.",
          style: GoogleFonts.poppins(color: kBodyTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.green)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text("Delete", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
        await user!.delete();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
        _showSnackbar("Account successfully deleted.");
      } catch (e) {
        _showSnackbar("Error: $e");
      }
    }
  }

  Widget _buildCardTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Card(
      color: kCardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (iconColor ?? kAccent).withOpacity(0.1),
          child: Icon(icon, color: iconColor ?? kAccent),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: kCardTextColor)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(color: kBodyTextColor)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: kCardTextColor),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryDark1,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimaryDark2, kPrimaryDark3],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: kCardColor,
                      child: Icon(Icons.person, size: 50, color: kAccent),
                    ),
                    const SizedBox(height: 12),
                    Text(userName, style: GoogleFonts.poppins(color: kCardTextColor, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(userEmail, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildCardTile(icon: Icons.person, title: "Name", subtitle: userName, onTap: () => _showEditDialog("Name", userName, "name")),
              _buildCardTile(icon: Icons.email, title: "Email", subtitle: userEmail, onTap: () => _showEditDialog("Email", userEmail, "email")),
              _buildCardTile(
                icon: Icons.lock,
                title: "Password",
                subtitle: "********",
                onTap: () async {
                  bool authenticated = false;
                  try {
                    authenticated = await auth.authenticate(
                      localizedReason: 'Authenticate to edit password',
                      options: const AuthenticationOptions(
                        biometricOnly: false,
                        useErrorDialogs: true,
                        stickyAuth: true,
                      ),
                    );
                  } catch (_) {}

                  if (authenticated) {
                    _showEditDialog("Password", '', "password", isPassword: true);
                  }
                },
              ),
              _buildCardTile(
                icon: Icons.attach_money,
                iconColor: kAccent,
                title: "Currency",
                subtitle: '$currencyFlag $selectedCurrency',
                onTap: _showCurrencyPicker,
              ),

              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _deleteAccount,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text("Delete Account"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryDark2,
                        foregroundColor: kAccent,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
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
