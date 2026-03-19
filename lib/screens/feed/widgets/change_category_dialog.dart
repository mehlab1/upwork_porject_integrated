import 'package:flutter/material.dart';
import '../../../services/post_service.dart';

/// Result model for change category dialog
class ChangeCategoryResult {
  const ChangeCategoryResult({required this.categorySlug, required this.categoryName});

  final String categorySlug;
  final String categoryName;
}

/// Dialog that lets moderators/admins change a post's category.
/// Fetches available categories from the API.
class ChangeCategoryDialog extends StatefulWidget {
  const ChangeCategoryDialog({
    super.key,
    required this.currentCategory,
  });

  final String currentCategory;

  @override
  State<ChangeCategoryDialog> createState() => _ChangeCategoryDialogState();
}

class _ChangeCategoryDialogState extends State<ChangeCategoryDialog> {
  final PostService _postService = PostService();
  Map<String, String> _categories = {};
  bool _isLoading = true;
  String? _selectedCategoryName;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _postService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load categories';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            const Text(
              'Change Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172B),
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Current category: ${widget.currentCategory}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF62748E),
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Categories list
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFE7000B),
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...(_categories.entries.map((entry) {
                final name = entry.key;
                final isSelected = _selectedCategoryName == name;
                final isCurrent = name.toLowerCase() ==
                    widget.currentCategory.toLowerCase();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: isCurrent
                        ? null
                        : () {
                            setState(() {
                              _selectedCategoryName = name;
                            });
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEFF6FF)
                            : isCurrent
                                ? const Color(0xFFF3F3F5)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1447E6)
                              : isCurrent
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                color: isCurrent
                                    ? const Color(0xFF90A1B9)
                                    : isSelected
                                        ? const Color(0xFF1447E6)
                                        : const Color(0xFF314158),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          if (isCurrent)
                            const Text(
                              'Current',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF90A1B9),
                                fontFamily: 'Inter',
                              ),
                            ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF1447E6),
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              })),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                        color: Color.fromRGBO(0, 0, 0, 0.1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF314158),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Confirm button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedCategoryName != null
                        ? () {
                            // Generate slug from category name
                            final slug = _selectedCategoryName!
                                .toLowerCase()
                                .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                                .replaceAll(RegExp(r'^-|-$'), '');
                            Navigator.of(context).pop(
                              ChangeCategoryResult(
                                categorySlug: slug,
                                categoryName: _selectedCategoryName!,
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1447E6),
                      disabledBackgroundColor:
                          const Color(0xFF1447E6).withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
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
