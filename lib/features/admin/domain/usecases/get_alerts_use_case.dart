import '../../../../core/usecases/usecase.dart';
import '../../data/models/system_alert.dart';
import '../repositories/alerts_repository.dart';

class GetAlertsUseCase implements UseCase<List<SystemAlert>, NoParams> {
  final AlertsRepository repository;

  const GetAlertsUseCase(this.repository);

  @override
  Future<List<SystemAlert>> call(NoParams params) {
    return repository.getAlerts();
  }
}
