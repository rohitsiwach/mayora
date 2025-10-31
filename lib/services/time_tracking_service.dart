import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hierarchical_firestore_service.dart';
import '../models/shift_record.dart';

class TimeTrackingController extends ChangeNotifier {
  // Services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // ignore: unused_field
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // reserved for future reads (projects cache)
  final HierarchicalFirestoreService _hier = HierarchicalFirestoreService();

  // Constants
  static const Duration maxShift = Duration(hours: 10, minutes: 45);
  static const String _prefsKey = 'mayora.timeTracking.state';

  // State
  String? orgId;
  String? get userId => _auth.currentUser?.uid;

  bool isClockedIn = false;
  bool isOnBreak = false;

  DateTime? shiftStartTime;
  DateTime? clockOutTime;

  Duration accumulatedBreak = Duration.zero;
  DateTime? currentBreakStartTime;

  Duration accumulatedWork = Duration.zero;
  DateTime? currentWorkSegmentStartTime;

  String? activeProjectId;
  String? activeProjectName;
  final Map<String, int> projectDurationsMs = {}; // projectId -> durationMs
  final Map<String, String> projectNames = {}; // projectId -> name cache

  // Location tracking
  Map<String, dynamic>? clockInLocation;
  Map<String, dynamic>? clockOutLocation;
  final List<Map<String, dynamic>> breakLocations = [];
  final List<Map<String, dynamic>> projectSwitchLocations = [];

  DateTime? lastActivity;
  String?
  _sessionId; // Unique ID for current shift session to prevent stale resurrection

  Timer? _ticker;

  // ========== Initialization & Persistence ==========

