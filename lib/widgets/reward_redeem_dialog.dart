import 'package:flutter/material.dart';

class RewardRedeemDialog extends StatefulWidget {
  final String couponCode;

  const RewardRedeemDialog({
    super.key,
    required this.couponCode,
  });

  @override
  State<RewardRedeemDialog> createState() => _RewardRedeemDialogState();
}

class _RewardRedeemDialogState extends State<RewardRedeemDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ConfettiLayer(),
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _controller,
              curve: Curves.elasticOut,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.card_giftcard,
                    size: 72,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Reward Unlocked!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.couponCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ================= CONFETTI ================= */

class _ConfettiLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: List.generate(20, (i) {
            return Positioned(
              left: (i * 37) % MediaQuery.of(context).size.width,
              top: -20,
              child: _ConfettiPiece(delay: i * 120),
            );
          }),
        ),
      ),
    );
  }
}

class _ConfettiPiece extends StatefulWidget {
  final int delay;

  const _ConfettiPiece({required this.delay});

  @override
  State<_ConfettiPiece> createState() => _ConfettiPieceState();
}

class _ConfettiPieceState extends State<_ConfettiPiece>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(0, _controller.value * 500),
          child: Opacity(
            opacity: 1 - _controller.value,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.primaries[
                    widget.delay % Colors.primaries.length],
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
