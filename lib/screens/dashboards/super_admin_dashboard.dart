import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../SuperAdminScreen/employee_list.dart';
import '../SuperAdminScreen/deactivated_account.dart';
import '../SuperAdminScreen/add_account.dart';
import '../SuperAdminScreen/system_management.dart';

class SuperAdminDashboard extends StatefulWidget {
  final AppUser user;
  const SuperAdminDashboard({super.key, required this.user});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;
  bool _isLoggingOut = false;
  bool showUserManagementOptions = false;
  int _deactivationNotificationCount = 0;
  StreamSubscription? _notificationsSubscription;
  List<QueryDocumentSnapshot> _firstPageNotifications = [];
  bool _isFirstPageLoading = true;

  // Pagination variables
  final int _notificationsPerPage = 10;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreNotifications = true;
  bool _isLoadingMore = false;
  List<QueryDocumentSnapshot> _allNotifications = [];

  // Define all screens that can be accessed from the hamburger menu
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _startListeningToDeactivationNotifications();
    _loadInitialNotifications(); // Load once immediately
    _startRealtimeNotificationsListener(); // Then start listening for real-time updates
  }

  // Load initial notifications once (immediately shows data)
  Future<void> _loadInitialNotifications() async {
    try {
      final query = getNotificationsQuery(widget.user.role);
      final snapshot = await query.limit(_notificationsPerPage).get();

      if (mounted) {
        setState(() {
          _firstPageNotifications = snapshot.docs;
          _allNotifications = snapshot.docs;
          _isFirstPageLoading = false;
          _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
          _hasMoreNotifications = snapshot.docs.length == _notificationsPerPage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFirstPageLoading = false);
      }
    }
  }

  void _initializeScreens() {
    _screens.addAll([
      _buildHomeScreen(), // Home screen (index 0)
      AddAccountScreen(user: widget.user), // Index 1
      EmployeeListScreen(user: widget.user), // Index 2
      DeactivatedAccountScreen(user: widget.user), // Index 3
      SystemManagementScreen(user: widget.user), // Index 4
    ]);
  }

  void _startRealtimeNotificationsListener() {
    _notificationsSubscription = getNotificationsQuery(widget.user.role)
        .limit(_notificationsPerPage)
        .snapshots()
        .listen(
          (snapshot) {
        if (mounted) {
          setState(() {
            _firstPageNotifications = snapshot.docs;
            _isFirstPageLoading = false; // Mark loading as complete

            // Merge first page with any additional loaded pages
            _allNotifications = [
              ..._firstPageNotifications,
              ..._allNotifications.skip(_notificationsPerPage),
            ];
            _lastDocument = _firstPageNotifications.isNotEmpty
                ? _firstPageNotifications.last
                : null;
            _hasMoreNotifications =
                _firstPageNotifications.length == _notificationsPerPage;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isFirstPageLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load notifications: $error')),
          );
        }
      },
    );
  }

  void _startListeningToDeactivationNotifications() {
    FirebaseFirestore.instance
        .collection('notifications')
        .where('dismissed', isEqualTo: false)
        .where('type', isEqualTo: 'deactivate')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _deactivationNotificationCount = snapshot.docs.length;
        });
      }
    });
  }

  void _navigateToScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close drawer after navigation
  }

  void _showAddNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = 'system';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add Notification"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Message",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: "Type",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('System')),
                      DropdownMenuItem(
                        value: 'security',
                        child: Text('Security'),
                      ),
                      DropdownMenuItem(
                        value: 'updates',
                        child: Text('Updates'),
                      ),
                      DropdownMenuItem(
                        value: 'deactivate',
                        child: Text('Deactivate'),
                      ),
                      DropdownMenuItem(
                        value: 'add_account',
                        child: Text('Add Account'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2364),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final message = messageController.text.trim();

                    if (title.isEmpty || message.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please fill in all fields"),
                          ),
                        );
                      }
                      return;
                    }

                    try {
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .add({
                        'title': title,
                        'message': message,
                        'time': FieldValue.serverTimestamp(),
                        'dismissed': false,
                        'type': selectedType,
                        'createdBy': widget.user.role,
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Notification added successfully!"),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to add notification: $e"),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'system':
        return Icons.system_update_alt;
      case 'security':
        return Icons.warning;
      case 'updates':
        return Icons.notifications_on;
      case 'deactivate':
        return Icons.person_off;
      case 'add_account':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'system':
        return Colors.blue;
      case 'security':
        return Colors.orange;
      case 'updates':
        return Colors.green;
      case 'deactivate':
        return Colors.red;
      case 'add_account':
        return Colors.blue;
      default:
        return const Color(0xFF0D2364);
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'system':
        return 'SYSTEM';
      case 'security':
        return 'SECURITY';
      case 'updates':
        return 'UPDATES';
      case 'deactivate':
        return 'DEACTIVATED';
      case 'add_account':
        return 'NEW ACCOUNT';
      default:
        return 'NOTICE';
    }
  }

  // Load more notifications (manual pagination, NOT real-time)
  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMoreNotifications) return;

    setState(() => _isLoadingMore = true);

    try {
      Query query = getNotificationsQuery(widget.user.role);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.limit(_notificationsPerPage).get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _allNotifications.addAll(snapshot.docs);
          _lastDocument = snapshot.docs.last;
          _hasMoreNotifications =
              snapshot.docs.length == _notificationsPerPage;
        });
      } else {
        setState(() => _hasMoreNotifications = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more notifications: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  // Refresh notifications
  Future<void> _refreshNotifications() async {
    setState(() {
      _lastDocument = null;
      _hasMoreNotifications = true;
      _allNotifications.clear();
      _firstPageNotifications.clear();
      _isFirstPageLoading = true;
    });
    // The listener will automatically reload the first page
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  Query getNotificationsQuery(String role) {
    final collection = FirebaseFirestore.instance.collection('notifications');

    if (role == 'super_admin' || role == 'admin') {
      return collection
          .where('dismissed', isEqualTo: false)
          .orderBy('time', descending: true);
    } else {
      // Other users see: system, deactivate, and add_account notifications
      return collection
          .where('dismissed', isEqualTo: false)
          .where('type', whereIn: ['system', 'deactivate', 'add_account'])
          .orderBy('time', descending: true);
    }
  }

  Widget _buildHomeScreen() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 768;

          return Stack(
            children: [
              Padding(
                padding: isMobile
                    ? const EdgeInsets.all(12.0)
                    : const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D2364),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D2364),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_allNotifications.length}${_hasMoreNotifications || _isLoadingMore ? '+' : ''}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Notifications Content
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshNotifications,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification scrollInfo) {
                            if (!_isLoadingMore &&
                                _hasMoreNotifications &&
                                scrollInfo.metrics.pixels ==
                                    scrollInfo.metrics.maxScrollExtent) {
                              _loadMoreNotifications();
                            }
                            return false;
                          },
                          child: CustomScrollView(
                            slivers: [
                              // Notifications List
                              if (_allNotifications.isEmpty && !_isLoadingMore && !_isFirstPageLoading)
                                SliverFillRemaining(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.notifications_off_outlined,
                                          size: isMobile ? 60 : 80,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No notifications',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: isMobile ? 18 : 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else if (_allNotifications.isEmpty && _isFirstPageLoading)
                                const SliverFillRemaining(
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (_allNotifications.isNotEmpty && isMobile)
                                  SliverList(
                                    delegate: SliverChildBuilderDelegate((
                                        context,
                                        index,
                                        ) {
                                      if (index < _allNotifications.length) {
                                        final data =
                                        _allNotifications[index].data()
                                        as Map<String, dynamic>;
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: MobileNotificationTile(
                                            data: data,
                                            docReference: _allNotifications[index]
                                                .reference,
                                            getIconForType: _getIconForType,
                                            getColorForType: _getColorForType,
                                            getTypeLabel: _getTypeLabel,
                                            onDismiss: _refreshNotifications,
                                          ),
                                        );
                                      }
                                      return null;
                                    }, childCount: _allNotifications.length),
                                  )
                                else
                                  SliverPadding(
                                    padding: const EdgeInsets.only(bottom: 80),
                                    sliver: SliverLayoutBuilder(
                                      builder: (context, constraints) {
                                        final double availableWidth =
                                            constraints.crossAxisExtent;
                                        final int crossAxisCount =
                                        availableWidth > 1200
                                            ? 4
                                            : availableWidth > 800
                                            ? 3
                                            : 2;

                                        return SliverGrid(
                                          gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            childAspectRatio: 1.0,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                          ),
                                          delegate: SliverChildBuilderDelegate(
                                                (context, index) {
                                              final data =
                                              _allNotifications[index].data()
                                              as Map<String, dynamic>;
                                              return DesktopNotificationTile(
                                                data: data,
                                                docReference:
                                                _allNotifications[index]
                                                    .reference,
                                                getIconForType: _getIconForType,
                                                getColorForType: _getColorForType,
                                                getTypeLabel: _getTypeLabel,
                                                onDismiss: _refreshNotifications,
                                              );
                                            },
                                            childCount: _allNotifications.length,
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                              // Loading More Indicator
                              if (_isLoadingMore)
                                const SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                ),

                              // End of List Message
                              if (!_hasMoreNotifications &&
                                  _allNotifications.isNotEmpty)
                                const SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: Text(
                                        'No more notifications',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Floating Action Button
              Positioned(
                bottom: isMobile ? 16 : 24,
                right: isMobile ? 16 : 24,
                child: FloatingActionButton(
                  onPressed: _showAddNotificationDialog,
                  backgroundColor: const Color(0xFF0D2364),
                  foregroundColor: Colors.white,
                  tooltip: 'Add Notification',
                  child: Icon(Icons.add, size: isMobile ? 24 : 28),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _signOut() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      await Future.delayed(const Duration(seconds: 3));
      await AuthService().logout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to sign out: $e')));
      setState(() => _isLoggingOut = false);
    }
  }

  // Build the hamburger menu drawer
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0D2364)),
            accountName: Text(
              widget.user.name ?? 'Super Admin',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              "Employee ID: ${widget.user.employeeId}",
              style: const TextStyle(fontSize: 16),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.admin_panel_settings,
                color: Color(0xFF0D2364),
                size: 40,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Home
                ListTile(
                  leading: const Icon(
                    Icons.home,
                    color: Color(0xFF0D2364),
                    size: 28,
                  ),
                  title: const Text('Home', style: TextStyle(fontSize: 16)),
                  selected: _selectedIndex == 0,
                  onTap: () => _navigateToScreen(0),
                ),

                // User Management with Expansion
                Stack(
                  children: [
                    ExpansionTile(
                      leading: const Icon(
                        Icons.people,
                        color: Color(0xFF0D2364),
                        size: 28,
                      ),
                      title: const Text(
                        'User Management',
                        style: TextStyle(fontSize: 16),
                      ),
                      initiallyExpanded: showUserManagementOptions,
                      onExpansionChanged: (expanded) =>
                          setState(() => showUserManagementOptions = expanded),
                      children: [
                        // Add Account
                        ListTile(
                          leading: const Icon(
                            Icons.person_add,
                            color: Color(0xFF0D2364),
                            size: 24,
                          ),
                          title: const Text(
                            'Add Account',
                            style: TextStyle(fontSize: 15),
                          ),
                          selected: _selectedIndex == 1,
                          onTap: () => _navigateToScreen(1),
                        ),
                        // Employee List
                        ListTile(
                          leading: const Icon(
                            Icons.list,
                            color: Color(0xFF0D2364),
                            size: 24,
                          ),
                          title: const Text(
                            'Employee List',
                            style: TextStyle(fontSize: 15),
                          ),
                          selected: _selectedIndex == 2,
                          onTap: () => _navigateToScreen(2),
                        ),
                        // Deactivated Account with notification badge
                        Stack(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.person_off,
                                color: Colors.red[700],
                                size: 24,
                              ),
                              title: Text(
                                'Deactivated Account',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.red[700],
                                ),
                              ),
                              selected: _selectedIndex == 3,
                              onTap: () => _navigateToScreen(3),
                            ),
                            if (_deactivationNotificationCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    _deactivationNotificationCount > 99
                                        ? '99+'
                                        : _deactivationNotificationCount
                                        .toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (_deactivationNotificationCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            _deactivationNotificationCount > 99
                                ? '99+'
                                : _deactivationNotificationCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),

                // System Management
                ListTile(
                  leading: const Icon(
                    Icons.settings,
                    color: Color(0xFF0D2364),
                    size: 28,
                  ),
                  title: const Text(
                    'System Management',
                    style: TextStyle(fontSize: 16),
                  ),
                  selected: _selectedIndex == 4,
                  onTap: () => _navigateToScreen(4),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Logout
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Color(0xFF0D2364),
              size: 28,
            ),
            title: Text(
              _isLoggingOut ? 'Logging out...' : 'Logout',
              style: const TextStyle(color: Color(0xFF0D2364), fontSize: 16),
            ),
            trailing: _isLoggingOut
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
                : null,
            onTap: _isLoggingOut ? null : _signOut,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(_selectedIndex),
          style: const TextStyle(fontSize: 20),
        ),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
        actions: [
          if (_deactivationNotificationCount > 0 && _selectedIndex != 3)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () =>
                      _navigateToScreen(3), // Navigate to deactivated accounts
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _deactivationNotificationCount > 99
                          ? '99+'
                          : _deactivationNotificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _selectedIndex == 0 ? _buildHomeScreen() : _screens[_selectedIndex],
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Super Admin Dashboard';
      case 1:
        return 'Add Account';
      case 2:
        return 'Employee List';
      case 3:
        return 'Deactivated Accounts';
      case 4:
        return 'System Management';
      default:
        return 'Super Admin Dashboard';
    }
  }
}

// Mobile Notification Tile
class MobileNotificationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final DocumentReference docReference;
  final IconData Function(String) getIconForType;
  final Color Function(String) getColorForType;
  final String Function(String) getTypeLabel;
  final VoidCallback? onDismiss;

  const MobileNotificationTile({
    super.key,
    required this.data,
    required this.docReference,
    required this.getIconForType,
    required this.getColorForType,
    required this.getTypeLabel,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final type = data['type'] ?? '';
    final color = getColorForType(type);
    final icon = getIconForType(type);
    final title = data['title'] ?? 'No Title';
    final message = data['message'] ?? '';
    final timestamp = data['time'] as Timestamp?;

    final bool isDeactivated = type == 'deactivate';
    final bool isAddAccount = type == 'add_account';

    final Color finalColor = isDeactivated
        ? Colors.red
        : isAddAccount
        ? Colors.blue
        : color;
    final Color iconColor = isDeactivated
        ? Colors.red
        : isAddAccount
        ? Colors.blue
        : color;
    final Color backgroundColor = isDeactivated
        ? Colors.red[50]!
        : isAddAccount
        ? Colors.blue[50]!
        : color.withAlpha(30);
    final Color textColor = isDeactivated
        ? Colors.red
        : isAddAccount
        ? Colors.blue
        : const Color(0xFF0D2364);
    final Color messageColor = isDeactivated
        ? Colors.red[700]!
        : isAddAccount
        ? Colors.blue[700]!
        : Colors.grey[700]!;
    final Color timeColor = isDeactivated
        ? Colors.red[300]!
        : isAddAccount
        ? Colors.blue[300]!
        : Colors.grey[600]!;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: isDeactivated
          ? Colors.red[50]
          : isAddAccount
          ? Colors.blue[50]
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDeactivated
              ? Colors.red
              : isAddAccount
              ? Colors.blue
              : Colors.grey[300]!,
          width: isDeactivated || isAddAccount ? 1.5 : 0.5,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: messageColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    getTypeLabel(type),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: finalColor,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 12, color: timeColor),
                const SizedBox(width: 4),
                Text(
                  timestamp != null
                      ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
                      : 'No date',
                  style: TextStyle(fontSize: 12, color: timeColor),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showNotificationDialog(
          context,
          title,
          message,
          icon,
          finalColor,
          timestamp,
          type,
        ),
        onLongPress: () => _dismissNotification(context),
      ),
    );
  }

  void _showNotificationDialog(
      BuildContext context,
      String title,
      String message,
      IconData icon,
      Color color,
      Timestamp? timestamp,
      String type,
      ) {
    final bool isDeactivated = type == 'deactivate';
    final bool isAddAccount = type == 'add_account';
    final Color dialogColor = isDeactivated
        ? Colors.red
        : isAddAccount
        ? Colors.blue
        : color;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDeactivated
            ? Colors.red[50]
            : isAddAccount
            ? Colors.blue[50]
            : null,
        title: Row(
          children: [
            Icon(icon, color: dialogColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 18, color: dialogColor),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: isDeactivated
                    ? Colors.red[700]
                    : isAddAccount
                    ? Colors.blue[700]
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            if (timestamp != null)
              Text(
                DateFormat('MMM d, yyyy - hh:mm a').format(timestamp.toDate()),
                style: TextStyle(
                  fontSize: 14,
                  color: isDeactivated
                      ? Colors.red[300]
                      : isAddAccount
                      ? Colors.blue[300]
                      : Colors.grey[600],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: dialogColor)),
          ),
          TextButton(
            onPressed: () {
              _dismissNotification(context);
              Navigator.pop(context);
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  void _dismissNotification(BuildContext context) async {
    try {
      await docReference.update({'dismissed': true});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification dismissed'),
            duration: Duration(seconds: 2),
          ),
        );
        // Refresh the list after dismissal
        onDismiss?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to dismiss notification: $e')),
        );
      }
    }
  }
}

// Desktop Notification Tile
class DesktopNotificationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final DocumentReference docReference;
  final IconData Function(String) getIconForType;
  final Color Function(String) getColorForType;
  final String Function(String) getTypeLabel;
  final VoidCallback? onDismiss;

  const DesktopNotificationTile({
    super.key,
    required this.data,
    required this.docReference,
    required this.getIconForType,
    required this.getColorForType,
    required this.getTypeLabel,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final type = data['type'] ?? '';
    final color = getColorForType(type);
    final icon = getIconForType(type);
    final title = data['title'] ?? 'No Title';
    final message = data['message'] ?? '';
    final timestamp = data['time'] as Timestamp?;

    final bool isDeactivated = type == 'deactivate';
    final bool isAddAccount = type == 'add_account';

    final Color finalColor = isDeactivated
        ? Colors.red
        : isAddAccount
        ? Colors.blue
        : color;
    final Color iconColor = isDeactivated
        ? Colors.red
        : isAddAccount
        ? Colors.blue
        : color;
    final Color backgroundColor = isDeactivated
        ? Colors.red[50]!
        : isAddAccount
        ? Colors.blue[50]!
        : color.withAlpha(30);
    final Color textColor = isDeactivated
        ? Colors.red
        : isAddAccount
        ? Colors.blue
        : const Color(0xFF0D2364);
    final Color messageColor = isDeactivated
        ? Colors.red[700]!
        : isAddAccount
        ? Colors.blue[700]!
        : Colors.grey[700]!;
    final Color timeColor = isDeactivated
        ? Colors.red[300]!
        : isAddAccount
        ? Colors.blue[300]!
        : Colors.grey[600]!;

    return Card(
      elevation: 4,
      color: isDeactivated
          ? Colors.red[50]
          : isAddAccount
          ? Colors.blue[50]
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDeactivated
              ? Colors.red
              : isAddAccount
              ? Colors.blue
              : Colors.grey[300]!,
          width: isDeactivated || isAddAccount ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => _showNotificationDialog(
          context,
          title,
          message,
          icon,
          finalColor,
          timestamp,
          type,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: isDeactivated
                          ? Colors.red[300]
                          : isAddAccount
                          ? Colors.blue[300]
                          : Colors.grey,
                    ),
                    onPressed: () => _dismissNotification(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  getTypeLabel(type),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: finalColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(fontSize: 14, color: messageColor),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: timeColor),
                  const SizedBox(width: 6),
                  Text(
                    timestamp != null
                        ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
                        : 'No date',
                    style: TextStyle(fontSize: 12, color: timeColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDialog(
      BuildContext context,
      String title,
      String message,
      IconData icon,
      Color color,
      Timestamp? timestamp,
      String type,
      ) {
    final bool isDeactivated = type == 'deactivate';
    final bool isAddAccount = type == 'add_account';
    final Color dialogColor = isDeactivated
        ? Colors.red
        : isAddAccount
        ? Colors.blue
        : color;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDeactivated
            ? Colors.red[50]
            : isAddAccount
            ? Colors.blue[50]
            : null,
        title: Row(
          children: [
            Icon(icon, color: dialogColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 20, color: dialogColor),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: isDeactivated
                    ? Colors.red[700]
                    : isAddAccount
                    ? Colors.blue[700]
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            if (timestamp != null)
              Text(
                DateFormat('MMM d, yyyy - hh:mm a').format(timestamp.toDate()),
                style: TextStyle(
                  fontSize: 14,
                  color: isDeactivated
                      ? Colors.red[300]
                      : isAddAccount
                      ? Colors.blue[300]
                      : Colors.grey[600],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: dialogColor)),
          ),
          TextButton(
            onPressed: () {
              _dismissNotification(context);
              Navigator.pop(context);
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  void _dismissNotification(BuildContext context) async {
    try {
      await docReference.update({'dismissed': true});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification dismissed'),
            duration: Duration(seconds: 2),
          ),
        );
        // Refresh the list after dismissal
        onDismiss?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to dismiss notification: $e')),
        );
      }
    }
  }
}

// Utility Functions
Future<void> createSystemNotification(
    String title,
    String message,
    String role,
    ) async {
  try {
    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: role)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty && role == 'super_admin') {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'message': message,
        'time': FieldValue.serverTimestamp(),
        'dismissed': false,
        'type': 'system',
        'createdBy': role,
      });
    } else {
      throw Exception('Not authorized to create system notifications');
    }
  } catch (e) {
    throw Exception('Failed to create system notification: $e');
  }
}

Future<void> addEmployee(String name, String email) async {
  try {
    final usersRef = FirebaseFirestore.instance.collection('users');

    await usersRef.add({
      'name': name,
      'email': email,
      'role': 'employee',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': name,
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'New Employee Registered',
      'message': '$name has been added to the system',
      'time': FieldValue.serverTimestamp(),
      'dismissed': false,
      'type': 'add_account',
      'createdBy': 'system',
    });
  } catch (e) {
    throw Exception('Failed to add employee: $e');
  }
}

Future<void> logSecurityWarning(String message) async {
  try {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'Security Warning',
      'message': message,
      'time': FieldValue.serverTimestamp(),
      'dismissed': false,
      'type': 'security',
      'createdBy': 'system',
    });
  } catch (e) {
    throw Exception('Failed to log security warning: $e');
  }
}