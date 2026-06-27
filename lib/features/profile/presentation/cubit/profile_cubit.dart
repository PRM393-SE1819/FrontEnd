import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository repository;

  ProfileCubit({required this.repository}) : super(ProfileInitial());

  Future<void> loadProfileData() async {
    emit(ProfileLoading());
    try {
      final userProfile = await repository.getHealthProfile();
      final allergies = await repository.getAllergies() ?? [];
      final conditions = await repository.getHealthConditions() ?? [];

      emit(ProfileLoaded(
        userProfile: userProfile,
        allergies: allergies,
        conditions: conditions,
      ));
    } catch (e) {
      emit(ProfileError("Không thể tải hồ sơ sức khỏe: $e"));
    }
  }

  Future<void> updateHealthProfile(Map<String, dynamic> profileData) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
      try {
        final success = await repository.updateHealthProfile(profileData);
        if (success) {
          final userProfile = await repository.getHealthProfile();
          emit(ProfileLoaded(
            userProfile: userProfile,
            allergies: currentState.allergies,
            conditions: currentState.conditions,
            toastMessage: "Đã cập nhật hồ sơ sức khỏe thành công!",
          ));
        } else {
          emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Cập nhật hồ sơ thất bại."));
        }
      } catch (e) {
        emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Lỗi: $e"));
      }
    }
  }

  Future<void> addAllergy(String allergyName, String notes) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
      try {
        final success = await repository.addAllergy(allergyName, notes);
        if (success) {
          final allergies = await repository.getAllergies() ?? [];
          emit(currentState.copyWith(
            isOperationLoading: false,
            allergies: allergies,
            toastMessage: "Đã thêm dị ứng thành công!",
          ));
        } else {
          emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Thêm dị ứng thất bại."));
        }
      } catch (e) {
        emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Lỗi: $e"));
      }
    }
  }

  Future<void> updateAllergy(int allergyId, String allergyName) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
      try {
        final success = await repository.updateAllergy(allergyId, allergyName);
        if (success) {
          final allergies = await repository.getAllergies() ?? [];
          emit(currentState.copyWith(
            isOperationLoading: false,
            allergies: allergies,
            toastMessage: "Đã cập nhật dị ứng thành công!",
          ));
        } else {
          emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Cập nhật dị ứng thất bại."));
        }
      } catch (e) {
        emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Lỗi: $e"));
      }
    }
  }

  Future<void> deleteAllergy(int allergyId) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
      try {
        final success = await repository.deleteAllergy(allergyId);
        if (success) {
          final allergies = await repository.getAllergies() ?? [];
          emit(currentState.copyWith(
            isOperationLoading: false,
            allergies: allergies,
            toastMessage: "Đã xóa dị ứng thành công!",
          ));
        } else {
          emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Xóa dị ứng thất bại."));
        }
      } catch (e) {
        emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Lỗi: $e"));
      }
    }
  }

  Future<void> addHealthCondition(String conditionName, String notes) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
      try {
        final success = await repository.addHealthCondition(conditionName, notes);
        if (success) {
          final conditions = await repository.getHealthConditions() ?? [];
          emit(currentState.copyWith(
            isOperationLoading: false,
            conditions: conditions,
            toastMessage: "Đã thêm tình trạng bệnh lý thành công!",
          ));
        } else {
          emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Thêm bệnh lý thất bại."));
        }
      } catch (e) {
        emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Lỗi: $e"));
      }
    }
  }

  Future<void> updateHealthCondition(int conditionId, String conditionName, String notes) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
      try {
        final success = await repository.updateHealthCondition(conditionId, conditionName, notes);
        if (success) {
          final conditions = await repository.getHealthConditions() ?? [];
          emit(currentState.copyWith(
            isOperationLoading: false,
            conditions: conditions,
            toastMessage: "Đã cập nhật tình trạng bệnh lý thành công!",
          ));
        } else {
          emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Cập nhật bệnh lý thất bại."));
        }
      } catch (e) {
        emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Lỗi: $e"));
      }
    }
  }

  Future<void> deleteHealthCondition(int conditionId) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
      try {
        final success = await repository.deleteHealthCondition(conditionId);
        if (success) {
          final conditions = await repository.getHealthConditions() ?? [];
          emit(currentState.copyWith(
            isOperationLoading: false,
            conditions: conditions,
            toastMessage: "Đã xóa tình trạng bệnh lý thành công!",
          ));
        } else {
          emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Xóa bệnh lý thất bại."));
        }
      } catch (e) {
        emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Lỗi: $e"));
      }
    }
  }

  Future<void> logout() async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
      try {
        await repository.logout();
        emit(currentState.copyWith(
          isOperationLoading: false,
          logoutSuccess: true,
        ));
      } catch (e) {
        emit(currentState.copyWith(isOperationLoading: false, toastMessage: "Lỗi đăng xuất: $e"));
      }
    }
  }
}
