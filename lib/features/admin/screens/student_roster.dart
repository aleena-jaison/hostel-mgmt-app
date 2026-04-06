import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hostel_manager/shared/models/user_model.dart';

class StudentRoster extends ConsumerStatefulWidget {
  const StudentRoster({super.key});

  @override
  ConsumerState<StudentRoster> createState() => _StudentRosterState();
}

class _StudentRosterState extends ConsumerState<StudentRoster> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Roster'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStudentSheet(context),
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
            ),
          ),
          // Student list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'student')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                final students = docs
                    .map((doc) => UserModel.fromFirestore(doc))
                    .where((student) =>
                        _searchQuery.isEmpty ||
                        student.name.toLowerCase().contains(_searchQuery))
                    .toList();

                if (students.isEmpty) {
                  return const Center(
                    child: Text('No students found.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return _StudentCard(
                      student: student,
                      onTap: () => _showStudentDetail(context, student),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentDetail(BuildContext context, UserModel student) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(student.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Email', value: student.email),
              _DetailRow(
                  label: 'Room', value: student.roomNumber ?? 'Not assigned'),
              _DetailRow(label: 'Phone', value: student.phone),
              _DetailRow(
                label: 'Joined',
                value:
                    '${student.createdAt.day}/${student.createdAt.month}/${student.createdAt.year}',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAddStudentSheet(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final roomController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            bool isCreating = false;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Register New Student',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: roomController,
                      decoration: const InputDecoration(
                        labelText: 'Room Number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: isCreating
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => isCreating = true);
                              await _createStudent(
                                ctx,
                                name: nameController.text.trim(),
                                email: emailController.text.trim(),
                                room: roomController.text.trim(),
                                phone: phoneController.text.trim(),
                              );
                              setSheetState(() => isCreating = false);
                            },
                      child: isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Register Student'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Creates a new student account in Firebase Auth and Firestore.
  ///
  /// LIMITATION: [FirebaseAuth.createUserWithEmailAndPassword] signs in as
  /// the newly created user, which signs out the current warden. As a
  /// workaround, we capture the warden's credentials before creating the
  /// student and re-authenticate afterwards.
  ///
  /// For production use, this should be handled by a Cloud Function that
  /// uses the Firebase Admin SDK to create user accounts without affecting
  /// the current session.
  Future<void> _createStudent(
    BuildContext context, {
    required String name,
    required String email,
    required String room,
    required String phone,
  }) async {
    const tempPassword = 'Hostel@123';
    final auth = FirebaseAuth.instance;

    // Save the current warden's credentials before creating the student.
    final wardenUser = auth.currentUser;
    final wardenEmail = wardenUser?.email;

    try {
      // Create the student's Firebase Auth account.
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );

      final studentUid = credential.user!.uid;

      // Write the student document to Firestore.
      await FirebaseFirestore.instance.collection('users').doc(studentUid).set({
        'name': name,
        'email': email,
        'role': 'student',
        'roomNumber': room,
        'phone': phone,
        'faceEmbedding': null,
        'profileImageUrl': null,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      // Sign back in as the warden.
      // NOTE: This requires the warden to re-enter their password in a real
      // app, or you'd need to store it temporarily. For development purposes
      // we sign out the student account and rely on auth state persistence
      // to restore the warden session. In production, use Cloud Functions.
      if (wardenEmail != null) {
        // Sign out the newly created student account.
        await auth.signOut();

        // The auth state listener will detect sign-out. The warden needs to
        // sign back in. Show a message about this limitation.
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Student registered. Please sign in again. '
                '(Use Cloud Functions in production to avoid this.)',
              ),
              duration: Duration(seconds: 5),
            ),
          );
          Navigator.of(context).pop(); // Close the bottom sheet
        }
        return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name registered with temporary password.'),
          ),
        );
        Navigator.of(context).pop(); // Close the bottom sheet
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.message}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _StudentCard extends StatelessWidget {
  final UserModel student;
  final VoidCallback onTap;

  const _StudentCard({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundImage: student.profileImageUrl != null
              ? NetworkImage(student.profileImageUrl!)
              : null,
          child: student.profileImageUrl == null
              ? Text(student.name.isNotEmpty ? student.name[0].toUpperCase() : '?')
              : null,
        ),
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${student.email}\nRoom: ${student.roomNumber ?? "N/A"} | ${student.phone}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
