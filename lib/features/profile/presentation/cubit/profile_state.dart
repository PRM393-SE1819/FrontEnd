import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/allergy.dart';
import '../../domain/entities/health_condition.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile? userProfile;
  final List<Allergy> allergies;
  final List<HealthCondition> conditions;
  final bool isOperationLoading;
  final String? toastMessage;
  final bool logoutSuccess;

  const ProfileLoaded({
    this.userProfile,
    required this.allergies,
    required this.conditions,
    this.isOperationLoading = false,
    this.toastMessage,
    this.logoutSuccess = false,
  });

  ProfileLoaded copyWith({
    UserProfile? userProfile,
    List<Allergy>? allergies,
    List<HealthCondition>? conditions,
    bool? isOperationLoading,
    String? toastMessage,
    bool? logoutSuccess,
  }) {
    return ProfileLoaded(
      userProfile: userProfile ?? this.userProfile,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      isOperationLoading: isOperationLoading ?? this.isOperationLoading,
      toastMessage: toastMessage,
      logoutSuccess: logoutSuccess ?? this.logoutSuccess,
    );
  }

  @override
  List<Object?> get props => [userProfile, allergies, conditions, isOperationLoading, toastMessage, logoutSuccess];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
