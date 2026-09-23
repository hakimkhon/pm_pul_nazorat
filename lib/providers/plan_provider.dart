import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/plan_repository.dart';
import '../models/plan_model.dart';

final planRepositoryProvider = Provider((ref) => PlanRepository());

class PlanNotifier extends StateNotifier<List<PlanModel>> {
  final PlanRepository _repo;
  PlanNotifier(this._repo) : super(_repo.getAll());

  void refresh() => state = _repo.getAll();

  Future<void> add(PlanModel plan) async {
    await _repo.add(plan);
    refresh();
  }

  Future<void> updateStatus(PlanModel plan, String status) async {
    plan.status = status;
    await _repo.save(plan);
    refresh();
  }

  Future<void> snooze(PlanModel plan, Duration by) async {
    plan.reminderTime = (plan.reminderTime ?? DateTime.now()).add(by);
    await _repo.save(plan);
    refresh();
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    refresh();
  }
}

final planProvider = StateNotifierProvider<PlanNotifier, List<PlanModel>>((ref) {
  return PlanNotifier(ref.read(planRepositoryProvider));
});