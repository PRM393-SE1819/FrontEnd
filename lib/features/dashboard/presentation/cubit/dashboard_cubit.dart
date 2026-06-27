import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository repository;
  DateTime _selectedDate = DateTime.now();

  DashboardCubit({required this.repository}) : super(const DashboardInitial());

  Future<void> loadDashboardData({bool showLoading = true}) async {
    if (showLoading) {
      emit(const DashboardLoading());
    }
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final summary = await repository.getDashboardSummary(dateStr);
      if (summary != null) {
        emit(DashboardLoaded(summary: summary, selectedDate: _selectedDate));
      } else {
        emit(const DashboardError(message: "Failed to fetch dashboard statistics."));
      }
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  void changeDate(int days) {
    _selectedDate = _selectedDate.add(Duration(days: days));
    loadDashboardData();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    loadDashboardData();
  }
}
