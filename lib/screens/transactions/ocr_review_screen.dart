import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/ocr_service.dart';

class OcrReviewScreen extends ConsumerStatefulWidget {
  final File imageFile;
  final OcrResult ocrResult;

  const OcrReviewScreen({
    super.key,
    required this.imageFile,
    required this.ocrResult,
  });

  @override
  ConsumerState<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends ConsumerState<OcrReviewScreen> {
  late TextEditingController _montoCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _comercioCtrl;
  String _tipo = 'gasto';
  String _categoria = 'General';
  String? _carteraId;
  String? _metaId;
  final bool _isSaving = false;

  static const _categorias = [
    'General',
    'Comida',
    'Transporte',
    'Vivienda',
    'Salud',
    'Educación',
    'Entretenimiento',
    'Ropa',
    'Tecnología',
    'Hogar',
    'Servicios',
  ];

  @override
  void initState() {
    super.initState();
    final result = widget.ocrResult;
    _montoCtrl = TextEditingController(
      text: result.monto?.toStringAsFixed(2) ?? '',
    );
    _descCtrl = TextEditingController(text: result.comercio ?? '');
    _comercioCtrl = TextEditingController(text: result.comercio ?? '');
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descCtrl.dispose();
    _comercioCtrl.dispose();

    // Auto-destrucción de la imagen temporal del OCR al cerrar o guardar la pantalla
    _deleteTempImage();

    super.dispose();
  }

  Future<void> _deleteTempImage() async {
    try {
      if (await widget.imageFile.exists()) {
        await widget.imageFile.delete();
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    if (_montoCtrl.text.trim().isEmpty) return;

    final double amount = double.parse(_montoCtrl.text.trim());
    final String description = _descCtrl.text.trim().isNotEmpty
        ? _descCtrl.text.trim()
        : 'Compra en ${_comercioCtrl.text.trim()}';

    final Transaction optimisticTx = Transaction(
      id: 'optimistic-${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      monto: amount,
      tipo: _tipo,
      categoria: _categoria,
      carteraId: _carteraId,
      metaId: _metaId,
      descripcion: description,
      fecha: widget.ocrResult.fecha ?? DateTime.now(),
      fuente: 'ocr',
    );

    final messenger = ScaffoldMessenger.of(context);

    // Actualizar el estado de manera optimista
    ref.read(recentTransactionsProvider.notifier).addOptimistic(optimisticTx);
    ref.read(transactionsProvider.notifier).addOptimistic(optimisticTx);
    if (_metaId != null) {
      ref
          .read(goalsProvider.notifier)
          .updateGoalOptimistically(_metaId!, amount, _tipo == 'ingreso');
    }

    // Regresar a la pantalla de inicio de inmediato
    Navigator.of(context).popUntil((route) => route.isFirst);

    try {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.create(
        Transaction(
          userId: user.id,
          monto: amount,
          tipo: _tipo,
          categoria: _categoria,
          carteraId: _carteraId,
          metaId: _metaId,
          descripcion: description,
          fecha: widget.ocrResult.fecha ?? DateTime.now(),
          fuente: 'ocr',
        ),
      );

      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(goalsProvider);
      ref.invalidate(portfoliosProvider);
      ref.invalidate(userProfileProvider);
    } catch (e) {
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(goalsProvider);
      ref.invalidate(portfoliosProvider);
      ref.invalidate(userProfileProvider);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Error al guardar en la base de datos. Transacción revertida. $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Revisar recibo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                widget.imageFile,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Texto detectado:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.ocrResult.rawText,
                style: theme.textTheme.bodySmall,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'gasto', label: Text('Gasto')),
                ButtonSegment(value: 'ingreso', label: Text('Ingreso')),
              ],
              selected: {_tipo},
              onSelectionChanged: (v) => setState(() => _tipo = v.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comercioCtrl,
              decoration: const InputDecoration(
                labelText: 'Comercio / Proveedor',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: _categorias
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            const SizedBox(height: 16),
            ref
                .watch(portfoliosProvider)
                .when(
                  data: (portfolios) {
                    if (portfolios.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        DropdownButtonFormField<String?>(
                          initialValue: _carteraId,
                          decoration: const InputDecoration(
                            labelText: 'Cartera (opcional)',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Sin cartera'),
                            ),
                            ...portfolios.map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.nombre),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _carteraId = v),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
            ref
                .watch(goalsProvider)
                .when(
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
                            ...goals.map(
                              (g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(g.nombre),
                              ),
                            ),
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
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Guardando...' : 'Guardar transacción'),
            ),
          ],
        ),
      ),
    );
  }
}
