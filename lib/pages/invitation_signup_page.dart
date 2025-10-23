import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class InvitationSignUpPage extends StatefulWidget {
  const InvitationSignUpPage({super.key});

  @override
  State<InvitationSignUpPage> createState() => _InvitationSignUpPageState();
}

class _InvitationSignUpPageState extends State<InvitationSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _invitationCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _insuranceProviderController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _ibanController = TextEditingController();
  final _taxIdController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _invitationData;
  bool _isLoading = false;
  bool _codeValidated = false;
  String _insuranceType = 'Public';
  DateTime _dateOfBirth = DateTime.now().subtract(
    const Duration(days: 6570),
  ); // 18 years ago

  @override
  void dispose() {
    _invitationCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _insuranceProviderController.dispose();
    _insuranceNumberController.dispose();
    _bankNameController.dispose();
    _ibanController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  Future<void> _validateInvitationCode() async {
    if (_invitationCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter invitation code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = await _firestoreService.validateInvitationCode(
        _invitationCodeController.text.trim().toUpperCase(),
      );

      if (data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid or expired invitation code'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _invitationData = data;
          _codeValidated = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${_firestoreService.getErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Step 1: Accept invitation and create user document (before auth)
      // Prepare additional user data
      final additionalData = {
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dateOfBirth': _dateOfBirth.toIso8601String().split('T')[0],
        'insuranceType': _insuranceType,
        'insuranceProvider': _insuranceProviderController.text.trim(),
        'insuranceNumber': _insuranceNumberController.text.trim(),
        'bankName': _bankNameController.text.trim(),
        'iban': _ibanController.text.trim(),
        'taxId': _taxIdController.text.trim(),
      };

      // Accept invitation (creates user document)
      await _firestoreService.acceptInvitation(
        _invitationData!['id'],
        additionalData,
      );

      // Step 2: Create authentication account
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email: _invitationData!['email'],
        password: _passwordController.text,
      );

      if (userCredential == null) {
        throw Exception('Failed to create account');
      }

      // Step 3: Now that user is authenticated, update the user document with userId
      // Wait a moment for auth to propagate
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Navigate to home page
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Registration'),
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_codeValidated) ...[
                      _buildInvitationCodeSection(),
                    ] else ...[
                      _buildInvitationInfoCard(),
                      const SizedBox(height: 24),
                      _buildRegistrationForm(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInvitationCodeSection() {
    return Column(
      children: [
        Icon(Icons.mail_outline, size: 80, color: Colors.purple.shade300),
        const SizedBox(height: 24),
        const Text(
          'Enter Your Invitation Code',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'You should have received this code via email',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _invitationCodeController,
          decoration: InputDecoration(
            labelText: 'Invitation Code',
            prefixIcon: const Icon(Icons.key),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'e.g., ABC12345',
          ),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            LengthLimitingTextInputFormatter(8),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _validateInvitationCode,
          icon: const Icon(Icons.check_circle),
          label: const Text('Validate Code'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF673AB7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvitationInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Invitation Validated',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Name', _invitationData!['name']),
            _buildInfoRow('Email', _invitationData!['email']),
            _buildInfoRow('Position', _invitationData!['position']),
            _buildInfoRow('Department', _invitationData!['department']),
            _buildInfoRow('Access Level', _invitationData!['accessLevel']),
            const SizedBox(height: 8),
            Text(
              'Please complete the additional information below',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Security',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF673AB7),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password *',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Confirm Password *',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF673AB7),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Address *',
            prefixIcon: const Icon(Icons.home),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number *',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _selectDateOfBirth(context),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date of Birth *',
              prefixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '${_dateOfBirth.day}/${_dateOfBirth.month}/${_dateOfBirth.year}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Insurance Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF673AB7),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _insuranceType,
          decoration: InputDecoration(
            labelText: 'Insurance Type *',
            prefixIcon: const Icon(Icons.health_and_safety),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(value: 'Public', child: Text('Public')),
            DropdownMenuItem(value: 'Private', child: Text('Private')),
          ],
          onChanged: (value) {
            setState(() => _insuranceType = value!);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _insuranceProviderController,
          decoration: InputDecoration(
            labelText: 'Insurance Provider *',
            prefixIcon: const Icon(Icons.business),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'e.g., TK, AOK, etc.',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter insurance provider';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _insuranceNumberController,
          decoration: InputDecoration(
            labelText: 'Insurance Number *',
            prefixIcon: const Icon(Icons.numbers),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter insurance number';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Banking Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF673AB7),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bankNameController,
          decoration: InputDecoration(
            labelText: 'Bank Name *',
            prefixIcon: const Icon(Icons.account_balance),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter bank name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _ibanController,
          decoration: InputDecoration(
            labelText: 'IBAN *',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'DE89 3704 0044 0532 0130 00',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter IBAN';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _taxIdController,
          decoration: InputDecoration(
            labelText: 'Tax ID *',
            prefixIcon: const Icon(Icons.badge),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter tax ID';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _completeRegistration,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF673AB7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Complete Registration',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // Must be 18+
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF673AB7),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }
}
