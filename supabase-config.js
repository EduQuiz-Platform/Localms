// Supabase Configuration
// This file contains the Supabase client initialization and helper functions

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY;

// Initialize Supabase client
let supabaseClient = null;

function initSupabase() {
  if (supabaseClient) return supabaseClient;

  if (typeof window !== 'undefined' && window.supabase) {
    supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: {
        autoRefreshToken: true,
        persistSession: true,
        detectSessionInUrl: true
      }
    });
  }

  return supabaseClient;
}

// Helper functions for common operations
const supabaseHelpers = {
  // Auth helpers
  async signUp(email, password, userData) {
    const supabase = initSupabase();
    return await supabase.auth.signUp({
      email,
      password,
      options: {
        data: userData
      }
    });
  },

  async signIn(email, password) {
    const supabase = initSupabase();
    return await supabase.auth.signInWithPassword({ email, password });
  },

  async signOut() {
    const supabase = initSupabase();
    return await supabase.auth.signOut();
  },

  async getSession() {
    const supabase = initSupabase();
    return await supabase.auth.getSession();
  },

  async getUser() {
    const supabase = initSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    return user;
  },

  // Profile helpers
  async getProfile(userId) {
    const supabase = initSupabase();
    return await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .maybeSingle();
  },

  async updateProfile(userId, updates) {
    const supabase = initSupabase();
    return await supabase
      .from('profiles')
      .update(updates)
      .eq('id', userId);
  },

  // Notification helpers
  async getNotifications(userId, unreadOnly = false) {
    const supabase = initSupabase();
    let query = supabase
      .from('notifications')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (unreadOnly) {
      query = query.eq('read', false);
    }

    return await query;
  },

  async markNotificationRead(notificationId) {
    const supabase = initSupabase();
    return await supabase
      .from('notifications')
      .update({ read: true })
      .eq('id', notificationId);
  },

  async createNotification(userId, type, message) {
    const supabase = initSupabase();
    return await supabase
      .from('notifications')
      .insert({ user_id: userId, type, message, read: false });
  },

  // Assignment helpers
  async getAssignments(filters = {}) {
    const supabase = initSupabase();
    let query = supabase.from('assignments').select('*');

    if (filters.teacherId) {
      query = query.eq('teacher_id', filters.teacherId);
    }

    if (filters.activeOnly) {
      const now = new Date().toISOString();
      query = query.lte('publish_at', now).gte('unpublish_at', now);
    }

    return await query.order('created_at', { ascending: false });
  },

  async createAssignment(assignmentData) {
    const supabase = initSupabase();
    return await supabase
      .from('assignments')
      .insert(assignmentData)
      .select()
      .single();
  },

  async updateAssignment(assignmentId, updates) {
    const supabase = initSupabase();
    return await supabase
      .from('assignments')
      .update(updates)
      .eq('id', assignmentId);
  },

  async deleteAssignment(assignmentId) {
    const supabase = initSupabase();
    return await supabase
      .from('assignments')
      .delete()
      .eq('id', assignmentId);
  },

  // Submission helpers
  async getSubmissions(filters = {}) {
    const supabase = initSupabase();
    let query = supabase.from('submissions').select('*, profiles!student_id(full_name, email), assignments(title)');

    if (filters.assignmentId) {
      query = query.eq('assignment_id', filters.assignmentId);
    }

    if (filters.studentId) {
      query = query.eq('student_id', filters.studentId);
    }

    return await query.order('submitted_at', { ascending: false });
  },

  async createSubmission(submissionData) {
    const supabase = initSupabase();
    return await supabase
      .from('submissions')
      .insert(submissionData)
      .select()
      .single();
  },

  async updateSubmission(submissionId, updates) {
    const supabase = initSupabase();
    return await supabase
      .from('submissions')
      .update(updates)
      .eq('id', submissionId);
  },

  // Maintenance helpers
  async getMaintenanceSchedule() {
    const supabase = initSupabase();
    return await supabase
      .from('maintenance_schedules')
      .select('*')
      .limit(1)
      .maybeSingle();
  },

  async updateMaintenanceSchedule(updates) {
    const supabase = initSupabase();
    const { data: existing } = await supabase
      .from('maintenance_schedules')
      .select('id')
      .limit(1)
      .maybeSingle();

    if (existing) {
      return await supabase
        .from('maintenance_schedules')
        .update(updates)
        .eq('id', existing.id);
    } else {
      return await supabase
        .from('maintenance_schedules')
        .insert(updates)
        .select()
        .single();
    }
  },

  // Activity helpers
  async logActivity(userId, action, description, metadata = null) {
    const supabase = initSupabase();
    return await supabase
      .from('activities')
      .insert({
        user_id: userId,
        action,
        description,
        metadata
      });
  }
};

// Export for use in other files
if (typeof window !== 'undefined') {
  window.initSupabase = initSupabase;
  window.supabaseHelpers = supabaseHelpers;
}