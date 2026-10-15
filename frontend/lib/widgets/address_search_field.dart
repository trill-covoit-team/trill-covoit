import 'dart:async';

import 'package:flutter/material.dart';

import '../models/address_suggestion.dart';
import '../services/geocoding_service.dart';

/// Champ de saisie d'adresse avec suggestions via Nominatim.
///
/// Le debounce évite de déclencher une requête à chaque frappe et respecte
/// la politique d'usage de l'instance publique (1 requête par seconde max).
class AddressSearchField extends StatefulWidget {
  final String label;
  final IconData icon;
  final ValueChanged<AddressSuggestion> onSelected;
  final GeocodingService geocodingService;

  const AddressSearchField({
    super.key,
    required this.label,
    required this.icon,
    required this.onSelected,
    this.geocodingService = const GeocodingService(), // Valeur par défaut pour la simplicité d'usage
  });

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<AddressSuggestion> _suggestions = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Déclenche la recherche après un délai de 400 ms sans frappe.
  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isLoading = true);
      // Utilisation du service injecté
      final results = await widget.geocodingService.searchAddresses(value);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    });
  }

  void _onSuggestionSelected(AddressSuggestion suggestion) {
    _controller.text = suggestion.displayName;
    setState(() => _suggestions = []);
    widget.onSelected(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: Icon(widget.icon),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 4),
            child: Column(
              children: _suggestions
                  .map((s) => ListTile(
                        dense: true,
                        title: Text(
                          s.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _onSuggestionSelected(s),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}