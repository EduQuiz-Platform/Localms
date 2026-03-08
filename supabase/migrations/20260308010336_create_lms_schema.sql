/*
  # SmartLMS Database Schema
  
  ## Overview
  Complete database schema for a Learning Management System with role-based access control,
  assignment management, grading system, notifications, and maintenance mode.
  
  ## Tables Created
  
  ### 1. profiles
  Extended user profile information linked to auth.users
  - `id` (uuid, references auth.users) - User ID from Supabase Auth
  - `email` (text) - User email
  - `full_name` (text) - Full name of user
  - `role` (text) - User role: 'student', 'teacher', or 'admin'
  - `phone` (text, optional) - Phone number
  - `failed_attempts` (integer) - Failed login attempts counter
  - `locked_until` (timestamptz, nullable) - Account lock expiration
  - `lockouts` (integer) - Total number of lockouts
  - `flagged` (boolean) - Admin flag for suspicious accounts
  - `active` (boolean) - Account active status
  - `created_at` (timestamptz) - Account creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp
  
  ### 2. password_reset_requests
  Password reset workflow management
  - `id` (uuid) - Request ID
  - `user_id` (uuid, references profiles) - User requesting reset
  - `status` (text) - Status: 'pending', 'approved', 'denied', 'expired'
  - `temp_password` (text, nullable) - Temporary password (only for approved)
  - `denial_reason` (text, nullable) - Reason if denied
  - `created_at` (timestamptz) - Request timestamp
  - `expires_at` (timestamptz) - Expiration timestamp (72 hours)
  - `reviewed_by` (uuid, nullable) - Admin who reviewed
  - `reviewed_at` (timestamptz, nullable) - Review timestamp
  
  ### 3. assignments
  Assignment/quiz management
  - `id` (uuid) - Assignment ID
  - `teacher_id` (uuid, references profiles) - Creator teacher
  - `title` (text) - Assignment title
  - `description` (text) - Assignment description
  - `questions` (jsonb) - Array of question objects with type, text, points, hints, explanations, attachments
  - `total_points` (integer) - Total possible points
  - `is_group` (boolean) - Whether it's a group assignment
  - `publish_at` (timestamptz) - When to publish to students
  - `unpublish_at` (timestamptz) - Deadline/unpublish time
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp
  
  ### 4. submissions
  Student submission tracking
  - `id` (uuid) - Submission ID
  - `assignment_id` (uuid, references assignments) - Related assignment
  - `student_id` (uuid, references profiles) - Submitting student
  - `answers` (jsonb) - Array of answer objects
  - `grade` (numeric, nullable) - Final grade/score
  - `late_penalty` (numeric) - Late submission penalty percentage
  - `feedback` (text, nullable) - General teacher feedback
  - `is_late` (boolean) - Whether submitted after deadline
  - `locked` (boolean) - Whether grading is locked
  - `submitted_at` (timestamptz) - Submission timestamp
  - `graded_at` (timestamptz, nullable) - Grading timestamp
  - `graded_by` (uuid, nullable, references profiles) - Grading teacher
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp
  
  ### 5. group_members
  Group assignment membership
  - `id` (uuid) - Record ID
  - `submission_id` (uuid, references submissions) - Related submission
  - `student_id` (uuid, references profiles) - Group member
  - `added_at` (timestamptz) - When added to group
  
  ### 6. feedback_copies
  Teacher-editable copies of submissions for annotation
  - `id` (uuid) - Copy ID
  - `submission_id` (uuid, references submissions) - Original submission
  - `teacher_id` (uuid, references profiles) - Teacher who created copy
  - `content` (jsonb) - Editable copy of submission content
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp
  
  ### 7. notifications
  User notification system
  - `id` (uuid) - Notification ID
  - `user_id` (uuid, references profiles) - Recipient user
  - `type` (text) - Notification type
  - `message` (text) - Notification message
  - `read` (boolean) - Read status
  - `created_at` (timestamptz) - Creation timestamp
  
  ### 8. activities
  Activity/audit log
  - `id` (uuid) - Activity ID
  - `user_id` (uuid, references profiles) - User performing action
  - `action` (text) - Action type
  - `description` (text) - Activity description
  - `metadata` (jsonb, nullable) - Additional data
  - `created_at` (timestamptz) - Activity timestamp
  
  ### 9. maintenance_schedules
  System maintenance mode configuration
  - `id` (uuid) - Schedule ID
  - `enabled` (boolean) - Manual maintenance mode active
  - `manual_until` (timestamptz, nullable) - Manual mode end time
  - `schedules` (jsonb) - Array of scheduled maintenance windows
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp
  
  ## Security
  - Enable RLS on all tables
  - Policies enforce role-based access:
    - Students: Own data only
    - Teachers: Own content + their students' data
    - Admins: Full access
  - Password reset workflow requires admin approval
  
  ## Indexes
  - Email lookups
  - Assignment queries by teacher and publish times
  - Submission queries by assignment and student
  - Notification queries by user and read status
  - Activity logs by user and timestamp
*/

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create enum types for better type safety
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM ('student', 'teacher', 'admin');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'reset_status') THEN
    CREATE TYPE reset_status AS ENUM ('pending', 'approved', 'denied', 'expired');
  END IF;
