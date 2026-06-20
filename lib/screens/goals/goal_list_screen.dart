import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/goal_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/premium_screen_header.dart';

class GoalListScreen extends ConsumerStatefulWidget {
  const GoalListScreen({super.key});

  @override
  ConsumerState<GoalListScreen> createState() => _GoalListScreenState();
}

class _GoalListScreenState extends ConsumerState<GoalListScreen> {
  final _nombreCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  DateTime _fechaObj = DateTime.now().add(const Duration(days: 365));
  bool _showForm = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _createGoal() async {
    final nombre = _nombreCtrl.text.trim();
    final montoStr = _montoCtrl.text.trim();
    if (nombre.isEmpty || montoStr.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(goalRepositoryProvider);
      await repo.create(
        Goal(
          userId: user.id,
          nombre: nombre,
          montoObjetivo: double.parse(montoStr),
          fechaObjetivo: _fechaObj,
        ),
      );

      _nombreCtrl.clear();
      _montoCtrl.clear();
      setState(() => _showForm = false);
      ref.invalidate(goalsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteGoal(Goal goal) async {
    final id = goal.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar meta'),
        content: Text(
          'Las transacciones vinculadas quedarán sin meta. ¿Eliminar "${goal.nombre}"?',
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
      await ref.read(goalRepositoryProvider).delete(id);
      ref.invalidate(goalsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(recentTransactionsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Meta eliminada')));
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
            'Nueva meta',
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
              hintText: 'Ej: Terreno propio, fondo de emergencia...',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _montoCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monto objetivo',
              prefixText: '\$ ',
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_rounded),
            title: Text(
              'Fecha límite: ${_fechaObj.day}/${_fechaObj.month}/${_fechaObj.year}',
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _fechaObj,
                firstDate: DateTime.now(),
                lastDate: DateTime(2050),
              );
              if (picked != null) setState(() => _fechaObj = picked);
            },
          ),
          const SizedBox(height: 12),
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
                  onPressed: _isLoading ? null : _createGoal,
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Crear meta'),
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
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(goalsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 140),
            children: [
              PremiumScreenHeader(
                title: 'Metas',
                subtitle: 'Objetivos que pelean contigo',
                primaryIcon: _showForm
                    ? Icons.close_rounded
                    : Icons.add_rounded,
                onPrimary: () => setState(() => _showForm = !_showForm),
                secondaryIcon: Icons.psychology_rounded,
                onSecondary: () => Navigator.pushNamed(
                  context,
                  '/agent',
                  arguments: {
                    'prompt':
                        'Analiza mis metas y dime que decision concreta debo tomar esta semana para avanzar.',
                  },
                ),
              ),
              const SizedBox(height: 22),
              goalsAsync.when(
                data: (goals) {
                  final activeGoals = goals
                      .where((g) => !g.completada)
                      .toList();
                  final boss = activeGoals.isEmpty && goals.isNotEmpty
                      ? goals.first
                      : activeGoals.isEmpty
                      ? null
                      : activeGoals.first;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: boss == null
                              ? 'Define tu jefe final.\n'
                              : 'Jefe final activo.\n',
                          style: const TextStyle(
                            fontSize: 27,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            color: Color(0xFF0A0A0A),
                          ),
                          children: [
                            TextSpan(
                              text: boss == null
                                  ? 'Sin una meta, el dinero no tiene dirección.'
                                  : boss.nombre,
                              style: const TextStyle(color: Color(0xFF8A8A8A)),
                            ),
                          ],
                        ),
                      ),
                      if (_showForm) ...[
                        const SizedBox(height: 18),
                        _buildFormCard(),
                      ],
                      const SizedBox(height: 18),
                      if (boss == null)
                        const _EmptyPanel(
                          icon: Icons.flag_outlined,
                          title: 'Crea tu primera meta',
                          subtitle:
                              'El agente necesita un objetivo para evaluar tus decisiones.',
                        )
                      else ...[
                        _GoalHeroCard(
                          goal: boss,
                          onDelete: () => _deleteGoal(boss),
                        ),
                        const SizedBox(height: 10),
                        _AchievementRibbon(goal: boss),
                        const SizedBox(height: 22),
                        const Text(
                          'Todas las metas',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Color(0xFF0A0A0A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final goal in goals)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _GoalTile(
                              goal: goal,
                              onDelete: () => _deleteGoal(goal),
                            ),
                          ),
                      ],
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

class _GoalHeroCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onDelete;

  const _GoalHeroCard({required this.goal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progreso * 100).clamp(0, 100).toStringAsFixed(0);
    final restante = (goal.montoObjetivo - goal.montoActual).clamp(
      0,
      double.infinity,
    );

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$pct% completado',
                  style: const TextStyle(
                    color: Color(0xFF0A0A0A),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
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
          const SizedBox(height: 8),
          Text(
            'Faltan \$${restante.toStringAsFixed(0)} para ${goal.nombre}.',
            style: const TextStyle(
              color: Color(0xFF8A8A8A),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: goal.progreso.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFC7E8FF),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2D20D8),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Stat(
                label: 'Actual',
                value: '\$${goal.montoActual.toStringAsFixed(0)}',
              ),
              const SizedBox(width: 24),
              _Stat(
                label: 'Objetivo',
                value: '\$${goal.montoObjetivo.toStringAsFixed(0)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementRibbon extends StatelessWidget {
  final Goal goal;

  const _AchievementRibbon({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF2D20D8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              goal.completada
                  ? 'Meta completada. Buena decisión acumulada.'
                  : 'Cada compra debe defender esta meta.',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'IA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final Goal goal;
  final VoidCallback onDelete;

  const _GoalTile({required this.goal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progreso * 100).clamp(0, 100).toStringAsFixed(0);

    return Dismissible(
      key: ValueKey(goal.id ?? goal.nombre),
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFC7E8FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.flag_rounded, color: Color(0xFF2D20D8)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0A0A0A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: goal.progreso.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFC7E8FF),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2D20D8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$pct%',
              style: const TextStyle(
                color: Color(0xFF2D20D8),
                fontWeight: FontWeight.w900,
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
