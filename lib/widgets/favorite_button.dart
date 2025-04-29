import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/event_service.dart';
import '../services/auth_service.dart';

class FavoriteButton extends StatefulWidget {
  final String eventId;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final VoidCallback? onToggle;

  const FavoriteButton({
    super.key,
    required this.eventId,
    this.size = 24.0,
    this.activeColor = Colors.red,
    this.inactiveColor,
    this.onToggle,
  });

  @override
  _FavoriteButtonState createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  @override
  void didUpdateWidget(FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventId != widget.eventId) {
      _checkFavoriteStatus();
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUserId;

    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final eventService = Provider.of<EventService>(context, listen: false);
      final isFavorite = await eventService.isEventInFavorites(
        userId,
        widget.eventId,
      );

      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final eventService = Provider.of<EventService>(context, listen: false);
    final userId = authService.currentUserId;

    if (userId == null) {
      // Show login prompt if user is not logged in
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save favorites')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool success;
    if (_isFavorite) {
      success = await eventService.removeEventFromFavorites(
        userId,
        widget.eventId,
      );
    } else {
      success = await eventService.saveEventToFavorites(userId, widget.eventId);
    }

    if (success && mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
        _isLoading = false;
      });

      if (widget.onToggle != null) {
        widget.onToggle!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? 'Added to favorites' : 'Removed from favorites',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.inactiveColor ?? Colors.grey;

    return IconButton(
      icon:
          _isLoading
              ? SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
              : Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                size: widget.size,
                color: _isFavorite ? widget.activeColor : color,
              ),
      onPressed: _isLoading ? null : _toggleFavorite,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: 24,
    );
  }
}
