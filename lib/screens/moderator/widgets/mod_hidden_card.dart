import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/post_service.dart';
import '../../../services/profile_service.dart';
import 'mod_comment_item.dart';
import 'mod_post_actions_sheet.dart';

enum ModeratorPostType { hidden, warned, muted, duplicated, reported, flagged }

class ModHiddenCard extends StatefulWidget {
  const ModHiddenCard({
    super.key,
    required this.username,
    required this.timeAgo,
    required this.location,
    required this.category,
    this.title,
    required this.body,
    required this.voteCount,
    required this.commentCount,
    this.initials = 'U',
    this.profileColor = const Color(0xFFF1F5F9),
    this.type = ModeratorPostType.hidden,
  });

  final String username;
  final String timeAgo;
  final String location;
  final String category;
  final String? title;
  final String body;
  final int voteCount;
  final int commentCount;
  final String initials;
  final Color profileColor;
  final ModeratorPostType type;

  @override
  State<ModHiddenCard> createState() => _ModHiddenCardState();
}

class _ModHiddenCardState extends State<ModHiddenCard> {
  bool _isCommentsExpanded = false;
  final TextEditingController _commentController = TextEditingController();
  bool _hasText = false;

  // Mention State
  final PostService _postService = PostService();
  List<ProfileData> _mentionSuggestions = [];
  bool _showMentionSuggestions = false;
  int _mentionStartIndex = -1;
  String _mentionQuery = '';
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_onTextChanged);
    _commentController.addListener(() {
      setState(() {
        _hasText = _commentController.text.trim().isNotEmpty;
      });
    });
  }

  void _onTextChanged() {
    final text = _commentController.text;
    final selection = _commentController.selection;
    final cursorPosition = selection.baseOffset;

    if (cursorPosition < 0) return;
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex != -1) {
      final textAfterAt = textBeforeCursor.substring(lastAtIndex + 1);
      if (!textAfterAt.contains(' ') && !textAfterAt.contains('\n')) {
        _mentionQuery = textAfterAt.trim();
        _mentionStartIndex = lastAtIndex;

        _searchDebounceTimer?.cancel();
        _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
          _searchUsers(_mentionQuery);
        });
      } else {
        setState(() {
          _showMentionSuggestions = false;
          _mentionSuggestions = [];
        });
      }
    } else {
      setState(() {
        _showMentionSuggestions = false;
        _mentionSuggestions = [];
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    try {
      final response = await _postService.searchUsers(query: query, limit: 10);
      
      if (mounted) {
        final usersList = response['users'] as List<dynamic>? ?? [];
        final profileDataList = usersList
            .map((u) => ProfileData.fromMap(u as Map<String, dynamic>))
            .toList();
            
        setState(() {
          _mentionSuggestions = profileDataList;
          _showMentionSuggestions = _mentionSuggestions.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error searching users: $e');
      if (mounted) {
        setState(() {
          _showMentionSuggestions = false;
          _mentionSuggestions = [];
        });
      }
    }
  }

  void _selectMention(ProfileData user) {
    final username = user.username;
    if (username.isEmpty) return;

    final text = _commentController.text;
    final selection = _commentController.selection;
    final cursorPosition = selection.baseOffset;

    final textBeforeCursor = text.substring(0, _mentionStartIndex);
    final textAfterMention = text.substring(cursorPosition);
    final newText = '$textBeforeCursor@$username $textAfterMention';

    _commentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: _mentionStartIndex + username.length + 2,
      ),
    );

    setState(() {
      _showMentionSuggestions = false;
      _mentionSuggestions = [];
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  static const Color _primary900 = Color(0xFF100B3C);
  static const Color _textBody = Color(0xFF45556C);
  static const Color _borderColor = Color(0xFFE2E8F0);

  Future<void> _showModeratorMenu(BuildContext context) async {
    await showModalBottomSheet<ModeratorPostAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ModPostActionsSheet(),
    );
    // Actual merge/delete behavior will be wired where this widget is used.
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1728).withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar + Info + Voting
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.profileColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF100B3C), width: 3),
                ),
                child: Text(
                  widget.initials,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _primary900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Middle: Name, Time, Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.username,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _primary900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${widget.timeAgo}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _textBody.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Badges Row
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildBadge(
                          widget.location,
                          icon:
                              'assets/adminIcons/adminPostTypes/locationIcon.svg',
                        ),
                        _buildBadge(
                          widget.category,
                          icon:
                              'assets/adminIcons/adminPostTypes/commentIcon.svg',
                          isHighlight: true,
                        ),
                        _buildTypeBadge(),
                      ],
                    ),
                  ],
                ),
              ),

              // Right: Voting Box
              Container(
                margin: const EdgeInsets.only(left: 12),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 0.76,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      size: 18,
                      color: _textBody,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${widget.voteCount}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _primary900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Icon(
                      Icons.arrow_downward_rounded,
                      size: 18,
                      color: _textBody,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),

          // Title
          if (widget.title != null && widget.title!.isNotEmpty) ...[
            Text(
              widget.title!,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.5,
                color: const Color(0xFF0F172B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Body Text
          Text(
            widget.body,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: _textBody,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
          
          const SizedBox(height: 24),

          // Footer: Comments + Menu (for duplicated posts)
          GestureDetector(
            onTap: () {
              setState(() {
                _isCommentsExpanded = !_isCommentsExpanded;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 16, color: _textBody),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.commentCount} comment${widget.commentCount != 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textBody,
                    ),
                  ),
                  const Spacer(),
                  if (widget.type == ModeratorPostType.duplicated)
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _showModeratorMenu(context),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.more_horiz,
                          size: 18,
                          color: _textBody,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Expandable Comments Section
          if (_isCommentsExpanded) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 16),
            
            // Comment Input Section (Outer Box)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Mention Suggestions
                  if (_showMentionSuggestions && _mentionSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFEFF6FF),
                            Color(0xFFFFFFFF),
                            Color(0xFFFFFFFF),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 0.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _mentionSuggestions.length,
                        itemBuilder: (context, index) {
                          final user = _mentionSuggestions[index];
                          final username = user.username.replaceAll('@', '');
                          final displayName = user.displayName ?? username;
                          final profilePictureUrl = user.pictureUrl;
                          final initials = user.initials;

                          return InkWell(
                            onTap: () => _selectMention(user),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          profilePictureUrl != null &&
                                              profilePictureUrl.isNotEmpty
                                          ? null
                                          : const Color(0xFF155DFC),
                                      border:
                                          profilePictureUrl != null &&
                                              profilePictureUrl.isNotEmpty
                                          ? null
                                          : Border.all(
                                              color: const Color(0xFFF1F5F9),
                                              width: 1.51,
                                            ),
                                      image:
                                          profilePictureUrl != null &&
                                              profilePictureUrl.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                profilePictureUrl!,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child:
                                        profilePictureUrl == null ||
                                            profilePictureUrl!.isEmpty
                                        ? Center(
                                            child: Text(
                                              initials,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child:
                                        displayName != username &&
                                            displayName.isNotEmpty
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                displayName,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF0F172B),
                                                  fontFamily: 'Inter',
                                                  letterSpacing: -0.1504,
                                                  height: 1.67,
                                                ),
                                              ),
                                              Text(
                                                '@$username',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w400,
                                                  color: Color(0xFF90A1B9),
                                                  fontFamily: 'Inter',
                                                  letterSpacing: -0.1504,
                                                  height: 2.0,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            '@$username',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF0F172B),
                                              fontFamily: 'Inter',
                                              letterSpacing: -0.1504,
                                              height: 1.67,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  
                  // Inner Input Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts...',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.1504,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: 3,
                      minLines: 1,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Reply Button
                  Opacity(
                    opacity: _hasText ? 1.0 : 0.5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF155DFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/adminIcons/adminPostTypes/replyIcon.svg',
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reply',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mock Comments List
            const ModCommentItem(
               username: '@lagosian_boy',
               timeAgo: '1h ago',
               initials: 'LB',
               profileColor: Color(0xFFF1F5F9),
               body: "You NEED to try the one at Yellow Chilli! Best I've ever had, hands down.",
               voteCount: 45,
            ),
            const ModCommentItem(
               username: '@naija_gourmet',
               timeAgo: '30m ago',
               initials: 'NG', 
               profileColor: Color(0xFFE0F2FE),
               body: "Party jollof is undefeated! There's something about that smoky flavor from the firewood.",
               voteCount: 38,
            ),
            const ModCommentItem(
               username: '@anonymous',
               timeAgo: 'just now',
               initials: 'AN',
               profileColor: Color(0xFFF1F5F9),
               body: "checking",
               voteCount: 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeBadge() {
    String text;
    String iconPath;
    Color bg;
    Color content;
    Color borderColor;

    switch (widget.type) {
      case ModeratorPostType.warned:
        text = 'Warned Post';
        iconPath = 'assets/adminIcons/adminPostTypes/warning.svg';
        bg = const Color(0xFFFEFED6);
        content = const Color(0xFFB45309);
        borderColor = const Color(0xFFF4F43D);
        break;
      case ModeratorPostType.muted:
        text = 'Muted Post';
        iconPath = 'assets/adminIcons/adminPostTypes/volume-slash.svg';
        bg = const Color(0xFFF0EEFF);
        content = const Color(0xFF4F39F6);
        borderColor = const Color(0xFF4F39F6);
        break;
      case ModeratorPostType.duplicated:
        text = 'Duplicated Post';
        iconPath = 'assets/adminIcons/adminPostTypes/document-copy.svg';
        bg = const Color(0xFFFDEFE9);
        content = const Color(0xFFCA3500);
        borderColor = const Color(0xFFCA3500);
        break;
      case ModeratorPostType.reported:
        text = 'Reported Post';
        iconPath = 'assets/adminIcons/adminPostTypes/reportedPostIcon.svg';
        bg = const Color(0xFFFFF5F5);
        content = const Color(0xFFE7000B);
        borderColor = const Color(0xFFE7000B);
        break;
      case ModeratorPostType.flagged:
        text = 'Flagged Post';
        iconPath = 'assets/adminIcons/adminSettings/flag-2.svg';
        bg = const Color(0xFFFFF5F5);
        content = const Color(0xFFE7000B);
        borderColor = const Color(0xFFE7000B);
        break;
      case ModeratorPostType.hidden:
      default:
        text = 'Hidden Post';
        iconPath = 'assets/adminIcons/adminPostTypes/eye-slash.svg';
        bg = const Color(0xFFF9F7FC);
        content = const Color(0xFF475569);
        borderColor = const Color(0xFF45556C);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.76),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 12,
            height: 12,
            colorFilter: ColorFilter.mode(content, BlendMode.srcIn),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: content,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, {required String icon, bool isHighlight = false}) {
    Color bg = const Color(0xFFF8FAFC);
    Color content = const Color(0xFF475569);
    Color borderColor = const Color(0xFFE2E8F0);

    if (isHighlight) {
      bg = const Color(0xFFFAF5FF);
      content = const Color(0xFF7C3AED);
      borderColor = const Color(0xFFDAB2FF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.76),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            icon,
            width: 12,
            height: 12,
            colorFilter: ColorFilter.mode(content, BlendMode.srcIn),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: content,
            ),
          ),
        ],
      ),
    );
  }
}
