import '../../../../core/usecases/usecase.dart';
import '../repositories/alerts_repository.dart';

class DismissAlertUseCase implements UseCase<void, String> {
  final AlertsRepository repository;

  const DismissAlertUseCase(this.repository);

  @override
  Future<void> call(String id) {
    return repository.dismissAlert(id);
  }
}
