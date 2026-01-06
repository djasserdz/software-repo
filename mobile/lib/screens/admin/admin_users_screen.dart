import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String selectedRole = 'all';
  String? _selectedRoleForForm;
  bool _showCreateDialog = false;
  bool _showEditDialog = false;
  int? _editingUserId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    await Provider.of<AdminProvider>(context, listen: false).fetchUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openCreateDialog() {
    setState(() {
      _showCreateDialog = true;
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _passwordController.clear();
      _selectedRoleForForm = 'farmer';
    });
  }

  void _openEditDialog(user) {
    setState(() {
      _showEditDialog = true;
      _editingUserId = user.userId;
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _selectedRoleForForm = user.role;
    });
  }

  void _closeDialogs() {
    setState(() {
      _showCreateDialog = false;
      _showEditDialog = false;
      _editingUserId = null;
    });
  }

  Future<void> _createUser() async {
    if (_nameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty ||
        _selectedRoleForForm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final provider = Provider.of<AdminProvider>(context, listen: false);
    final success = await provider.createUser(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      role: _selectedRoleForForm!,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
    );

    if (success) {
      _closeDialogs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.usersError ?? 'Failed to create user')),
      );
    }
  }

  Future<void> _updateUser() async {
    if (_editingUserId == null || _nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final provider = Provider.of<AdminProvider>(context, listen: false);
    final success = await provider.updateUser(
      userId: _editingUserId!,
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      role: _selectedRoleForForm,
    );

    if (success) {
      _closeDialogs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.usersError ?? 'Failed to update user')),
      );
    }
  }

  void _deleteUser(int userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<AdminProvider>(context, listen: false);
              final success = await provider.deleteUser(userId);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User deleted successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(provider.usersError ?? 'Failed to delete user')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.usersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredUsers = provider.users;

          return Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    child: Column(
                      children: [
                        SearchField(
                          controller: searchController,
                          hintText: 'Search users...',
                          onChanged: (value) {
                            if (value.isEmpty) {
                              provider.fetchUsers();
                            } else {
                              provider.searchUsers(value);
                            }
                          },
                        ),
                        const SizedBox(height: AppTheme.spacing12),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _roleFilter('all', 'All'),
                              const SizedBox(width: 8),
                              _roleFilter('admin', 'Admin'),
                              const SizedBox(width: 8),
                              _roleFilter('warehouse_admin', 'Warehouse Admin'),
                              const SizedBox(width: 8),
                              _roleFilter('farmer', 'Farmer'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredUsers.isEmpty
                        ? const EmptyState(
                            icon: Icons.person_outline,
                            title: 'No Users Found',
                            subtitle: 'Try adjusting your search or filters',
                          )
                        : ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacing12,
                                  vertical: AppTheme.spacing8,
                                ),
                                child: CustomCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  user.email,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          StatusBadge(
                                            label: user.role.toUpperCase(),
                                            status: user.role,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              user.phone ?? 'No phone',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppTheme.spacing12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          TextButton.icon(
                                            icon: const Icon(Icons.edit),
                                            label: const Text('Edit'),
                                            onPressed: () => _openEditDialog(user),
                                          ),
                                          TextButton.icon(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            label: const Text('Delete',
                                                style: TextStyle(color: Colors.red)),
                                            onPressed: () =>
                                                _deleteUser(user.userId),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
              // Create User Dialog
              if (_showCreateDialog)
                _buildUserDialog(
                  title: 'Create User',
                  onSave: _createUser,
                  showPassword: true,
                ),
              // Edit User Dialog
              if (_showEditDialog)
                _buildUserDialog(
                  title: 'Edit User',
                  onSave: _updateUser,
                  showPassword: false,
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUserDialog({
    required String title,
    required VoidCallback onSave,
    required bool showPassword,
  }) {
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppTheme.spacing12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppTheme.spacing12),
            if (showPassword)
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password *',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            if (showPassword) const SizedBox(height: AppTheme.spacing12),
            DropdownButtonFormField<String>(
              value: _selectedRoleForForm,
              decoration: const InputDecoration(
                labelText: 'Role *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'warehouse_admin', child: Text('Warehouse Admin')),
                DropdownMenuItem(value: 'farmer', child: Text('Farmer')),
              ],
              onChanged: (value) {
                setState(() => _selectedRoleForForm = value);
              },
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _closeDialogs,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppTheme.spacing8),
                ElevatedButton(
                  onPressed: onSave,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleFilter(String role, String label) {
    return FilterChip(
      label: Text(label),
      selected: selectedRole == role,
      onSelected: (selected) {
        setState(() => selectedRole = role);
        if (role == 'all') {
          Provider.of<AdminProvider>(context, listen: false).fetchUsers();
        } else {
          Provider.of<AdminProvider>(context, listen: false)
              .filterUsersByRole(role);
        }
      },
    );
  }
}
