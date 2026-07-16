class SyncMerge {
  static const String deletedKey = 'deleted';

  static List<Map<String, dynamic>> mergeRecords(
    Iterable<Map<String, dynamic>> localRecords,
    Iterable<Map<String, dynamic>> remoteRecords,
  ) {
    final recordsById = <String, Map<String, dynamic>>{};

    void addRecord(Map<String, dynamic> record) {
      final objectId = record['objectId']?.toString();
      if (objectId == null || objectId.isEmpty) return;

      final existing = recordsById[objectId];
      if (existing == null ||
          _updatedAt(record).isAfter(_updatedAt(existing))) {
        recordsById[objectId] = Map<String, dynamic>.from(record);
      }
    }

    for (final record in localRecords) {
      addRecord(record);
    }
    for (final record in remoteRecords) {
      addRecord(record);
    }

    return recordsById.values.toList();
  }

  static List<Map<String, dynamic>> visibleRecords(
    Iterable<Map<String, dynamic>> records,
  ) {
    return records.where((record) => !isDeleted(record)).toList();
  }

  static Map<String, dynamic> tombstoneFor(
    String objectId, {
    DateTime? deletedAt,
  }) {
    final timestamp = (deletedAt ?? DateTime.now()).toIso8601String();
    return {
      'objectId': objectId,
      deletedKey: true,
      'deletedAt': timestamp,
      'updatedAt': timestamp,
    };
  }

  static bool isDeleted(Map<String, dynamic> record) {
    return record[deletedKey] == true;
  }

  static DateTime _updatedAt(Map<String, dynamic> record) {
    return DateTime.tryParse(record['updatedAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
