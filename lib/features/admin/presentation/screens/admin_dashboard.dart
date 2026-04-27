import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pitch_premier/features/profile/presentation/screens/profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
int _selectedIndex = 0;
  bool _isSidebarOpen = false;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _news = [];
  List<Map<String, dynamic>> _players = [];

  int _totalUsers = 0;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _loadAvatar();
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

      if (mounted) {
        setState(() {
          _avatarUrl = response['avatar_url'];
        });
      }
    } catch (e) {}
  }

  Future<void> _loadAllData() async {
    await _loadUsers();
    await _loadMatches();
    await _loadNews();
    await _loadPlayers();
  }

  Future<void> _loadUsers() async {
    try {
      final response = await Supabase.instance.client.from('profiles').select();
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response);
          _totalUsers = _users.length;
        });
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _loadMatches() async {
    try {
      final response = await Supabase.instance.client.from('matches').select();
      if (mounted) {
        setState(() {
          _matches = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _loadNews() async {
    try {
      final response = await Supabase.instance.client.from('news').select();
      if (mounted) {
        setState(() {
          _news = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _loadPlayers() async {
    try {
      final response = await Supabase.instance.client.from('players').select();
      if (mounted) {
        setState(() {
          _players = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ========== USER MANAGEMENT ==========
  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);
      await _loadUsers();
      _showSuccess('User role updated');
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await Supabase.instance.client.from('profiles').delete().eq('id', userId);
      await _loadUsers();
      _showSuccess('User deleted');
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ========== MATCH MANAGEMENT ==========
  Future<void> _addMatch(String homeTeam, String awayTeam) async {
    try {
      await Supabase.instance.client.from('matches').insert({
        'home_team': homeTeam,
        'away_team': awayTeam,
        'home_score': 0,
        'away_score': 0,
        'match_status': 'upcoming',
      });
      await _loadMatches();
      _showSuccess('Match added');
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _deleteMatch(String matchId) async {
    try {
      await Supabase.instance.client.from('matches').delete().eq('id', matchId);
      await _loadMatches();
      _showSuccess('Match deleted');
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _updateMatchScore(
    String matchId,
    int homeScore,
    int awayScore,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from('matches')
          .update({
            'home_score': homeScore,
            'away_score': awayScore,
            'match_status': homeScore > 0 || awayScore > 0
                ? 'live'
                : 'upcoming',
          })
          .eq('id', matchId);

      await _loadMatches();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Score updated to $homeScore - $awayScore'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ========== NEWS MANAGEMENT ==========
  Future<void> _addNews(String title, String summary, String category) async {
    try {
      await Supabase.instance.client.from('news').insert({
        'title': title,
        'summary': summary,
        'category': category,
      });
      await _loadNews();
      _showSuccess('News added');
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _deleteNews(String newsId) async {
    try {
      await Supabase.instance.client.from('news').delete().eq('id', newsId);
      await _loadNews();
      _showSuccess('News deleted');
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ========== PLAYER MANAGEMENT ==========
  Future<void> _addPlayer(
    String name,
    String position,
    String team,
    double price,
    int points,
  ) async {
    try {
      await Supabase.instance.client.from('players').insert({
        'name': name,
        'position': position,
        'team': team,
        'price': price,
        'points': points,
      });
      await _loadPlayers();
      _showSuccess('Player added');
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _updatePlayerPoints(String playerId, int newPoints) async {
    try {
      await Supabase.instance.client
          .from('players')
          .update({'points': newPoints})
          .eq('id', playerId);
      await _loadPlayers();
      _showSuccess('Player points updated');
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $message'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $message'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
              if (dialogContext.mounted) {
                Navigator.pushReplacementNamed(dialogContext, '/');
              }
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
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => setState(() => _isSidebarOpen = true),
        ),
        title: Text(
          ['Overview', 'Users', 'Matches', 'News', 'Players'][_selectedIndex],
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
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
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              _buildOverviewScreen(),
              _buildUsersScreen(),
              _buildMatchesScreen(),
              _buildNewsScreen(),
              _buildPlayersScreen(),
            ],
          ),
          if (_isSidebarOpen)
            GestureDetector(
              onTap: () => setState(() => _isSidebarOpen = false),
              child: Container(color: Colors.black54),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: _isSidebarOpen ? 0 : -280,
            top: 0,
            bottom: 0,
            child: Container(
              width: 280,
              color: const Color(0xFF1A1A1A),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Admin Panel',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white60),
                          onPressed: () =>
                              setState(() => _isSidebarOpen = false),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildMenuItem(Icons.dashboard_outlined, 'Overview', 0),
                        _buildMenuItem(Icons.people_outline, 'Users', 1),
                        _buildMenuItem(Icons.sports_soccer, 'Matches', 2),
                        _buildMenuItem(Icons.article_outlined, 'News', 3),
                        _buildMenuItem(Icons.people, 'Players', 4),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      setState(() => _isSidebarOpen = false);
                      _showLogoutDialog();
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF14FFEC) : Colors.white60,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF14FFEC) : Colors.white70,
        ),
      ),
      tileColor: isSelected
          ? const Color(0xFF14FFEC).withValues(alpha: 0.1)
          : null,
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _isSidebarOpen = false;
        });
      },
    );
  }

  Widget _buildOverviewScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Dashboard Overview',
            style: GoogleFonts.poppins(fontSize: 28, color: Colors.white),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                'Users',
                _totalUsers.toString(),
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Matches',
                _matches.length.toString(),
                Icons.sports_soccer,
                Colors.orange,
              ),
              _buildStatCard(
                'News',
                _news.length.toString(),
                Icons.article,
                const Color(0xFF14FFEC),
              ),
              _buildStatCard(
                'Players',
                _players.length.toString(),
                Icons.people,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title, style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildUsersScreen() {
    if (_users.isEmpty) {
      return const Center(
        child: Text('No users found', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final currentRole = user['role'] ?? 'fan';
        return Card(
          color: const Color(0xFF1A1A1A),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF14FFEC).withValues(alpha: 0.2),
              child: Text(user['email']?[0]?.toUpperCase() ?? 'U'),
            ),
            title: Text(
              user['email'] ?? 'No email',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Role: $currentRole',
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'make_fan') _updateUserRole(user['id'], 'fan');
                if (value == 'make_fantasy')
                  _updateUserRole(user['id'], 'fantasyManager');
                if (value == 'make_admin') _updateUserRole(user['id'], 'admin');
                if (value == 'delete') _deleteUser(user['id']);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'make_fan', child: Text('Make Fan')),
                const PopupMenuItem(
                  value: 'make_fantasy',
                  child: Text('Make Fantasy Manager'),
                ),
                const PopupMenuItem(
                  value: 'make_admin',
                  child: Text('Make Admin'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchesScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddMatchDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Match'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14FFEC),
            ),
          ),
        ),
        Expanded(
          child: _matches.isEmpty
              ? const Center(
                  child: Text(
                    'No matches',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _matches.length,
                  itemBuilder: (context, index) {
                    final match = _matches[index];
                    return Card(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          '${match['home_team']} vs ${match['away_team']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Score: ${match['home_score'] ?? 0} - ${match['away_score'] ?? 0}',
                          style: const TextStyle(
                            color: Color(0xFF14FFEC),
                            fontSize: 18,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFF14FFEC),
                              ),
                              onPressed: () => _showScoreDialog(match),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteMatch(match['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddMatchDialog() {
    final homeController = TextEditingController();
    final awayController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Add Match', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: homeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Home Team',
                labelStyle: TextStyle(color: Colors.white60),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: awayController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Away Team',
                labelStyle: TextStyle(color: Colors.white60),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addMatch(homeController.text, awayController.text);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showScoreDialog(Map<String, dynamic> match) {
    final homeController = TextEditingController(
      text: (match['home_score'] ?? 0).toString(),
    );
    final awayController = TextEditingController(
      text: (match['away_score'] ?? 0).toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Update Score: ${match['home_team']} vs ${match['away_team']}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: homeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Home Score'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: awayController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Away Score'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateMatchScore(
                match['id'],
                int.tryParse(homeController.text) ?? 0,
                int.tryParse(awayController.text) ?? 0,
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddNewsDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add News'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14FFEC),
            ),
          ),
        ),
        Expanded(
          child: _news.isEmpty
              ? const Center(
                  child: Text(
                    'No news',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _news.length,
                  itemBuilder: (context, index) {
                    final news = _news[index];
                    return Card(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          news['title'] ?? 'No title',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          news['category'] ?? 'News',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNews(news['id']),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddNewsDialog() {
    final titleController = TextEditingController();
    final summaryController = TextEditingController();
    String selectedCategory = 'NEWS';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Add News', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Colors.white60),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: summaryController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Summary',
                labelStyle: TextStyle(color: Colors.white60),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(value: 'NEWS', child: Text('NEWS')),
                DropdownMenuItem(value: 'TRANSFER', child: Text('TRANSFER')),
                DropdownMenuItem(value: 'INJURY', child: Text('INJURY')),
              ],
              onChanged: (value) {
                if (value != null) selectedCategory = value;
              },
              decoration: const InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: Colors.white60),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addNews(
                titleController.text,
                summaryController.text,
                selectedCategory,
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddPlayerDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Player'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14FFEC),
            ),
          ),
        ),
        Expanded(
          child: _players.isEmpty
              ? const Center(
                  child: Text(
                    'No players',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _players.length,
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    return Card(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(player['name']?[0] ?? 'P'),
                        ),
                        title: Text(
                          player['name'] ?? 'Unknown',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${player['position']} • £${player['price']}m • ${player['points']} pts',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Color(0xFF14FFEC),
                          ),
                          onPressed: () => _showUpdatePointsDialog(player),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddPlayerDialog() {
    final nameController = TextEditingController();
    String selectedPosition = 'Midfielder';
    final teamController = TextEditingController();
    final priceController = TextEditingController();
    final pointsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Add Player', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedPosition,
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Forward', child: Text('Forward')),
                  DropdownMenuItem(
                    value: 'Midfielder',
                    child: Text('Midfielder'),
                  ),
                  DropdownMenuItem(value: 'Defender', child: Text('Defender')),
                  DropdownMenuItem(
                    value: 'Goalkeeper',
                    child: Text('Goalkeeper'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) selectedPosition = value;
                },
                decoration: const InputDecoration(
                  labelText: 'Position',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: teamController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Team',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Price (millions)',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Points',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addPlayer(
                nameController.text,
                selectedPosition,
                teamController.text,
                double.tryParse(priceController.text) ?? 5.0,
                int.tryParse(pointsController.text) ?? 0,
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showUpdatePointsDialog(Map<String, dynamic> player) {
    final pointsController = TextEditingController(
      text: (player['points'] ?? 0).toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('Update Points: ${player['name']}'),
        content: TextField(
          controller: pointsController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Points'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updatePlayerPoints(
                player['id'],
                int.tryParse(pointsController.text) ?? 0,
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
