import '../../domain/repositories/moderation_repository.dart';
import '../datasources/moderation_remote_data_source.dart';
import '../models/moderation_item.dart';

/// Hiện thực [ModerationRepository] — ủy quyền cho [ModerationRemoteDataSource].
class ModerationRepositoryImpl implements ModerationRepository {
  final ModerationRemoteDataSource remoteDataSource;

  ModerationRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ModerationItem>> getQueue() => remoteDataSource.getQueue();

  @override
  Future<List<ModerationItem>> getResolved() => remoteDataSource.getResolved();

  @override
  Future<void> updateStatus(String id, ModerationStatus status) =>
      remoteDataSource.updateStatus(id, status);
}
