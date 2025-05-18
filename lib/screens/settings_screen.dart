import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _devicePasswordController = TextEditingController();

  bool _isEditing = false;
  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  bool _useBiometrics = false;
  bool _biometricsAvailable = false;
  String? _storedEmail;
  String? _storedPassword;
  bool _showDevicePasswordField = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();
    setState(() {
      _biometricsAvailable = canCheck && isDeviceSupported;
    });
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storedEmail = prefs.getString('email');
      _storedPassword = prefs.getString('password');
      _useBiometrics = prefs.getBool('use_biometrics') ?? false;
      if (_storedEmail != null) {
        _emailController.text = _storedEmail!;
      }
    });
  }

  Future<bool> _authenticate() async {
    try {
      if (_useBiometrics && _biometricsAvailable) {
        return await _localAuth.authenticate(
          localizedReason: 'Authenticate to change credentials',
          options: const AuthenticationOptions(
            biometricOnly: true,
            useErrorDialogs: true,
            stickyAuth: true,
          ),
        );
      } else {
        // Show device password field
        setState(() {
          _showDevicePasswordField = true;
        });
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveCredentials() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
      await prefs.setBool('use_biometrics', _useBiometrics);
      setState(() {
        _storedEmail = _emailController.text;
        _storedPassword = _passwordController.text;
        _isEditing = false;
      });
      _showSuccessSnackBar('Credentials saved successfully');
    }
  }

  Future<void> _updateCredentials() async {
    if (_formKey.currentState!.validate()) {
      // Verify device password if shown
      if (_showDevicePasswordField) {
        if (_devicePasswordController.text != _storedPassword) {
          _showErrorSnackBar('Incorrect device password');
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', _newEmailController.text);
      await prefs.setString('password', _newPasswordController.text);
      setState(() {
        _storedEmail = _newEmailController.text;
        _storedPassword = _newPasswordController.text;
        _emailController.text = _newEmailController.text;
        _isEditing = false;
        _showDevicePasswordField = false;
        _newEmailController.clear();
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _devicePasswordController.clear();
      });
      _showSuccessSnackBar('Credentials updated successfully');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.blue[600],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.red[600],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _newEmailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _devicePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Security Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.blue[100]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Security Settings Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security Options',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 15),
                          if (_biometricsAvailable)
                            SwitchListTile(
                              title: Text(
                                'Use Biometric Authentication',
                                style: TextStyle(
                                  color: Colors.blue[800],
                                ),
                              ),
                              subtitle: Text(
                                'Require fingerprint/face ID for changes',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                ),
                              ),
                              value: _useBiometrics,
                              onChanged: (value) async {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setBool('use_biometrics', value);
                                setState(() {
                                  _useBiometrics = value;
                                });
                              },
                              activeColor: Colors.blue[600],
                              secondary: Icon(
                                Icons.fingerprint,
                                color: Colors.blue[600],
                              ),
                            ),
                          const Divider(height: 20),
                          ListTile(
                            leading: Icon(
                              Icons.security,
                              color: Colors.blue[600],
                            ),
                            title: Text(
                              'Change Security Settings',
                              style: TextStyle(
                                color: Colors.blue[800],
                              ),
                            ),
                            subtitle: Text(
                              'Update your authentication preferences',
                              style: TextStyle(
                                color: Colors.blue[600],
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // Would navigate to more detailed security settings
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Current account display
                  if (_storedEmail != null && !_isEditing)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildAccountInfoRow(
                              Icons.email_outlined,
                              'Email',
                              _storedEmail!,
                            ),
                            const SizedBox(height: 15),
                            _buildAccountInfoRow(
                              Icons.lock_outline,
                              'Password',
                              '••••••••',
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final authenticated = await _authenticate();
                                  if (authenticated || !_useBiometrics) {
                                    setState(() {
                                      _isEditing = true;
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Update Credentials',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Credentials update form
                  if (_isEditing && _storedEmail != null) ...[
                    const SizedBox(height: 20),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              'Update Credentials',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_showDevicePasswordField)
                              Column(
                                children: [
                                  TextFormField(
                                    controller: _devicePasswordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: 'Device Password',
                                      labelStyle: TextStyle(color: Colors.blue[800]),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.blue[400]!),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.blue[400]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.blue[600]!),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.phone_android,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your device password';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            _buildAuthTextField(
                              controller: _newEmailController,
                              label: 'New Email',
                              icon: Icons.email_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a new email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildAuthTextField(
                              controller: _newPasswordController,
                              label: 'New Password',
                              icon: Icons.lock_outline,
                              obscureText: _obscureNewPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNewPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.blue[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureNewPassword = !_obscureNewPassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a new password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _updateCredentials,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[600],
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Update',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = false;
                                        _showDevicePasswordField = false;
                                        _newEmailController.clear();
                                        _newPasswordController.clear();
                                        _devicePasswordController.clear();
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: BorderSide(color: Colors.blue[600]!),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.blue[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Initial setup form
                  if (_storedEmail == null)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              'Setup Your Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildAuthTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildAuthTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.blue[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            if (_biometricsAvailable) ...[
                              const SizedBox(height: 16),
                              SwitchListTile(
                                title: Text(
                                  'Enable Biometric Authentication',
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                  ),
                                ),
                                value: _useBiometrics,
                                onChanged: (value) {
                                  setState(() {
                                    _useBiometrics = value;
                                  });
                                },
                                activeColor: Colors.blue[600],
                                secondary: Icon(
                                  Icons.fingerprint,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                            const SizedBox(height: 25),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveCredentials,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Text(
                                  'Save Credentials',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.blue[600],
          size: 24,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.blue[800],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blue[800]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[600]!),
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.blue[600],
        ),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}