END $$;

-- 1. Profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text NOT NULL,
  role user_role NOT NULL DEFAULT 'student',
  phone text,
  failed_attempts integer DEFAULT 0,
  locked_until timestamptz,
  lockouts integer DEFAULT 0,
  flagged boolean DEFAULT false,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_active ON profiles(active);

-- 2. Password reset requests
CREATE TABLE IF NOT EXISTS password_reset_requests (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status reset_status DEFAULT 'pending',
  temp_password text,
  denial_reason text,
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz DEFAULT (now() + interval '72 hours'),
  reviewed_by uuid REFERENCES profiles(id),
  reviewed_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_reset_user ON password_reset_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_reset_status ON password_reset_requests(status);

-- 3. Assignments
CREATE TABLE IF NOT EXISTS assignments (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  teacher_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text DEFAULT '',
  questions jsonb DEFAULT '[]'::jsonb,
  total_points integer DEFAULT 100,
  is_group boolean DEFAULT false,
  publish_at timestamptz NOT NULL,
  unpublish_at timestamptz NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT valid_publish_window CHECK (unpublish_at > publish_at)
);

CREATE INDEX IF NOT EXISTS idx_assignments_teacher ON assignments(teacher_id);
CREATE INDEX IF NOT EXISTS idx_assignments_publish ON assignments(publish_at, unpublish_at);

-- 4. Submissions
CREATE TABLE IF NOT EXISTS submissions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  assignment_id uuid NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  answers jsonb DEFAULT '[]'::jsonb,
  grade numeric,
  late_penalty numeric DEFAULT 0,
  feedback text,
  is_late boolean DEFAULT false,
  locked boolean DEFAULT false,
  submitted_at timestamptz DEFAULT now(),
  graded_at timestamptz,
  graded_by uuid REFERENCES profiles(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(assignment_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_submissions_assignment ON submissions(assignment_id);
CREATE INDEX IF NOT EXISTS idx_submissions_student ON submissions(student_id);
CREATE INDEX IF NOT EXISTS idx_submissions_graded ON submissions(graded_at);

-- 5. Group members
CREATE TABLE IF NOT EXISTS group_members (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  submission_id uuid NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  added_at timestamptz DEFAULT now(),
  UNIQUE(submission_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_group_members_submission ON group_members(submission_id);
CREATE INDEX IF NOT EXISTS idx_group_members_student ON group_members(student_id);

-- 6. Feedback copies
CREATE TABLE IF NOT EXISTS feedback_copies (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  submission_id uuid NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
  teacher_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(submission_id, teacher_id)
);

CREATE INDEX IF NOT EXISTS idx_feedback_submission ON feedback_copies(submission_id);
CREATE INDEX IF NOT EXISTS idx_feedback_teacher ON feedback_copies(teacher_id);

-- 7. Notifications
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type text NOT NULL,
  message text NOT NULL,
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(user_id, read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);

-- 8. Activities
CREATE TABLE IF NOT EXISTS activities (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  action text NOT NULL,
  description text NOT NULL,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_activities_user ON activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_created ON activities(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activities_action ON activities(action);

-- 9. Maintenance schedules (single row config table)
CREATE TABLE IF NOT EXISTS maintenance_schedules (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  enabled boolean DEFAULT false,
  manual_until timestamptz,
  schedules jsonb DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Insert default maintenance config if not exists
INSERT INTO maintenance_schedules (enabled, schedules)
SELECT false, '[]'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM maintenance_schedules LIMIT 1);

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE password_reset_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback_copies ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_schedules ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Teachers can view student profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'teacher'
    AND role = 'student'
  );

CREATE POLICY "Admins can view all profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can update any profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin')
  WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Admins can insert profiles"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Admins can delete profiles"
  ON profiles FOR DELETE
  TO authenticated
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- RLS Policies for password_reset_requests
CREATE POLICY "Users can view own reset requests"
  ON password_reset_requests FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can view all reset requests"
  ON password_reset_requests FOR SELECT
  TO authenticated
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Users can create reset requests"
  ON password_reset_requests FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can update reset requests"
  ON password_reset_requests FOR UPDATE
  TO authenticated
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin')
  WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- RLS Policies for assignments
CREATE POLICY "Students can view published assignments"
  ON assignments FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'student'
    AND now() >= publish_at
    AND now() <= unpublish_at
  );

CREATE POLICY "Teachers can view own assignments"
  ON assignments FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'teacher'
    AND teacher_id = auth.uid()
  );

CREATE POLICY "Admins can view all assignments"
  ON assignments FOR SELECT
  TO authenticated
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Teachers can create assignments"
  ON assignments FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'teacher'
    AND teacher_id = auth.uid()
  );

CREATE POLICY "Teachers can update own assignments"
  ON assignments FOR UPDATE
  TO authenticated
  USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'teacher'
    AND teacher_id = auth.uid()
  )
  WITH CHECK (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'teacher'
    AND teacher_id = auth.uid()
  );

CREATE POLICY "Teachers can delete own assignments"
  ON assignments FOR DELETE
  TO authenticated
  USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'teacher'
    AND teacher_id = auth.uid()
  );

CREATE POLICY "Admins can manage all assignments"
  ON assignments FOR ALL
  TO authenticated
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin')
  WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- RLS Policies for submissions
CREATE POLICY "Students can view own submissions"
  ON submissions FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'student'
    AND student_id = auth.uid()
  );

