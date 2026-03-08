# SmartLMS - Supabase Backend Integration

A complete Learning Management System (LMS) with Supabase backend, featuring role-based access control, assignment management, grading system, and admin controls.

## Features

### Authentication & Security
- Secure email/password authentication via Supabase Auth
- Role-based access control (Student, Teacher, Admin)
- Account lockout protection (5 failed attempts = 30min lock)
- Admin-approved password reset workflow
- Activity audit logging
- Maintenance mode with scheduled downtime

### Student Features
- View active assignments
- Submit assignments with file uploads
- View grades and feedback
- Receive notifications
- Track submission history

### Teacher Features
- Create and manage assignments
- Question types: Essay, File Upload, Link/Resource
- Add hints and explanations to questions
- Grade student submissions
- Provide detailed feedback
- Manage group assignments
- View submission analytics

### Admin Features
- User management (create, edit, deactivate, delete)
- Approve/deny password reset requests
- View system analytics
- Activity audit log
- Maintenance mode scheduling
- Bulk operations
- Security monitoring (locked accounts, flagged users)

## Technology Stack

- **Frontend**: Pure HTML, CSS, JavaScript (no build step required)
- **Backend**: Supabase
  - PostgreSQL database
  - Supabase Auth
  - Row Level Security (RLS)
  - Edge Functions
- **Deployment**: Vercel (or any static host)

## Database Schema

### Core Tables
- `profiles` - User information and settings
- `password_reset_requests` - Password reset workflow
- `assignments` - Teacher-created assignments
- `submissions` - Student submissions
- `group_members` - Group assignment members
- `feedback_copies` - Teacher-editable submission copies
- `notifications` - User notifications
- `activities` - Audit log
- `maintenance_schedules` - System maintenance config

## Setup Instructions

### Prerequisites
- Supabase account and project
- Node.js (for local development, optional)

### Database Setup

The database has already been configured with:
1. All tables created with proper relationships
2. Row Level Security (RLS) policies applied
3. Triggers for automatic timestamps and activity logging
4. Indexes for optimal query performance

### Edge Functions Deployed

Two Edge Functions are already deployed:
- `handle-new-user`: Creates profile on signup
- `send-notification`: Sends notifications to users

### Environment Variables

The `.env` file contains your Supabase credentials:
```
VITE_SUPABASE_URL=https://scgmwwomswamcyxtfhpr.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Local Development

1. Open `index.html` in a web browser directly, or
2. Use a local server:
```bash
npx http-server -p 3000
```

Then navigate to `http://localhost:3000`

### Deployment to Vercel

1. Install Vercel CLI: `npm i -g vercel`
2. Run: `vercel`
3. Follow prompts to deploy

The `vercel.json` configuration is already set up.

## Project Structure

```
.
├── index.html                      # Auth page (login/signup) - FULLY INTEGRATED ✅
├── student.html                    # Student dashboard - NEEDS INTEGRATION
├── teacher.html                    # Teacher dashboard - NEEDS INTEGRATION
├── admin.html                      # Admin dashboard - NEEDS INTEGRATION
├── supabase-config.js              # Supabase helper functions
├── supabase/
│   └── functions/
│       ├── send-notification/      # Notification Edge Function ✅
│       └── handle-new-user/        # User creation Edge Function ✅
├── .env                            # Environment variables
├── package.json                    # NPM configuration
├── vercel.json                     # Vercel deployment config
├── SUPABASE_INTEGRATION.md         # Integration guide
└── README.md                       # This file
```

## Integration Status

### ✅ Completed
- Database schema with all tables
- Row Level Security (RLS) policies
- Edge Functions deployed
- index.html fully integrated with Supabase Auth
- Authentication flow (signup, login, password reset)
- Account security (lockouts, flagging)
- Maintenance mode functionality

### 📝 Next Steps

The **student.html**, **teacher.html**, and **admin.html** files need to be updated to use Supabase instead of localStorage.

**Detailed integration instructions are provided in `SUPABASE_INTEGRATION.md`**

Key changes needed for each file:
1. Add Supabase client initialization
2. Replace localStorage calls with Supabase queries
3. Update session management to use Supabase Auth
4. Implement proper error handling
5. Add loading states

## User Roles & Permissions

### Student
- ✅ View published assignments (within publish window)
- ✅ Submit assignments
- ✅ View own submissions and grades
- ✅ Receive notifications
- ❌ Cannot view other students' work
- ❌ Cannot access teacher/admin features

