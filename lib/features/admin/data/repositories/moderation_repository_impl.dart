import '../../domain/repositories/moderation_repository.dart';
import '../datasources/moderation_mock_data_source.dart';
import '../models/moderation_item.dart';

/// Hiện thực [ModerationRepository] — ủy quyền cho [ModerationDataSource]
/// (mock hoặc remote, chọn ở DI).
class ModerationRepositoryImpl implements ModerationRepository {
  final ModerationDataSource dataSource;

  ModerationRepositoryImpl(this.dataSource);

  @override
  Future<List<ModerationItem>> getQueue() => dataSource.getQueue();

  @override
  Future<List<ModerationItem>> getResolved() => dataSource.getResolved();

  @override
  Future<void> updateStatus(String id, ModerationStatus status) =>
      dataSource.updateStatus(id, status);
}
