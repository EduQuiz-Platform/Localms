# SmartLMS Supabase Integration Guide

## Overview

This document describes the complete Supabase backend integration for SmartLMS. The localStorage-based system has been replaced with a robust Supabase backend featuring:

- Full multi-user, multi-device persistence
- Secure role-based access control (RBAC)
- Real-time data synchronization
- Comprehensive audit logging
- Password reset workflow with admin approval
- Maintenance mode functionality

## What's Been Completed

### 1. Database Schema ✅

All necessary tables have been created with proper relationships:

- **profiles**: User information linked to Supabase Auth
- **password_reset_requests**: Admin-approved password reset workflow
- **assignments**: Teacher-created assignments with questions
- **submissions**: Student submissions with grading
- **group_members**: Group assignment membership
- **feedback_copies**: Teacher-editable submission copies
- **notifications**: User notification system
- **activities**: Audit log for all user actions
- **maintenance_schedules**: System maintenance configuration

### 2. Row Level Security (RLS) Policies ✅

All tables have comprehensive RLS policies enforcing:

- **Students**: Can only view/edit their own data
- **Teachers**: Can manage their assignments and grade submissions
- **Admins**: Full access to all data

### 3. Edge Functions ✅

Two Edge Functions deployed:

- **handle-new-user**: Creates profile and welcome notification on signup
- **send-notification**: Sends notifications to users (used by teachers/admins)

### 4. Authentication ✅

- **index.html** fully integrated with Supabase Auth
- Signup with email/password
- Login with account lockout protection (5 attempts = 30min lock)
- Password reset request workflow (admin approval required)
- Maintenance mode enforcement
- Automatic session management

## Integration Instructions for Remaining Pages

### Student Dashboard (student.html)

Replace localStorage calls with Supabase queries:

```javascript
// At the top, add Supabase initialization
const SUPABASE_URL = 'https://scgmwwomswamcyxtfhpr.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNjZ213d29tc3dhbWN5eHRmaHByIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI5MjU4MTAsImV4cCI6MjA4ODUwMTgxMH0.ptmhYha50Kg1ZxQesqD_FjARVLlXL6hcerKGncoEhrY';
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Check authentication
async function requireStudent() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) {
    window.location.href = 'index.html';
    return null;
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', session.user.id)
    .maybeSingle();

  if (!profile || profile.role !== 'student') {
    alert('Access denied');
    window.location.href = 'index.html';
    return null;
  }

  return profile;
}

// Get assignments (active only)
async function getAssignments() {
  const now = new Date().toISOString();
  const { data, error } = await supabase
    .from('assignments')
    .select('*')
    .lte('publish_at', now)
    .gte('unpublish_at', now)
    .order('unpublish_at', { ascending: true });

  if (error) {
    console.error('Error fetching assignments:', error);
    return [];
  }

  return data || [];
}

// Get student's submissions
async function getSubmissions(studentId) {
  const { data, error } = await supabase
    .from('submissions')
    .select('*, assignments(title)')
    .eq('student_id', studentId);

  if (error) {
    console.error('Error fetching submissions:', error);
    return [];
  }

  return data || [];
}

// Create/update submission
async function submitAssignment(assignmentId, studentId, answers) {
  const submissionData = {
    assignment_id: assignmentId,
    student_id: studentId,
    answers,
    submitted_at: new Date().toISOString()
  };

  const { data, error } = await supabase
    .from('submissions')
    .upsert(submissionData, { onConflict: 'assignment_id,student_id' })
    .select()
    .single();

  if (error) {
    console.error('Submission error:', error);
    return null;
  }

  return data;
}

// Get notifications
async function getNotifications(userId) {
  const { data, error } = await supabase
    .from('notifications')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(50);

  return data || [];
}

// Logout
async function logout() {
  await supabase.auth.signOut();
  window.location.href = 'index.html';
}
```

### Teacher Dashboard (teacher.html)

