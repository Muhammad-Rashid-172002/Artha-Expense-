import 'package:expanse_tracker_app/Screens/Auth_moduls/SignInScreen.dart';
import 'package:expanse_tracker_app/Screens/OnboardingScreens/onboardingscreens.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';

// ==== COLORS ====
// AppBar
const Color kAppBarColor = Color(0xFF1565C0); // Deep Blue
const Color kAppBarTextColor = Colors.white; // White text

// Balance Card
const Color kBalanceCardColor = Color(0xFFFFD700); // Gold
const Color kBalanceCardTextColor = Colors.black; // Black text on gold

// Cards / ListTile
const Color kCardColor = Colors.white;
const Color kCardTextColor = Colors.black87;

// Text
const Color kHeadingTextColor = Color(0xFF0D47A1); // Dark Blue heading
const Color kSubtitleTextColor = Colors.black87;
const Color kBodyTextColor = Colors.black54;
const Color kFadedTextColor = Colors.grey;

// Buttons
const Color kButtonPrimary = Color(0xFF1565C0); // Deep Blue
const Color kButtonPrimaryText = Colors.white;
const Color kButtonSecondaryBorder = Color(0xFFFFD700); // Gold
const Color kButtonSecondaryText = Color(0xFF1565C0);
const Color kButtonDisabled = Color(0xFFBDBDBD);
const Color kButtonDisabledText = Color(0xFF757575);

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully.')),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$field updated successfully.')));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please log in again to update $field.")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Unexpected error: $e")));
    }
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
        title: Text("Edit $title", style: TextStyle(color: kHeadingTextColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              obscureText: isPassword,
              style: TextStyle(color: kBodyTextColor),
              decoration: InputDecoration(
                hintText: "Enter $title",
                hintStyle: TextStyle(color: kSubtitleTextColor),
              ),
            ),
            if (isPassword) const SizedBox(height: 10),
            if (isPassword)
              TextField(
                controller: confirmController,
                obscureText: true,
                style: TextStyle(color: kBodyTextColor),
                decoration: InputDecoration(
                  hintText: "Confirm Password",
                  hintStyle: TextStyle(color: kSubtitleTextColor),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: kButtonSecondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (isPassword && controller.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Passwords do not match!")),
                );
                return;
              }
              _updateField(field, controller.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kButtonPrimary),
            child: const Text(
              "Save",
              style: TextStyle(color: kButtonPrimaryText),
            ),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Currency updated to ${currency.code}'),
        backgroundColor: kButtonPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCurrencyPicker() {
    showCurrencyPicker(
      context: context,
      showFlag: true,
      showSearchField: true,
      theme: CurrencyPickerThemeData(
        backgroundColor: kCardColor,
        titleTextStyle: TextStyle(color: kButtonPrimary, fontSize: 18),
        subtitleTextStyle: TextStyle(color: kSubtitleTextColor),
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
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: TextStyle(color: kButtonSecondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SigninScreen()),
      );
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
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure you want to delete your account? This action is permanent.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: Colors.green)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
        await user!.delete();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnboardingScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account successfully deleted."),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (iconColor ?? kButtonPrimary).withOpacity(0.1),
          child: Icon(icon, color: iconColor ?? kButtonPrimary),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: kCardTextColor),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: kBodyTextColor)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      kAppBarColor,
                      kBalanceCardColor,
                    ], // Deep Blue to Gold
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
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: kButtonPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        color: kAppBarTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildCardTile(
                icon: Icons.person,
                title: "Name",
                subtitle: userName,
                onTap: () => _showEditDialog("Name", userName, "name"),
              ),
              _buildCardTile(
                icon: Icons.email,
                title: "Email",
                subtitle: userEmail,
                onTap: () => _showEditDialog("Email", userEmail, "email"),
              ),
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
                    _showEditDialog(
                      "Password",
                      '',
                      "password",
                      isPassword: true,
                    );
                  }
                },
              ),
              _buildCardTile(
                icon: Icons.attach_money,
                iconColor: kButtonPrimary,
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _deleteAccount,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text("Delete Account"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBalanceCardColor,
                        foregroundColor: kBalanceCardTextColor,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
