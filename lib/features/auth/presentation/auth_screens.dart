import 'package:dayforge/core/presentation/dayforge_ui.dart';
import 'package:dayforge/features/auth/presentation/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to continue building your day.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: _requiredEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              decoration:
                  const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ).copyWith(
                    suffixIcon: IconButton(
                      tooltip: _hidePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () {
                        setState(() => _hidePassword = !_hidePassword);
                      },
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
              obscureText: _hidePassword,
              validator: _requiredPassword,
            ),
            if (auth.errorMessage != null) ...[
              const SizedBox(height: 14),
              ErrorText(auth.errorMessage!),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: auth.isLoading ? null : _submit,
              icon: auth.isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: const Text('Sign in'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: context.dayforgeBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: TextStyle(
                      color: context.dayforgeMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: context.dayforgeBorder)),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: auth.isLoading ? null : () => _showGoogleChooser(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: context.dayforgeBorder),
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white,
                foregroundColor: context.dayforgeText,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png',
                    width: 18,
                    height: 18,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.g_mobiledata, size: 22, color: Colors.blue);
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Sign in with Google',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: auth.isLoading ? null : () => context.go('/register'),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGoogleChooser(BuildContext context) async {
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const GoogleAccountChooserDialog(),
    );

    if (success == true && mounted) {
      context.go('/profile');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      context.go('/profile');
    }
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return AuthScaffold(
      title: 'Create Upgro',
      subtitle: 'Start with a secure account.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: _requiredText,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: _requiredEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              decoration:
                  const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ).copyWith(
                    suffixIcon: IconButton(
                      tooltip: _hidePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () {
                        setState(() => _hidePassword = !_hidePassword);
                      },
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
              obscureText: _hidePassword,
              validator: _requiredPassword,
            ),
            if (auth.errorMessage != null) ...[
              const SizedBox(height: 14),
              ErrorText(auth.errorMessage!),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: auth.isLoading ? null : _submit,
              icon: auth.isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt),
              label: const Text('Create account'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: context.dayforgeBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: TextStyle(
                      color: context.dayforgeMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: context.dayforgeBorder)),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: auth.isLoading ? null : () => _showGoogleChooser(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: context.dayforgeBorder),
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white,
                foregroundColor: context.dayforgeText,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png',
                    width: 18,
                    height: 18,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.g_mobiledata, size: 22, color: Colors.blue);
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Sign up with Google',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: auth.isLoading ? null : () => context.go('/login'),
              child: const Text('I already have an account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGoogleChooser(BuildContext context) async {
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const GoogleAccountChooserDialog(),
    );

    if (success == true && mounted) {
      context.go('/profile');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      context.go('/profile');
    }
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  final content = AuthPanel(
                    title: title,
                    subtitle: subtitle,
                    child: child,
                  );

                  if (!wide) {
                    return content;
                  }

                  return Row(
                    children: [
                      const Expanded(child: BrandPanel()),
                      const SizedBox(width: 28),
                      SizedBox(width: 430, child: content),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthPanel extends StatelessWidget {
  const AuthPanel({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DayForgeCard(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.trending_up,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: context.dayforgeText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.dayforgeMuted),
            ),
            const SizedBox(height: 28),
            child,
          ],
        ),
      ),
    );
  }
}

class BrandPanel extends StatelessWidget {
  const BrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(Icons.trending_up, size: 38, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(
          'Upgro',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: context.dayforgeText,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Plan the day, build the habit, finish the goal.',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: context.dayforgeMuted),
        ),
        const SizedBox(height: 24),
        DayForgeCard(
          color: theme.colorScheme.primary,
          child: const Text(
            'Focus tasks, habits, goals, and progress in one daily loop.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class ErrorText extends StatelessWidget {
  const ErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}

String? _requiredText(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required.';
  }

  return null;
}

String? _requiredEmail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Email is required.';
  }

  if (!text.contains('@')) {
    return 'Enter a valid email.';
  }

  return null;
}

String? _requiredPassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required.';
  }

  if (value.length < 8) {
    return 'Use at least 8 characters.';
  }

  return null;
}

class GoogleAccountChooserDialog extends ConsumerStatefulWidget {
  const GoogleAccountChooserDialog({super.key});

  @override
  ConsumerState<GoogleAccountChooserDialog> createState() => _GoogleAccountChooserDialogState();
}

class _GoogleAccountChooserDialogState extends ConsumerState<GoogleAccountChooserDialog> {
  bool _useCustom = false;
  bool _isLoading = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: DayForgeCard(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 28, color: Colors.blue),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Google Sign In',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.dayforgeText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose an account to continue to Upgro',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.dayforgeMuted,
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (!_useCustom) ...[
                _buildAccountTile(
                  name: 'John Doe',
                  email: 'john.doe@gmail.com',
                  avatarColor: Colors.blue.shade600,
                  avatarText: 'JD',
                ),
                const SizedBox(height: 10),
                _buildAccountTile(
                  name: 'Jane Smith',
                  email: 'jane.smith@gmail.com',
                  avatarColor: Colors.purple.shade600,
                  avatarText: 'JS',
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _useCustom = true),
                  icon: const Icon(Icons.add),
                  label: const Text('Use another account'),
                ),
              ] else ...[
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _requiredText,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _requiredEmail,
                      ),
                      const SizedBox(height: 18),
                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() {
                              _useCustom = false;
                              _errorMessage = null;
                            }),
                            child: const Text('Back'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _submitCustom,
                            child: const Text('Sign in'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (_errorMessage != null && !_useCustom && !_isLoading) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTile({
    required String name,
    required String email,
    required Color avatarColor,
    required String avatarText,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _signIn(name: name, email: email),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: context.dayforgeBorder.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: avatarColor,
              radius: 18,
              child: Text(
                avatarText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.dayforgeText,
                    ),
                  ),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.dayforgeMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: context.dayforgeMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signIn({required String name, required String email}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!mounted) return;

    final googleId = 'google_sim_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';

    try {
      final success = await ref.read(authControllerProvider.notifier).loginWithGoogle(
        email: email,
        name: name,
        googleId: googleId,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, true);
      } else {
        final authState = ref.read(authControllerProvider);
        setState(() {
          _isLoading = false;
          _errorMessage = authState.errorMessage ?? 'Sign in failed. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred.';
        });
      }
    }
  }

  void _submitCustom() {
    if (_formKey.currentState!.validate()) {
      _signIn(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );
    }
  }
}
