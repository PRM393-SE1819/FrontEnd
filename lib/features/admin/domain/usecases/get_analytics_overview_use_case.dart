import '../../../../core/usecases/usecase.dart';
import '../../data/models/analytics_overview.dart';
import '../repositories/analytics_repository.dart';

class GetAnalyticsOverviewUseCase implements UseCase<AnalyticsOverview, NoParams> {
  final AnalyticsRepository repository;

  const GetAnalyticsOverviewUseCase(this.repository);

  @override
  Future<AnalyticsOverview> call(NoParams params) {
    return repository.getOverview();
  }
}
