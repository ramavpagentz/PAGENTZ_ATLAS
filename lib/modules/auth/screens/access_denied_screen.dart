import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.block, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text('Access denied',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text(
                    'This account is not provisioned as PagentZ staff. Contact the Atlas owner if you believe this is an error.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => Get.offAllNamed('/login'),
                    child: const Text('Back to sign-in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