```javascript
// Supabase initialization (same as above)

// Check authentication
async function requireTeacher() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) {
    window.location.href = 'index.html';
    return null;
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', session.user.id)
    .maybeSingle();

  if (!profile || profile.role !== 'teacher') {
    alert('Access denied');
    window.location.href = 'index.html';
    return null;
  }

  return profile;
}

// Get teacher's assignments
async function getAssignments(teacherId) {
  const { data, error } = await supabase
    .from('assignments')
    .select('*')
    .eq('teacher_id', teacherId)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching assignments:', error);
    return [];
  }

  return data || [];
}

// Create assignment
async function createAssignment(assignmentData) {
  const { data, error } = await supabase
    .from('assignments')
    .insert(assignmentData)
    .select()
    .single();

  if (error) {
    console.error('Error creating assignment:', error);
    return null;
  }

  return data;
}

// Update assignment
async function updateAssignment(assignmentId, updates) {
  const { data, error } = await supabase
    .from('assignments')
    .update(updates)
    .eq('id', assignmentId)
    .select()
    .single();

  if (error) {
    console.error('Error updating assignment:', error);
    return null;
  }

  return data;
}

// Delete assignment
async function deleteAssignment(assignmentId) {
  const { error } = await supabase
    .from('assignments')
    .delete()
    .eq('id', assignmentId);

  if (error) {
    console.error('Error deleting assignment:', error);
    return false;
  }

  return true;
}

// Get submissions for teacher's assignments
async function getSubmissions(teacherId) {
  const { data, error } = await supabase
    .from('submissions')
    .select(`
      *,
      profiles!student_id(full_name, email),
      assignments!inner(id, title, teacher_id)
    `)
    .eq('assignments.teacher_id', teacherId)
    .order('submitted_at', { ascending: false });

  if (error) {
    console.error('Error fetching submissions:', error);
    return [];
  }

  return data || [];
}

// Grade submission
async function gradeSubmission(submissionId, grade, feedback, teacherId) {
  const { data, error } = await supabase
    .from('submissions')
    .update({
      grade,
      feedback,
      graded_at: new Date().toISOString(),
      graded_by: teacherId,
      locked: true
    })
    .eq('id', submissionId)
    .select()
    .single();

  if (error) {
    console.error('Error grading submission:', error);
    return null;
  }

  // Send notification to student
  const submission = data;
  await supabase.functions.invoke('send-notification', {
    body: {
      user_id: submission.student_id,
      type: 'grade_received',
      message: `Your assignment has been graded. Score: ${grade}`
    }
  });

  return data;
}

// Get student profiles for dropdown
async function getStudentProfiles() {
  const { data, error } = await supabase
    .from('profiles')
    .select('id, email, full_name')
    .eq('role', 'student')
    .order('full_name');

  return data || [];
}

// Manage group members
async function addGroupMember(submissionId, studentId) {
  const { data, error } = await supabase
    .from('group_members')
    .insert({ submission_id: submissionId, student_id: studentId })
    .select()
    .single();

  if (error) {
    console.error('Error adding group member:', error);
    return null;
  }

  return data;
}

async function removeGroupMember(submissionId, studentId) {
  const { error } = await supabase
    .from('group_members')
    .delete()
    .eq('submission_id', submissionId)
    .eq('student_id', studentId);

  return !error;
}

async function getGroupMembers(submissionId) {
  const { data, error } = await supabase
    .from('group_members')
    .select('*, profiles(full_name, email)')
    .eq('submission_id', submissionId);

  return data || [];
}
```

### Admin Dashboard (admin.html)

