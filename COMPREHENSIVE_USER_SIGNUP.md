# Comprehensive User Information Collection During Signup

## Overview
Updated the company registration/signup process to collect complete user information for the admin user, matching the fields required when creating users via invitation system.

## Implementation Details

### Files Modified
1. **lib/pages/sign_up_page.dart** - Added comprehensive user data collection form

### New Form Sections Added

#### 1. Employment Information
- **Department** (required) - Text field for user's department
- **Position** (required) - Text field for user's job position
- **Hire Date** (required) - Date picker, defaults to current date
- **Payment Type** (required) - Dropdown: Monthly or Hourly
- **Monthly Income** (conditional) - Shown when Payment Type is "Monthly"
- **Hourly Rate** (conditional) - Shown when Payment Type is "Hourly"
- **Yearly Vacation Days** (required) - Integer field for annual vacation days

#### 2. Personal Information
- **Address** (required) - Multi-line text field for full address
- **Date of Birth** (required) - Date picker, defaults to 18 years old (6570 days)

#### 3. Insurance Information
- **Insurance Type** (required) - Dropdown: Public or Private
- **Insurance Provider** (required) - Text field for provider name
- **Insurance Number** (required) - Text field for insurance ID

#### 4. Banking Information
- **Bank Name** (required) - Text field for bank name
- **IBAN** (required) - Text field in uppercase for International Bank Account Number
- **Tax ID** (required) - Text field for tax identification number

### State Variables Added
```dart
// Employment fields
final _departmentController = TextEditingController();
final _positionController = TextEditingController();
final _monthlyIncomeController = TextEditingController();
final _hourlyRateController = TextEditingController();
final _yearlyVacationsController = TextEditingController();

// Personal fields
final _addressController = TextEditingController();

// Insurance fields
final _insuranceProviderController = TextEditingController();
final _insuranceNumberController = TextEditingController();

// Banking fields
final _bankNameController = TextEditingController();
final _ibanController = TextEditingController();
final _taxIdController = TextEditingController();

// Dropdown/Date fields
String _accessLevel = 'Admin'; // Always Admin for company owner
String _paymentType = 'Monthly'; // Default to Monthly payment
String _insuranceType = 'Public'; // Default to Public insurance
DateTime _hireDate = DateTime.now(); // Default to today
DateTime _dateOfBirth = DateTime.now().subtract(const Duration(days: 6570)); // ~18 years
```

### Firestore User Document Structure
The user document created during signup now includes all fields:

```dart
{
  'userId': userId,
  'organizationId': organizationId,
  'name': name,
  'email': email,
  'phone': phone,
  'accessLevel': 'Admin', // Changed from 'role' for consistency
  'status': 'Active',
  
  // Employment
  'department': department,
  'position': position,
  'hireDate': Timestamp,
  'paymentType': 'Monthly' or 'Hourly',
  'monthlyIncome': double (if Monthly),
  'hourlyRate': double (if Hourly),
  'yearlyVacations': int,
  
  // Personal
  'address': address,
  'dateOfBirth': Timestamp,
  
  // Insurance
  'insuranceType': 'Public' or 'Private',
  'insuranceProvider': provider,
  'insuranceNumber': number,
  
  // Banking
  'bankName': bankName,
  'iban': iban,
  'taxId': taxId,
  
  // Metadata
  'createdAt': serverTimestamp,
  'updatedAt': serverTimestamp
}
```

### Key Features

#### 1. Conditional Fields
- Monthly Income field appears only when Payment Type is "Monthly"
- Hourly Rate field appears only when Payment Type is "Hourly"
- Only the relevant payment field is validated and saved

#### 2. Date Pickers
- Custom themed date pickers using Material Design purple color (#673AB7)
- Hire Date allows future dates (up to 1 year ahead)
- Date of Birth restricted to past dates only
- Dates displayed in DD/MM/YYYY format

#### 3. Validation
All new fields are required and validated:
- Department and Position: Non-empty text
- Payment amounts: Valid decimal numbers
- Vacation days: Valid integer
- All insurance and banking fields: Non-empty text
- Addresses: Non-empty text (multi-line supported)

#### 4. Field Formatting
- IBAN field uses uppercase transformation
- Department, Position, Bank Name: Word capitalization
- All text fields have Material Design styling with purple accent

#### 5. Memory Management
All controllers are properly disposed in the dispose() method to prevent memory leaks

### Consistency with Invitation System
This implementation ensures that:
1. Admin users created during signup have complete profiles
2. Field names match those used in invitation acceptance (`accessLevel` instead of `role`)
3. All users in the system have the same data structure
4. No partial profiles exist in the database

### User Experience
1. Form is organized into logical sections with visual headers
2. Clear labeling with required field indicators (*)
3. Consistent visual design with existing signup form
4. Interactive date pickers with calendar UI
5. Conditional logic reduces clutter (payment type selection)
6. All sections maintain the purple gradient theme

### Benefits
1. **Data Completeness**: All users have complete profiles from creation
2. **Consistency**: Same fields for admin and invited users
3. **Compliance**: Proper collection of employment and tax information
4. **HR Management**: Complete employee data available immediately
5. **Payment Processing**: All necessary banking/payment info collected upfront

## Testing Checklist
- [ ] All form fields appear correctly
- [ ] Date pickers work for Hire Date and Date of Birth
- [ ] Payment Type dropdown changes displayed income field
- [ ] Insurance Type dropdown works
- [ ] All validations prevent empty submissions
- [ ] Form scrolls properly with all new fields
- [ ] User document created with all fields in Firestore
- [ ] Organization and default project still created correctly
- [ ] Navigation to home page after successful signup
- [ ] All controllers disposed properly (no memory leaks)

## Notes
- First user during signup is always Admin level (accessLevel='Admin')
- Changed from 'role' field to 'accessLevel' field for consistency with invitation system
- Date fields stored as Firestore Timestamp objects
- Payment amounts stored as double (0.0 for unused type)
- Vacation days stored as integer