  Future<void> initialize() async {
    orgId ??= await _hier.getCurrentUserOrganizationId();

    // FIRST: Check if there's any persisted state that should be cleared
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final wasClockedIn = data['isClockedIn'] == true;
        final savedUserId = data['userId'] as String?;

        // If the saved state shows NOT clocked in, it's an ended shift - clear it
        if (!wasClockedIn) {
          await prefs.remove(_prefsKey);
          _startTickerIfNeeded();
          return;
        }

        // If it's from a different user, clear it
        if (savedUserId != userId) {
          await prefs.remove(_prefsKey);
          _startTickerIfNeeded();
          return;
        }

        // If it WAS clocked in and is the same user, this is a legitimate
        // in-progress shift that should be restored (e.g., page refresh, re-login)
        // Continue to _restoreState()
      } catch (e) {
        // Corrupted data - clear it
        await prefs.remove(_prefsKey);
        _startTickerIfNeeded();
        return;
      }
    }

    await _restoreState();
    _startTickerIfNeeded();
  }

  void disposeController() {
    _ticker?.cancel();
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{
      'sessionId': _sessionId,
      'orgId': orgId,
      'userId': userId,
      'isClockedIn': isClockedIn,
      'isOnBreak': isOnBreak,
      'shiftStartTime': shiftStartTime?.toIso8601String(),
      'clockOutTime': clockOutTime?.toIso8601String(),
      'accumulatedBreakMs': accumulatedBreak.inMilliseconds,
      'currentBreakStartTime': currentBreakStartTime?.toIso8601String(),
      'accumulatedWorkMs': accumulatedWork.inMilliseconds,
      'currentWorkSegmentStartTime': currentWorkSegmentStartTime
          ?.toIso8601String(),
      'activeProjectId': activeProjectId,
      'activeProjectName': activeProjectName,
      'projectDurationsMs': projectDurationsMs,
      'projectNames': projectNames,
      'clockInLocation': clockInLocation,
      'clockOutLocation': clockOutLocation,
      'breakLocations': breakLocations,
      'projectSwitchLocations': projectSwitchLocations,
      'lastActivity': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;

    orgId ??= data['orgId'] as String?;
    if (data['userId'] != userId) {
      // Different user; ignore persisted state
      await prefs.remove(_prefsKey);
      return;
    }

    isClockedIn = data['isClockedIn'] == true;

    // If there's no active shift, clean up any stale persisted blob so the
    // next session starts from a blank state. Do this BEFORE restoring any
    // other fields to prevent accidental resurrection.
    if (!isClockedIn) {
      await prefs.remove(_prefsKey);
      return; // Exit early - don't restore ended shift data
    }

    // Restore the session ID from storage
    final savedSessionId = data['sessionId'] as String?;

    // On a fresh start (page refresh, re-login), we won't have a current _sessionId
    // but we should restore the saved one to continue the in-progress shift
    if (_sessionId == null && savedSessionId != null) {
      _sessionId = savedSessionId; // Adopt the saved session
    }

    isOnBreak = data['isOnBreak'] == true;
    final shiftStart = data['shiftStartTime'] as String?;
    if (shiftStart != null) shiftStartTime = DateTime.parse(shiftStart);
    final co = data['clockOutTime'] as String?;
    if (co != null) clockOutTime = DateTime.parse(co);

    accumulatedBreak = Duration(
      milliseconds: (data['accumulatedBreakMs'] ?? 0) as int,
    );
    final cbs = data['currentBreakStartTime'] as String?;
    if (cbs != null) currentBreakStartTime = DateTime.parse(cbs);

    accumulatedWork = Duration(
      milliseconds: (data['accumulatedWorkMs'] ?? 0) as int,
    );
    final cws = data['currentWorkSegmentStartTime'] as String?;
    if (cws != null) currentWorkSegmentStartTime = DateTime.parse(cws);

    activeProjectId = data['activeProjectId'] as String?;
    activeProjectName = data['activeProjectName'] as String?;
    final pd = data['projectDurationsMs'] as Map<String, dynamic>?;
    if (pd != null) {
      projectDurationsMs.clear();
      pd.forEach((k, v) => projectDurationsMs[k] = (v as num).toInt());
    }
    final pn = data['projectNames'] as Map<String, dynamic>?;
    if (pn != null) {
      projectNames.clear();
      pn.forEach((k, v) => projectNames[k] = v as String);
    }

    // Restore location data
    clockInLocation = data['clockInLocation'] as Map<String, dynamic>?;
    clockOutLocation = data['clockOutLocation'] as Map<String, dynamic>?;
    final bl = data['breakLocations'] as List<dynamic>?;
    if (bl != null) {
      breakLocations.clear();
      breakLocations.addAll(bl.cast<Map<String, dynamic>>());
    }
    final psl = data['projectSwitchLocations'] as List<dynamic>?;
    if (psl != null) {
      projectSwitchLocations.clear();
      projectSwitchLocations.addAll(psl.cast<Map<String, dynamic>>());
    }

    final la = data['lastActivity'] as String?;
    if (la != null) lastActivity = DateTime.parse(la);

    // Apply inactive time since lastActivity
    if (isClockedIn && lastActivity != null) {
      final delta = DateTime.now().difference(lastActivity!);
      if (delta.isNegative) {
        // ignore clock skew
      } else {
        _applyInactiveDelta(delta);
      }
    }
  }

  void _applyInactiveDelta(Duration delta) {
    // Add to total-at-work implicitly when we compute values dynamically
    // Here we update accumulatedWork or accumulatedBreak depending on state
    if (isOnBreak) {
      accumulatedBreak += delta;
    } else {
      accumulatedWork += delta;
      _addToActiveProject(delta);
    }

    // Auto-end if exceeded max shift
    final totalAtWork = _currentTotalAtWork();
    if (totalAtWork >= maxShift) {
      final over = totalAtWork - maxShift;
      // Reduce from whichever timer is currently running to cap
      if (isOnBreak) {
        accumulatedBreak -= over;
        if (accumulatedBreak.isNegative) accumulatedBreak = Duration.zero;
      } else {
        accumulatedWork -= over;
        if (accumulatedWork.isNegative) accumulatedWork = Duration.zero;
        _addToActiveProject(-over);
      }
      endShift(autoEnded: true);
    }
  }

  void _startTickerIfNeeded() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!isClockedIn) {
        print('[Ticker] Skipping - not clocked in');
        return;
      }
      // Update running segment
      if (!isOnBreak) {
        accumulatedWork += const Duration(seconds: 1);
        print('[Ticker] Adding 1s to activeProject: $activeProjectId');
        print('[Ticker] Before add: ${projectDurationsMs[activeProjectId]}ms');
        _addToActiveProject(const Duration(seconds: 1));
        print('[Ticker] After add: ${projectDurationsMs[activeProjectId]}ms');
      } else {
        accumulatedBreak += const Duration(seconds: 1);
      }

      // Auto-end rule
      if (_currentTotalAtWork() >= maxShift) {
        await endShift(autoEnded: true);
        return;
      }

      await _persistState();
      notifyListeners();
    });
  }

  // ========== Public API ==========

  Future<void> clockIn({
    required String projectId,
    required String projectName,
    double? latitude,
    double? longitude,
  }) async {
    if (userId == null) throw Exception('Not authenticated');
    orgId ??= await _hier.getCurrentUserOrganizationId();
    if (orgId == null) throw Exception('No organization');

    // Generate a NEW session ID for this shift to prevent any stale state resurrection
    _sessionId =
        '${DateTime.now().millisecondsSinceEpoch}_${userId}_${projectId.hashCode}';

    isClockedIn = true;
    isOnBreak = false;
    shiftStartTime = DateTime.now();
    currentWorkSegmentStartTime = DateTime.now();
    accumulatedBreak = Duration.zero;
    accumulatedWork = Duration.zero;
    activeProjectId = projectId;
    activeProjectName = projectName;
    projectNames[projectId] = projectName;
    projectDurationsMs.clear();
    // Initialize the starting project with 0 duration so it appears in the map immediately
    projectDurationsMs[projectId] = 0;

    // Store clock-in location
    if (latitude != null && longitude != null) {
      clockInLocation = {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'clockIn',
      };
    }
    breakLocations.clear();
    projectSwitchLocations.clear();

    _startTickerIfNeeded();
    await _persistState();
    notifyListeners();
  }

  Future<void> switchProject({
    required String projectId,
    required String projectName,
    double? latitude,
    double? longitude,
  }) async {
    if (!isClockedIn) return;
    // The ticker already handles incremental time tracking every second,
    // so we don't need to manually add delta here (that would double-count).
    // Just switch to the new project and let the ticker continue.
    activeProjectId = projectId;
    activeProjectName = projectName;
    projectNames[projectId] = projectName;
    // Initialize the new project in the map if not already present
    projectDurationsMs[projectId] ??= 0;
    currentWorkSegmentStartTime = DateTime.now();

    // Store project switch location
    if (latitude != null && longitude != null) {
      projectSwitchLocations.add({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'switchProject',
        'projectId': projectId,
        'projectName': projectName,
      });
    }

    await _persistState();
    notifyListeners();
  }

  Future<void> startBreak({double? latitude, double? longitude}) async {
    if (!isClockedIn || isOnBreak) return;
    // The ticker already handles incremental time tracking every second,
    // so we don't need to manually add delta here (that would double-count).
    // Just switch to break state and let the ticker continue.
    isOnBreak = true;
    currentBreakStartTime = DateTime.now();
    currentWorkSegmentStartTime = null;

    // Store break start location
    if (latitude != null && longitude != null) {
      breakLocations.add({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'startBreak',
      });
    }

    await _persistState();
    notifyListeners();
  }

  Future<void> resumeFromBreak({double? latitude, double? longitude}) async {
    if (!isClockedIn || !isOnBreak) return;
    isOnBreak = false;
    currentBreakStartTime = null;
    currentWorkSegmentStartTime = DateTime.now();

    // Store break resume location
    if (latitude != null && longitude != null) {
      breakLocations.add({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'resumeFromBreak',
      });
    }

    await _persistState();
    notifyListeners();
  }

  Future<void> endShift({
    bool autoEnded = false,
    double? latitude,
    double? longitude,
  }) async {
    if (!isClockedIn) return;
    isClockedIn = false;
    clockOutTime = DateTime.now();

    // Store clock-out location
    if (latitude != null && longitude != null) {
      clockOutLocation = {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'clockOut',
      };
    }

    // Persist an 'ended' state immediately so a quick refresh won't revive
    // a running shift from stale local storage.
    await _persistState();

    // The ticker already handles incremental time tracking every second,
    // so we don't need to manually add delta here (ticker stops after this).
    // We may lose up to 1 second of precision, but that's acceptable.

    final totalAtWork = _currentTotalAtWork();
    final totalBreak = accumulatedBreak;
    int workingMs = totalAtWork.inMilliseconds - totalBreak.inMilliseconds;
    if (workingMs < 0) workingMs = 0;

    // Apply business rules for break adjustment
    int adjustedBreakMs = totalBreak.inMilliseconds;
    bool adjusted = false;
    final sixHoursMs = const Duration(hours: 6).inMilliseconds;
    final nineHoursMs = const Duration(hours: 9).inMilliseconds;
    if (totalAtWork.inMilliseconds > nineHoursMs &&
        adjustedBreakMs < const Duration(minutes: 45).inMilliseconds) {
      adjustedBreakMs = const Duration(minutes: 45).inMilliseconds;
      adjusted = true;
    } else if (totalAtWork.inMilliseconds > sixHoursMs &&
        adjustedBreakMs < const Duration(minutes: 30).inMilliseconds) {
      adjustedBreakMs = const Duration(minutes: 30).inMilliseconds;
      adjusted = true;
    }
    int adjustedWorkingMs = totalAtWork.inMilliseconds - adjustedBreakMs;
    if (adjustedWorkingMs < 0) adjustedWorkingMs = 0;

    // Build project breakdown list
    final breakdown =
        projectDurationsMs.entries
            .map(
              (e) => ProjectTimeEntry(
                projectId: e.key,
                projectName: projectNames[e.key] ?? '',
                durationMs: e.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.durationMs.compareTo(a.durationMs));

    // Persist shift record to Firestore
    if (orgId == null ||
        userId == null ||
        shiftStartTime == null ||
        clockOutTime == null) {
      // Can't persist; just reset state safely
    } else {
      final recordMap = buildShiftRecordMap(
        orgId: orgId!,
        userId: userId!,
        clockInTime: shiftStartTime!,
        clockOutTime: clockOutTime!,
        totalHoursAtWorkMs: totalAtWork.inMilliseconds,
        actualWorkingHoursMs: adjustedWorkingMs,
        totalBreakTimeMs: adjustedBreakMs,
        projectBreakdown: breakdown,
        shiftAdjustmentsMade: adjusted,
        isAutoEnded: autoEnded,
        clockInLocation: clockInLocation,
        clockOutLocation: clockOutLocation,
        breakLocations: breakLocations.isEmpty ? null : breakLocations,
        projectSwitchLocations: projectSwitchLocations.isEmpty
            ? null
            : projectSwitchLocations,
      );

      final ref = _hier.userDoc(orgId!, userId!).collection('shifts');
      await ref.add({...recordMap, 'createdAt': FieldValue.serverTimestamp()});
    }

    // Clear state
    _ticker?.cancel();
    _ticker = null;
    await _clearState();
    notifyListeners();
  }

  // ========== Helpers ==========

  /// Build a preview of the shift record as it would be saved if ended now.
  /// Does not persist anything.
  Map<String, dynamic>? previewShiftRecord({DateTime? at}) {
    if (!isClockedIn || shiftStartTime == null) return null;
    final now = at ?? DateTime.now();

    print('[previewShiftRecord] projectDurationsMs: $projectDurationsMs');
    print('[previewShiftRecord] projectNames: $projectNames');
    print('[previewShiftRecord] activeProjectId: $activeProjectId');

    // Compute totals as of 'now'
    final totalAtWork = now.difference(shiftStartTime!);
    final totalBreak = accumulatedBreak;

    // Apply minimum break adjustments per business rules
    int adjustedBreakMs = totalBreak.inMilliseconds;
    bool adjusted = false;
    final sixHoursMs = const Duration(hours: 6).inMilliseconds;
    final nineHoursMs = const Duration(hours: 9).inMilliseconds;
    if (totalAtWork.inMilliseconds > nineHoursMs &&
        adjustedBreakMs < const Duration(minutes: 45).inMilliseconds) {
      adjustedBreakMs = const Duration(minutes: 45).inMilliseconds;
      adjusted = true;
    } else if (totalAtWork.inMilliseconds > sixHoursMs &&
        adjustedBreakMs < const Duration(minutes: 30).inMilliseconds) {
      adjustedBreakMs = const Duration(minutes: 30).inMilliseconds;
      adjusted = true;
    }

    int adjustedWorkingMs = totalAtWork.inMilliseconds - adjustedBreakMs;
    if (adjustedWorkingMs < 0) adjustedWorkingMs = 0;

    // Project breakdown snapshot including current running segment (without mutating state)
    final pdSnapshot = projectDurationsSnapshot(at: now);
    print('[previewShiftRecord] pdSnapshot: $pdSnapshot');
    final breakdown =
        pdSnapshot.entries
            .map(
              (e) => ProjectTimeEntry(
                projectId: e.key,
                projectName: projectNames[e.key] ?? '',
                durationMs: e.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.durationMs.compareTo(a.durationMs));
    print('[previewShiftRecord] breakdown length: ${breakdown.length}');
    for (final entry in breakdown) {
      print(
        '[previewShiftRecord] - ${entry.projectName} (${entry.projectId}): ${entry.durationMs}ms',
      );
    }

    final map = buildShiftRecordMap(
      orgId: orgId ?? '',
      userId: userId ?? '',
      clockInTime: shiftStartTime!,
      clockOutTime: now,
      totalHoursAtWorkMs: totalAtWork.inMilliseconds,
      actualWorkingHoursMs: adjustedWorkingMs,
      totalBreakTimeMs: adjustedBreakMs,
      projectBreakdown: breakdown,
      shiftAdjustmentsMade: adjusted,
      isAutoEnded: false,
      clockInLocation: clockInLocation,
      clockOutLocation: clockOutLocation,
      breakLocations: breakLocations.isEmpty ? null : breakLocations,
      projectSwitchLocations: projectSwitchLocations.isEmpty
          ? null
          : projectSwitchLocations,
    );

    return map;
  }

  /// Returns a copy of projectDurationsMs without adding pending deltas.
  /// We already attribute time to the active project on every tick to avoid
  /// double-counting here.
  Map<String, int> projectDurationsSnapshot({DateTime? at}) {
    final copy = Map<String, int>.from(projectDurationsMs);
    // Clamp values to be safe - use explicit large number instead of bit shift for web compatibility
    for (final k in copy.keys.toList()) {
      final v = copy[k] ?? 0;
      copy[k] = v.clamp(0, 9000000000000); // ~285 years in ms
    }
    return copy;
  }

  Duration _currentTotalAtWork() {
    if (shiftStartTime == null) return Duration.zero;
    final now = DateTime.now();
    return now.difference(shiftStartTime!);
  }

  void _addToActiveProject(Duration delta) {
    final id = activeProjectId;
    if (id == null) {
      print('[_addToActiveProject] Skipping - activeProjectId is null');
      return;
    }
    final deltaMs = delta.inMilliseconds;
    final prev = projectDurationsMs[id] ?? 0;
    final sum = prev + deltaMs;
    // Explicitly cap instead of using clamp to avoid any JS/web surprises
    const int upperCap =
        9000000000000; // ~285 years in ms, effectively "infinite"
    int next = sum;
    if (next < 0) next = 0;
    if (next > upperCap) next = upperCap;
    print(
      '[_addToActiveProject] Project $id: prev=$prev ms, delta=$deltaMs ms, sum=$sum ms, next=$next ms',
    );
    projectDurationsMs[id] = next;
    print(
      '[_addToActiveProject] Map updated => ${projectDurationsMs[id]} ms for $id',
    );
  }

  Future<void> _clearState() async {
    isClockedIn = false;
    isOnBreak = false;
    shiftStartTime = null;
    clockOutTime = null;
    accumulatedBreak = Duration.zero;
    accumulatedWork = Duration.zero;
    currentBreakStartTime = null;
    currentWorkSegmentStartTime = null;
    activeProjectId = null;
    activeProjectName = null;
    projectDurationsMs.clear();
    projectNames.clear();
    clockInLocation = null;
    clockOutLocation = null;
    breakLocations.clear();
    projectSwitchLocations.clear();
    _sessionId = null; // Clear session ID to prevent any resurrection
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  // Exposed getters for UI formatting
  Duration get totalAtWork => _currentTotalAtWork();
  Duration get totalBreak => accumulatedBreak;
  Duration get actualWorking =>
      Duration(
        milliseconds: totalAtWork.inMilliseconds - totalBreak.inMilliseconds,
      ).isNegative
      ? Duration.zero
      : Duration(
          milliseconds: totalAtWork.inMilliseconds - totalBreak.inMilliseconds,
        );

  // Get current active project duration in milliseconds
  int get activeProjectDurationMs {
    if (activeProjectId == null) return 0;
    return projectDurationsMs[activeProjectId] ?? 0;
  }

  static String formatHms(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
