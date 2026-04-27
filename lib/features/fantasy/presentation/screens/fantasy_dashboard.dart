import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pitch_premier/features/profile/presentation/screens/profile_screen.dart';

class FantasyDashboard extends StatefulWidget {
  const FantasyDashboard({super.key});

  @override
  State<FantasyDashboard> createState() => _FantasyDashboardState();
}

class _FantasyDashboardState extends State<FantasyDashboard> {
  List<Map<String, dynamic>> _players = [];
  List<Map<String, dynamic>> _myTeam = [];
  bool _isLoading = true;
  double _budget = 100.0;
  int _selectedTab = 0;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
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
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // First, load players from the players table
      final playersResponse = await Supabase.instance.client
          .from('players')
          .select()
          .order('points', ascending: false);

      // Then load user's fantasy team
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final teamResponse = await Supabase.instance.client
            .from('fantasy_teams')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        if (teamResponse != null && mounted) {
          // Get player IDs in the team
          List<String> playerIds = List<String>.from(
            teamResponse['players'] ?? [],
          );

          // Fetch full player details for the team
          if (playerIds.isNotEmpty) {
            final teamPlayersResponse = await Supabase.instance.client
                .from('players')
                .select()
                .inFilter('id', playerIds);

            if (mounted) {
              setState(() {
                _myTeam = List<Map<String, dynamic>>.from(teamPlayersResponse);
                _budget = (teamResponse['budget'] ?? 100.0).toDouble();
              });
            }
          } else if (mounted) {
            setState(() {
              _myTeam = [];
              _budget = (teamResponse['budget'] ?? 100.0).toDouble();
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _players = List<Map<String, dynamic>>.from(playersResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTeam() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.from('fantasy_teams').upsert({
      'user_id': user.id,
      'budget': _budget,
      'players': _myTeam.map((p) => p['id']).toList(),
    });
  }

  Future<void> _addPlayer(Map<String, dynamic> player) async {
    if (_myTeam.length >= 15) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 15 players allowed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final playerPrice = (player['price'] ?? 5.0).toDouble();
    if (_budget < playerPrice) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient budget'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _myTeam.add(player);
      _budget -= playerPrice;
    });
    await _saveTeam();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player['name']} added to your team!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _removePlayer(Map<String, dynamic> player) async {
    if (!mounted) return;
    setState(() {
      _myTeam.remove(player);
      _budget += (player['price'] ?? 5.0).toDouble();
    });
    await _saveTeam();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player['name']} removed from your team'),
          backgroundColor: Colors.orange,
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
          'Are you sure you want to logout?',
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
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    ).then((_) {
      if (mounted) {
        _loadAvatar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'FANTASY MANAGER',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                _buildTab('My Team (${_myTeam.length}/15)', 0),
                _buildTab('Available Players', 1),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF14FFEC)),
            )
          : IndexedStack(
              index: _selectedTab,
              children: [_buildMyTeam(), _buildAvailablePlayers()],
            ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (mounted) {
            setState(() => _selectedTab = index);
          }
        },
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
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyTeam() {
    if (_myTeam.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 64, color: Colors.white30),
            SizedBox(height: 16),
            Text(
              'No players in your team',
              style: TextStyle(color: Colors.white54),
            ),
            Text(
              'Go to Available Players tab to add',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF14FFEC).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('BUDGET', style: TextStyle(color: Colors.white60)),
                  Text(
                    '£${_budget.toStringAsFixed(1)}m',
                    style: const TextStyle(
                      color: Color(0xFF14FFEC),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text(
                    'PLAYERS',
                    style: TextStyle(color: Colors.white60),
                  ),
                  Text(
                    '${_myTeam.length}/15',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _myTeam.length,
            itemBuilder: (context, index) {
              final player = _myTeam[index];
              return Card(
                color: const Color(0xFF1A1A1A),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(
                      0xFF14FFEC,
                    ).withValues(alpha: 0.2),
                    child: Text(
                      player['name']?[0] ?? 'P',
                      style: const TextStyle(color: Color(0xFF14FFEC)),
                    ),
                  ),
                  title: Text(
                    player['name'] ?? 'Player',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '£${player['price']}m • ${player['points'] ?? 0} pts',
                    style: const TextStyle(color: Color(0xFF14FFEC)),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removePlayer(player),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAvailablePlayers() {
    if (_players.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.white30),
            SizedBox(height: 16),
            Text(
              'No players available',
              style: TextStyle(color: Colors.white54),
            ),
            Text(
              'Run SQL to insert players',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _players.length,
      itemBuilder: (context, index) {
        final player = _players[index];
        final isInTeam = _myTeam.any((p) => p['id'] == player['id']);

        return Card(
          color: const Color(0xFF1A1A1A),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF14FFEC).withValues(alpha: 0.2),
              child: Text(
                player['name']?[0] ?? 'P',
                style: const TextStyle(color: Color(0xFF14FFEC)),
              ),
            ),
            title: Text(
              player['name'] ?? 'Player',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '£${player['price']}m • ${player['points'] ?? 0} pts',
              style: const TextStyle(color: Color(0xFF14FFEC)),
            ),
            trailing: isInTeam
                ? const Icon(Icons.check_circle, color: Colors.green)
                : IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Color(0xFF14FFEC),
                    ),
                    onPressed: () => _addPlayer(player),
                  ),
          ),
        );
      },
    );
  }
}
