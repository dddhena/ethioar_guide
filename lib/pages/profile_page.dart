import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/snackbar_helper.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _auth = AuthService();
  final FirestoreService _fs = FirestoreService();

  // Avatar presets
  static const Map<String, IconData> avatarPresets = {
    'default': Icons.person,
    'explorer': Icons.explore,
    'camera': Icons.camera_alt,
    'hiking': Icons.hiking,
    'landscape': Icons.landscape,
    'castle': Icons.fort,
    'flight': Icons.flight_takeoff,
    'star': Icons.star,
  };

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return AppScaffold(
        title: 'User Profile',
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('You are not currently logged in.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<UserProfile>(
      stream: _fs.getUserProfileStream(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const AppScaffold(
            title: 'User Profile',
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = snapshot.data ??
            UserProfile(
              uid: currentUser.uid,
              name: currentUser.displayName ?? 'Guest',
              email: currentUser.email ?? '',
              role: 'user',
            );

        return AppScaffold(
          title: 'My Profile',
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Profile',
              onPressed: () => _showEditProfileDialog(context, profile),
            ),
          ],
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            children: [
              _buildHeaderCard(context, profile),
              const SizedBox(height: 16),
              _buildSectionTitle(context, 'Personal Information'),
              const SizedBox(height: 8),
              _buildInfoCard(context, profile),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Account & Security'),
              const SizedBox(height: 8),
              _buildSecurityCard(context, profile),
              const SizedBox(height: 24),
              _buildSignOutButton(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, UserProfile profile) {
    final avatarIcon = avatarPresets[profile.avatar] ?? Icons.person;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.teal.shade700,
                  child: CircleAvatar(
                    radius: 43,
                    backgroundColor: Colors.teal.shade100,
                    child: Icon(avatarIcon, size: 48, color: Colors.teal.shade900),
                  ),
                ),
                InkWell(
                  onTap: () => _showAvatarPicker(context, profile),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              profile.name.isNotEmpty ? profile.name : 'EthioAR Traveler',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              profile.email,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  avatar: Icon(
                    profile.isAdmin ? Icons.admin_panel_settings : Icons.person,
                    size: 18,
                    color: profile.isAdmin ? Colors.amber.shade900 : Colors.teal.shade800,
                  ),
                  label: Text(
                    profile.isAdmin ? 'Admin' : 'Explorer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: profile.isAdmin ? Colors.amber.shade900 : Colors.teal.shade900,
                    ),
                  ),
                  backgroundColor: profile.isAdmin ? Colors.amber.shade100 : Colors.teal.shade50,
                  side: BorderSide(
                    color: profile.isAdmin ? Colors.amber.shade400 : Colors.teal.shade200,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showEditProfileDialog(context, profile),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal.shade700,
                side: BorderSide(color: Colors.teal.shade400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, UserProfile profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            _buildDetailTile(
              icon: Icons.person_outline,
              label: 'Full Name',
              value: profile.name.isNotEmpty ? profile.name : 'Not set',
            ),
            const Divider(height: 1, indent: 56),
            _buildDetailTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: profile.email,
              trailing: const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
            ),
            const Divider(height: 1, indent: 56),
            _buildDetailTile(
              icon: Icons.phone_outlined,
              label: 'Phone Number',
              value: profile.phone.isNotEmpty ? profile.phone : 'Not provided',
            ),
            const Divider(height: 1, indent: 56),
            _buildDetailTile(
              icon: Icons.public_outlined,
              label: 'Country / Origin',
              value: profile.country.isNotEmpty ? profile.country : 'Not provided',
            ),
            const Divider(height: 1, indent: 56),
            _buildDetailTile(
              icon: Icons.notes_outlined,
              label: 'Traveler Bio',
              value: profile.bio.isNotEmpty ? profile.bio : 'No bio added yet. Tell us about your journey!',
            ),
            if (profile.createdAt != null) ...[
              const Divider(height: 1, indent: 56),
              _buildDetailTile(
                icon: Icons.calendar_today_outlined,
                label: 'Member Since',
                value: '${profile.createdAt!.day}/${profile.createdAt!.month}/${profile.createdAt!.year}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.teal.shade50,
        child: Icon(icon, size: 20, color: Colors.teal.shade700),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
      ),
      trailing: trailing,
    );
  }

  Widget _buildSecurityCard(BuildContext context, UserProfile profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.orange.shade50,
              child: Icon(Icons.key, size: 20, color: Colors.orange.shade700),
            ),
            title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Update your login password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showChangePasswordDialog(context),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.shade50,
              child: Icon(Icons.mail_lock_outlined, size: 20, color: Colors.blue.shade700),
            ),
            title: const Text('Send Password Reset Email', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Receive a password reset link to your email'),
            trailing: const Icon(Icons.send_outlined, size: 18),
            onTap: () => _sendPasswordResetEmail(context, profile.email),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.logout),
      label: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      onPressed: () => _confirmSignOut(context),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to log out of EthioAR Guide?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordResetEmail(BuildContext context, String email) async {
    try {
      await _auth.sendPasswordResetEmail(email);
      if (context.mounted) {
        SnackbarHelper.show(context, 'Password reset link sent to $email');
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.show(context, 'Failed to send reset email: $e');
      }
    }
  }

  void _showAvatarPicker(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Traveler Avatar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: avatarPresets.entries.map((entry) {
                    final isSelected = profile.avatar == entry.key;
                    return InkWell(
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        final updated = profile.copyWith(avatar: entry.key);
                        await _fs.updateUserProfile(updated);
                        if (context.mounted) {
                          SnackbarHelper.show(context, 'Avatar updated');
                        }
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.teal.shade700 : Colors.teal.shade50,
                          border: Border.all(
                            color: isSelected ? Colors.teal.shade900 : Colors.teal.shade200,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          entry.value,
                          size: 32,
                          color: isSelected ? Colors.white : Colors.teal.shade800,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, UserProfile profile) {
    final nameCtrl = TextEditingController(text: profile.name);
    final phoneCtrl = TextEditingController(text: profile.phone);
    final countryCtrl = TextEditingController(text: profile.country);
    final bioCtrl = TextEditingController(text: profile.bio);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Profile',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: countryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Country / City of Origin',
                          prefixIcon: Icon(Icons.public),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bioCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Traveler Bio',
                          prefixIcon: Icon(Icons.notes),
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: saving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => saving = true);
                                try {
                                  final newName = nameCtrl.text.trim();
                                  final updated = profile.copyWith(
                                    name: newName,
                                    phone: phoneCtrl.text.trim(),
                                    country: countryCtrl.text.trim(),
                                    bio: bioCtrl.text.trim(),
                                  );

                                  await _fs.updateUserProfile(updated);
                                  await _auth.updateDisplayName(newName);

                                  if (ctx.mounted) Navigator.of(ctx).pop();
                                  if (context.mounted) {
                                    SnackbarHelper.show(context, 'Profile updated successfully');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    SnackbarHelper.show(context, 'Failed to update profile: $e');
                                  }
                                } finally {
                                  if (ctx.mounted) setModalState(() => saving = false);
                                }
                              },
                        icon: saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(saving ? 'Saving...' : 'Save Changes'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;
    bool obscureCurrent = true;
    bool obscureNew = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentPassCtrl,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureCurrent ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter your current password' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPassCtrl,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPassCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: (v) => (v != newPassCtrl.text) ? 'Passwords do not match' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => saving = true);
                          try {
                            await _auth.updatePassword(
                              currentPassword: currentPassCtrl.text.trim(),
                              newPassword: newPassCtrl.text.trim(),
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (context.mounted) {
                              SnackbarHelper.show(context, 'Password updated successfully');
                            }
                          } on FirebaseAuthException catch (e) {
                            if (context.mounted) {
                              SnackbarHelper.show(context, 'Error: ${e.message ?? e.code}');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              SnackbarHelper.show(context, 'Failed to update password: $e');
                            }
                          } finally {
                            if (ctx.mounted) setDialogState(() => saving = false);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