### Teacher
- ✅ Create, edit, delete own assignments
- ✅ View all submissions for their assignments
- ✅ Grade submissions
- ✅ Send notifications to students
- ✅ Manage group assignments
- ❌ Cannot access other teachers' assignments
- ❌ Cannot access admin features

### Admin
- ✅ Full access to all data
- ✅ User management (CRUD operations)
- ✅ Approve/deny password reset requests
- ✅ View system analytics
- ✅ Manage maintenance mode
- ✅ View audit logs
- ✅ Send system-wide notifications

## Security Features

### Authentication
- Supabase Auth handles password hashing (bcrypt)
- JWT tokens for session management
- Automatic session refresh
- Secure password requirements (8+ chars, letters + numbers)

### Account Protection
- Failed login attempt tracking
- Automatic lockout after 5 failed attempts (30 minutes)
- Flag accounts with 3+ lockouts
- Admin can manually lock/unlock accounts

### Data Security
- Row Level Security (RLS) enforced at database level
- Users can only access their own data
- Teachers can only access their assignments/students
- Admins have full access
- All policies validated server-side

### Audit Trail
- All critical operations logged to `activities` table
- Tracks user actions, timestamps, metadata
- Admin can review audit log

## Password Reset Workflow

1. User requests password reset on index.html
2. Temporary password generated and stored in `password_reset_requests` table
3. Request set to "pending" status
4. Admin reviews request in admin dashboard
5. Admin can approve (with temp password) or deny (with reason)
6. User receives notification of decision
7. If approved, user logs in with temp password
8. User prompted to set new password
9. Request expires after 72 hours

## Maintenance Mode

Admins can:
- Enable immediate maintenance mode (duration in hours)
- Schedule future maintenance windows
- Set recurring maintenance schedules
- Automatically log out non-admin users during maintenance
- Display countdown timers to users

During maintenance:
- Only admins can log in
- Students and teachers see maintenance message
- Countdown shows time remaining

## Data Migration

The original localStorage data structure is preserved. No migration needed since:
1. Old system used IndexedDB/localStorage per-device
2. New system uses Supabase multi-device
3. Users will need to re-register (data was local-only)

For production deployments with existing users, create a migration script to:
1. Export localStorage data
2. Format for Supabase schema
3. Bulk import via Supabase API

## Testing Guide

### Test User Accounts
Create test accounts for each role:
```
Student: student@test.com
Teacher: teacher@test.com
Admin: admin@test.com
```

### Test Scenarios

1. **Authentication**
   - Signup with each role
   - Login with correct credentials
   - Login with wrong password (trigger lockout)
   - Request password reset
   - Admin approve/deny reset

2. **Student Workflow**
   - View active assignments
   - Submit assignment
   - View grade/feedback

3. **Teacher Workflow**
   - Create assignment with questions
   - Set publish/unpublish times
   - Grade student submission
   - Provide feedback

4. **Admin Workflow**
   - View all users
   - Edit user details
   - Deactivate/reactivate user
   - Approve password reset
   - View analytics
   - Enable maintenance mode

5. **Security Tests**
   - Try accessing admin page as student
   - Try accessing other users' data
   - Test account lockout
   - Test maintenance mode enforcement

## API Reference

See `SUPABASE_INTEGRATION.md` for complete API documentation including:
- Supabase query examples
- Edge Function usage
- RLS policy explanations
- Helper function library

## Troubleshooting

### Authentication Issues
- Clear browser storage and cookies
- Check Supabase project status
- Verify .env credentials match Supabase dashboard

### RLS Policy Errors
- Ensure user is authenticated
- Check user role matches required permission
- Review browser console for detailed error messages

### Edge Function Errors
- Check function logs in Supabase dashboard
- Verify function is deployed
- Test function independently via Supabase dashboard

## Performance Considerations

- Database queries optimized with indexes
- RLS policies use efficient joins
- Pagination recommended for large datasets
- Consider caching frequently accessed data
- Use Supabase Realtime for live updates (optional enhancement)

## Future Enhancements

Potential improvements:
- Real-time collaboration on assignments
- File uploads to Supabase Storage (instead of Base64)
- Email notifications via Supabase SMTP
- Advanced analytics dashboard
- Export grades to CSV/Excel
- Plagiarism detection integration
- Video/audio submission support
- Discussion forums
- Calendar integration
- Mobile app (React Native)

## Support & Documentation

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase JavaScript Client](https://supabase.com/docs/reference/javascript/introduction)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Edge Functions Guide](https://supabase.com/docs/guides/functions)

## License

MIT License - feel free to use this project as a template for your own LMS.

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Credits

Built with Supabase, PostgreSQL, and vanilla JavaScript. No frameworks required!