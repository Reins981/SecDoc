import 'package:flutter/material.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const TextField(
              decoration: InputDecoration(labelText: 'Username'),
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'Email'),
            ),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            DropdownButton<String>(
              value: 'client',
              onChanged: (newValue) {
                // TODO: Handle dropdown value change
              },
              items: <String>['client', 'admin'].map<DropdownMenuItem<String>>(
                    (String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                },
              ).toList(),
            ),
            DropdownButton<String>(
              value: 'BACQROO-MEX',
              onChanged: (newValue) {
                // TODO: Handle dropdown value change
              },
              items: <String>['BACQROO-MEX', 'BACQROO-PDC', 'BACQROO-ALL']
                  .map<DropdownMenuItem<String>>(
                    (String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                },
              ).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement registration logic
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
