import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction_model.dart';
import '../../providers/goal_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/premium_screen_header.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  Future<void> _deleteTransaction(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    final id = transaction.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar transacción'),
        content: Text('Se eliminará "${transaction.descripcion}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      HapticFeedback.mediumImpact();
      await ref.read(transactionRepositoryProvider).delete(id);
      ref.invalidate(transactionsProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(goalsProvider);
      ref.invalidate(portfoliosProvider);
      ref.invalidate(userProfileProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transacción eliminada')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(transactionsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 140),
            children: [
              PremiumScreenHeader(
                title: 'Movimientos',
                subtitle: 'Decisiones registradas',
                primaryIcon: Icons.add_rounded,
                onPrimary: () =>
                    Navigator.pushNamed(context, '/add-transaction'),
                secondaryIcon: Icons.document_scanner_rounded,
                onSecondary: () => Navigator.pushNamed(context, '/ocr-capture'),
              ),
              const SizedBox(height: 22),
              transactionsAsync.when(
                data: (transactions) {
                  final ingresos = transactions
                      .where((t) => t.tipo == 'ingreso')
                      .fold<double>(0, (sum, t) => sum + t.monto);
                  final gastos = transactions
                      .where((t) => t.tipo == 'gasto')
                      .fold<double>(0, (sum, t) => sum + t.monto);
                  final balance = ingresos - gastos;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: 'Tu actividad reciente\n',
                          style: const TextStyle(
                            fontSize: 27,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            color: Color(0xFF0A0A0A),
                          ),
                          children: [
                            TextSpan(
                              text: transactions.isEmpty
                                  ? 'todavía espera señales.'
                                  : balance >= 0
                                  ? 'mantiene margen positivo.'
                                  : 'necesita una revisión.',
                              style: const TextStyle(color: Color(0xFF8A8A8A)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              label: 'Ingresos',
                              value: '\$${ingresos.toStringAsFixed(0)}',
                              icon: Icons.south_west_rounded,
                              tint: const Color(0xFFC7E8FF),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Gastos',
                              value: '\$${gastos.toStringAsFixed(0)}',
                              icon: Icons.north_east_rounded,
                              tint: const Color(0xFFF7F7F7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Text(
                            'Recientes',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Color(0xFF0A0A0A),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${transactions.length}',
                            style: const TextStyle(
                              color: Color(0xFF8A8A8A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (transactions.isEmpty)
                        const _EmptyPanel(
                          icon: Icons.receipt_long_outlined,
                          title: 'No hay movimientos',
                          subtitle:
                              'Registra una decisión para activar el historial.',
                        )
                      else
                        BentoCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (int i = 0; i < transactions.length; i++) ...[
                                _TransactionRow(
                                  transaction: transactions[i],
                                  onDelete: () => _deleteTransaction(
                                    context,
                                    ref,
                                    transactions[i],
                                  ),
                                ),
                                if (i != transactions.length - 1)
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFE6E6E6),
                                  ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const SizedBox(
                  height: 360,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _EmptyPanel(
                  icon: Icons.error_outline_rounded,
                  title: 'No se pudo cargar',
                  subtitle: '$e',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2D20D8), size: 18),
          ),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: Color(0xFF8A8A8A))),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0A0A0A),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onDelete;

  const _TransactionRow({required this.transaction, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.tipo == 'ingreso';
    final color = isIncome ? const Color(0xFF10B981) : const Color(0xFFFF3B30);

    return Dismissible(
      key: ValueKey(transaction.id ?? transaction.descripcion),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        color: const Color(0xFFFF3B30),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.descripcion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0A0A0A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${transaction.categoria} · ${transaction.fecha.day}/${transaction.fecha.month}/${transaction.fecha.year}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8A8A8A),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${isIncome ? '+' : '-'}\$${transaction.monto.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: const Color(0xFF8A8A8A),
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      child: SizedBox(
        height: 220,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: const Color(0xFF2D20D8)),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0A0A0A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8A8A8A)),
            ),
          ],
        ),
      ),
    );
  }
}
