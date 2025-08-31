import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'پروفایل',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black54),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: MediaQuery.of(context).size.width * 0.12,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person,
                    size: MediaQuery.of(context).size.width * 0.12,
                    color: Colors.white),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            // اطلاعات کاربر و تنظیمات مرتبط با حساب کاربری اینجا اضافه خواهد شد
            const Center(
              child: Text(
                'بخش پروفایل در حال توسعه است',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
