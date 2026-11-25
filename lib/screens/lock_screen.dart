import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_lock.dart';
import '../theme.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppLock>().unlock();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.green,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fingerprint, size: 96, color: AppColors.dark),
              const SizedBox(height: 16),
              const Text('FinWise verrouillé',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.dark)),
              const SizedBox(height: 8),
              const Text('Authentifiez-vous pour continuer',
                  style: TextStyle(color: AppColors.dark)),
              const SizedBox(height: 32),
              SizedBox(
                width: 260,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.dark, foregroundColor: Colors.white),
                  onPressed: () => context.read<AppLock>().unlock(),
                  child: const Text('Déverrouiller'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
