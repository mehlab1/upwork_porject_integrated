# Post Reporting System Guide
**Task: ADO-909 - Integrate 'Report Post' Action**

## Overview

Complete backend implementation for post reporting with:
- ✅ Multiple report reasons
- ✅ Optional description
- ✅ One report per user per post
- ✅ Auto-flagging after threshold (3+ reports)
- ✅ Admin moderation interface
- ✅ Report status tracking

---

## Architecture

### Components

1. **Database Layer**
   - `post_reports` table: Stores individual reports
   - `report_post()` function: Handles report submission
   - `update_post_report_count()` trigger: Auto-updates counts
   - RLS policies for security

2. **Edge Function**
   - `report-post`: API endpoint for submitting reports
   - Authentication required
   - Validates input and prevents duplicates

3. **Feed Integration**
   - All feed functions include `has_reported` field
   - UI knows if user already reported a post

---

## Database Schema

### `post_reports` Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `post_id` | UUID | Reference to reported post |
| `reported_by` | UUID | User who submitted report |
| `reason` | ENUM | Reason for report |
| `description` | TEXT | Optional details (10-500 chars) |
| `status` | ENUM | pending/under_review/resolved/dismissed |
| `reviewed_by` | UUID | Admin who reviewed (nullable) |
| `reviewed_at` | TIMESTAMP | When reviewed |
| `resolution_notes` | TEXT | Admin notes |
| `created_at` | TIMESTAMP | When report was submitted |

**Unique Constraint:** `(post_id, reported_by)` - one report per user per post

### Report Reasons

- `spam` - Unwanted commercial content
- `harassment` - Bullying or harassment
- `hate_speech` - Hateful or discriminatory content
- `violence` - Violent threats or content
- `inappropriate_content` - NSFW or offensive material
- `misinformation` - False or misleading information
- `copyright_violation` - Stolen or copyrighted content
- `scam` - Fraudulent or deceptive content
- `other` - Other reasons

### Report Status

- `pending` - Awaiting review
- `under_review` - Being reviewed by moderator
- `resolved` - Action taken
- `dismissed` - No action needed

---

## API Usage

### Endpoint

```
POST /functions/v1/report-post
```

### Headers

```
Authorization: Bearer <access_token>
apikey: <supabase_anon_key>
Content-Type: application/json
```

### Request Body

```json
{
  "post_id": "uuid-of-post",
  "reason": "spam",  // See valid reasons above
  "description": "This post is promoting unwanted products"  // Optional
}
```

### Response - Success

```json
{
  "success": true,
  "message": "Report submitted successfully",
  "report_id": "uuid-of-report"
}
```

### Response - Already Reported

```json
{
  "success": false,
  "error": "You have already reported this post"
}
```

### Response - Invalid Reason

```json
{
  "success": false,
  "error": "Invalid reason. Must be one of: spam, harassment, hate_speech, ..."
}
```

---

## Frontend Integration

### Report Button UI

```dart
class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;

  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Post content...
          
          // Actions row
          Row(
            children: [
              // Vote buttons...
              
              Spacer(),
              
              // Report button
              if (!post['has_reported'])
                IconButton(
                  icon: Icon(Icons.flag_outlined),
                  onPressed: () => showReportDialog(context, post['id']),
                  tooltip: 'Report Post',
                )
              else
                // Show "Reported" status
                Chip(
                  label: Text('Reported'),
                  avatar: Icon(Icons.flag, size: 16),
                  backgroundColor: Colors.red[100],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### Report Dialog

```dart
void showReportDialog(BuildContext context, String postId) {
  String selectedReason = 'spam';
  TextEditingController descController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Report Post'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reason dropdown
          DropdownButton<String>(
            value: selectedReason,
            isExpanded: true,
            items: [
              DropdownMenuItem(value: 'spam', child: Text('Spam')),
              DropdownMenuItem(value: 'harassment', child: Text('Harassment')),
              DropdownMenuItem(value: 'hate_speech', child: Text('Hate Speech')),
              DropdownMenuItem(value: 'violence', child: Text('Violence')),
              DropdownMenuItem(value: 'inappropriate_content', child: Text('Inappropriate Content')),
              DropdownMenuItem(value: 'misinformation', child: Text('Misinformation')),
              DropdownMenuItem(value: 'copyright_violation', child: Text('Copyright Violation')),
              DropdownMenuItem(value: 'scam', child: Text('Scam')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (value) {
              setState(() {
                selectedReason = value!;
              });
            },
          ),
          SizedBox(height: 16),
          
          // Optional description
          TextField(
            controller: descController,
            decoration: InputDecoration(
              labelText: 'Additional details (optional)',
              hintText: 'Explain why you\'re reporting this post',
              border: OutlineInputBorder(),
            ),
            maxLength: 500,
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text('Submit Report'),
          onPressed: () async {
            Navigator.pop(context);
            await reportPost(postId, selectedReason, descController.text);
          },
        ),
      ],
    ),
  );
}
```

### Report Function

```dart
Future<void> reportPost(String postId, String reason, String description) async {
  try {
    final response = await supabase.functions.invoke(
      'report-post',
      body: {
        'post_id': postId,
        'reason': reason,
        'description': description.isNotEmpty ? description : null,
      },
    );

    if (response.data['success']) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Update UI to show "Reported" status
      setState(() {
        post['has_reported'] = true;
      });
    } else {
      // Show error
      showErrorDialog(response.data['error']);
    }
  } catch (e) {
    showErrorDialog('Failed to submit report: $e');
  }
}
```

### Check Report Status (from Feed)

```dart
// Feed query includes has_reported field
final posts = await supabase.rpc('get_posts_hot', params: {
  'p_user_id': currentUserId,
  'p_limit': 20,
});

// Each post includes:
for (var post in posts) {
  print('Has reported: ${post['has_reported']}');
  
  // Show different UI based on status
  if (post['has_reported']) {
    // Show "Reported" chip instead of report button
  }
}
```

---

## Auto-Flagging

### Threshold System

When a post receives **3 or more reports**:
- Post status automatically changes to `'flagged'`
- Post is hidden from public feeds
- Moderators are notified for review

### Database Logic

```sql
-- After each report, check count
IF report_count >= 3 THEN
    UPDATE posts
    SET status = 'flagged'
    WHERE id = post_id AND status = 'active';
END IF;
```

---

## Admin/Moderator Functions

### Get All Reports for a Post

**Function:** `get_post_reports()`
**Access:** Admin/Moderator only

```sql
SELECT * FROM get_post_reports(
  p_post_id := 'uuid-of-post',
  p_limit := 50
);
```

**Returns:**
```sql
id | reported_by | reporter_username | reason | description | status | created_at
```

### Update Report Status

**Function:** `update_report_status()`
**Access:** Admin/Moderator only

```sql
SELECT * FROM update_report_status(
  p_report_id := 'uuid-of-report',
  p_status := 'resolved',  -- or 'dismissed' or 'under_review'
  p_resolution_notes := 'Post removed for violating terms'
);
```

---

## Security Features

### RLS Policies

- ✅ Users can only view their own reports
- ✅ Users can only submit reports as themselves
- ✅ One report per user per post (enforced by unique constraint)
- ✅ Only admins/moderators can update/delete reports
- ✅ Only admins/moderators can view all reports

### Rate Limiting

- Database constraint prevents duplicate reports
- No additional rate limiting needed (already covered by unique constraint)

### Validation

- Reason must be one of valid enum values
- Description must be 10-500 characters (if provided)
- Post must exist
- User must be authenticated

---
