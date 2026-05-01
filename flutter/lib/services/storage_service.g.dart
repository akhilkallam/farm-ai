// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_service.dart';

// ignore_for_file: type=lint
class $FarmerProfilesTable extends FarmerProfiles
    with TableInfo<$FarmerProfilesTable, FarmerProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FarmerProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cropsMeta = const VerificationMeta('crops');
  @override
  late final GeneratedColumn<String> crops = GeneratedColumn<String>(
    'crops',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _landAcresMeta = const VerificationMeta(
    'landAcres',
  );
  @override
  late final GeneratedColumn<double> landAcres = GeneratedColumn<double>(
    'land_acres',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    location,
    crops,
    landAcres,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'farmer_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<FarmerProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('crops')) {
      context.handle(
        _cropsMeta,
        crops.isAcceptableOrUnknown(data['crops']!, _cropsMeta),
      );
    } else if (isInserting) {
      context.missing(_cropsMeta);
    }
    if (data.containsKey('land_acres')) {
      context.handle(
        _landAcresMeta,
        landAcres.isAcceptableOrUnknown(data['land_acres']!, _landAcresMeta),
      );
    } else if (isInserting) {
      context.missing(_landAcresMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FarmerProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FarmerProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      crops: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crops'],
      )!,
      landAcres: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}land_acres'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FarmerProfilesTable createAlias(String alias) {
    return $FarmerProfilesTable(attachedDatabase, alias);
  }
}

