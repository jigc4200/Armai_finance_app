import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/portfolio_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/premium_screen_header.dart';

class PortfolioListScreen extends ConsumerStatefulWidget {
  const PortfolioListScreen({super.key});

  @override
  ConsumerState<PortfolioListScreen> createState() =>
      _PortfolioListScreenState();
}

class _PortfolioListScreenState extends ConsumerState<PortfolioListScreen> {
  final _nombreCtrl = TextEditingController();
  final _invertidoCtrl = TextEditingController();
  String _tipo = 'activo';
  bool _showForm = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _invertidoCtrl.dispose();
    super.dispose();
  }

  Future<void> _createPortfolio() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(portfolioRepositoryProvider);
      await repo.create(
        Portfolio(
          userId: user.id,
          nombre: nombre,
          tipo: _tipo,
          totalInvertido: double.tryParse(_invertidoCtrl.text.trim()) ?? 0,
        ),
      );

      _nombreCtrl.clear();
      _invertidoCtrl.clear();
      setState(() => _showForm = false);
      ref.invalidate(portfoliosProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePortfolio(Portfolio portfolio) async {
    final id = portfolio.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cartera'),
        content: Text(
          'Las transacciones vinculadas quedarán sin cartera. ¿Eliminar "${portfolio.nombre}"?',
        ),
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
      await ref.read(portfolioRepositoryProvider).delete(id);
      ref.invalidate(portfoliosProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(recentTransactionsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cartera eliminada')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
    }
  }

  Widget _buildFormCard() {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nueva cartera',
            style: TextStyle(
              color: Color(0xFF0A0A0A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej: Laptop IA, Educación...',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _invertidoCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Inversión inicial',
              prefixText: '\$ ',
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'activo', label: Text('Activo')),
              ButtonSegment(
                value: 'gasto_recurrente',
                label: Text('Recurrente'),
              ),
              ButtonSegment(value: 'proyecto', label: Text('Proyecto')),
            ],
            selected: {_tipo},
            onSelectionChanged: (v) => setState(() => _tipo = v.first),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showForm = false),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isLoading ? null : _createPortfolio,
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Crear'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfoliosAsync = ref.watch(portfoliosProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(portfoliosProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 140),
            children: [
              PremiumScreenHeader(
                title: 'Carteras',
                subtitle: 'ROI personal por decisión',
                primaryIcon: _showForm
                    ? Icons.close_rounded
                    : Icons.add_rounded,
                onPrimary: () => setState(() => _showForm = !_showForm),
                secondaryIcon: Icons.insights_rounded,
                onSecondary: () => Navigator.pushNamed(
                  context,
                  '/agent',
                  arguments: {
                    'prompt':
                        'Analiza mis carteras y dime cual decision esta construyendo mas patrimonio.',
                  },
                ),
              ),
              const SizedBox(height: 22),
              Text.rich(
                const TextSpan(
                  text: 'No son cuentas.\n',
                  style: TextStyle(
                    fontSize: 27,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    color: Color(0xFF0A0A0A),
                  ),
                  children: [
                    TextSpan(
                      text: 'son expedientes de decisiones.',
                      style: TextStyle(color: Color(0xFF8A8A8A)),
                    ),
                  ],
                ),
              ),
              if (_showForm) ...[const SizedBox(height: 18), _buildFormCard()],
              const SizedBox(height: 18),
              portfoliosAsync.when(
                data: (portfolios) {
                  if (portfolios.isEmpty) {
                    return const _EmptyPanel(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Crea tu primera cartera',
                      subtitle:
                          'Agrupa decisiones como educación, herramientas o proyectos.',
                    );
                  }

                  return Column(
                    children: [
                      for (final portfolio in portfolios)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PortfolioCard(
                            portfolio: portfolio,
                            onDelete: () => _deletePortfolio(portfolio),
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

class _PortfolioCard extends StatelessWidget {
  final Portfolio portfolio;
  final VoidCallback onDelete;

  const _PortfolioCard({required this.portfolio, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final roiPositive = portfolio.roiCalculado >= 0;
    final roiColor = roiPositive
        ? const Color(0xFF10B981)
        : const Color(0xFFFF3B30);

    return Dismissible(
      key: ValueKey(portfolio.id ?? portfolio.nombre),
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
      child: BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC7E8FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    portfolio.tipo == 'activo'
                        ? Icons.trending_up_rounded
                        : portfolio.tipo == 'proyecto'
                        ? Icons.rocket_launch_rounded
                        : Icons.repeat_rounded,
                    color: const Color(0xFF2D20D8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        portfolio.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0A0A0A),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        portfolio.tipo.replaceAll('_', ' '),
                        style: const TextStyle(color: Color(0xFF8A8A8A)),
                      ),
                    ],
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
            const SizedBox(height: 18),
            Row(
              children: [
                _Stat(
                  label: 'Invertido',
                  value: '\$${portfolio.totalInvertido.toStringAsFixed(0)}',
                ),
                const SizedBox(width: 24),
                _Stat(
                  label: 'Retorno',
                  value: '\$${portfolio.totalRetorno.toStringAsFixed(0)}',
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: roiColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${roiPositive ? '+' : ''}${portfolio.roiCalculado.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: roiColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 12),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0A0A0A),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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
        height: 260,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: const Color(0xFF2D20D8)),
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
