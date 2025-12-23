# Pal App - Complete Microcopy Report
**Master Copy Document**  
**Generated:** December 2025  
**Purpose:** Comprehensive documentation of all microcopy (text content) currently implemented and required in the Pal application.

---

## Table of Contents

1. [Hint/Placeholder Text](#1-hintplaceholder-text)
2. [Helper Text](#2-helper-text)
3. [Error Messages](#3-error-messages)
4. [Success/Confirmation Messages](#4-successconfirmation-messages)
5. [System Notifications/Toasts](#5-system-notificationstoasts)
6. [Empty State Messages](#6-empty-state-messages)
7. [Modal Microcopy](#7-modal-microcopy)
8. [Security & Authentication Microcopy](#8-security--authentication-microcopy)
9. [Rate Limiting / Restriction Messages](#9-rate-limiting--restriction-messages)
10. [Missing or Incomplete Copy](#10-missing-or-incomplete-copy)

---

## 1. Hint/Placeholder Text

### Authentication Screens

#### Login Screen (`lib/screens/login/login_screen.dart`)
- **Email field:** `"Email"`
- **Password field:** `"Password"`

#### Signup Screen (`lib/screens/signup/signup_screen.dart`)
- **First Name field:** `"First Name"`
- **Last Name field:** `"Last Name"`
- **Username field:** `"Username"`
- **Email field:** `"Email"`
- **State/Location field:** `"State"` (with autocomplete search)
- **Password field:** `"Password"` (implied, not explicitly shown in code)
- **Confirm Password field:** `"Confirm Password"` (implied, not explicitly shown in code)
- **Date of Birth field:** `"Date of Birth"` (implied, not explicitly shown in code)

#### OTP Verification Screen (`lib/screens/otp/otp_verification_screen.dart`)
- **OTP input fields:** No placeholder (6 individual digit boxes)

#### Forgot Password Email Screen (`lib/screens/forgot_password/forgot_password_email_screen.dart`)
- **Email field:** `"Email"`

#### Reset Password Screen (`lib/screens/forgot_password/reset_password_screen.dart`)
- **New Password field:** `"My Strong Password Here"`
- **Confirm Password field:** `"My Strong Password Here"` (implied)

### Feed Screens

#### Create Post Screen (`lib/screens/feed/create_post_screen.dart`)
- **Title field:** `"What's happening?"`
- **Body/Content field:** `"Share your thoughts..."` (implied, needs verification)

### Report Post Sheet (`lib/screens/feed/widgets/report_post_sheet.dart`)
- **Additional Details field:** `"Provide more context about this report..."`

---

## 2. Helper Text

### Authentication Screens

#### Login Screen
- **Remember me checkbox:** `"Remember me"`

#### Signup Screen
- **Name validation helper:** 
  - `"Use Letters and spaces only"` (when special characters detected)
  - `"Use 3+ letters/spaces only"` (when less than 3 characters)
- **Username validation helper:**
  - `"no spaces allowed"` (when spaces detected)
  - `"Use Alphanumeric or underscore only"` (when invalid characters)
- **Email validation helper:**
  - `"Email must contain @"` (when @ missing)
  - `"Invalid email format. Use format: example@gmail.com"` (when format invalid)
- **Password strength indicator:**
  - `"Use 6+ characters with a mix of letters, numbers & symbols"` (when strength < 3)
  - `"Strong password"` (when strength >= 3)
- **Password match indicator:**
  - `"Passwords match"` (when passwords match)

#### Forgot Password Email Screen
- **Helper text below email field:** `"We will send a 4-digit code to this email. The code is valid for 5 minutes."`
- **Note:** This mentions "4-digit code" but OTP is actually 6 digits - **INCONSISTENCY FOUND**

#### Reset Password Screen
- **Helper text:** `"Your new password must be different from previously used passwords."`
- **Password strength helper:** `"Use 6+ characters with a mix of letters, numbers & symbols"`
- **Password match helper:** `"Passwords match"`

### Feed Screens

#### Create Post Screen
- **Form status messages (dynamic helper text):**
  - `"Title exceeds 75 characters"`
  - `"Content exceeds 500 characters"`
  - `"Select a post category"`
  - `"Add a title to get started"`
  - `"Share some details"`
  - `"Select a location"`
  - `"Please follow community guidelines"`

### OTP Verification Screen
- **Resend timer text:** `"Resend code in (MM:SS)"` (dynamic timer display)

---

## 3. Error Messages

### Authentication Errors

#### Login Screen
- **Email errors:**
  - `"Email is required"`
  - `"Email must contain @"`
  - `"Please enter a valid email"`
  - `"Invalid email or password"` (for authentication failures)
  - Dynamic error from backend (e.g., `e.message`)
- **Password errors:**
  - `"Password is required"`
  - `"Password must be at least 8 characters"`
  - `"Invalid email or password"` (for authentication failures)
- **General errors:**
  - `"An unexpected error occurred. Please try again."`

#### Signup Screen
- **First Name errors:**
  - `"Use Letters and spaces only"`
  - `"Use 3+ letters/spaces only"`
- **Last Name errors:**
  - `"Use Letters and spaces only"`
  - `"Use 3+ letters/spaces only"`
- **Username errors:**
  - `"no spaces allowed"`
  - `"Use Alphanumeric or underscore only"`
  - `"This username is already taken"` (from backend)
- **Email errors:**
  - `"Email must contain @"`
  - `"Invalid email format. Use format: example@gmail.com"`
- **Password errors:**
  - `"Password must be at least 6 characters"` (in reset password screen)
- **Confirm Password errors:**
  - `"Passwords do not match"`
- **Gender errors:**
  - `"Please select a gender"` (implied)
- **Account Type errors:**
  - `"Please select an account type"` (implied)
- **Terms errors:**
  - `"Please agree to terms and conditions"` (implied)
- **Date of Birth errors:**
  - `"Please enter your date of birth"` (implied)

#### OTP Verification Screen
- **OTP errors:**
  - `"Please enter the complete OTP code"`
  - `"Please enter the complete 6-digit code"` (for password reset flow)
  - Dynamic backend error messages (e.g., `e.message`)
  - `"An unexpected error occurred. Please try again."`
- **Resend errors:**
  - `"Failed to resend OTP. Please try again."`
  - `"Failed to resend password reset code. Please try again."`
  - Rate limit errors (dynamic from backend)

#### Forgot Password Email Screen
- **Email errors:**
  - `"Email is required"`
  - `"Enter a valid email address"`
  - `"Too many requests. Please try again later."` (rate limiting)
  - `"If this email exists, a password reset code has been sent."` (security measure)
  - `"Failed to send password reset code. Please try again."`

#### Reset Password Screen
- **Password errors:**
  - `"Password must be at least 6 characters"`
  - `"Invalid or expired reset code. Please request a new one."` (OTP errors)
  - Dynamic backend error messages
  - `"Failed to reset password. Please try again."`
- **Confirm Password errors:**
  - `"Passwords do not match"`
- **General errors:**
  - `"An unexpected error occurred. Please try again."`

### Post Creation Errors

#### Create Post Screen
- **Validation errors:**
  - `"Please enter post details."` (when content is empty)
  - `"Post exceeds 1000 characters."` (when content too long)
  - `"Selected location is unavailable right now."` (when location fetch fails)
- **Submission errors:**
  - Dynamic error messages from backend (e.g., `e.toString().replaceFirst('Exception: ', '')`)

### System Error Messages (from `lib/utils/error_handler.dart` and `lib/widgets/error_dialog.dart`)

#### Network/Connection Errors
- **Title:** `"Connection Error"`
- **Subtitle:** `"Unable to connect"`
- **Message:** `"Your internet connection was lost or is unstable. Please check your connection and try again."`

#### Timeout Errors
- **Title:** `"Request Timeout"`
- **Subtitle:** `"Request took too long"`
- **Message:** `"The request took too long to complete. Please check your connection and try again."`

#### Authentication/Session Errors
- **Title:** `"Session Expired"`
- **Subtitle:** `"Please log in again"`
- **Message:** `"Your session has expired or is invalid. Please log in again to continue."`

#### Server Errors (500)
- **Title:** `"Server Error"`
- **Subtitle:** `"Something went wrong"`
- **Message:** `"We encountered an issue on our servers. Please try again in a few moments."`

#### Not Found Errors (404)
- **Title:** `"Not Found"`
- **Subtitle:** `"Resource unavailable"`
- **Message:** `"The requested resource could not be found. It may have been removed or is temporarily unavailable."`

#### Bad Request Errors (400)
- **Title:** `"Invalid Request"`
- **Subtitle:** `"Please check your input"`
- **Message:** `"Your request could not be processed due to invalid data. Please check your input and try again."`

#### Permission/Access Errors (403)
- **Title:** `"Access Denied"`
- **Subtitle:** `"Insufficient permissions"`
- **Message:** `"You don't have permission to perform this action. Please contact support if you believe this is an error."`

#### Account Inactive Errors
- **Title:** `"Account Inactive"`
- **Subtitle:** `"Account access restricted"`
- **Message:** `"Your account is currently inactive. Please contact support for assistance."`

#### Content Validation Errors
- **Title:** `"Invalid Content"`
- **Subtitle:** `"Please check your post"`
- **Message:** `"Your post content is too long. Please keep it under 1000 characters."` OR `"Your post content is empty or invalid. Please add some content before posting."`

#### Comment Validation Errors
- **Title:** `"Invalid Comment"`
- **Subtitle:** `"Please check your comment"`
- **Message:** `"Your comment is too long. Please keep it under 500 characters."` OR `"Your comment is empty. Please add some content before posting."`

#### Database Function Errors
- **Title:** `"System Error"`
- **Subtitle:** `"Database issue"`
- **Message:** `"We encountered a technical issue with our database. Our team has been notified and is working on a fix."`

#### Post Not Found Errors
- **Title:** `"Post Not Found"`
- **Subtitle:** `"No longer available"`
- **Message:** `"This post is no longer available. It may have been deleted or is temporarily unavailable."`

#### Rate Limiting Errors
- **Title:** `"Too Many Requests"`
- **Subtitle:** `"Please wait"`
- **Message:** `"You've made too many requests in a short period. Please wait a moment and try again."`

#### Profile/Account Errors
- **Title:** `"Account Error"`
- **Subtitle:** `"Profile issue"`
- **Message:** `"There was an issue with your account profile. Please try logging out and back in."`

#### Image Upload Errors
- **Title:** `"Upload Error"`
- **Subtitle:** `"Image issue"`
- **Message:** 
  - `"The image file is too large. Please choose a smaller image and try again."` (file too large)
  - `"The selected file is not a valid image type. Please choose a JPG, PNG, or GIF file."` (invalid file type)
  - `"There was an issue uploading your image. Please try again."` (general upload error)

#### General Fallback
- **Title:** `"Something Went Wrong"`
- **Subtitle:** `"Unexpected error"`
- **Message:** Dynamic (converted from technical error)

### Profile Upload Errors

#### Profile Upload Screen (`lib/screens/signup/profile_upload_screen.dart`)
- **Image picker error:** `"Error picking image: $e"`
- **Upload error:** `"Failed to upload profile picture: ${e.toString().replaceFirst('Exception: ', '')}"`

---

## 4. Success/Confirmation Messages

### Authentication Success Messages

#### OTP Verification Screen
- **Account creation:** `"Account created successfully!"`
- **OTP verified (session creation failed):** `"OTP verified successfully! Please sign in with your email and password."`
- **OTP resent:** `"OTP resent successfully"`
- **Password reset code resent:** `"Password reset code resent successfully"`

#### Forgot Password Email Screen
- **Success SnackBar:** `"Password reset code sent to your email"` (or dynamic from backend: `response['message']`)

#### Reset Password Screen
- **Success SnackBar:** `"Password reset successfully"` (or dynamic from backend: `response['message']`)

### Post Creation Success Messages

#### Create Post Screen
- **Post created:** `"Post created successfully"` (or dynamic from backend: `response['message']`)
- **Post updated:** `"Post updated successfully"` (or dynamic from backend: `response['message']`)

### User Action Success Messages

#### Blocked Accounts Screen (`lib/screens/settings/blocked_accounts_screen.dart`)
- **User unblocked:** `"User unblocked successfully"`

---

## 5. System Notifications/Toasts

### Toast Messages (via `PalToast.show()`)

#### General Toasts
- Toast widget displays dynamic messages passed to it
- Common toast messages found in code:
  - `"Account created successfully!"`
  - `"OTP verified successfully! Please sign in with your email and password."`
  - `"OTP resent successfully"`
  - `"Password reset code resent successfully"`
  - `"Post created successfully"`
  - `"Post updated successfully"`
  - `"Please enter post details."`
  - `"Post exceeds 1000 characters."`
  - `"Selected location is unavailable right now."`
  - `"An unexpected error occurred. Please try again."`
  - `"Failed to load spotlight posts."`
  - `"Failed to load hottest post."`
  - `"Failed to load top post."`

#### Toast Widget Styling
- Background: White with border
- Icon: Check icon in black circle
- Text: Dynamic message in black
- Position: Above bottom navigation bar (responsive)

### SnackBar Messages

#### Forgot Password Email Screen
- **Success:** Green SnackBar with message from backend or `"Password reset code sent to your email"`

#### Reset Password Screen
- **Success:** Green SnackBar with message from backend or `"Password reset successfully"`
- **Error:** Red SnackBar with error message

#### Blocked Accounts Screen
- **Success:** `"User unblocked successfully"`
- **Error:** `"Failed to unblock user: ${e.toString()}"`

---

## 6. Empty State Messages

### Notifications Screen (`lib/screens/notifications/notifications_screen.dart`)
- **Welcome card (always shown):** 
  - `"Welcome to Pal! A chill spot to vibe, swap ideas, learn, and grow together"`
  - Timestamp: `"2m ago"` (hardcoded)

### Blocked Accounts Screen (`lib/screens/settings/blocked_accounts_screen.dart`)
- **Empty state title:** `"Restrict Accounts"`
- **Empty state message:** `"You haven't blocked anyone. Any blocked accounts will show up here."`

### Your Posts Screen (`lib/screens/settings/your_posts_screen.dart`)
- **Empty state:** `"No posts yet"` (simple text, needs design improvement)

### Feed Home Screen (`lib/screens/feed/feed_home_screen.dart`)
- **No posts state:** Not explicitly defined in code - **MISSING**
- **No search results:** Not implemented - **MISSING**

### Settings Screen
- Empty states not explicitly defined - **MISSING**

### Upvoted Posts Screen (`lib/screens/settings/upvoted_posts_screen.dart`)
- Empty state not found in code - **MISSING**

---

## 7. Modal Microcopy

### Delete Post Dialog (`lib/screens/feed/widgets/delete_post_dialog.dart`)

#### Header
- **Title:** `"Delete Post?"`
- **Subtitle:** `"This action cannot be undone"`

#### Body
- **Main message:** `"Are you sure you want to delete this post? All comments and votes will be permanently removed."`
- **Post quote:** `"$postTitle"` (dynamic, displayed in quote box)
- **Warning box:**
  - **Label:** `"Warning: "`
  - **Message:** `"This will permanently delete your post from the feed."`

#### Actions
- **Cancel button:** `"Cancel"`
- **Delete button:** `"Delete Post"` (with delete icon)

### Block User Dialog (`lib/screens/feed/widgets/block_user_dialog.dart`)

#### Header
- **Title:** `"Block $username ?"` (Note: Space before question mark - **INCONSISTENCY**)

#### Body
- **Message:** `"They can still view your posts, but you won't interact with each other. $username won't be able to comment, and you won't get notifications from them."`

#### Actions
- **Cancel button:** `"Cancel"`
- **Block button:** `"Block"`

### Report Post Sheet (`lib/screens/feed/widgets/report_post_sheet.dart`)

#### Header
- **Title:** `"Report Post"` or `"Report Comment"` (dynamic based on subject)
- **Subtitle:** `"Help us understand the issue"`

#### Report Options
1. **Spam or misleading**
   - Description: `"Repetitive or deceptive content"`
2. **Harassment or hate speech**
   - Description: `"Bullying, threats, or discriminatory language"`
3. **Inappropriate content**
   - Description: `"Explicit, violent, or offensive material"`
4. **False information**
   - Description: `"Deliberately spreading misinformation"`
5. **Other**
   - Description: `"Another reason not listed above"`

#### Additional Details Section
- **Section title:** `"Additional details (optional)"`
- **Field placeholder:** `"Provide more context about this report..."`

#### Info Card
- **Title:** `"What happens next?"`
- **Message:** `"Our moderation team will review this report within 24 hours. You'll receive a notification once we've taken action."`

#### Actions
- **Cancel button:** `"Cancel"`
- **Submit button:** `"Submit Report"`

### Report Success Dialog

#### Header
- **Title:** `"Report Submitted"`
- **Subtitle:** `"Thank you for your feedback"`

#### Body
- **Message:** `"Your report has been submitted successfully. Our moderation team will review it within 24 hours."`
- **Info box:** `"We take community safety seriously and appreciate your help in keeping it safe."`

#### Actions
- **Done button:** `"Done"`

### Delete Comment Dialog (`lib/screens/feed/widgets/delete_comment_dialog.dart`)
- **Status:** File exists but content not fully extracted - **NEEDS REVIEW**

### Logout Confirmation
- **Status:** Not found in code - **MISSING**

### Account Deactivation Confirmation
- **Status:** Not found in code - **MISSING**

---

## 8. Security & Authentication Microcopy

### OTP Verification Screen

#### Code Sent Message
- **Message:** `"Code has been send to ${email}"` (Note: "send" should be "sent" - **TYPO FOUND**)

#### Resend Code
- **Timer text:** `"Resend code in (MM:SS)"` (dynamic timer)
- **Resend button:** `"Resend code"` (when timer expires)

#### Continue Button
- **Label:** `"Continue"`

### Forgot Password Flow

#### Email Screen
- **Title:** `"Reset Password"`
- **Subtitle:** `"Forgot Password"`
- **Description:** `"Please enter your email to reset the password"`
- **Helper text:** `"We will send a 4-digit code to this email. The code is valid for 5 minutes."` (Note: Actually 6-digit code - **INCONSISTENCY**)

#### Reset Password Screen
- **Title:** `"Set New Password"`
- **Subtitle:** `"Create a New Password"`
- **Description:** `"Your new password must be different from previously used passwords."`

### Security Alerts
- **Session expired:** Handled in error dialogs (see Error Messages section)
- **Account inactive:** Handled in error dialogs (see Error Messages section)
- **Login/logout notices:** Not explicitly implemented - **MISSING**

---

## 9. Rate Limiting / Restriction Messages

### Rate Limiting Errors

#### General Rate Limit
- **Title:** `"Too Many Requests"`
- **Subtitle:** `"Please wait"`
- **Message:** `"You've made too many requests in a short period. Please wait a moment and try again."`

#### Forgot Password Rate Limit
- **Error message:** `"Too many requests. Please try again later."` (from `forgot_password_email_screen.dart`)

#### OTP Resend Rate Limit
- **Error message:** Dynamic from backend (checks for "wait" or "rate limit" in error string)

### Posting Restrictions

#### Post Creation Limits
- **Character limit error:** `"Post exceeds 1000 characters."`
- **Title limit:** 75 characters (enforced, but no explicit error message shown)
- **Body limit:** 500 characters (enforced, but no explicit error message shown)

#### Comment Limits
- **Character limit:** 500 characters (enforced in backend, error shown in error dialogs)

### Temporary Restrictions
- **Account suspension messages:** Not found in user-facing code - **MISSING**
- **Posting too fast:** Not implemented - **MISSING**

---

## 10. Missing or Incomplete Copy

### Critical Missing Items

#### 1. Empty States
- **Feed empty state:** No message defined when feed has no posts
- **Search results empty:** No "No results found" message
- **Upvoted posts empty:** No empty state message
- **Settings sections:** No empty states for various settings sections

#### 2. Logout Confirmation
- **Missing:** Logout confirmation dialog with body text
- **Location:** Should be in `lib/services/auth_logout_service.dart` or settings screen

#### 3. Account Deactivation
- **Missing:** Account deactivation confirmation dialog
- **Location:** Should be in `lib/services/auth_deactivate_service.dart` or settings screen

#### 4. Interest Selection Screen
- **Missing:** Error message for when no interests are selected (code has `_showSelectionError` flag but message not found)

#### 5. Profile Upload Screen
- **Missing:** Helper text explaining image requirements (size, format)
- **Missing:** Success message after successful upload

#### 6. Settings Screen
- **Missing:** Various settings section descriptions
- **Missing:** Confirmation messages for settings changes

#### 7. Community Guidelines Screen
- **Status:** File exists but content not extracted - **NEEDS REVIEW**

#### 8. Post Detail Screen
- **Status:** File exists but microcopy not fully extracted - **NEEDS REVIEW**

#### 9. Edit Post Screen
- **Status:** File exists but microcopy not fully extracted - **NEEDS REVIEW**

#### 10. Admin Screens
- **Status:** Multiple admin screens exist but microcopy not extracted - **NEEDS REVIEW**

### Inconsistencies Found

#### 1. OTP Code Length
- **Forgot Password Email Screen:** Says "4-digit code" but OTP is actually 6 digits
- **Location:** `lib/screens/forgot_password/forgot_password_email_screen.dart` line 257

#### 2. Block User Dialog Title
- **Issue:** Extra space before question mark: `"Block $username ?"` should be `"Block $username?"`
- **Location:** `lib/screens/feed/widgets/block_user_dialog.dart` line 40

#### 3. OTP Verification Message
- **Issue:** "Code has been send" should be "Code has been sent"
- **Location:** `lib/screens/otp/otp_verification_screen.dart` line 152

#### 4. Name Validation Error Messages
- **Current:** `"Use 3+ letters/spaces only"` and `"Use Letters and spaces only"`
- **Expected (from KP2 doc):** `"Minimum 3 characters. Letters, spaces, or hyphens only."`
- **Location:** `lib/screens/signup/signup_screen.dart`

### Placeholder Text Issues

#### 1. Generic Error Messages
- Many error messages use `e.toString()` or `e.message` directly without user-friendly conversion
- **Recommendation:** All errors should go through `ErrorHandler.showHumanReadableError()`

#### 2. TODO Comments
- **Blocked Accounts Screen:** Has TODO for API implementation
- **Profile Upload:** Error handling could be more user-friendly

#### 3. Hardcoded Values
- **Notifications welcome card:** Timestamp hardcoded as "2m ago"
- **Location:** `lib/screens/notifications/notifications_screen.dart` line 358

### Recommendations for Missing Copy

#### 1. Empty States
- Create consistent empty state component with:
  - Icon/illustration
  - Title (e.g., "No posts yet")
  - Description (e.g., "Start sharing with your community")
  - Optional CTA button

#### 2. Logout Confirmation
- **Title:** "Log Out?"
- **Body:** "Are you sure you want to log out? You'll need to sign in again to access your account."
- **Actions:** "Cancel" and "Log Out"

#### 3. Account Deactivation
- **Title:** "Deactivate Account?"
- **Body:** "Deactivating your account will hide your profile and posts. You can reactivate your account within 30 days by logging in again."
- **Warning:** "After 30 days, your account will be permanently deleted."
- **Actions:** "Cancel" and "Deactivate Account"

#### 4. Posting Too Fast
- **Message:** "You're posting too quickly. Please wait a moment before creating another post."

#### 5. Account Suspension
- **Title:** "Account Suspended"
- **Body:** "Your account has been temporarily suspended for violating community guidelines. The suspension will be lifted on [DATE]."
- **Actions:** "Contact Support" and "OK"

#### 6. Search Empty State
- **Title:** "No results found"
- **Description:** "Try adjusting your search terms or filters."

#### 7. Settings Change Confirmations
- **Success:** "Settings saved successfully"
- **Error:** "Failed to save settings. Please try again."

---

## Summary Statistics

### Total Microcopy Items Documented
- **Hint/Placeholder Text:** ~15 items
- **Helper Text:** ~20 items
- **Error Messages:** ~80+ items
- **Success Messages:** ~10 items
- **Toast Messages:** ~15 items
- **Empty State Messages:** ~5 items
- **Modal Microcopy:** ~30 items
- **Security/Auth Messages:** ~10 items
- **Rate Limiting Messages:** ~5 items
- **Missing/Incomplete:** ~20 items identified

### Critical Issues
1. **3 typos/inconsistencies** found
2. **~20 missing microcopy items** identified
3. **Multiple screens** need microcopy review
4. **Error handling** needs standardization

### Next Steps
1. Fix identified typos and inconsistencies
2. Implement missing empty states
3. Add logout and deactivation confirmation dialogs
4. Standardize error message handling
5. Review and complete admin screen microcopy
6. Create centralized copy management system

---

**End of Report**

