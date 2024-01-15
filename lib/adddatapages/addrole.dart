import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kr_fitness/displaypages/dashboard.dart';
import 'package:kr_fitness/utils/color.dart';
import 'package:line_icons/line_icons.dart';
import 'package:toast/toast.dart';

class AddRolePage extends StatefulWidget {
  const AddRolePage({super.key});

  @override
  State<AddRolePage> createState() => _AddRolePageState();
}

class _AddRolePageState extends State<AddRolePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _selectedRole = 'Manager';

  Future<void> _addUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Step 1: Create a new user account using Firebase Authentication
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Step 2: Get the user ID from the authentication result
        String userId = userCredential.user!.uid;

        // Step 3: Store additional information in Firestore
        await FirebaseFirestore.instance
            .collection('UserRoles')
            .doc(userId)
            .set({
          'name': _nameController.text.trim(),
          'role': _selectedRole,
        });
        Toast.show('Role added successfully',
            backgroundColor: Colors.green,
            duration: Toast.lengthShort,
            gravity: Toast.bottom);
      } catch (e) {
        // Handle errors (e.g., email already exists)
        print('Error adding user: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Add User',
          style: TextStyle(
              fontSize: 23, color: Colors.black, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    LineIcons.mailBulk,
                    color: Colors.black87,
                  ),
                  border: OutlineInputBorder(),
                  label: Text("Email"),
                  labelStyle: TextStyle(color: Colors.black87),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    LineIcons.userSecret,
                    color: Colors.black87,
                  ),
                  border: OutlineInputBorder(),
                  label: Text("Password"),
                  labelStyle: TextStyle(color: Colors.black87),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    LineIcons.user,
                    color: Colors.black87,
                  ),
                  border: OutlineInputBorder(),
                  label: Text("Name"),
                  labelStyle: TextStyle(color: Colors.black87),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 10,
              ),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: ['Developer', 'Manager']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.manage_accounts,
                    color: Colors.black87,
                  ),
                  border: OutlineInputBorder(),
                  label: Text("Role"),
                  labelStyle: TextStyle(color: Colors.black87),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a role';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: AppColors.primaryCard,
                ),
                onPressed: () async {
                  if (GlobalVariablesUse.role == 'Owner') {
                    await _addUser();
                    await FirebaseAuth.instance.signOut();
                    Navigator.pop(context);
                  } else {
                    Toast.show('you cant add a role',
                        backgroundColor: Colors.red,
                        duration: Toast.lengthShort,
                        gravity: Toast.bottom);
                  }
                },
                child: Text(
                  'Add User',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
