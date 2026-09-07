import 'package:get/get.dart';
import '../../core/merchant_repository.dart';
import '../../core/models.dart';

class MerchantController extends GetxController {
  MerchantController(this.repository);
  final MerchantRepository repository;
  MerchantSnapshot? data;
  bool loading = true;
  String? error;
  DemoScenario scenario = DemoScenario.normal;
  int selectedTab = 0;
  final Set<String> _busy = {};
  bool busy(String key) => _busy.contains(key);
  int _loadVersion = 0;

  Future<void> load({DemoScenario? scenario}) async {
    if (scenario != null) this.scenario = scenario;
    final version = ++_loadVersion;
    loading = true;
    error = null;
    update();
    try {
      final result = await repository.load(scenario: this.scenario);
      if (isClosed || version != _loadVersion) return;
      data = result;
    } catch (e) {
      if (isClosed || version != _loadVersion) return;
      error = messageFor(e);
    } finally {
      if (!isClosed && version == _loadVersion) {
        loading = false;
        update();
      }
    }
  }

  void selectTab(int value) {
    selectedTab = value;
    update();
  }

  /// Returns a user-facing failure; the caller shows inline feedback.
  Future<String?> perform(String key, Future<void> Function() action) async {
    if (!_busy.add(key)) return 'This action is already being saved.';
    update();
    try {
      await action();
      final result = await repository.load(scenario: scenario);
      if (!isClosed) {
        data = result;
        update();
      }
      return null;
    } catch (e) {
      return messageFor(e);
    } finally {
      _busy.remove(key);
      if (!isClosed) update();
    }
  }

  static String messageFor(Object error) => error is MerchantException
      ? error.message
      : 'Could not load or save demo data. Please try again.';
}