CREATE POLICY "Teachers can view submissions for their assignments"
  ON submissions FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'teacher'
    AND assignment_id IN (
      SELECT id FROM assignments WHERE teacher_id = auth.uid()
    )
  );

CREATE POLICY "Admins can view all submissions"
  ON submissions FOR SELECT
  TO authenticated
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Students can create own submissions"
  ON submissions FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'student'
    AND student_id = auth.uid()
  );

CREATE POLICY "Students can update own submissions"
  ON submissions FOR UPDATE
  TO authenticated
  USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'student'
    AND student_id = auth.uid()
    AND locked = false
  )
  WITH CHECK (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'student'
    AND student_id = auth.uid()
    AND locked = false
  );

CREATE POLICY "Teachers can update submissions for their assignments"
  ON submissions FOR UPDATE
  TO authenticated
  USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'teacher'
    AND assignment_id IN (
      SELECT id FROM assignments WHERE teacher_id = auth.uid()
    )
  )
  WITH CHECK (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'teacher'
    AND assignment_id IN (
      SELECT id FROM assignments WHERE teacher_id = auth.uid()
    )
  );

-- RLS Policies for group_members
CREATE POLICY "Students can view own group memberships"
  ON group_members FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

CREATE POLICY "Teachers can view group members for their assignments"
  ON group_members FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'teacher'
    AND submission_id IN (
      SELECT s.id FROM submissions s
      JOIN assignments a ON s.assignment_id = a.id
      WHERE a.teacher_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can manage group members"
  ON group_members FOR ALL
  TO authenticated
  USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'teacher'
    AND submission_id IN (
      SELECT s.id FROM submissions s
      JOIN assignments a ON s.assignment_id = a.id
      WHERE a.teacher_id = auth.uid()
    )
  )
  WITH CHECK (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'teacher'
    AND submission_id IN (
      SELECT s.id FROM submissions s
      JOIN assignments a ON s.assignment_id = a.id
      WHERE a.teacher_id = auth.uid()
    )
  );

-- RLS Policies for feedback_copies
CREATE POLICY "Teachers can manage own feedback copies"
  ON feedback_copies FOR ALL
  TO authenticated
  USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'teacher'
    AND teacher_id = auth.uid()
  )
  WITH CHECK (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'teacher'
    AND teacher_id = auth.uid()
  );

-- RLS Policies for notifications
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Teachers can create notifications for students"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT role FROM profiles WHERE id = auth.uid()) IN ('teacher', 'admin')
  );

CREATE POLICY "Admins can manage all notifications"
  ON notifications FOR ALL
  TO authenticated
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin')
  WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- RLS Policies for activities
CREATE POLICY "Users can view own activities"
  ON activities FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can view all activities"
  ON activities FOR SELECT
  TO authenticated
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Authenticated users can create activities"
  ON activities FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- RLS Policies for maintenance_schedules
CREATE POLICY "Everyone can view maintenance schedules"
  ON maintenance_schedules FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage maintenance schedules"
  ON maintenance_schedules FOR ALL
  TO authenticated
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin')
  WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_assignments_updated_at ON assignments;
CREATE TRIGGER update_assignments_updated_at
  BEFORE UPDATE ON assignments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_submissions_updated_at ON submissions;
CREATE TRIGGER update_submissions_updated_at
  BEFORE UPDATE ON submissions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_feedback_copies_updated_at ON feedback_copies;
CREATE TRIGGER update_feedback_copies_updated_at
  BEFORE UPDATE ON feedback_copies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_maintenance_schedules_updated_at ON maintenance_schedules;
CREATE TRIGGER update_maintenance_schedules_updated_at
  BEFORE UPDATE ON maintenance_schedules
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Activity logging trigger for critical operations
CREATE OR REPLACE FUNCTION log_activity()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO activities (user_id, action, description, metadata)
    VALUES (
      NEW.id,
      TG_TABLE_NAME || '_created',
      'New ' || TG_TABLE_NAME || ' record created',
      row_to_json(NEW)::jsonb
    );
  ELSIF TG_OP = 'UPDATE' AND TG_TABLE_NAME = 'profiles' AND OLD.active != NEW.active THEN
    INSERT INTO activities (user_id, action, description)
    VALUES (
      NEW.id,
      CASE WHEN NEW.active THEN 'account_activated' ELSE 'account_deactivated' END,
      CASE WHEN NEW.active THEN 'Account was activated' ELSE 'Account was deactivated' END
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS log_profile_activity ON profiles;
CREATE TRIGGER log_profile_activity
  AFTER INSERT OR UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION log_activity();