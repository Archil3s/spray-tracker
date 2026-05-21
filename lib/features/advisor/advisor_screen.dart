import 'package:flutter/cupertino.dart';

import 'gemini_service.dart';

class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({
    required this.products,
    required this.canvasColor,
    required this.cardColor,
    required this.softColor,
    required this.inkColor,
    required this.mutedColor,
    required this.lineColor,
    required this.primaryColor,
    required this.errorColor,
    super.key,
  });

  final List<AdvisorProduct> products;
  final Color canvasColor;
  final Color cardColor;
  final Color softColor;
  final Color inkColor;
  final Color mutedColor;
  final Color lineColor;
  final Color primaryColor;
  final Color errorColor;

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final _controller = TextEditingController();
  final _service = GeminiAdvisorService();

  bool _loading = false;
  String? _reply;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTyping);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTyping);
    _controller.dispose();
    super.dispose();
  }

  void _handleTyping() {
    if (_reply != null || _error != null) {
      setState(() {
        _reply = null;
        _error = null;
      });
    }
  }

  Future<void> _getAdvice() async {
    final observation = _controller.text.trim();
    if (observation.isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _reply = null;
      _error = null;
    });

    try {
      final reply = await _service.getAdvice(
        observation: observation,
        products: widget.products,
      );
      if (!mounted) return;
      setState(() => _reply = reply);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not reach advisor. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Advisor',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.1,
                      color: widget.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Describe plant symptoms and get product-aware guidance.',
                    style: TextStyle(
                      color: widget.mutedColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.softColor,
                shape: BoxShape.circle,
                border: Border.all(color: widget.lineColor),
              ),
              child: Icon(CupertinoIcons.leaf_arrow_circlepath, color: widget.primaryColor, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What are you seeing?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: widget.inkColor)),
              const SizedBox(height: 10),
              CupertinoTextField(
                controller: _controller,
                placeholder: "Describe what you're seeing...",
                minLines: 5,
                maxLines: 8,
                textInputAction: TextInputAction.newline,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.softColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.lineColor),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  color: widget.primaryColor,
                  disabledColor: widget.lineColor,
                  borderRadius: BorderRadius.circular(16),
                  onPressed: _loading ? null : _getAdvice,
                  child: _loading
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Text('Get advice', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: widget.errorColor.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.errorColor.withValues(alpha: .28)),
            ),
            child: Text(_error!, style: TextStyle(color: widget.errorColor, fontWeight: FontWeight.w900)),
          ),
        ],
        if (_reply != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Advisor reply', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: widget.primaryColor)),
                const SizedBox(height: 10),
                Text(_reply!, style: TextStyle(color: widget.inkColor, fontSize: 14, height: 1.35, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.softColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.lineColor),
          ),
          child: Text(
            'Uses your product library and Marlborough context. Always follow the product label before applying anything to edible crops.',
            style: TextStyle(color: widget.mutedColor, fontWeight: FontWeight.w700, height: 1.3),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: widget.lineColor),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 7)),
        ],
      );
}
