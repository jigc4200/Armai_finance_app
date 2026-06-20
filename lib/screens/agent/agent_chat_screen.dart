import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/agent_service.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/ai_insight_provider.dart';
import '../../widgets/premium_screen_header.dart';

class ChatMessage {
  final String texto;
  final bool esUsuario;
  final DateTime timestamp;

  ChatMessage({
    required this.texto,
    required this.esUsuario,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AgentChatScreen extends ConsumerStatefulWidget {
  const AgentChatScreen({super.key});

  @override
  ConsumerState<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends ConsumerState<AgentChatScreen> {
  final _messages = <ChatMessage>[
    ChatMessage(
      texto:
          '¡Hola! Soy tu copiloto financiero.\n\n'
          'Podés preguntarme cosas como:\n'
          '- "¿Cómo van mis finanzas?"\n'
          '- "¿Cuál fue mi mejor inversión?"\n'
          '- "Simulá que compro una laptop de \$1,200"\n'
          '- "Dame una recomendación"',
      esUsuario: false,
    ),
  ];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isLoading = false;
  bool _modoBrutal = false;

  static const _quickPrompts = [
    'Detecta mi fuga principal',
    '¿Cuál fue mi mejor decisión?',
    'Simula una compra importante',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        final prompt = args['prompt'];
        if (prompt != null && prompt is String && prompt.trim().isNotEmpty) {
          _inputCtrl.text = prompt.trim();
          _sendMessage();
          return;
        }

        final simulacion = args['simulacion'];
        if (simulacion != null && simulacion is Map<String, dynamic>) {
          final desc = simulacion['descripcion'] as String? ?? '';
          final monto = simulacion['monto'] as double? ?? 0.0;
          _inputCtrl.text = 'Simulá que compro $desc por \$$monto';
          _sendMessage();
        }
      }
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(texto: text, esUsuario: true));
      _isLoading = true;
    });
    _inputCtrl.clear();

    try {
      final agent = AgentService();

      Map<String, dynamic>? simulacion;
      if (text.toLowerCase().contains('simul') ||
          text.toLowerCase().contains('qué pasa si')) {
        final montoMatch = RegExp(r'\$?(\d+(?:[.,]\d+)?)').firstMatch(text);
        if (montoMatch != null) {
          simulacion = {
            'descripcion': text,
            'monto': double.parse(montoMatch.group(1)!.replaceAll(',', '.')),
          };
        }
      }

      final response = await agent.chat(
        mensaje: text,
        modo: _modoBrutal ? 'brutal' : 'conversacional',
        simulacion: simulacion,
      );

      if (!mounted) return;
      if (_modoBrutal) {
        HapticFeedback.heavyImpact();
      }
      if (response.insight != null) {
        ref
            .read(activeAiInsightProvider.notifier)
            .updateInsight(response.insight);
      }
      setState(() {
        _messages.add(ChatMessage(texto: response.respuesta, esUsuario: false));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            texto: 'Error al conectar con el agente: $e',
            esUsuario: false,
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSimulationDialog() {
    final descCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    final portfoliosAsync = ref.read(portfoliosProvider);
    String? carteraId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Simular compra'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: '¿Qué querés comprar?',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: montoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 12),
              portfoliosAsync.when(
                data: (portfolios) {
                  if (portfolios.isEmpty) return const SizedBox.shrink();
                  return DropdownButtonFormField<String?>(
                    initialValue: carteraId,
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
                    onChanged: (v) => setDialogState(() => carteraId = v),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                final msg =
                    'Simulá que compro ${descCtrl.text.trim()} por \$${montoCtrl.text.trim()}';
                _inputCtrl.text = msg;
                _sendMessage();
              },
              child: const Text('Simular'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendQuickPrompt(String prompt) {
    _inputCtrl.text = prompt;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: PremiumScreenHeader(
                title: 'Copiloto',
                subtitle: _modoBrutal
                    ? 'Modo brutal activo'
                    : 'Agente de decisiones',
                primaryIcon: Icons.arrow_back_rounded,
                onPrimary: () => Navigator.pop(context),
                secondaryIcon: _modoBrutal
                    ? Icons.local_fire_department_rounded
                    : Icons.psychology_rounded,
                onSecondary: () => setState(() => _modoBrutal = !_modoBrutal),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text.rich(
                TextSpan(
                  text: 'Pregúntale antes\n',
                  style: const TextStyle(
                    fontSize: 27,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    color: Color(0xFF0A0A0A),
                  ),
                  children: [
                    TextSpan(
                      text: 'de repetir una decisión.',
                      style: const TextStyle(color: Color(0xFF8A8A8A)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_modoBrutal)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Center(child: ModoBrutalPulseBadge()),
              ),
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ActionChip(
                  label: Text(_quickPrompts[index]),
                  onPressed: _isLoading
                      ? null
                      : () => _sendQuickPrompt(_quickPrompts[index]),
                  avatar: const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFF2D20D8),
                    size: 16,
                  ),
                  labelStyle: const TextStyle(
                    color: Color(0xFF0A0A0A),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                  side: const BorderSide(color: Color(0xFFE6E6E6)),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _MessageBubble(message: msg);
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const _AgentAvatar(size: 28),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          18,
                        ).copyWith(bottomLeft: const Radius.circular(6)),
                        border: Border.all(color: const Color(0xFFE6E6E6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          _ShimmerDot(delay: 0),
                          SizedBox(width: 4),
                          _ShimmerDot(delay: 150),
                          SizedBox(width: 4),
                          _ShimmerDot(delay: 300),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFE6E6E6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.science_outlined),
                    tooltip: 'Simular compra',
                    onPressed: _showSimulationDialog,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Describe una decisión...',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    tooltip: 'Enviar',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF2D20D8),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.esUsuario;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const _AgentAvatar(size: 30),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF2D20D8) : Colors.white,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser ? null : const Radius.circular(6),
                  bottomRight: isUser ? const Radius.circular(6) : null,
                ),
                border: isUser
                    ? null
                    : Border.all(color: const Color(0xFFE6E6E6)),
                boxShadow: isUser
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Text(
                message.texto,
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF0A0A0A),
                  height: 1.35,
                  fontWeight: isUser ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _AgentAvatar extends StatelessWidget {
  final double size;

  const _AgentAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFC7E8FF),
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Icon(
        Icons.psychology_rounded,
        size: size * 0.58,
        color: const Color(0xFF2D20D8),
      ),
    );
  }
}

// =========================================================================
// CUSTOM SHIMMER TYPING DOTS
// =========================================================================

class _ShimmerDot extends StatefulWidget {
  final int delay;
  const _ShimmerDot({required this.delay});

  @override
  State<_ShimmerDot> createState() => _ShimmerDotState();
}

class _ShimmerDotState extends State<_ShimmerDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _animation,
        child: Container(
          height: 8,
          width: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class ModoBrutalPulseBadge extends StatefulWidget {
  const ModoBrutalPulseBadge({super.key});

  @override
  State<ModoBrutalPulseBadge> createState() => _ModoBrutalPulseBadgeState();
}

class _ModoBrutalPulseBadgeState extends State<ModoBrutalPulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(
      begin: 0.2,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final alphaVal = _glowAnimation.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3366).withValues(alpha: alphaVal * 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF3366).withValues(alpha: alphaVal),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFFFF3366,
                  ).withValues(alpha: alphaVal * 0.3),
                  blurRadius: 8 * alphaVal,
                  spreadRadius: 1 * alphaVal,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.psychology,
                  color: Color(0xFFFF3366),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  "MODO BRUTAL ACTIVO",
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFFFF3366),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
