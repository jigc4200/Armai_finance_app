import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  String _tipo = 'gasto';
  String _categoria = 'General';
  String? _carteraId;
  String? _metaId;
  DateTime _fecha = DateTime.now();
  final bool _isLoading = false;

  static const _categoriasGasto = [
    'General', 'Comida', 'Transporte', 'Vivienda',
    'Salud', 'Educación', 'Entretenimiento', 'Ropa',
    'Tecnología', 'Hogar', 'Servicios',
  ];

  static const _categoriasIngreso = [
    'Salario', 'Freelance', 'Inversiones', 'Ventas',
    'Regalos', 'Reembolso', 'Otros',
  ];

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final double amount = double.parse(_montoController.text.trim());
    final Transaction optimisticTx = Transaction(
      id: 'optimistic-${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      monto: amount,
      tipo: _tipo,
      categoria: _categoria,
      carteraId: _carteraId,
      metaId: _metaId,
      descripcion: _descripcionController.text.trim(),
      fecha: _fecha,
    );

    // Guardar una referencia al messenger antes del pop por si falla y necesitamos mostrar un error
    final messenger = ScaffoldMessenger.of(context);

    // Actualizar el estado optimísticamente
    ref.read(recentTransactionsProvider.notifier).addOptimistic(optimisticTx);
    ref.read(transactionsProvider.notifier).addOptimistic(optimisticTx);
    if (_metaId != null) {
      ref.read(goalsProvider.notifier).updateGoalOptimistically(_metaId!, amount, _tipo == 'ingreso');
    }

    // Regresar de inmediato para una experiencia de usuario instantánea
    Navigator.of(context).pop();

    try {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.create(Transaction(
        userId: user.id,
        monto: amount,
        tipo: _tipo,
        categoria: _categoria,
        carteraId: _carteraId,
        metaId: _metaId,
        descripcion: _descripcionController.text.trim(),
        fecha: _fecha,
      ));

      // Invalidar para sincronizar el estado real de la base de datos
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(goalsProvider);
      ref.invalidate(portfoliosProvider);
      ref.invalidate(userProfileProvider);
    } catch (e) {
      // En caso de error, hacemos rollback invalidando y mostrando un error
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(goalsProvider);
      ref.invalidate(portfoliosProvider);
      ref.invalidate(userProfileProvider);

      messenger.showSnackBar(
        SnackBar(content: Text('Error al guardar en la base de datos. Transacción revertida. $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categorias =
        _tipo == 'ingreso' ? _categoriasIngreso : _categoriasGasto;
    final portfoliosAsync = ref.watch(portfoliosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva transacción'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'gasto', label: Text('Gasto')),
                  ButtonSegment(value: 'ingreso', label: Text('Ingreso')),
                ],
                selected: {_tipo},
                onSelectionChanged: (v) => setState(() => _tipo = v.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa el monto';
                  if (double.tryParse(v.trim()) == null) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Describe la transacción';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _categoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: categorias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v!),
              ),
              const SizedBox(height: 16),
              portfoliosAsync.when(
                data: (portfolios) {
                  if (portfolios.isEmpty) return const SizedBox.shrink();
                  return DropdownButtonFormField<String?>(
                    initialValue: _carteraId,
                    decoration: const InputDecoration(
                      labelText: 'Cartera (opcional)',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sin cartera'),
                      ),
                      ...portfolios.map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.nombre),
                          )),
                    ],
                    onChanged: (v) => setState(() => _carteraId = v),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              ref.watch(goalsProvider).when(
                data: (goals) {
                  if (goals.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: [
                      DropdownButtonFormField<String?>(
                        initialValue: _metaId,
                        decoration: const InputDecoration(
                          labelText: 'Meta / Objetivo (opcional)',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Sin meta'),
                          ),
                          ...goals.map((g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(g.nombre),
                              )),
                        ],
                        onChanged: (v) => setState(() => _metaId = v),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  'Fecha: ${_fecha.day}/${_fecha.month}/${_fecha.year}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fecha,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _fecha = picked);
                },
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar transacción'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
