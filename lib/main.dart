import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/transactions/transaction_list_screen.dart';
import 'screens/transactions/add_transaction_screen.dart';
import 'screens/transactions/ocr_capture_screen.dart';
import 'screens/agent/agent_chat_screen.dart';
import 'screens/portfolios/portfolio_list_screen.dart';
import 'screens/goals/goal_list_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await SupabaseService.instance.initialize();

  runApp(const ProviderScope(child: CopilotoFinancieroApp()));
}

class CopilotoFinancieroApp extends StatelessWidget {
  const CopilotoFinancieroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Copiloto Financiero',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode:
          ThemeMode.light, // Pivote visual completo a light mode minimalista
      routes: {
        '/add-transaction': (_) => const AddTransactionScreen(),
        '/ocr-capture': (_) => const OcrCaptureScreen(),
        '/agent': (_) => const AgentChatScreen(),
      },
      home: StreamBuilder(
        stream: SupabaseService.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.data?.session;
          if (session != null) {
            return const MainShell();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    TransactionListScreen(),
    PortfolioListScreen(),
    GoalListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: buildActionPill(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE6E6E6), width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF0A0A0A),
          unselectedItemColor: const Color(0xFF8A8A8A),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          onTap: (i) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = i);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_vert_rounded),
              label: 'Transacciones',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'Carteras',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flag_outlined),
              label: 'Metas',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildActionPill() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D20D8),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D20D8).withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _pillAction(Icons.edit_note, "Manual", () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, '/add-transaction');
          }),
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withValues(alpha: 0.3),
          ), // Divisor
          _pillAction(Icons.document_scanner, "OCR", () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, '/ocr-capture');
          }),
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _pillAction(Icons.psychology, "IA", () {
            _showQuickSimulationDialog(context);
          }),
        ],
      ),
    );
  }

  void _showQuickSimulationDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    final descCtrl = TextEditingController();
    final montoCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F5FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Simulador de Compras IA",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "¿Qué quieres comprar? La IA evaluará el impacto de esta compra en tu balance, carteras y metas en tiempo real.",
                style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: '¿Qué vas a comprar? (ej: Laptop, Cafe)',
                  hintText: 'ej: Laptop',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: montoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto (\$)',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Cancelar"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final desc = descCtrl.text.trim();
                        final monto = montoCtrl.text.trim();
                        if (desc.isEmpty || monto.isEmpty) return;

                        HapticFeedback.mediumImpact();
                        Navigator.pop(ctx);

                        // Navegamos al chat de IA pasándole los argumentos de simulación
                        Navigator.pushNamed(
                          context,
                          '/agent',
                          arguments: {
                            'simulacion': {
                              'descripcion': desc,
                              'monto': double.tryParse(monto) ?? 0.0,
                            },
                          },
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Simular con IA"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pillAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
