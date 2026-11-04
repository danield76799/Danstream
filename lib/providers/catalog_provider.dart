import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../providers/auth_provider.dart';

class CatalogProvider extends ChangeNotifier {
  List<ChannelCategory> _liveCategories = [];
  List<Channel> _liveChannels = [];
  List<MovieCategory> _movieCategories = [];
  List<Movie> _movies = [];
  List<SeriesCategory> _seriesCategories = [];
  List<Series> _series = [];
  Map<String, List<Program>> _epgData = {};

  bool _loading = false;
  String? _error;

  List<ChannelCategory> get liveCategories => _liveCategories;
  List<Channel> get liveChannels => _liveChannels;
  List<MovieCategory> get movieCategories => _movieCategories;
  List<Movie> get movies => _movies;
  List<SeriesCategory> get seriesCategories => _seriesCategories;
  List<Series> get series => _series;
  Map<String, List<Program>> get epgData => _epgData;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadCatalog(ServerCredentials credentials) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (credentials.type == LoginType.m3u) {
        await _loadM3u(credentials.m3uUrl!);
      } else {
        await _loadXtream(credentials);
      }
    } catch (e) {
      _error = 'Kan catalogus niet laden: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadM3u(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('M3U kon niet worden opgehaald (${response.statusCode})');
    }
    final channels = M3uParser.parse(response.body);
    _liveCategories = [ChannelCategory(id: 'all', name: 'Alle zenders')];
    _liveChannels = channels;
  }

  Future<void> _loadXtream(ServerCredentials credentials) async {
    final server = credentials.xtreamServer!.endsWith('/')
        ? credentials.xtreamServer!
        : '${credentials.xtreamServer}/';
    final base = '${server}player_api.php'
        '?username=${credentials.xtreamUsername}'
        '&password=${credentials.xtreamPassword}';

    final accountResp = await http.get(Uri.parse('$base&action=get_account_info'));
    if (accountResp.statusCode != 200) {
      throw Exception('Xtream server reageert niet');
    }

    final liveResp = await http.get(Uri.parse('$base&action=get_live_streams'));
    _liveChannels = _parseXtreamLive(liveResp.body);
    _liveCategories = [ChannelCategory(id: 'all', name: 'Alle zenders')];

    final vodResp = await http.get(Uri.parse('$base&action=get_vod_streams'));
    _movies = _parseXtreamMovies(vodResp.body);
    _movieCategories = [MovieCategory(id: 'all', name: 'Alle films')];

    final seriesResp = await http.get(Uri.parse('$base&action=get_series'));
    _series = _parseXtreamSeries(seriesResp.body);
    _seriesCategories = [SeriesCategory(id: 'all', name: 'Alle series')];

    // Load EPG for today
    await _loadXtreamEpg(base);
  }

  Future<void> _loadXtreamEpg(String base) async {
    try {
      final date = DateTime.now().toIso8601String().split('T')[0];
      final epgResp = await http.get(Uri.parse('$base&action=get_program_guide&date=$date'));
      if (epgResp.statusCode == 200) {
        final data = jsonDecode(epgResp.body) as List<dynamic>? ?? [];
        for (final item in data) {
          final map = item as Map<String, dynamic>;
          final streamId = map['stream_id'].toString();
          final program = Program(
            id: map['program_id'].toString(),
            title: map['title']?.toString() ?? 'Onbekend',
            description: map['description']?.toString() ?? '',
            start: DateTime.parse(map['start'].toString()),
            end: DateTime.parse(map['stop'].toString()),
            category: map['category']?.toString(),
          );
          _epgData.putIfAbsent(streamId, () => []).add(program);
        }
      }
    } catch (e) {
      debugPrint('EPG loading failed: $e');
    }
  }

  List<Channel> _parseXtreamLive(String body) {
    final data = jsonDecode(body) as List<dynamic>? ?? [];
    return data.map((e) {
      final map = e as Map<String, dynamic>;
      return Channel(
        id: map['stream_id'].toString(),
        name: map['name']?.toString() ?? 'Onbekend',
        logo: map['stream_icon']?.toString(),
        groupTitle: map['category_id']?.toString() ?? 'all',
        streamUrl: '',
      );
    }).toList();
  }

  List<Movie> _parseXtreamMovies(String body) {
    final data = jsonDecode(body) as List<dynamic>? ?? [];
    return data.map((e) {
      final map = e as Map<String, dynamic>;
      return Movie(
        id: map['stream_id'].toString(),
        name: map['name']?.toString() ?? 'Onbekend',
        cover: map['stream_icon']?.toString(),
        categoryId: map['category_id']?.toString() ?? 'all',
        streamUrl: '',
      );
    }).toList();
  }

  List<Series> _parseXtreamSeries(String body) {
    final data = jsonDecode(body) as List<dynamic>? ?? [];
    return data.map((e) {
      final map = e as Map<String, dynamic>;
      return Series(
        id: map['series_id'].toString(),
        name: map['name']?.toString() ?? 'Onbekend',
        cover: map['cover']?.toString(),
        categoryId: map['category_id']?.toString() ?? 'all',
      );
    }).toList();
  }

  String buildXtreamStreamUrl(
    ServerCredentials credentials, {
    required String streamId,
    required String type,
  }) {
    final server = credentials.xtreamServer!.endsWith('/')
        ? credentials.xtreamServer!
        : '${credentials.xtreamServer}/';
    final extension = type == 'movie' ? 'mp4' : 'ts';
    return '${server}live/${credentials.xtreamUsername}/${credentials.xtreamPassword}/$streamId.$extension';
  }
}

class M3uParser {
  static List<Channel> parse(String content) {
    final lines = const LineSplitter().convert(content);
    final List<Channel> channels = [];
    String? currentName;
    String? currentLogo;
    String? currentGroup;

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        currentName = _extractAttribute(line, 'tvg-name')
            ?? _extractAfterComma(line);
        currentLogo = _extractAttribute(line, 'tvg-logo');
        currentGroup = _extractAttribute(line, 'group-title') ?? 'Algemeen';
      } else if (!line.startsWith('#')) {
        if (currentName != null) {
          channels.add(Channel(
            id: channels.length.toString(),
            name: currentName,
            logo: currentLogo,
            groupTitle: currentGroup ?? 'Algemeen',
            streamUrl: line.trim(),
          ));
          currentName = null;
          currentLogo = null;
          currentGroup = null;
        }
      }
    }

    return channels;
  }

  static String? _extractAttribute(String line, String key) {
    final regex = RegExp('$key=\"([^\"]+)\"');
    final match = regex.firstMatch(line);
    return match?.group(1);
  }

  static String? _extractAfterComma(String line) {
    final commaIndex = line.lastIndexOf(',');
    if (commaIndex == -1 || commaIndex == line.length - 1) return null;
    return line.substring(commaIndex + 1).trim();
  }
}
