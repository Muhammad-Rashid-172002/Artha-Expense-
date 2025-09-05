import 'package:expanse_tracker_app/Screens/Auth_moduls/SignInScreen.dart';
import 'package:expanse_tracker_app/Screens/OnboardingScreens/onboardingscreens.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';

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
        setState(() {
          userName = value;
        });
      } else if (field == 'email') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({'email': value});
        await user!.updateEmail(value);
        setState(() {
          userEmail = value;
        });
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
        backgroundColor: Colors.amber.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text("Edit $title", style: const TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              obscureText: isPassword,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: "Enter $title",
                hintStyle: const TextStyle(color: Colors.black54),
              ),
            ),
            if (isPassword) const SizedBox(height: 10),
            if (isPassword)
              TextField(
                controller: confirmController,
                obscureText: true,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: "Confirm Password",
                  hintStyle: TextStyle(color: Colors.black54),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.amber)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
            ),
            child: const Text("Save"),
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
        backgroundColor: Colors.orange.shade700, // Matches Scaffold gradient
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
        backgroundColor: Colors.amber.shade50, // Matches light part of gradient
        titleTextStyle: TextStyle(color: Colors.orange.shade900, fontSize: 18),
        subtitleTextStyle: TextStyle(color: Colors.black54),
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
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to logout?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.amber)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SigninScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Logout failed: $e")));
      }
    }
  }

  void _deleteAccount() async {
    final uid = user?.uid;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          "Delete Account",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to delete your account? This action is permanent.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.green)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete"),
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
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please log in again to delete your account."),
              backgroundColor: Colors.green,
            ),
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
  }

  final LocalAuthentication auth = LocalAuthentication();
  final LocalAuthentication authentication = LocalAuthentication();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Text(
                "Settings",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF37474F), //  BlueGrey
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.orange.shade700,
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 20),
              // Editable Name
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Name"),
                subtitle: Text(userName),
                onTap: () => _showEditDialog("Name", userName, "name"),
              ),
              // Editable Email
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text("Email"),
                subtitle: Text(userEmail),
                onTap: () => _showEditDialog("Email", userEmail, "email"),
              ),
              // Editable Password
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text("Password"),
                subtitle: const Text("********"),
                onTap: () async {
                  try {
                    final bool canCheckBiometrics =
                        await auth.canCheckBiometrics;
                    final bool isDeviceSupported = await auth
                        .isDeviceSupported();

                    if (canCheckBiometrics && isDeviceSupported) {
                      // Biometric OR device passcode authentication
                      final bool authenticated = await auth.authenticate(
                        localizedReason:
                            'Please authenticate to edit your password',
                        options: const AuthenticationOptions(
                          biometricOnly:
                              false, // allow PIN/Pattern/Password as fallback
                          useErrorDialogs: true,
                          stickyAuth: true,
                        ),
                      );

                      if (authenticated) {
                        _showEditDialog(
                          "Password",
                          '',
                          "password",
                          isPassword: true,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Authentication failed'),
                          ),
                        );
                      }
                    } else {
                      // No biometrics available, go directly to password edit
                      _showEditDialog(
                        "Password",
                        '',
                        "password",
                        isPassword: true,
                      );
                    }
                  } catch (e) {
                    debugPrint("Fingerprint auth error: $e");
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    // fallback to password dialog
                    _showEditDialog(
                      "Password",
                      '',
                      "password",
                      isPassword: true,
                    );
                  }
                },
              ),
              // Currency
              ListTile(
                leading: Icon(
                  Icons.attach_money,
                  color: Colors.orange.shade700,
                ),
                title: const Text("Preferred Currency"),
                subtitle: Text('$currencyFlag $selectedCurrency'),
                onTap: _showCurrencyPicker,
              ),
              const SizedBox(height: 30), // Spacer replacement for scroll
              Padding(
                padding: const EdgeInsets.all(20.0),
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
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
