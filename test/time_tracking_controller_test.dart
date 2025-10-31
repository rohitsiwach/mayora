import 'package:flutter_test/flutter_test.dart';
import 'package:mayora/services/time_tracking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimeTrackingController', () {
    test('increments active project time while working', () async {
      final c = TimeTrackingController();
      await c.initialize();

      await c.clockIn(projectId: 'p1', projectName: 'Project 1');

      // Wait ~2.2 seconds to allow at least 2 ticks
      await Future.delayed(const Duration(milliseconds: 2200));

      final ms = c.projectDurationsSnapshot()[c.activeProjectId] ?? 0;
      expect(
        ms >= 2000,
        true,
        reason: 'Expected at least 2 seconds recorded, got $ms ms',
      );

      await c.endShift();
      c.disposeController();
    });

    test('switching projects attributes time correctly', () async {
      final c = TimeTrackingController();
      await c.initialize();

      await c.clockIn(projectId: 'pA', projectName: 'A');
      await Future.delayed(const Duration(milliseconds: 1100));

      await c.switchProject(projectId: 'pB', projectName: 'B');
      await Future.delayed(const Duration(milliseconds: 1100));

      final snap = c.projectDurationsSnapshot();
      final aMs = snap['pA'] ?? 0;
      final bMs = snap['pB'] ?? 0;

      expect(
        aMs >= 1000,
        true,
        reason: 'Project A should have at least 1s, got $aMs',
      );
      expect(
        bMs >= 1000,
        true,
        reason: 'Project B should have at least 1s, got $bMs',
      );

      await c.endShift();
      c.disposeController();
    });
  });
}
