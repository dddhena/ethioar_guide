import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'ar_guide.dart';
import '../widgets/app_scaffold.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _auth = AuthService();
  final FirestoreService _fs = FirestoreService();
  String _role = 'user';
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _role = 'guest';
        _loadingRole = false;
      });
      return;
    }
    final r = await _fs.getUserRole(uid);
    setState(() {
      _role = r;
      _loadingRole = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final displayName = user?.displayName ?? 'Guest';

    return AppScaffold(
      title: 'Dashboard',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(child: Text(displayName.isNotEmpty ? displayName[0] : 'G')),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, $displayName', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      _loadingRole ? const Text('Loading role...') : Text('Role: $_role'),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.explore),
            label: const Text('AR Tourist Guide'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ARGuidePage())),
          ),
          const SizedBox(height: 12),
          if (!_loadingRole && _role == 'admin')
            ElevatedButton.icon(
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Admin: Manage Users'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPage())),
            ),
        ],
      ),
    );
  }
}

// Simple admin page to manage roles
class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirestoreService _fs = FirestoreService();
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    _users = await _fs.listUsers();
    setState(() {
      _loading = false;
    });
  }

  Future<void> _setRole(String uid, String role) async {
    await _fs.setUserRole(uid, role);
    await _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'User Management',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, i) {
                final u = _users[i];
                return ListTile(
                  title: Text(u['name'] ?? u['email'] ?? 'Unknown'),
                  subtitle: Text(u['email'] ?? ''),
                  trailing: DropdownButton<String>(
                    value: (u['role'] as String?) ?? 'user',
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) async {
                      if (v != null) await _setRole(u['uid'], v);
                    },
                  ),
                );
              },
            ),
    );
  }
}
