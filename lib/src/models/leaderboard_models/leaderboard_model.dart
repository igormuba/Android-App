import 'dart:convert';
import 'package:acela/src/utils/safe_convert.dart';

List<LeaderboardResponseItem> leaderboardResponseItemFromString(String string) {
  final jsonList = json.decode(string) as List;
  final list =
      jsonList.map((e) => LeaderboardResponseItem.fromJson(e)).toList();
  return list;
}

class LeaderboardResponseItem {
  // 735
  final int rank;

  // 667.6
  final double score;

  // mrosenquist1
  final String username;

  LeaderboardResponseItem({
    this.rank = 0,
    this.score = 0.0,
    this.username = "",
  });

  factory LeaderboardResponseItem.fromJson(Map<String, dynamic>? json) =>
      LeaderboardResponseItem(
        rank: asInt(json, 'rank'),
        score: asDouble(json, 'score'),
        username: asString(json, 'username'),
      );

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'score': score,
        'username': username,
      };
}
