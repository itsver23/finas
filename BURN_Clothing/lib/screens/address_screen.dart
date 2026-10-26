import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../config/ui_helpers.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressState();
}

class _AddressState extends State<AddressPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final streetController = TextEditingController();
  final barangayController = TextEditingController();
  final cityController = TextEditingController();
  final postalController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool busy = false;
  String countryCode = '+63';
  String? selectedCity;
  String? selectedBarangay;
  String? suggestedPostal;

  static const cityCodes = <String, String>{
    'Caloocan': '1400', 'Las Piñas': '1740', 'Makati': '1200',
    'Malabon': '1470', 'Mandaluyong': '1550', 'Manila': '1000',
    'Marikina': '1800', 'Muntinlupa': '1770', 'Navotas': '1485',
    'Parañaque': '1700', 'Pasay': '1300', 'Pasig': '1600',
    'Pateros': '1620', 'Quezon City': '1100', 'San Juan': '1500',
    'Taguig': '1630', 'Valenzuela': '1440',
  };

  // Barangay choices are supplied for Malabon. Other locations have a
  // manual option so the form never guesses the customer's barangay.
  static const barangays = <String, List<String>>{
    'Malabon': [
      'Acacia', 'Baritan', 'Bayan-Bayanan', 'Catmon', 'Concepcion',
      'Dampalit', 'Flores', 'Hulong Duhat', 'Ibaba', 'Longos',
      'Maysilo', 'Muzon', 'Niugan', 'Panghulo', 'Potrero',
      'San Agustin', 'Santulan', 'Tanong', 'Tinajeros', 'Tonsuya',
      'Tugatog',
    ],
  };

  void chooseCity(String? value) {
    setState(() {
      selectedCity = value;
      selectedBarangay = null;
      barangayController.clear();
      cityController.text = value == 'Other city / province' ? '' : (value ?? '');
      final next = cityCodes[value];
      if (postalController.text.isEmpty ||
          postalController.text == suggestedPostal) {
        postalController.text = next ?? '';
      }
      suggestedPostal = next;
    });
  }

  Future<void> saveData() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (!connected || db.auth.currentUser == null) {
      notice(context, 'Login first to save your address');
      return;
    }
    final phone = phoneController.text.trim();
    final normalizedPhone = countryCode == '+63' && phone.startsWith('0')
        ? phone.substring(1)
        : phone;
    final fullPhone = '$countryCode$normalizedPhone';
    final barangay = barangayController.text.trim();
    final street = streetController.text.trim();
    setState(() => busy = true);
    try {
      // Preserve existing Supabase addresses schema: street and city are strings.
      await db.from('addresses').insert({
        'user_id': db.auth.currentUser!.id,
        'full_name': nameController.text.trim(),
        'phone': fullPhone,
        'street': '$street, Brgy. $barangay',
        'city': cityController.text.trim(),
        'postal_code': postalController.text.trim(),
      });
      if (!mounted) return;
      notice(context, 'Address saved successfully');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) notice(context, 'Could not save: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      nameController, phoneController, streetController, barangayController,
      cityController, postalController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  InputDecoration decoration(String label, {String? hint, IconData? icon}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, color: const Color(0xFFE50920)),
        filled: true,
        fillColor: const Color(0xFF202020),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      );

  Widget section(String label) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 10),
        child: Text(label, style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white,
        )),
      );

  @override
  Widget build(BuildContext context) {
    final choices = barangays[selectedCity] ?? const <String>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Shipping Address')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('DELIVERY DETAILS', style: TextStyle(
              color: Color(0xFFE50920), fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            )),
            const SizedBox(height: 6),
            const Text('Enter accurate details for your delivery.',
                style: TextStyle(color: Colors.white60)),
            section('Recipient'),
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[0-9]'))],
              decoration: decoration('Full Name', icon: Icons.person_outline),
              validator: (value) {
                final name = (value ?? '').trim();
                if (name.isEmpty) return 'Enter your full name';
                if (RegExp(r'[0-9]').hasMatch(name)) return 'Numbers are not allowed';
                if (name.length < 2) return 'Enter a valid name';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(children: [
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<String>(
                  initialValue: countryCode,
                  isExpanded: true,
                  decoration: decoration('Code'),
                  items: const [
                    DropdownMenuItem(value: '+63', child: Text('🇵🇭 +63')),
                    DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
                    DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
                    DropdownMenuItem(value: '+65', child: Text('🇸🇬 +65')),
                    DropdownMenuItem(value: '+81', child: Text('🇯🇵 +81')),
                    DropdownMenuItem(value: '+82', child: Text('🇰🇷 +82')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      countryCode = v ?? '+63';
                      // Clear the previous number to avoid retaining digits
                      // that are invalid for the newly selected country.
                      phoneController.clear();
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(countryCode == '+63' ? 11 : 15)],
                decoration: decoration('Phone Number', icon: Icons.phone_outlined,
                    hint: countryCode == '+63' ? '09XXXXXXXXX' : 'Local number'),
                validator: (value) {
                  final number = (value ?? '').trim();
                  if (countryCode == '+63') {
                    if (!RegExp(r'^(09\d{9}|9\d{9})$').hasMatch(number)) {
                      return 'Enter valid PH mobile';
                    }
                  } else if (number.length < 6 || number.length > 15) {
                    return 'Invalid phone number';
                  }
                  return null;
                },
              )),
            ]),
            section('Delivery location'),
            DropdownButtonFormField<String>(
              initialValue: selectedCity,
              isExpanded: true,
              decoration: decoration('City / Province', icon: Icons.location_city_outlined),
              items: [
                ...cityCodes.keys.map((city) => DropdownMenuItem(
                  value: city, child: Text(city))),
                const DropdownMenuItem(
                  value: 'Other city / province',
                  child: Text('Other city / province'),
                ),
              ],
              onChanged: chooseCity,
              validator: (v) => v == null ? 'Choose your city' : null,
            ),
            if (selectedCity == 'Other city / province') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: cityController,
                textCapitalization: TextCapitalization.words,
                decoration: decoration('Enter City / Province'),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Enter city / province' : null,
              ),
            ],
            const SizedBox(height: 12),
            if (choices.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: selectedBarangay,
                isExpanded: true,
                decoration: decoration('Barangay', icon: Icons.place_outlined),
                items: [
                  ...choices.map((b) => DropdownMenuItem(value: b, child: Text(b))),
                  const DropdownMenuItem(value: 'Other barangay',
                      child: Text('Other barangay')),
                ],
                onChanged: (v) => setState(() {
                  selectedBarangay = v;
                  barangayController.text = v == 'Other barangay' ? '' : (v ?? '');
                }),
                validator: (v) => v == null ? 'Choose a barangay' : null,
              ),
              if (selectedBarangay == 'Other barangay') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: barangayController,
                  decoration: decoration('Enter Barangay'),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Enter your barangay' : null,
                ),
              ],
            ] else
              TextFormField(
                controller: barangayController,
                textCapitalization: TextCapitalization.words,
                decoration: decoration('Barangay', icon: Icons.place_outlined,
                    hint: 'Enter your barangay'),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Enter your barangay' : null,
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: streetController,
              textCapitalization: TextCapitalization.words,
              decoration: decoration('House No. / Street / Building',
                  icon: Icons.home_outlined),
              validator: (v) => (v ?? '').trim().isEmpty
                  ? 'Enter your street address' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: postalController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4)],
              decoration: decoration('Postal Code', icon: Icons.markunread_mailbox_outlined,
                  hint: 'Confirm ZIP code for your barangay'),
              validator: (v) => RegExp(r'^\d{4}$').hasMatch((v ?? '').trim())
                  ? null : 'Enter a 4-digit Philippine postal code',
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 20),
              child: Text('Postal codes are suggestions only. Verify your exact ZIP code before saving. Delivery locations are currently in the Philippines.',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: busy ? null : saveData,
                icon: busy
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                label: Text(busy ? 'Saving...' : 'Save Address'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50920),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
