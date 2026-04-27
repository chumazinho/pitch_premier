import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pitch_premier/features/profile/presentation/screens/profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class FanDashboard extends StatefulWidget {
  const FanDashboard({super.key});

  @override
  State<FanDashboard> createState() => _FanDashboardState();
}

class _FanDashboardState extends State<FanDashboard> {
  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _news = [];
  bool _isLoading = true;
  int _selectedTab = 0;
  String? _avatarUrl;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadAvatar();
    _subscribeToLiveUpdates();
  }

  Future<void> _loadAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .single();
      if (mounted) setState(() => _avatarUrl = response['avatar_url']);
    } catch (e) {}
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final matchesResponse = await Supabase.instance.client
          .from('matches')
          .select()
          .order('created_at', ascending: true);

      final newsResponse = await Supabase.instance.client
          .from('news')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _matches = List<Map<String, dynamic>>.from(matchesResponse);
          _news = List<Map<String, dynamic>>.from(newsResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToLiveUpdates() {
    _realtimeChannel = Supabase.instance.client
        .channel('matches-channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'matches',
          callback: (payload) {
            if (mounted) _updateMatchScore(payload);
          },
        )
        .subscribe();
  }

  void _updateMatchScore(PostgresChangePayload payload) {
    final updatedMatch = payload.newRecord;
    setState(() {
      final index = _matches.indexWhere((m) => m['id'] == updatedMatch['id']);
      if (index != -1) {
        _matches[index] = updatedMatch;
      }
    });
  }

  void _watchHighlights(String homeTeam, String awayTeam) async {
    // Search YouTube for match highlights using a direct link format
    final query = '$homeTeam vs $awayTeam highlights Premier League';
    final url =
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening YouTube search...'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text('Error', style: TextStyle(color: Colors.white)),
      content: Text(message, style: const TextStyle(color: Colors.white70)),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<void> _openYouTube(String homeTeam, String awayTeam) async {
  final searchQuery = '$homeTeam vs $awayTeam highlights premier league';
  final encodedQuery = Uri.encodeComponent(searchQuery);
  final youtubeUrl = 'https://www.youtube.com/results?search_query=$encodedQuery';
  
  try {
    final uri = Uri.parse(youtubeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } else {
      _showManualInstructions(searchQuery);
    }
  } catch (e) {
    _showManualInstructions(searchQuery);
  }
}

void _showManualInstructions(String searchQuery) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Watch Highlights', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info, size: 50, color: Colors.orange),
          const SizedBox(height: 16),
          const Text('Please open YouTube and search for:', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '"$searchQuery"',
              style: const TextStyle(color: Color(0xFF14FFEC), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

void _showHighlightsDialog(String homeTeam, String awayTeam) {
  final searchQuery = '$homeTeam vs $awayTeam highlights premier league';
  final encodedQuery = Uri.encodeComponent(searchQuery);
  
  // Try multiple URL formats to ensure it works
  final youtubeWebUrl = 'https://www.youtube.com/results?search_query=$encodedQuery';
  final youtubeAppUrl = 'vnd.youtube://search?query=$encodedQuery';
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('$homeTeam vs $awayTeam', style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_circle_filled, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Watch match highlights on YouTube', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('"$searchQuery"', style: const TextStyle(color: Color(0xFF14FFEC), fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            await _openYouTubeDirect(youtubeAppUrl, youtubeWebUrl, searchQuery);
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Watch Now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    ),
  );
}

Future<void> _openYouTubeDirect(String appUrl, String webUrl, String searchQuery) async {
  try {
    // First try: Open YouTube app directly
    final appUri = Uri.parse(appUrl);
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
      return;
    }
    
    // Second try: Open browser
    final webUri = Uri.parse(webUrl);
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return;
    }
    
    // Last resort: Show the search query
    _showSearchHelp(searchQuery);
  } catch (e) {
    _showSearchHelp(searchQuery);
  }
}

void _showSearchHelp(String searchQuery) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Watch Highlights', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.youtube_searched_for, size: 50, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Open YouTube and search:', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              searchQuery,
              style: const TextStyle(color: Color(0xFF14FFEC), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (dialogContext.mounted)
                Navigator.pushReplacementNamed(dialogContext, '/');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    ).then((_) => _loadAvatar());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'PITCH PREMIER',
          style: GoogleFonts.bebasNeue(fontSize: 24, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: _goToProfile,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF14FFEC).withValues(alpha: 0.2),
              backgroundImage: _avatarUrl != null
                  ? NetworkImage(_avatarUrl!)
                  : null,
              child: _avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.white, size: 20)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [_buildTab('LIVE MATCHES', 0), _buildTab('NEWS', 1)],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF14FFEC)),
                  )
                : IndexedStack(
                    index: _selectedTab,
                    children: [_buildMatchesList(), _buildNewsList()],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF14FFEC) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchesList() {
    if (_matches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 64, color: Colors.white30),
            SizedBox(height: 16),
            Text(
              'No matches scheduled',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        final isLive = match['match_status'] == 'live';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: isLive ? Border.all(color: Colors.red, width: 2) : null,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLive
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isLive)
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    Text(
                      'Premier League',
                      style: TextStyle(
                        color: isLive ? Colors.red : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        match['home_team'] ?? 'Team A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14FFEC).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${match['home_score'] ?? 0} - ${match['away_score'] ?? 0}',
                        style: const TextStyle(
                          color: Color(0xFF14FFEC),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        match['away_team'] ?? 'Team B',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: () => _showHighlightsDialog(
                    match['home_team'] ?? 'Team',
                    match['away_team'] ?? 'Team',
                  ),
                  icon: const Icon(Icons.play_circle, size: 20),
                  label: const Text('Watch Highlights'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewsList() {
    if (_news.isEmpty) {
      return const Center(
        child: Text(
          'No news available',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _news.length,
      itemBuilder: (context, index) {
        final news = _news[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF14FFEC).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  news['category'] ?? 'NEWS',
                  style: const TextStyle(
                    color: Color(0xFF14FFEC),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                news['title'] ?? 'Latest News',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                news['summary'] ?? 'Click to read more...',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                maxLines: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
