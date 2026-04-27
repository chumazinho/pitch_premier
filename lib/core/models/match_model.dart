class MatchModel {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final DateTime kickoffTime;
  final int? homeScore;
  final int? awayScore;
  final String status;

  MatchModel({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.kickoffTime,
    this.homeScore,
    this.awayScore,
    required this.status,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] ?? '',
      homeTeam: json['home_team'] ?? '',
      awayTeam: json['away_team'] ?? '',
      kickoffTime: DateTime.parse(
        json['kickoff_time'] ?? DateTime.now().toIso8601String(),
      ),
      homeScore: json['home_score'],
      awayScore: json['away_score'],
      status: json['status'] ?? 'scheduled',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'home_team': homeTeam,
      'away_team': awayTeam,
      'kickoff_time': kickoffTime.toIso8601String(),
      'home_score': homeScore,
      'away_score': awayScore,
      'status': status,
    };
  }
}