class FarmerProfile extends DataClass implements Insertable<FarmerProfile> {
  final String id;
  final String name;
  final String location;
  final String crops;
  final double landAcres;
  final DateTime updatedAt;
  const FarmerProfile({
    required this.id,
    required this.name,
    required this.location,
    required this.crops,
    required this.landAcres,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['location'] = Variable<String>(location);
    map['crops'] = Variable<String>(crops);
    map['land_acres'] = Variable<double>(landAcres);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FarmerProfilesCompanion toCompanion(bool nullToAbsent) {
    return FarmerProfilesCompanion(
      id: Value(id),
      name: Value(name),
      location: Value(location),
      crops: Value(crops),
      landAcres: Value(landAcres),
      updatedAt: Value(updatedAt),
    );
  }

  factory FarmerProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FarmerProfile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      location: serializer.fromJson<String>(json['location']),
      crops: serializer.fromJson<String>(json['crops']),
      landAcres: serializer.fromJson<double>(json['landAcres']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'location': serializer.toJson<String>(location),
      'crops': serializer.toJson<String>(crops),
      'landAcres': serializer.toJson<double>(landAcres),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FarmerProfile copyWith({
    String? id,
    String? name,
    String? location,
    String? crops,
    double? landAcres,
    DateTime? updatedAt,
  }) => FarmerProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    location: location ?? this.location,
    crops: crops ?? this.crops,
    landAcres: landAcres ?? this.landAcres,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FarmerProfile copyWithCompanion(FarmerProfilesCompanion data) {
    return FarmerProfile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      location: data.location.present ? data.location.value : this.location,
      crops: data.crops.present ? data.crops.value : this.crops,
      landAcres: data.landAcres.present ? data.landAcres.value : this.landAcres,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FarmerProfile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('crops: $crops, ')
          ..write('landAcres: $landAcres, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, location, crops, landAcres, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FarmerProfile &&
          other.id == this.id &&
          other.name == this.name &&
          other.location == this.location &&
          other.crops == this.crops &&
          other.landAcres == this.landAcres &&
          other.updatedAt == this.updatedAt);
}

class FarmerProfilesCompanion extends UpdateCompanion<FarmerProfile> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> location;
  final Value<String> crops;
  final Value<double> landAcres;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FarmerProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.location = const Value.absent(),
    this.crops = const Value.absent(),
    this.landAcres = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FarmerProfilesCompanion.insert({
    required String id,
    required String name,
    required String location,
    required String crops,
    required double landAcres,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       location = Value(location),
       crops = Value(crops),
       landAcres = Value(landAcres),
       updatedAt = Value(updatedAt);
  static Insertable<FarmerProfile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? location,
    Expression<String>? crops,
    Expression<double>? landAcres,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (location != null) 'location': location,
      if (crops != null) 'crops': crops,
      if (landAcres != null) 'land_acres': landAcres,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FarmerProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? location,
    Value<String>? crops,
    Value<double>? landAcres,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FarmerProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      crops: crops ?? this.crops,
      landAcres: landAcres ?? this.landAcres,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (crops.present) {
      map['crops'] = Variable<String>(crops.value);
    }
    if (landAcres.present) {
      map['land_acres'] = Variable<double>(landAcres.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FarmerProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('crops: $crops, ')
          ..write('landAcres: $landAcres, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationMessagesTable extends ConversationMessages
    with TableInfo<$ConversationMessagesTable, ConversationMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _farmerIdMeta = const VerificationMeta(
    'farmerId',
  );
  @override
  late final GeneratedColumn<String> farmerId = GeneratedColumn<String>(
    'farmer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agentMeta = const VerificationMeta('agent');
  @override
  late final GeneratedColumn<String> agent = GeneratedColumn<String>(
    'agent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioPathMeta = const VerificationMeta(
    'audioPath',
  );
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
    'audio_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    farmerId,
    role,
    content,
    agent,
    audioPath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversation_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('farmer_id')) {
      context.handle(
        _farmerIdMeta,
        farmerId.isAcceptableOrUnknown(data['farmer_id']!, _farmerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_farmerIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('agent')) {
      context.handle(
        _agentMeta,
        agent.isAcceptableOrUnknown(data['agent']!, _agentMeta),
      );
    }
    if (data.containsKey('audio_path')) {
      context.handle(
        _audioPathMeta,
        audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConversationMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      farmerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}farmer_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      agent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent'],
      ),
      audioPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ConversationMessagesTable createAlias(String alias) {
    return $ConversationMessagesTable(attachedDatabase, alias);
  }
}

class ConversationMessage extends DataClass
    implements Insertable<ConversationMessage> {
  final String id;
  final String farmerId;
  final String role;
  final String content;
  final String? agent;
  final String? audioPath;
  final DateTime createdAt;
  const ConversationMessage({
    required this.id,
    required this.farmerId,
    required this.role,
    required this.content,
    this.agent,
    this.audioPath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['farmer_id'] = Variable<String>(farmerId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || agent != null) {
      map['agent'] = Variable<String>(agent);
    }
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ConversationMessagesCompanion toCompanion(bool nullToAbsent) {
    return ConversationMessagesCompanion(
      id: Value(id),
      farmerId: Value(farmerId),
      role: Value(role),
      content: Value(content),
      agent: agent == null && nullToAbsent
          ? const Value.absent()
          : Value(agent),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      createdAt: Value(createdAt),
    );
  }

  factory ConversationMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationMessage(
      id: serializer.fromJson<String>(json['id']),
      farmerId: serializer.fromJson<String>(json['farmerId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      agent: serializer.fromJson<String?>(json['agent']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'farmerId': serializer.toJson<String>(farmerId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'agent': serializer.toJson<String?>(agent),
      'audioPath': serializer.toJson<String?>(audioPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ConversationMessage copyWith({
    String? id,
    String? farmerId,
    String? role,
    String? content,
    Value<String?> agent = const Value.absent(),
    Value<String?> audioPath = const Value.absent(),
    DateTime? createdAt,
  }) => ConversationMessage(
    id: id ?? this.id,
    farmerId: farmerId ?? this.farmerId,
    role: role ?? this.role,
    content: content ?? this.content,
    agent: agent.present ? agent.value : this.agent,
    audioPath: audioPath.present ? audioPath.value : this.audioPath,
    createdAt: createdAt ?? this.createdAt,
  );
  ConversationMessage copyWithCompanion(ConversationMessagesCompanion data) {
    return ConversationMessage(
      id: data.id.present ? data.id.value : this.id,
      farmerId: data.farmerId.present ? data.farmerId.value : this.farmerId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      agent: data.agent.present ? data.agent.value : this.agent,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationMessage(')
          ..write('id: $id, ')
          ..write('farmerId: $farmerId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('agent: $agent, ')
          ..write('audioPath: $audioPath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, farmerId, role, content, agent, audioPath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationMessage &&
          other.id == this.id &&
          other.farmerId == this.farmerId &&
          other.role == this.role &&
          other.content == this.content &&
          other.agent == this.agent &&
          other.audioPath == this.audioPath &&
          other.createdAt == this.createdAt);
}

class ConversationMessagesCompanion
    extends UpdateCompanion<ConversationMessage> {
  final Value<String> id;
  final Value<String> farmerId;
  final Value<String> role;
  final Value<String> content;
  final Value<String?> agent;
  final Value<String?> audioPath;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ConversationMessagesCompanion({
    this.id = const Value.absent(),
    this.farmerId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.agent = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationMessagesCompanion.insert({
    required String id,
    required String farmerId,
    required String role,
    required String content,
    this.agent = const Value.absent(),
    this.audioPath = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       farmerId = Value(farmerId),
       role = Value(role),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<ConversationMessage> custom({
    Expression<String>? id,
    Expression<String>? farmerId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? agent,
    Expression<String>? audioPath,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (farmerId != null) 'farmer_id': farmerId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (agent != null) 'agent': agent,
      if (audioPath != null) 'audio_path': audioPath,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? farmerId,
    Value<String>? role,
    Value<String>? content,
    Value<String?>? agent,
    Value<String?>? audioPath,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ConversationMessagesCompanion(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      role: role ?? this.role,
      content: content ?? this.content,
      agent: agent ?? this.agent,
      audioPath: audioPath ?? this.audioPath,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (farmerId.present) {
      map['farmer_id'] = Variable<String>(farmerId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (agent.present) {
      map['agent'] = Variable<String>(agent.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationMessagesCompanion(')
          ..write('id: $id, ')
          ..write('farmerId: $farmerId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('agent: $agent, ')
          ..write('audioPath: $audioPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineQueueTable extends OfflineQueue
    with TableInfo<$OfflineQueueTable, OfflineQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    type,
    payload,
    status,
    retryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
    );
  }

  @override
  $OfflineQueueTable createAlias(String alias) {
    return $OfflineQueueTable(attachedDatabase, alias);
  }
}

class OfflineQueueData extends DataClass
    implements Insertable<OfflineQueueData> {
  final String id;
  final DateTime createdAt;
  final String type;
  final String payload;
  final String status;
  final int retryCount;
  const OfflineQueueData({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.payload,
    required this.status,
    required this.retryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['type'] = Variable<String>(type);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  OfflineQueueCompanion toCompanion(bool nullToAbsent) {
    return OfflineQueueCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      type: Value(type),
      payload: Value(payload),
      status: Value(status),
      retryCount: Value(retryCount),
    );
  }

  factory OfflineQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineQueueData(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  OfflineQueueData copyWith({
    String? id,
    DateTime? createdAt,
    String? type,
    String? payload,
    String? status,
    int? retryCount,
  }) => OfflineQueueData(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    type: type ?? this.type,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
  );
  OfflineQueueData copyWithCompanion(OfflineQueueCompanion data) {
    return OfflineQueueData(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineQueueData(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, type, payload, status, retryCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineQueueData &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.type == this.type &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.retryCount == this.retryCount);
}

class OfflineQueueCompanion extends UpdateCompanion<OfflineQueueData> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<String> type;
  final Value<String> payload;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<int> rowid;
  const OfflineQueueCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineQueueCompanion.insert({
    required String id,
    required DateTime createdAt,
    required String type,
    required String payload,
    required String status,
    this.retryCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       type = Value(type),
       payload = Value(payload),
       status = Value(status);
  static Insertable<OfflineQueueData> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? type,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineQueueCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<String>? type,
    Value<String>? payload,
    Value<String>? status,
    Value<int>? retryCount,
    Value<int>? rowid,
  }) {
    return OfflineQueueCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineQueueCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FarmerProfilesTable farmerProfiles = $FarmerProfilesTable(this);
  late final $ConversationMessagesTable conversationMessages =
      $ConversationMessagesTable(this);
  late final $OfflineQueueTable offlineQueue = $OfflineQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    farmerProfiles,
    conversationMessages,
    offlineQueue,
  ];
}

typedef $$FarmerProfilesTableCreateCompanionBuilder =
    FarmerProfilesCompanion Function({
      required String id,
      required String name,
      required String location,
      required String crops,
      required double landAcres,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$FarmerProfilesTableUpdateCompanionBuilder =
    FarmerProfilesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> location,
      Value<String> crops,
      Value<double> landAcres,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$FarmerProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $FarmerProfilesTable> {
  $$FarmerProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crops => $composableBuilder(
    column: $table.crops,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get landAcres => $composableBuilder(
    column: $table.landAcres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FarmerProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $FarmerProfilesTable> {
  $$FarmerProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crops => $composableBuilder(
    column: $table.crops,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get landAcres => $composableBuilder(
    column: $table.landAcres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FarmerProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FarmerProfilesTable> {
  $$FarmerProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get crops =>
      $composableBuilder(column: $table.crops, builder: (column) => column);

  GeneratedColumn<double> get landAcres =>
      $composableBuilder(column: $table.landAcres, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FarmerProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FarmerProfilesTable,
          FarmerProfile,
          $$FarmerProfilesTableFilterComposer,
          $$FarmerProfilesTableOrderingComposer,
          $$FarmerProfilesTableAnnotationComposer,
          $$FarmerProfilesTableCreateCompanionBuilder,
          $$FarmerProfilesTableUpdateCompanionBuilder,
          (
            FarmerProfile,
            BaseReferences<_$AppDatabase, $FarmerProfilesTable, FarmerProfile>,
          ),
          FarmerProfile,
          PrefetchHooks Function()
        > {
  $$FarmerProfilesTableTableManager(
    _$AppDatabase db,
    $FarmerProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FarmerProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FarmerProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FarmerProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> crops = const Value.absent(),
                Value<double> landAcres = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FarmerProfilesCompanion(
                id: id,
                name: name,
                location: location,
                crops: crops,
                landAcres: landAcres,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String location,
                required String crops,
                required double landAcres,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FarmerProfilesCompanion.insert(
                id: id,
                name: name,
                location: location,
                crops: crops,
                landAcres: landAcres,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FarmerProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FarmerProfilesTable,
      FarmerProfile,
      $$FarmerProfilesTableFilterComposer,
      $$FarmerProfilesTableOrderingComposer,
      $$FarmerProfilesTableAnnotationComposer,
      $$FarmerProfilesTableCreateCompanionBuilder,
      $$FarmerProfilesTableUpdateCompanionBuilder,
      (
        FarmerProfile,
        BaseReferences<_$AppDatabase, $FarmerProfilesTable, FarmerProfile>,
      ),
      FarmerProfile,
      PrefetchHooks Function()
    >;
typedef $$ConversationMessagesTableCreateCompanionBuilder =
    ConversationMessagesCompanion Function({
      required String id,
      required String farmerId,
      required String role,
      required String content,
      Value<String?> agent,
      Value<String?> audioPath,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ConversationMessagesTableUpdateCompanionBuilder =
    ConversationMessagesCompanion Function({
      Value<String> id,
      Value<String> farmerId,
      Value<String> role,
      Value<String> content,
      Value<String?> agent,
      Value<String?> audioPath,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ConversationMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationMessagesTable> {
  $$ConversationMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get farmerId => $composableBuilder(
    column: $table.farmerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agent => $composableBuilder(
    column: $table.agent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConversationMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationMessagesTable> {
  $$ConversationMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get farmerId => $composableBuilder(
    column: $table.farmerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agent => $composableBuilder(
    column: $table.agent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationMessagesTable> {
  $$ConversationMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get farmerId =>
      $composableBuilder(column: $table.farmerId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get agent =>
      $composableBuilder(column: $table.agent, builder: (column) => column);

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ConversationMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationMessagesTable,
          ConversationMessage,
          $$ConversationMessagesTableFilterComposer,
          $$ConversationMessagesTableOrderingComposer,
          $$ConversationMessagesTableAnnotationComposer,
          $$ConversationMessagesTableCreateCompanionBuilder,
          $$ConversationMessagesTableUpdateCompanionBuilder,
          (
            ConversationMessage,
            BaseReferences<
              _$AppDatabase,
              $ConversationMessagesTable,
              ConversationMessage
            >,
          ),
          ConversationMessage,
          PrefetchHooks Function()
        > {
  $$ConversationMessagesTableTableManager(
    _$AppDatabase db,
    $ConversationMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationMessagesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ConversationMessagesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> farmerId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> agent = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationMessagesCompanion(
                id: id,
                farmerId: farmerId,
                role: role,
                content: content,
                agent: agent,
                audioPath: audioPath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String farmerId,
                required String role,
                required String content,
                Value<String?> agent = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ConversationMessagesCompanion.insert(
                id: id,
                farmerId: farmerId,
                role: role,
                content: content,
                agent: agent,
                audioPath: audioPath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConversationMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationMessagesTable,
      ConversationMessage,
      $$ConversationMessagesTableFilterComposer,
      $$ConversationMessagesTableOrderingComposer,
      $$ConversationMessagesTableAnnotationComposer,
      $$ConversationMessagesTableCreateCompanionBuilder,
      $$ConversationMessagesTableUpdateCompanionBuilder,
      (
        ConversationMessage,
        BaseReferences<
          _$AppDatabase,
          $ConversationMessagesTable,
          ConversationMessage
        >,
      ),
      ConversationMessage,
      PrefetchHooks Function()
    >;
typedef $$OfflineQueueTableCreateCompanionBuilder =
    OfflineQueueCompanion Function({
      required String id,
      required DateTime createdAt,
      required String type,
      required String payload,
      required String status,
      Value<int> retryCount,
      Value<int> rowid,
    });
typedef $$OfflineQueueTableUpdateCompanionBuilder =
    OfflineQueueCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<String> type,
      Value<String> payload,
      Value<String> status,
      Value<int> retryCount,
      Value<int> rowid,
    });

class $$OfflineQueueTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineQueueTable> {
  $$OfflineQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineQueueTable> {
  $$OfflineQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineQueueTable> {
  $$OfflineQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );
}

class $$OfflineQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineQueueTable,
          OfflineQueueData,
          $$OfflineQueueTableFilterComposer,
          $$OfflineQueueTableOrderingComposer,
          $$OfflineQueueTableAnnotationComposer,
          $$OfflineQueueTableCreateCompanionBuilder,
          $$OfflineQueueTableUpdateCompanionBuilder,
          (
            OfflineQueueData,
            BaseReferences<_$AppDatabase, $OfflineQueueTable, OfflineQueueData>,
          ),
          OfflineQueueData,
          PrefetchHooks Function()
        > {
  $$OfflineQueueTableTableManager(_$AppDatabase db, $OfflineQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineQueueCompanion(
                id: id,
                createdAt: createdAt,
                type: type,
                payload: payload,
                status: status,
                retryCount: retryCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required String type,
                required String payload,
                required String status,
                Value<int> retryCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineQueueCompanion.insert(
                id: id,
                createdAt: createdAt,
                type: type,
                payload: payload,
                status: status,
                retryCount: retryCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineQueueTable,
      OfflineQueueData,
      $$OfflineQueueTableFilterComposer,
      $$OfflineQueueTableOrderingComposer,
      $$OfflineQueueTableAnnotationComposer,
      $$OfflineQueueTableCreateCompanionBuilder,
      $$OfflineQueueTableUpdateCompanionBuilder,
      (
        OfflineQueueData,
        BaseReferences<_$AppDatabase, $OfflineQueueTable, OfflineQueueData>,
      ),
      OfflineQueueData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FarmerProfilesTableTableManager get farmerProfiles =>
      $$FarmerProfilesTableTableManager(_db, _db.farmerProfiles);
  $$ConversationMessagesTableTableManager get conversationMessages =>
      $$ConversationMessagesTableTableManager(_db, _db.conversationMessages);
  $$OfflineQueueTableTableManager get offlineQueue =>
      $$OfflineQueueTableTableManager(_db, _db.offlineQueue);
}
