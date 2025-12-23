# Engineering Questions & Answers
Based on Current Implementation

## Q-1: OTP / Session - Post-Verification Navigation
**Question:** When user closes page after verifying OTP, what page should they return to on reopen?

**Answer (Based on Implementation):**
- After successful OTP verification, user is navigated to `/home` (feed) with `showWelcomeModal: true` and `showFirstPostCard: true` arguments
- Session is created via Supabase auth after OTP verification
- If user closes app after verification, session persists (see Q-11)
- On app reopen, if session exists and Remember Me is enabled, user is auto-logged in and goes to feed
- **Current behavior:** User returns to feed/home screen if session is valid
- **Recommendation:** This aligns with updated flow - user goes straight to feed after verification

---

## Q-2: Icons - Consistency with Design
**Question:** Why are similar but not identical icons used vs design?

**Answer (Based on Implementation):**
- Icons are primarily from Material Icons (`Icons.chevron_left`, `Icons.more_horiz`, etc.) and custom SVG assets
- Some icons may differ from Figma design due to:
  - Material Icons being used as fallback
  - SVG assets may not match exact Figma specifications
- **Recommendation:** 
  - Audit all icons against Figma design
  - Create/update SVG assets to match Figma exactly
  - Establish icon library/component system
  - Document icon usage guidelines

---

## Q-3: Hint & Error Messages - Master List
**Question:** Do we have a master list of all hint/error messages?

**Answer (Based on Implementation):**
- **No centralized master list found in codebase**
- Error messages are scattered across screens:
  - Signup: Username validation messages, email errors, password errors
  - Login: Email/password validation
  - OTP: Verification errors
  - Settings: Birthday update errors
- **Recommendation:**
  - Create `lib/constants/error_messages.dart` or similar
  - Create `lib/constants/hint_messages.dart`
  - Version control these messages
  - Document all user-facing text in centralized location

---

## Q-4: Rate Limiting - Account Creations
**Question:** Should there be rate limiting for account creations?

**Answer (Based on Implementation):**
- **No rate limiting found in current implementation**
- Signup flow directly calls `AuthService.signUp()` without rate limiting checks
- **Recommendation:**
  - Implement backend rate limiting (rolling 24-hour window)
  - Consider IP-based and email-based limits
  - Add rate limiting to OTP resend functionality
  - Document limits in error messages

---

## Q-5: Location Fields - State and Country
**Question:** Separate fields for state and country vs API restriction?

**Answer (Based on Implementation):**
- **Current implementation:** Uses Geoapify API with single location input field
- API returns both `country` and `state` separately
- Results displayed as `"$state, $country"` format
- Database schema has separate fields: `country`, `state`, `city` in `locations` table
- **Current UX:** Single text field that searches and displays "State, Country"
- **Recommendation:** Current approach is acceptable - single field with combined display maintains simplicity while backend stores separate values

---

## Q-6: "Remember Me" Logic
**Question:** Exact logic for "Remember Me" (duration, multi-device)?

**Answer (Based on Implementation):**
- **Implementation found in:** `lib/services/auth_remember_me_service.dart`
- **Logic:**
  - Stores preference in SharedPreferences
  - When enabled: Saves user ID and preference
  - When disabled: Clears stored user ID
  - Auto-login checks:
    1. Remember Me preference is true
    2. Valid Supabase session exists
    3. Session not expired
    4. User ID matches stored ID (if available)
  - **Session duration:** Uses Supabase session expiration (default ~1 hour, but can be extended)
  - **Multi-device:** Each device has independent Remember Me preference
  - **Current behavior:** Session persists until expiration or explicit logout
  - **Recommendation:** Document exact session duration and multi-device behavior clearly

---

## Q-7: Post-Verification Routing
**Question:** After verification in updated flow, does signup go straight to feed with new user pop-up?

**Answer (Based on Implementation):**
- **Yes, confirmed in code:**
  - After OTP verification: `Navigator.pushNamedAndRemoveUntil('/home', (route) => false, arguments: {'showWelcomeModal': true, 'showFirstPostCard': true})`
  - Welcome modal is shown for new users
  - First post card is displayed for users with 0 posts
  - **Current flow:** Signup → Interest Selection → Profile Upload → OTP Verification → Feed (with welcome modal)
  - **Recommendation:** This matches the updated flow requirement

---

## Q-8: Sign-in Precautions
**Question:** Any sign-in precautions for MVP (e.g., new IP alerts)?

**Answer (Based on Implementation):**
- **No sign-in precautions found in current code**
- Login flow only validates email/password format
- No IP tracking, device fingerprinting, or suspicious activity detection
- **Recommendation:**
  - For MVP: Basic email/password validation is acceptable
  - For production: Consider adding:
    - Failed login attempt tracking
    - IP-based anomaly detection
    - Device registration
    - Email notifications for new device logins

---

## Q-9: Feed Algorithm Testing
**Question:** How do we test algorithms (top/hot/new/new user boost)?

**Answer (Based on Implementation):**
- **No testing framework found for feed algorithms**
- Feed filters: "Hot", "Top", "New" are implemented
- Algorithm logic appears to be in backend (PostService)
- **Recommendation:**
  - Create test data sets with known engagement metrics
  - Implement A/B testing framework
  - Add logging/metrics for algorithm performance
  - Create admin panel to test different algorithm parameters
  - Document expected behavior for each feed type

---

## Q-10: Block Rules
**Question:** Should blocked users never see each other's posts except TOP/hottest/platform-pinned?

