import '../../domain/entities/dashboard_summary.dart';

abstract class DashboardState {
  const DashboardState();
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardSummary summary;
  final DateTime selectedDate;

  const DashboardLoaded({
    required this.summary,
    required this.selectedDate,
  });
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});
}
