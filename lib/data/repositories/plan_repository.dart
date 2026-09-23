import 'package:hive/hive.dart';
import '../../models/plan_model.dart';
import '../hive_service.dart';

class PlanRepository {
  Box<PlanModel> get _box => Hive.box<PlanModel>(HiveService.planBox);

  List<PlanModel> getAll() => _box.values.toList();
  Future<void> add(PlanModel plan) async => await _box.put(plan.id, plan);
  Future<void> save(PlanModel plan) async => await plan.save();
  Future<void> delete(String id) async => await _box.delete(id);
}