**Answer (Based on Implementation):**
- **Current implementation found in:** `lib/screens/feed/widgets/post_card.dart`
- Block message states: "You won't see each other's posts, except for official platform-pinned posts, which remain visible to all users."
- **Current behavior:** Blocking implemented, but exact filtering logic appears to be backend-driven
- **Recommendation:**
  - Confirm backend filtering excludes blocked users from feeds
  - Exception: Platform-pinned posts remain visible (as per message)
  - Clarify if TOP/hottest posts should also be visible (not mentioned in current message)
  - Update message if TOP/hottest exception is desired

---

## Q-11: Session Persistence
**Question:** Confirm rule: closing app should not log user out; session duration?

**Answer (Based on Implementation):**
- **Confirmed:** Closing app does NOT log user out
- Session persistence handled by Supabase auth
- `AuthStateService` checks session validity on app startup
- If Remember Me is enabled AND session is valid, user is auto-logged in
- **Session duration:** Supabase default session expiration (typically 1 hour, but refreshable)
- **Current behavior:**
  - Session persists across app restarts
  - If Remember Me is false, session is cleared on app restart
  - If Remember Me is true, session persists until expiration
- **Recommendation:** Document exact session duration and refresh mechanism

---

## Q-12: Admin/Mods Implementation
**Question:** Confirm Admin and mods implementation details (blocking, visibility, powers)

**Answer (Based on Implementation):**
- **Admin detection:** `email.toLowerCase() == 'admin@kp2.com'` in login screen
- Admin status stored via `AdminService.setAdminStatus()`
- Admin settings screen exists: `lib/screens/admin/admin_settings_screen.dart`
- **Current implementation:**
  - Admin role exists in database schema (`user_role` enum)
  - Admin can access admin settings
  - Moderation features exist (report handling, content blocking)
- **Recommendation:**
  - Document all admin/mod powers
  - Clarify moderation workflow
  - Define admin visibility rules
  - Connect with SET-13 for blocking/visibility details

---

## Q-13: Birthday Changes
**Question:** Restriction on changing birthday and backend writes/auditing

**Answer (Based on Implementation):**
- **Found in:** `lib/screens/settings/settings_screen.dart` - `_showEditBirthdayDialog()`
- **Current validation:**
  - Must be in YYYY-MM-DD format
  - Cannot be in the future
  - Must be within last 120 years
  - Birthday is private (not shown to others)
- **Backend:** Calls `_profileService.updateBirthday(birthday)`
- **Recommendation:**
  - Document if birthday changes should be restricted (e.g., once per year)
  - Add audit logging for birthday changes
  - Consider requiring verification for significant changes
  - Connect with Legal team for age verification requirements

---

## Q-14: WOD Rules
**Question:** WOD cannot duplicate; only posts from that week — final confirmation

**Answer (Based on Implementation):**
- **WOD (Wahala of the Day) found in:**
  - FAQ: "Wahala of the Day is a featured post that's highlighted for 24 hours"
  - Feed shows WOD posts with special variant
  - Database has `is_monthly_spotlight` field (not WOD-specific)
- **Current implementation:**
  - WOD posts are pinned at top of feed
  - Special badge/design for WOD posts
  - Monthly Spotlight exists separately
- **Recommendation:**
  - Confirm WOD vs Monthly Spotlight distinction
  - Document WOD selection rules (no duplicates, weekly posts only)
  - Implement backend validation for WOD rules
  - Connect with SET-11 for spotlight rules

---

## Q-15: CI/CD
**Question:** Any CI/CD errors contributing to stale builds or missing fixes?

**Answer (Based on Implementation):**
- **No CI/CD configuration found in codebase**
- No `.github/workflows`, `.gitlab-ci.yml`, or similar files found
- **Recommendation:**
  - Set up CI/CD pipeline
  - Add automated testing
  - Implement build verification
  - Add deployment automation
  - Document build process

---

## Q-16: Staging vs Main
**Question:** Confirm: staging = daily; main = only when ready for prod

**Answer (Based on Implementation):**
- **No deployment configuration found**
- Supabase URL is hardcoded in `main.dart`
- **Recommendation:**
  - Implement environment configuration (staging/prod)
  - Set up separate Supabase projects for staging/prod
  - Document deployment process
  - Establish staging deployment schedule (daily)
  - Main/prod deployment only when ready

---

## Q-17: Copy Fallback
**Question:** Confirm global rule: when in doubt, use text similar to Instagram/X and validate

**Answer (Based on Implementation):**
- **No global copy guidelines found**
- Current copy varies across screens
- Some messages reference Instagram/X patterns (e.g., "Report" functionality)
- **Recommendation:**
  - Create copy style guide
  - Document fallback rule (Instagram/X similarity)
  - Create error/hint message library
  - Validate all user-facing text
  - Establish copy review process

---

## Summary of Recommendations

### High Priority:
1. **Q-3:** Create centralized error/hint message library
2. **Q-4:** Implement rate limiting for account creation
3. **Q-10:** Clarify and document block rules (TOP/hottest exception)
4. **Q-11:** Document exact session duration and refresh mechanism
5. **Q-17:** Create copy style guide and message library

### Medium Priority:
1. **Q-2:** Audit and standardize icons against Figma
2. **Q-8:** Add basic sign-in security precautions
3. **Q-9:** Create feed algorithm testing framework
4. **Q-13:** Add birthday change restrictions and auditing
5. **Q-14:** Document and validate WOD rules

### Low Priority:
1. **Q-15:** Set up CI/CD pipeline
2. **Q-16:** Implement staging/prod environment separation
3. **Q-12:** Document admin/mod powers and workflows