```javascript
// Supabase initialization (same as above)

// Check authentication
async function requireAdmin() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) {
    window.location.href = 'index.html';
    return null;
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', session.user.id)
    .maybeSingle();

  if (!profile || profile.role !== 'admin') {
    alert('Access denied');
    window.location.href = 'index.html';
    return null;
  }

  return profile;
}

// Get all users
async function getAllUsers() {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching users:', error);
    return [];
  }

  return data || [];
}

// Update user
async function updateUser(userId, updates) {
  const { data, error } = await supabase
    .from('profiles')
    .update(updates)
    .eq('id', userId)
    .select()
    .single();

  if (error) {
    console.error('Error updating user:', error);
    return null;
  }

  return data;
}

// Delete user
async function deleteUser(userId) {
  // This will cascade delete all related data
  const { error } = await supabase.auth.admin.deleteUser(userId);

  if (error) {
    console.error('Error deleting user:', error);
    return false;
  }

  return true;
}

// Get password reset requests
async function getResetRequests(status = null) {
  let query = supabase
    .from('password_reset_requests')
    .select('*, profiles(full_name, email, role)')
    .order('created_at', { ascending: false });

  if (status) {
    query = query.eq('status', status);
  }

  const { data, error } = await query;

  if (error) {
    console.error('Error fetching reset requests:', error);
    return [];
  }

  return data || [];
}

// Approve reset request
async function approveResetRequest(requestId, adminId) {
  const { data, error } = await supabase
    .from('password_reset_requests')
    .update({
      status: 'approved',
      reviewed_by: adminId,
      reviewed_at: new Date().toISOString()
    })
    .eq('id', requestId)
    .select('*, profiles(id, email)')
    .single();

  if (error) {
    console.error('Error approving reset:', error);
    return null;
  }

  // Update user's password using temp password
  if (data && data.temp_password) {
    // Send notification
    await supabase.functions.invoke('send-notification', {
      body: {
        user_id: data.user_id,
        type: 'reset_approved',
        message: `Your password reset was approved. Temporary password: ${data.temp_password}`
      }
    });
  }

  return data;
}

// Deny reset request
async function denyResetRequest(requestId, adminId, reason) {
  const { data, error } = await supabase
    .from('password_reset_requests')
    .update({
      status: 'denied',
      denial_reason: reason,
      reviewed_by: adminId,
      reviewed_at: new Date().toISOString()
    })
    .eq('id', requestId)
    .select()
    .single();

  if (error) {
    console.error('Error denying reset:', error);
    return null;
  }

  // Send notification
  await supabase.functions.invoke('send-notification', {
    body: {
      user_id: data.user_id,
      type: 'reset_denied',
      message: reason ? `Your password reset was denied: ${reason}` : 'Your password reset was denied.'
    }
  });

  return data;
}

// Get all assignments (for analytics)
async function getAllAssignments() {
  const { data, error } = await supabase
    .from('assignments')
    .select('*, profiles(full_name)')
    .order('created_at', { ascending: false });

  return data || [];
}

// Get all submissions (for analytics)
async function getAllSubmissions() {
  const { data, error } = await supabase
    .from('submissions')
    .select('*');

  return data || [];
}

// Get activities/audit log
async function getActivities(limit = 100) {
  const { data, error } = await supabase
    .from('activities')
    .select('*, profiles(full_name, email)')
    .order('created_at', { ascending: false })
    .limit(limit);

  return data || [];
}

// Maintenance mode management
async function getMaintenanceConfig() {
  const { data, error } = await supabase
    .from('maintenance_schedules')
    .select('*')
    .limit(1)
    .maybeSingle();

  return data || { enabled: false, schedules: [] };
}

async function updateMaintenanceConfig(updates) {
  const { data: existing } = await supabase
    .from('maintenance_schedules')
    .select('id')
    .limit(1)
    .maybeSingle();

  if (existing) {
    const { data, error } = await supabase
      .from('maintenance_schedules')
      .update(updates)
      .eq('id', existing.id)
      .select()
      .single();

    return data;
  } else {
    const { data, error } = await supabase
      .from('maintenance_schedules')
      .insert(updates)
      .select()
      .single();

    return data;
  }
}

// Enable maintenance mode
async function enableMaintenance(durationHours) {
  const until = new Date(Date.now() + durationHours * 3600 * 1000).toISOString();
  return await updateMaintenanceConfig({
    enabled: true,
    manual_until: until
  });
}

// Disable maintenance mode
async function disableMaintenance() {
  return await updateMaintenanceConfig({
    enabled: false,
    manual_until: null
  });
}

// Add scheduled maintenance
async function addMaintenanceSchedule(startAt, durationHours) {
  const config = await getMaintenanceConfig();
  const schedules = config.schedules || [];

  schedules.push({
    id: 'sch_' + Date.now(),
    startAt: new Date(startAt).toISOString(),
    endAt: new Date(new Date(startAt).getTime() + durationHours * 3600 * 1000).toISOString(),
    createdAt: new Date().toISOString(),
    durationHrs: durationHours
  });

  return await updateMaintenanceConfig({ schedules });
}

// Send notification to all users
async function notifyAllUsers(message, excludeAdmins = false) {
  const users = await getAllUsers();
  const targetUsers = excludeAdmins
    ? users.filter(u => u.role !== 'admin')
    : users;

  const notifications = targetUsers.map(u => ({
    user_id: u.id,
    type: 'system_announcement',
    message
  }));

  const { error } = await supabase
    .from('notifications')
    .insert(notifications);

  return !error;
}
```

## File Attachments Handling

The existing system stores file attachments as Base64 data URLs. For a production system, consider:

1. **Supabase Storage** for file uploads:
```javascript
async function uploadFile(file, bucket = 'assignments') {
  const fileExt = file.name.split('.').pop();
  const fileName = `${Math.random()}.${fileExt}`;
  const filePath = `${bucket}/${fileName}`;

  const { data, error } = await supabase.storage
    .from('files')
    .upload(filePath, file);

  if (error) return null;

  const { data: { publicUrl } } = supabase.storage
    .from('files')
    .getPublicUrl(filePath);

  return publicUrl;
}
```

2. For now, continue using Base64 data URLs stored in JSONB fields.

## Testing Checklist

- [ ] Signup as student, teacher, admin
- [ ] Login with correct/incorrect credentials
- [ ] Test account lockout (5 failed attempts)
- [ ] Request password reset
- [ ] Admin approves/denies reset
- [ ] Teacher creates assignment
- [ ] Student views and submits assignment
- [ ] Teacher grades submission
- [ ] Student receives grade notification
- [ ] Admin manages users
- [ ] Admin views analytics
- [ ] Admin enables/disables maintenance mode
- [ ] Test maintenance mode blocks non-admin users
- [ ] Test notifications system
- [ ] Test activity logging

## Deployment on Vercel

1. Create `vercel.json`:
```json
{
  "buildCommand": "echo 'No build required'",
  "outputDirectory": ".",
  "framework": null,
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/$1"
    }
  ]
}
```

2. Add environment variables in Vercel dashboard:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`

3. Deploy: `vercel --prod`

## Security Notes

1. All RLS policies are enforced at the database level
2. Supabase Auth handles password hashing and JWT tokens
3. Failed login attempts are tracked and accounts auto-lock
4. Admin approval required for password resets
5. Activity logging for audit trail
6. Maintenance mode enforced at application level

## Support

For issues or questions, refer to:
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase JavaScript Client](https://supabase.com/docs/reference/javascript/introduction)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
