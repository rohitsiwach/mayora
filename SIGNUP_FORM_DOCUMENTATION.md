# Company Registration Form - Documentation

## Overview
The signup form is designed for **Company Owner/Administrator** registration and collects comprehensive information needed to onboard a new company into the Mayora platform.

## User Flow

### 1. Information Popup (Initial)
When users access the signup page, they are immediately presented with an informational dialog that explains:
- This is for Company Owner/Administrator registration
- It will create a new company account
- The user will become the primary administrator
- Full access rights will be granted
- Accurate information is required

**Actions Available:**
- **Cancel**: Returns to sign-in page
- **Continue**: Proceeds to registration form

## Form Structure

The registration form is divided into two main sections:

### Section 1: Company Information

#### Company Name (Required)
- **Field Type**: Text Input
- **Validation**: Must not be empty
- **Icon**: Business/Company icon
- **Purpose**: Primary identifier for the company

#### Company Address (Required - All Fields)
The address is broken down into detailed components:

1. **Street Address**
   - Full street address including building number
   - Icon: Location pin
   
2. **City**
   - City name
   - Icon: City buildings
   - Layout: Takes 2/3 of row width
   
3. **State/Province**
   - State or province abbreviation/name
   - Layout: Takes 1/3 of row width
   
4. **Postal Code**
   - ZIP/Postal code
   - Icon: Mailbox
   - Layout: Takes 1/2 of row width
   
5. **Country**
   - Country name
   - Icon: Flag
   - Layout: Takes 1/2 of row width

### Section 2: Administrator Information

#### Personal Details (Required - All Fields)

1. **Full Name**
   - Complete legal name of the administrator
   - Icon: Person
   - Text capitalization enabled

2. **Email**
   - Valid email address
   - Icon: Email
   - Validation: Must contain '@' and '.'
   - Used for authentication

3. **Phone Number**
   - Contact phone number
   - Icon: Phone
   - Validation: Minimum 10 characters
   - Keyboard: Numeric

4. **Password**
   - Secure password
   - Icon: Lock
   - Validation: Minimum 6 characters
   - Toggle visibility available

5. **Confirm Password**
   - Must match password field
   - Icon: Outlined lock
   - Toggle visibility available

### GDPR Compliance Section

Two mandatory checkboxes ensure GDPR compliance:

#### Checkbox 1: Terms of Service
- "I agree to the Terms of Service and acknowledge that my data will be processed according to the Privacy Policy"
- **Required**: Yes
- **Purpose**: Legal agreement to platform terms

#### Checkbox 2: GDPR Consent
- "I consent to the collection and processing of my personal data in accordance with GDPR regulations"
- **Required**: Yes
- **Purpose**: Explicit consent for data processing under GDPR

#### Information Notice
A blue information box displays:
- "Your data is protected under GDPR. You can request access, correction, or deletion of your data at any time."
- **Icon**: Information outline
- **Purpose**: Transparency about data rights

## Validation Rules

### Required Fields
All fields marked with `*` are mandatory:
- Company Name
- Street Address
- City
- State
- Postal Code
- Country
- Full Name
- Email
- Phone Number
- Password
- Confirm Password

### Field-Specific Validation

1. **Email**
   - Must contain '@' symbol
   - Must contain '.' (period)
   - Error: "Please enter a valid email"

2. **Password**
   - Minimum 6 characters
   - Error: "Password must be at least 6 characters"

3. **Confirm Password**
   - Must exactly match Password field
   - Error: "Passwords do not match"

4. **Phone Number**
   - Minimum 10 characters
   - Error: "Please enter a valid phone number"

5. **All Text Fields**
   - Cannot be empty
   - Whitespace is trimmed
   - Error: "Please enter [field name]" or "Required"

### Checkbox Validation

1. **Terms Agreement**
   - Must be checked before submission
   - Error: "Please agree to the Terms of Service"

2. **GDPR Consent**
   - Must be checked before submission
   - Error: "Please consent to GDPR data processing"

## Visual Design

