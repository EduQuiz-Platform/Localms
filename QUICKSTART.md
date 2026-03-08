# SmartLMS - Quick Start Guide

## What's Ready to Use Right Now ✅

1. **Complete Supabase Backend**
   - Database with 9 tables
   - Row Level Security enabled
   - Edge Functions deployed
   - Ready for production

2. **Authentication System**
   - Fully functional signup/login (index.html)
   - Role-based access control
   - Password reset workflow
   - Account security features

## Test It Now (5 Minutes)

### Step 1: Open the App
```bash
# Option 1: Direct browser
open index.html

# Option 2: Local server
npx http-server -p 3000
# Then open http://localhost:3000
```

### Step 2: Create Accounts

1. **Create a Student Account**
   - Click "Student" button
   - Fill in form
   - Email: `student@test.com`
   - Password: `password123`
   - Click "Create Account"

2. **Create a Teacher Account**
   - Go back to landing page
   - Click "Teacher" button
   - Email: `teacher@test.com`
   - Password: `password123`
   - Click "Create Account"

3. **Create an Admin Account**
   - Go back to landing page
   - Click "Admin" button
   - Email: `admin@test.com`
   - Password: `password123`
   - Click "Create Account"

### Step 3: Verify Database

1. Open [Supabase Dashboard](https://supabase.com/dashboard)
2. Go to Table Editor
3. Check `profiles` table - you should see 3 users!
4. Check `notifications` table - you should see welcome notifications
5. Check `activities` table - you should see signup activities

### Step 4: Test Login Features

1. **Test Failed Login**
   - Try logging in with wrong password 5 times
   - Account should lock for 30 minutes
   - Check `profiles.locked_until` in database

2. **Test Password Reset**
   - Click "Forgot Password"
   - Enter one of your test emails
   - Check `password_reset_requests` table
   - See request with status "pending"

## What Works Now vs. What Doesn't

### ✅ Works Now
- Signup with any role
- Login with correct credentials
- Account lockout after failed attempts
- Password reset request creation
- Maintenance mode checking
- Session management
- Automatic logout on inactive maintenance

### 📝 Not Yet Implemented
- Student dashboard (student.html needs Supabase integration)
- Teacher dashboard (teacher.html needs Supabase integration)
- Admin dashboard (admin.html needs Supabase integration)
- Assignment creation/viewing
- Submission and grading
- Notifications display
- Password reset approval

## Complete the Integration (Next Steps)

Follow these files in order:

### 1. Read the Integration Guide (15 minutes)
```bash
open SUPABASE_INTEGRATION.md
```

This file contains:
- Complete code examples
- Step-by-step instructions
- Copy-paste-ready snippets

### 2. Integrate Student Dashboard (2 hours)
File: `student.html`

Key functions to add:
- `requireStudent()` - Check auth
- `getAssignments()` - Fetch active assignments
- `submitAssignment()` - Create submission
- `getNotifications()` - Fetch user notifications

### 3. Integrate Teacher Dashboard (3 hours)
File: `teacher.html`

Key functions to add:
- `requireTeacher()` - Check auth
- `createAssignment()` - Create new assignment
- `getSubmissions()` - Fetch submissions
- `gradeSubmission()` - Grade and provide feedback

### 4. Integrate Admin Dashboard (4 hours)
File: `admin.html`

Key functions to add:
- `requireAdmin()` - Check auth
- `getAllUsers()` - Fetch all users
- `getResetRequests()` - Fetch reset requests
- `approveResetRequest()` - Approve password reset
- `updateMaintenanceConfig()` - Manage maintenance mode

## Database Schema Quick Reference

### Key Tables

**profiles** - User accounts
```sql
id, email, full_name, role, phone, active,
failed_attempts, locked_until, lockouts, flagged
```

**assignments** - Teacher-created assignments
```sql
id, teacher_id, title, description, questions (JSONB),
total_points, is_group, publish_at, unpublish_at
```

**submissions** - Student submissions
```sql
id, assignment_id, student_id, answers (JSONB),
grade, feedback, is_late, locked, submitted_at, graded_at
```

**notifications** - User notifications
```sql
id, user_id, type, message, read, created_at
```

**password_reset_requests** - Reset workflow
```sql
id, user_id, status, temp_password, denial_reason,
created_at, expires_at, reviewed_by, reviewed_at
```

## Common Queries

### Get Current User
```javascript
const { data: { session } } = await supabase.auth.getSession();
const { data: profile } = await supabase
  .from('profiles')
  .select('*')
  .eq('id', session.user.id)
  .maybeSingle();
```

### Get Active Assignments (Student)
```javascript
const now = new Date().toISOString();
const { data } = await supabase
  .from('assignments')
  .select('*')
  .lte('publish_at', now)
  .gte('unpublish_at', now);
```

### Get User's Submissions (Student)
```javascript
const { data } = await supabase
  .from('submissions')
  .select('*, assignments(title)')
  .eq('student_id', userId);
```

### Get Teacher's Assignments
```javascript
const { data } = await supabase
  .from('assignments')
  .select('*')
  .eq('teacher_id', teacherId);
```

### Get Submissions for Teacher
```javascript
const { data } = await supabase
  .from('submissions')
  .select(`
    *,
    profiles!student_id(full_name, email),
    assignments!inner(id, title, teacher_id)
  `)
  .eq('assignments.teacher_id', teacherId);
```

## Debugging Tips

### Check Authentication
```javascript
// Check if user is logged in
const { data: { session } } = await supabase.auth.getSession();
console.log('Session:', session);

// Get user details
const { data: { user } } = await supabase.auth.getUser();
console.log('User:', user);
```

### Check RLS Policies
```javascript
// If query returns empty but data exists, check RLS
// View policies in Supabase Dashboard > Authentication > Policies
// Or query directly:
const { data, error } = await supabase
  .from('table_name')
  .select('*');

if (error) {
  console.error('RLS might be blocking:', error);
}
```

### View Edge Function Logs
1. Go to Supabase Dashboard
2. Click "Edge Functions"
3. Select function
4. View logs in real-time

### Check Browser Console
- All Supabase errors show in console
- Look for authentication errors
- Check for CORS issues
- Verify API calls

## Environment Variables

Already configured in `.env`:
```
VITE_SUPABASE_URL=https://scgmwwomswamcyxtfhpr.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Deploy to Production (15 minutes)

### Option 1: Vercel (Recommended)
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod

# Add environment variables in Vercel dashboard
```

### Option 2: Netlify
```bash
# Install Netlify CLI
npm i -g netlify-cli

# Deploy
netlify deploy --prod --dir .
```

### Option 3: Any Static Host
Upload these files to your host:
- index.html
- student.html
- teacher.html
- admin.html
- supabase-config.js

## Support Resources

- **Integration Guide**: `SUPABASE_INTEGRATION.md`
- **Architecture Docs**: `ARCHITECTURE.md`
- **Migration Summary**: `MIGRATION_SUMMARY.md`
- **Full README**: `README.md`

### External Documentation
- [Supabase Docs](https://supabase.com/docs)
- [Supabase JavaScript Client](https://supabase.com/docs/reference/javascript/introduction)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

## Common Issues & Solutions

### Issue: "User not found" on login
**Solution**: Make sure you signed up first. Check `profiles` table in Supabase.

### Issue: "Invalid API key"
**Solution**: Verify `.env` file has correct `VITE_SUPABASE_ANON_KEY`.

### Issue: "Permission denied" errors
**Solution**: RLS policies are working! Make sure you're logged in and have the correct role.

### Issue: Student dashboard shows nothing
**Solution**: Dashboard not yet integrated. Follow `SUPABASE_INTEGRATION.md` to add Supabase queries.

### Issue: Can't access teacher/admin features
**Solution**: Make sure you signed up with "Teacher" or "Admin" role. Check `profiles.role` in database.

## Testing Checklist

After completing integration:

- [ ] Signup as student, teacher, admin
- [ ] Login with each role
- [ ] Test wrong password (triggers lockout)
- [ ] Request password reset
- [ ] Verify admin can see reset request
- [ ] Teacher creates assignment
- [ ] Student views assignment
- [ ] Student submits assignment
- [ ] Teacher grades submission
- [ ] Student sees grade
- [ ] Admin manages users
- [ ] Admin enables maintenance mode
- [ ] Verify non-admins blocked during maintenance

## Project File Structure

```
SmartLMS/
├── index.html                    ✅ Authentication (DONE)
├── student.html                  📝 Student dashboard (TODO)
├── teacher.html                  📝 Teacher dashboard (TODO)
├── admin.html                    📝 Admin dashboard (TODO)
├── supabase-config.js            ✅ Helper functions
│
├── supabase/
│   └── functions/
│       ├── handle-new-user/      ✅ Deployed
│       └── send-notification/    ✅ Deployed
│
├── .env                          ✅ Configuration
├── package.json                  ✅ NPM config
├── vercel.json                   ✅ Deployment config
│
└── docs/
    ├── README.md                 📚 Project overview
    ├── SUPABASE_INTEGRATION.md   📚 Integration guide
    ├── ARCHITECTURE.md           📚 System architecture
    ├── MIGRATION_SUMMARY.md      📚 What was done
    └── QUICKSTART.md            📚 This file
```

## Success Criteria

You'll know the integration is complete when:

✅ Users can signup and login
✅ Students can view and submit assignments
✅ Teachers can create assignments and grade submissions
✅ Admins can manage users and system settings
✅ All roles enforced by RLS at database level
✅ Notifications working
✅ Password reset workflow functional
✅ Maintenance mode working
✅ Activity logging tracking all actions

## Estimated Timeline

- **Backend Setup**: ✅ Complete (4-6 hours already done)
- **index.html Integration**: ✅ Complete (2 hours already done)
- **student.html Integration**: 📝 2 hours
- **teacher.html Integration**: 📝 3 hours
- **admin.html Integration**: 📝 4 hours
- **Testing**: 📝 2 hours
- **Deployment**: 📝 1 hour

**Total Remaining**: ~12 hours

## Get Help

If you get stuck:
1. Check browser console for errors
2. Review Supabase dashboard logs
3. Verify RLS policies
4. Read integration guide code examples
5. Test Edge Functions independently

## Next Action

Open `SUPABASE_INTEGRATION.md` and start with the student dashboard integration. The file contains complete, working code you can copy and paste!

```bash
open SUPABASE_INTEGRATION.md
```

Good luck! 🚀