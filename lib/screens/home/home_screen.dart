import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/ai_insight_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/goal_model.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/insight_ia_card.dart';
import '../../services/supabase_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(recentTransactionsProvider);
            ref.invalidate(portfoliosProvider);
            ref.invalidate(goalsProvider);
            ref.invalidate(userProfileProvider);
          },
          child: ListView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: 140,
            ),
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final profileAsync = ref.watch(userProfileProvider);
                  return profileAsync.when(
                    data: (profile) {
                      return _DashboardHeader(
                        title: 'Decisiones',
                        subtitle: profile == null
                            ? 'Copiloto financiero'
                            : '${profile.rango} · Nivel ${profile.nivel}',
                        onPrimary: () =>
                            Navigator.pushNamed(context, '/add-transaction'),
                        onSecondary: () =>
                            Navigator.pushNamed(context, '/ocr-capture'),
                        onLogout: () async {
                          HapticFeedback.mediumImpact();
                          await ref.read(authRepositoryProvider).signOut();
                        },
                        onTitleTap: profile == null
                            ? null
                            : () => _showAchievementsSheet(context, ref),
                      );
                    },
                    loading: () => _DashboardHeader(
                      title: 'Decisiones',
                      subtitle: 'Preparando cabina',
                      onPrimary: () =>
                          Navigator.pushNamed(context, '/add-transaction'),
                      onSecondary: () =>
                          Navigator.pushNamed(context, '/ocr-capture'),
                      onLogout: () async {
                        HapticFeedback.mediumImpact();
                        await ref.read(authRepositoryProvider).signOut();
                      },
                    ),
                    error: (error, _) => _DashboardHeader(
                      title: 'Decisiones',
                      subtitle: user?.email ?? 'Copiloto financiero',
                      onPrimary: () =>
                          Navigator.pushNamed(context, '/add-transaction'),
                      onSecondary: () =>
                          Navigator.pushNamed(context, '/ocr-capture'),
                      onLogout: () async {
                        HapticFeedback.mediumImpact();
                        await ref.read(authRepositoryProvider).signOut();
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
              Consumer(
                builder: (context, ref, child) {
                  return _DashboardHero(
                    transactionsAsync: ref.watch(recentTransactionsProvider),
                    goalsAsync: ref.watch(goalsProvider),
                  );
                },
              ),
              const SizedBox(height: 18),
              Consumer(
                builder: (context, ref, child) {
                  return _DecisionCockpit(
                    transactionsAsync: ref.watch(recentTransactionsProvider),
                    goalsAsync: ref.watch(goalsProvider),
                  );
                },
              ),
              const SizedBox(height: 6),
              Consumer(
                builder: (context, ref, child) {
                  return _TwoColumnSummary(
                    transactionsAsync: ref.watch(recentTransactionsProvider),
                    goalsAsync: ref.watch(goalsProvider),
                  );
                },
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Text(
                    'Actividad',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0A0A0A),
                    ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: () {}, child: const Text('Ver todo')),
                ],
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, child) {
                  return _ActivityGrid(
                    transactionsAsync: ref.watch(recentTransactionsProvider),
                    portfoliosAsync: ref.watch(portfoliosProvider),
                  );
                },
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final insightAsync = ref.watch(activeAiInsightProvider);
                  return insightAsync.when(
                    data: (insight) {
                      if (insight == null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            InsightIaCard.repose(
                              title: "Todo en orden",
                              message:
                                  "Tu Copiloto está analizando tus movimientos financieros en segundo plano.",
                              actionText: "Preguntar algo",
                              iconName: "psychology",
                              onTap: () {
                                Navigator.pushNamed(context, '/agent');
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          InsightIaCard(
                            title: insight.titulo,
                            message: insight.mensajeCorto,
                            actionText: insight.accionTexto,
                            iconName: insight.icono,
                            onTap: () {
                              Navigator.pushNamed(context, '/agent');
                            },
                            onDismiss: () {
                              ref
                                  .read(activeAiInsightProvider.notifier)
                                  .dismissInsight();
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                    loading: () => const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [ShimmerInsightCard(), SizedBox(height: 16)],
                    ),
                    error: (error, stackTrace) => const SizedBox.shrink(),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, child) {
                  final goalsAsync = ref.watch(goalsProvider);
                  return _buildBossFightCard(theme, goalsAsync);
                },
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final portfoliosAsync = ref.watch(portfoliosProvider);
                  return _buildPortfoliosPreview(theme, portfoliosAsync);
                },
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final transactionsAsync = ref.watch(
                    recentTransactionsProvider,
                  );
                  return _buildRecentTransactions(theme, transactionsAsync);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final VoidCallback onLogout;
  final VoidCallback? onTitleTap;

  const _DashboardHeader({
    required this.title,
    required this.subtitle,
    required this.onPrimary,
    required this.onSecondary,
    required this.onLogout,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onTitleTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8A8A8A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        _CircleHeaderButton(
          icon: Icons.add_rounded,
          background: const Color(0xFF0A0A0A),
          foreground: Colors.white,
          onTap: onPrimary,
        ),
        const SizedBox(width: 10),
        _CircleHeaderButton(
          icon: Icons.document_scanner_rounded,
          background: Colors.white,
          foreground: const Color(0xFF0A0A0A),
          onTap: onSecondary,
        ),
        const SizedBox(width: 10),
        _CircleHeaderButton(
          icon: Icons.logout_rounded,
          background: Colors.white,
          foreground: const Color(0xFFFF3B30),
          onTap: onLogout,
        ),
      ],
    );
  }
}

class _CircleHeaderButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _CircleHeaderButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: foreground, size: 21),
        ),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final AsyncValue<List> transactionsAsync;
  final AsyncValue<List<Goal>> goalsAsync;

  const _DashboardHero({
    required this.transactionsAsync,
    required this.goalsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final transactions = (transactionsAsync.asData?.value ?? [])
        .whereType<Transaction>()
        .toList();
    final goals = goalsAsync.asData?.value ?? [];
    final pulse = _FinancialPulse.from(transactions, goals);

    return Text.rich(
      TextSpan(
        text: '${pulse.heroLine}\n',
        style: const TextStyle(
          fontSize: 27,
          height: 1.05,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
          color: Color(0xFF0A0A0A),
        ),
        children: [
          TextSpan(
            text: pulse.heroMuted,
            style: const TextStyle(color: Color(0xFF8A8A8A)),
          ),
        ],
      ),
    );
  }
}

class _TwoColumnSummary extends StatelessWidget {
  final AsyncValue<List> transactionsAsync;
  final AsyncValue<List<Goal>> goalsAsync;

  const _TwoColumnSummary({
    required this.transactionsAsync,
    required this.goalsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final transactions = (transactionsAsync.asData?.value ?? [])
        .whereType<Transaction>()
        .toList();
    final goals = goalsAsync.asData?.value ?? [];
    final ingresos = transactions
        .where((t) => t.tipo == 'ingreso')
        .fold<double>(0, (sum, t) => sum + t.monto);
    final gastos = transactions
        .where((t) => t.tipo == 'gasto')
        .fold<double>(0, (sum, t) => sum + t.monto);
    final activeGoal = goals.where((g) => !g.completada).isEmpty
        ? null
        : goals.where((g) => !g.completada).first;

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Margen',
            value: '\$${(ingresos - gastos).toStringAsFixed(0)}',
            caption: 'Balance reciente',
            icon: Icons.insights_rounded,
            tint: const Color(0xFFC7E8FF),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: _SummaryTile(
            label: 'Meta activa',
            value: activeGoal == null
                ? '0%'
                : '${(activeGoal.progreso * 100).toStringAsFixed(0)}%',
            caption: activeGoal?.nombre ?? 'Sin objetivo',
            icon: Icons.flag_rounded,
            tint: const Color(0xFFF7F7F7),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color tint;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(16),
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
            child: Icon(icon, size: 18, color: const Color(0xFF2D20D8)),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8A8A8A),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0A0A0A),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ActivityGrid extends StatelessWidget {
  final AsyncValue<List> transactionsAsync;
  final AsyncValue<List> portfoliosAsync;

  const _ActivityGrid({
    required this.transactionsAsync,
    required this.portfoliosAsync,
  });

  @override
  Widget build(BuildContext context) {
    final transactions = (transactionsAsync.asData?.value ?? [])
        .whereType<Transaction>()
        .toList();
    final portfolios = portfoliosAsync.asData?.value ?? [];
    final lastTx = transactions.isEmpty ? null : transactions.first;
    final bestPortfolio = portfolios.isEmpty
        ? null
        : portfolios.reduce((a, b) => a.roiCalculado >= b.roiCalculado ? a : b);

    return Row(
      children: [
        Expanded(
          child: _ActivityTile(
            title: lastTx?.descripcion ?? 'Sin movimientos',
            subtitle: lastTx == null
                ? 'Registra tu primera decisión'
                : '${lastTx.categoria} · ${lastTx.tipo}',
            amount: lastTx == null
                ? 'Nuevo'
                : '\$${lastTx.monto.toStringAsFixed(0)}',
            icon: Icons.receipt_long_rounded,
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: _ActivityTile(
            title: bestPortfolio?.nombre ?? 'ROI pendiente',
            subtitle: bestPortfolio == null
                ? 'Crea una cartera'
                : 'Mejor cartera',
            amount: bestPortfolio == null
                ? '0%'
                : '${bestPortfolio.roiCalculado.toStringAsFixed(1)}%',
            icon: Icons.trending_up_rounded,
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 116,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF2D20D8), size: 20),
                const Spacer(),
                Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0A0A0A),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0A0A0A),
                fontWeight: FontWeight.w800,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionCockpit extends StatefulWidget {
  final AsyncValue<List> transactionsAsync;
  final AsyncValue<List<Goal>> goalsAsync;

  const _DecisionCockpit({
    required this.transactionsAsync,
    required this.goalsAsync,
  });

  @override
  State<_DecisionCockpit> createState() => _DecisionCockpitState();
}

class _DecisionCockpitState extends State<_DecisionCockpit> {
  final _decisionCtrl = TextEditingController();

  @override
  void dispose() {
    _decisionCtrl.dispose();
    super.dispose();
  }

  void _sendDecision(String text) {
    final prompt = text.trim();
    if (prompt.isEmpty) return;

    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/agent', arguments: {'prompt': prompt});
    _decisionCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsData = widget.transactionsAsync.asData?.value ?? [];
    final transactions = transactionsData.whereType<Transaction>().toList();
    final goals = widget.goalsAsync.asData?.value ?? [];
    final pulse = _FinancialPulse.from(transactions, goals);
    final ingresos = transactions
        .where((t) => t.tipo == 'ingreso')
        .fold<double>(0, (sum, t) => sum + t.monto);
    final gastos = transactions
        .where((t) => t.tipo == 'gasto')
        .fold<double>(0, (sum, t) => sum + t.monto);
    final balance = ingresos - gastos;
    final reversedTx = transactions.reversed.toList();
    double runningBalance = 0;
    final spots = <FlSpot>[];
    for (int i = 0; i < reversedTx.length; i++) {
      final tx = reversedTx[i];
      runningBalance += tx.tipo == 'ingreso' ? tx.monto : -tx.monto;
      spots.add(FlSpot(i.toDouble(), runningBalance));
    }

    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFC7E8FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(pulse.icon, color: const Color(0xFF2D20D8)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pulso financiero',
                      style: TextStyle(
                        color: Color(0xFF8A8A8A),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pulse.label,
                      style: const TextStyle(
                        color: Color(0xFF0A0A0A),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  pulse.score,
                  style: const TextStyle(
                    color: Color(0xFF2D20D8),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF0A0A0A),
              fontSize: 38,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            pulse.message,
            style: const TextStyle(
              color: Color(0xFF8A8A8A),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          _buildSparkline(Theme.of(context), spots, balance >= 0),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE6E6E6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _decisionCtrl,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendDecision,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      hintText: '¿Qué decisión quieres analizar?',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _sendDecision(_decisionCtrl.text),
                  icon: const Icon(Icons.arrow_upward_rounded),
                  tooltip: 'Analizar decisión',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF2D20D8),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DecisionChip(
                label: 'Analiza una compra',
                onTap: () => _sendDecision(
                  'Quiero comprar algo. Hazme preguntas y dime si esta decision ayuda o retrasa mis metas.',
                ),
              ),
              _DecisionChip(
                label: 'Mejor decisión',
                onTap: () => _sendDecision(
                  'Cual ha sido mi mejor decision financiera segun mis transacciones y carteras?',
                ),
              ),
              _DecisionChip(
                label: 'Detecta fugas',
                onTap: () => _sendDecision(
                  'Detecta mi principal fuga de dinero y dime que decision debo cambiar esta semana.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecisionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DecisionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      avatar: const Icon(
        Icons.bolt_rounded,
        size: 16,
        color: Color(0xFF2D20D8),
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF0A0A0A),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      side: const BorderSide(color: Color(0xFFE6E6E6)),
      backgroundColor: const Color(0xFFF7F7F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _FinancialPulse {
  final String label;
  final String score;
  final String message;
  final String detail;
  final String heroLine;
  final String heroMuted;
  final Color color;
  final IconData icon;

  const _FinancialPulse({
    required this.label,
    required this.score,
    required this.message,
    required this.detail,
    required this.heroLine,
    required this.heroMuted,
    required this.color,
    required this.icon,
  });

  factory _FinancialPulse.from(
    List<Transaction> transactions,
    List<Goal> goals,
  ) {
    if (transactions.isEmpty) {
      return const _FinancialPulse(
        label: 'Sin lectura inicial',
        score: '0 mov.',
        message: 'Tu copiloto necesita sus primeras señales.',
        detail:
            'Registra una decision o escanea un recibo para que la IA empiece a detectar patrones reales.',
        heroLine: 'Empieza con una decisión.',
        heroMuted: 'El agente aprende de cada movimiento.',
        color: Color(0xFF60A5FA),
        icon: Icons.radar_rounded,
      );
    }

    final ingresos = transactions
        .where((t) => t.tipo == 'ingreso')
        .fold<double>(0, (sum, t) => sum + t.monto);
    final gastos = transactions
        .where((t) => t.tipo == 'gasto')
        .fold<double>(0, (sum, t) => sum + t.monto);
    final balance = ingresos - gastos;
    final openGoals = goals.where((g) => !g.completada).toList();
    final avgGoalProgress = openGoals.isEmpty
        ? 0.0
        : openGoals.fold<double>(0, (sum, goal) => sum + goal.progreso) /
              openGoals.length;

    if (balance < 0) {
      return _FinancialPulse(
        label: 'Pulso en defensa',
        score: '\$${balance.toStringAsFixed(0)}',
        message: 'Estas gastando por encima de tu entrada reciente.',
        detail:
            'Antes de registrar otra compra, pide un veredicto. El agente debe proteger tus metas, no solo guardar gastos.',
        heroLine: 'Tu dinero está en defensa.',
        heroMuted: 'Analiza antes de comprar.',
        color: const Color(0xFFF87171),
        icon: Icons.warning_amber_rounded,
      );
    }

    if (avgGoalProgress > 0.65) {
      return _FinancialPulse(
        label: 'Meta en zona de cierre',
        score: '${(avgGoalProgress * 100).toStringAsFixed(0)}%',
        message: 'Estas cerca de convertir disciplina en patrimonio.',
        detail:
            'Cualquier compra grande ahora debe justificar su retorno o esperar. Tu ventaja esta en no distraerte.',
        heroLine: 'Una meta está cerca.',
        heroMuted: 'No dejes que una compra la retrase.',
        color: const Color(0xFF34D399),
        icon: Icons.flag_rounded,
      );
    }

    if (gastos > ingresos * 0.65 && ingresos > 0) {
      return _FinancialPulse(
        label: 'Ritmo acelerado',
        score: '${((gastos / ingresos) * 100).toStringAsFixed(0)}%',
        message: 'Tu margen se esta estrechando.',
        detail:
            'La pregunta correcta hoy no es cuanto gastaste, sino que decision se esta repitiendo demasiado.',
        heroLine: 'Tu ritmo se aceleró.',
        heroMuted: 'Busca la fuga antes de que pese.',
        color: const Color(0xFFFBBF24),
        icon: Icons.speed_rounded,
      );
    }

    return _FinancialPulse(
      label: 'Pulso estable',
      score: '+\$${balance.toStringAsFixed(0)}',
      message: 'Tienes espacio para decidir con estrategia.',
      detail:
          'Simula compras grandes antes de hacerlas y compara cada una contra tus carteras y metas activas.',
      heroLine: 'Tienes margen para decidir.',
      heroMuted: 'Úsalo con estrategia.',
      color: const Color(0xFF34D399),
      icon: Icons.trending_up_rounded,
    );
  }
}

Widget _buildPortfoliosPreview(
  ThemeData theme,
  AsyncValue<List> portfoliosAsync,
) {
  return portfoliosAsync.when(
    data: (portfolios) {
      if (portfolios.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Carteras', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          BentoCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: portfolios
                  .take(3)
                  .map(
                    (p) => ListTile(
                      leading: Icon(
                        p.tipo == 'activo' ? Icons.trending_up : Icons.repeat,
                        color: p.roiCalculado >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFFF3B30),
                      ),
                      title: Text(p.nombre),
                      subtitle: Text(
                        'Invertido: \$${p.totalInvertido.toStringAsFixed(0)}',
                      ),
                      trailing: Text(
                        '${p.roiCalculado.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: p.roiCalculado >= 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFFF3B30),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      );
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, _) => const SizedBox.shrink(),
  );
}

Widget _buildRecentTransactions(
  ThemeData theme,
  AsyncValue<List> transactionsAsync,
) {
  return transactionsAsync.when(
    data: (transactions) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Últimas transacciones', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (transactions.isEmpty)
            BentoCard(
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aún no hay transacciones',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            )
          else
            BentoCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: transactions
                    .take(5)
                    .map(
                      (t) => ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: t.tipo == 'ingreso'
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : const Color(0xFFFF3B30).withValues(alpha: 0.1),
                          child: Icon(
                            t.tipo == 'ingreso'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            size: 16,
                            color: t.tipo == 'ingreso'
                                ? const Color(0xFF10B981)
                                : const Color(0xFFFF3B30),
                          ),
                        ),
                        title: Text(
                          t.descripcion,
                          style: theme.textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          t.categoria,
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Text(
                          '\$${t.monto.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: t.tipo == 'ingreso'
                                ? const Color(0xFF10B981)
                                : const Color(0xFFFF3B30),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      );
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) =>
        BentoCard(child: Center(child: Text('Error al cargar: $e'))),
  );
}

void _showAchievementsSheet(BuildContext context, WidgetRef ref) async {
  HapticFeedback.lightImpact();
  final theme = Theme.of(context);
  final user = ref.read(currentUserProvider);
  if (user == null) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Árbol de Logros",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Derrota al Jefe Final y realiza buenas decisiones para desbloquear trofeos de tu carrera RPG financiera.",
                style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: SupabaseService.instance.client
                    .from('achievements')
                    .select()
                    .eq('user_id', user.id)
                    .then((value) => value as List<dynamic>),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final unlockedSlugs = (snapshot.data ?? [])
                      .map((e) => e['tipo'] as String)
                      .toSet();

                  final allAchievements = [
                    {
                      'slug': 'primer_mes_positivo',
                      'title': 'Primer mes positivo',
                      'desc': 'Balance positivo al cerrar el mes',
                      'icon': Icons.calendar_today_rounded,
                    },
                    {
                      'slug': 'fondo_emergencia',
                      'title': 'Fondo de emergencia completo',
                      'desc': 'Meta de emergencia al 100%',
                      'icon': Icons.shield_rounded,
                    },
                    {
                      'slug': 'primera_cartera_rentable',
                      'title': 'Primera cartera rentable',
                      'desc': 'ROI de alguna cartera > 0%',
                      'icon': Icons.trending_up_rounded,
                    },
                    {
                      'slug': 'roi_superior_100',
                      'title': 'ROI superior al 100%',
                      'desc': 'Alguna cartera supera el 100% de retorno',
                      'icon': Icons.rocket_launch_rounded,
                    },
                    {
                      'slug': 'no_compras_impulsivas_90',
                      'title': '90 días sin compras impulsivas',
                      'desc': '90 días sin compras marcadas como negativas',
                      'icon': Icons.shopping_bag_rounded,
                    },
                    {
                      'slug': 'decision_millon',
                      'title': 'Decisión de un millón',
                      'desc': 'Una cartera acumula retorno > \$1,000',
                      'icon': Icons.monetization_on_rounded,
                    },
                    {
                      'slug': 'racha_30_dias',
                      'title': 'Racha de 30 días',
                      'desc': '30 días consecutivos registrando transacciones',
                      'icon': Icons.local_fire_department_rounded,
                    },
                  ];

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    itemCount: allAchievements.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final ach = allAchievements[index];
                      final isUnlocked = unlockedSlugs.contains(ach['slug']);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isUnlocked
                              ? const Color(0xFFF0F5FF)
                              : const Color(0xFFF2F2F7),
                          child: Icon(
                            ach['icon'] as IconData,
                            color: isUnlocked
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                        title: Text(
                          ach['title'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isUnlocked
                                ? const Color(0xFF1C1C1E)
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                        subtitle: Text(
                          ach['desc'] as String,
                          style: TextStyle(
                            color: isUnlocked
                                ? const Color(0xFF475569)
                                : const Color(0xFFC7C7CC),
                          ),
                        ),
                        trailing: isUnlocked
                            ? const Icon(
                                Icons.emoji_events,
                                color: Colors.amber,
                              )
                            : const Icon(
                                Icons.lock_outline,
                                color: Color(0xFFC7C7CC),
                              ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildBossFightCard(ThemeData theme, AsyncValue<List<Goal>> goalsAsync) {
  return goalsAsync.when(
    data: (goals) {
      if (goals.isEmpty) return const SizedBox.shrink();

      // The first active goal is the "Boss"
      final bossGoal = goals.firstWhere(
        (g) => !g.completada,
        orElse: () => goals.first,
      );
      final pct = (bossGoal.progreso * 100).toStringAsFixed(0);
      final restante = bossGoal.montoObjetivo - bossGoal.montoActual;

      return BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.gavel, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  'JEFE FINAL: ${bossGoal.nombre.toUpperCase()}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (bossGoal.completada)
                  const Icon(Icons.emoji_events, color: Colors.amber)
                else
                  Text(
                    '$pct%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GlowingBossBar(progreso: bossGoal.progreso),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Objetivo: \$${bossGoal.montoObjetivo.toStringAsFixed(0)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!bossGoal.completada)
                  Text(
                    'Faltan: \$${restante.toStringAsFixed(0)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            if (!bossGoal.completada) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 4),
              Text(
                '💡 Consejo de combate: ¡Registrar carteras con ROI positivo debilita al jefe!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      );
    },
    loading: () => const SizedBox.shrink(),
    error: (error, _) => const SizedBox.shrink(),
  );
}

Widget _buildSparkline(ThemeData theme, List<FlSpot> spots, bool isPositive) {
  if (spots.length < 2) return const SizedBox(height: 10);

  final lineColor = isPositive
      ? const Color(0xFF10B981)
      : const Color(0xFFFF3366);

  return SizedBox(
    height: 60,
    width: double.infinity,
    child: LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.2),
                  lineColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class GlowingBossBar extends StatelessWidget {
  final double progreso;
  const GlowingBossBar({super.key, required this.progreso});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        height: 12,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progreso,
            backgroundColor: const Color(0xFFE5E5EA),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF3B30)),
          ),
        ),
      ),
    );
  }
}