### Color Scheme
- **Primary**: Purple (#673AB7)
- **Secondary**: Pink-Purple (#9C27B0)
- **Accent**: Cyan (#00BCD4)
- **Background**: Gradient (Purple → Pink-Purple → Cyan)

### Layout
- **Form Container**: White card with rounded corners
- **Elevation**: Shadow effect for depth
- **Spacing**: Consistent 16px between fields, 24px between sections
- **Border Radius**: 12px for input fields
- **Focus State**: 2px purple border

### Section Headers
- **Style**: Bold, purple text
- **Decoration**: Bottom border with purple tint
- **Purpose**: Clear visual separation between sections

### Responsive Design
- Two-column layout for City/State and Postal Code/Country pairs
- Single column for all other fields
- Scrollable container to accommodate all fields
- Mobile-friendly touch targets

## User Experience Features

### 1. Progressive Disclosure
- Information popup appears first
- Form only accessible after acknowledgment

### 2. Input Assistance
- Appropriate keyboards (email, phone, text)
- Text capitalization for names and addresses
- Password visibility toggle
- Tab navigation between fields

### 3. Error Handling
- Real-time validation on form submission
- Clear, specific error messages
- Orange/red color for error states
- Inline error display under each field

### 4. Loading State
- Disabled button during submission
- Loading spinner replaces button text
- Prevents double submission

### 5. Success Feedback
- Green snackbar on successful registration
- Automatic navigation to homepage
- Display name updated in Firebase

## Technical Implementation

### Controllers
```dart
// Company Information
_companyNameController
_streetAddressController
_cityController
_stateController
_postalCodeController
_countryController

// User Information
_nameController
_emailController
_phoneController
_passwordController
_confirmPasswordController
```

### State Variables
```dart
_isLoading          // Submission state
_obscurePassword    // Password visibility
_obscureConfirmPassword  // Confirm password visibility
_agreeToTerms       // Terms checkbox state
_agreeToPrivacy     // GDPR checkbox state
_showInfoPopup      // Initial popup control
```

### Firebase Integration
- Uses `AuthService` for user creation
- Email/password authentication
- Display name update after registration
- Error handling with user-friendly messages

## Data Storage Considerations

### Current Implementation
Currently, only authentication data (email/password) is stored in Firebase Authentication. The additional company and personal information collected is:
- Validated on the client side
- Ready for storage in Firestore or other database

### Recommended Next Steps
1. Create a Firestore collection for companies
2. Create a Firestore collection for users
3. Store company information with company ID
4. Link user to company with role information
5. Implement data access controls per GDPR

## GDPR Compliance Notes

### Data Collection Transparency
- Users are informed about data collection
- Purpose of data collection is clear
- Explicit consent is obtained

### User Rights Communicated
- Right to access data
- Right to correction
- Right to deletion

### Implementation Requirements
To be fully GDPR compliant, implement:
1. **Privacy Policy Page**: Detailed information about data processing
2. **Terms of Service Page**: Legal terms and conditions
3. **Data Access Feature**: Allow users to download their data
4. **Data Deletion Feature**: Allow users to request data deletion
5. **Data Correction Feature**: Allow users to update their information
6. **Consent Tracking**: Store timestamps of consent
7. **Audit Logs**: Track data access and modifications

## Testing Checklist

- [ ] Popup appears on page load
- [ ] Cancel button returns to sign-in
- [ ] Continue button dismisses popup
- [ ] All form fields accept input
- [ ] Email validation works correctly
- [ ] Password validation (minimum 6 chars) works
- [ ] Confirm password matching works
- [ ] Phone number validation (minimum 10 digits) works
- [ ] Terms checkbox can be toggled
- [ ] GDPR checkbox can be toggled
- [ ] Submit fails without terms agreement
- [ ] Submit fails without GDPR consent
- [ ] Submit fails with invalid data
- [ ] Submit succeeds with valid data
- [ ] Loading state appears during submission
- [ ] Success message appears after registration
- [ ] User is redirected to homepage
- [ ] Display name is updated in Firebase
- [ ] Error messages display correctly
- [ ] All required field validations work
- [ ] Password visibility toggle works

## Future Enhancements

1. **Company Logo Upload**: Allow companies to upload their logo during registration
2. **Multi-step Form**: Break into steps to reduce initial complexity
3. **Address Autocomplete**: Integration with Google Places API
4. **Phone Number Formatting**: Auto-format based on country
5. **Email Verification**: Send verification email before activation
6. **Company Domain Verification**: Verify user owns company email domain
7. **Role Selection**: Allow selection of specific admin role during signup
8. **Industry Selection**: Dropdown for company industry/sector
9. **Company Size**: Select number of employees
10. **Terms Preview**: Show terms in modal before accepting

## Accessibility

### Implemented
- Label text for all form fields
- Visual focus indicators
- Color contrast ratios meet WCAG standards
- Touch target sizes appropriate for mobile

### To Implement
- Screen reader announcements for errors
- Semantic HTML roles
- Keyboard navigation testing
- Focus trap in popup dialog
- ARIA labels for icon-only buttons
