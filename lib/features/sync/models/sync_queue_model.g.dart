// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncQueueModelAdapter extends TypeAdapter<SyncQueueModel> {
  @override
  final int typeId = 12;

  @override
  SyncQueueModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncQueueModel(
      id: fields[0] as String,
      entityType: fields[1] as String,
      entityId: fields[2] as String,
      departmentId: fields[3] as String?,
      operation: fields[4] as SyncOperation,
      payload: fields[5] as String,
      status: fields[6] as SyncStatus,
      errorMessage: fields[7] as String?,
      retryCount: fields[8] as int,
      timestamp: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SyncQueueModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.entityType)
      ..writeByte(2)
      ..write(obj.entityId)
      ..writeByte(3)
      ..write(obj.departmentId)
      ..writeByte(4)
      ..write(obj.operation)
      ..writeByte(5)
      ..write(obj.payload)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.errorMessage)
      ..writeByte(8)
      ..write(obj.retryCount)
      ..writeByte(9)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncQueueModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncOperationAdapter extends TypeAdapter<SyncOperation> {
  @override
  final int typeId = 10;

  @override
  SyncOperation read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncOperation.create;
      case 1:
        return SyncOperation.update;
      case 2:
        return SyncOperation.delete;
      default:
        return SyncOperation.create;
    }
  }

  @override
  void write(BinaryWriter writer, SyncOperation obj) {
    switch (obj) {
      case SyncOperation.create:
        writer.writeByte(0);
        break;
      case SyncOperation.update:
        writer.writeByte(1);
        break;
      case SyncOperation.delete:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 11;

  @override
  SyncStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncStatus.pending;
      case 1:
        return SyncStatus.synced;
      case 2:
        return SyncStatus.error;
      default:
        return SyncStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    switch (obj) {
      case SyncStatus.pending:
        writer.writeByte(0);
        break;
      case SyncStatus.synced:
        writer.writeByte(1);
        break;
      case SyncStatus.error:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
