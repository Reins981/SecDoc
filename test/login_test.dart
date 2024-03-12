import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sec_doc/login.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    // Mock FirebaseAuth instance for testing
    FirebaseAuthMock authMock;

    setUp(() {
      // Initialize the mock before each test
      authMock = FirebaseAuthMock();
      LoginScreen.auth = authMock;
    });

    testWidgets('LoginScreen UI test', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Verify if the key UI components are present
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('LoginScreen authentication success', (WidgetTester tester) async {
      // Mock the signInWithEmailAndPassword method to return a successful result
      when(authMock.signInWithEmailAndPassword(email: anyNamed('email'), password: anyNamed('password')))
          .thenAnswer((_) => Future<UserCredential>.value(MockUserCredential()));

      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Tap the login button.
      await tester.tap(find.byType(ElevatedButton));

      // Wait for the async call to complete.
      await tester.pump();

      // Verify if the welcome dialog is shown
      expect(find.text('Welcome!'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('LoginScreen authentication failure', (WidgetTester tester) async {
      // Mock the signInWithEmailAndPassword method to throw an exception
      when(authMock.signInWithEmailAndPassword(email: anyNamed('email'), password: anyNamed('password')))
          .thenThrow(FirebaseAuthException(code: 'code', message: 'Error message'));

      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Tap the login button.
      await tester.tap(find.byType(ElevatedButton));

      // Wait for the async call to complete.
      await tester.pump();

      // Verify if an error snackbar is shown
      expect(find.text('Error message'), findsOneWidget);
    });
  });
}

class FirebaseAuthMock extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}
