// lib/features/camera/domain/camera_models.dart
enum CameraStatus { ENABLED, DISABLED }

CameraStatus _statusFrom(String? s) =>
    (s ?? '').toUpperCase() == 'ENABLED'
        ? CameraStatus.ENABLED
        : CameraStatus.DISABLED;

class Camera {
  final String id;
  final String? ipAddress;
  final String? cameraModel;
  final String? ingestSource;
  final String? streamKey;

  /// LIVE HLS (низкая задержка)
  final String? hlsUrl;

  /// RECORD/VOD HLS (архив/запись)
  final String? videoPlaylistUrl;
  final CameraStatus status;

  Camera({
    required this.id,
    this.ipAddress,
    this.cameraModel,
    this.ingestSource,
    this.streamKey,
    this.hlsUrl,
    this.videoPlaylistUrl,
    required this.status,
  });

  factory Camera.fromJson(Map<String, dynamic> j) => Camera(
    id: j['id'] as String,
    ipAddress: j['ipAddress'] as String?,
    cameraModel: j['cameraModel'] as String?,
    ingestSource: j['ingestSource'] as String?,
    streamKey: j['streamKey'] as String?,
    hlsUrl: j['hlsUrl'] as String?,
    videoPlaylistUrl: j['videoPlaylistUrl'] as String?,
    status: _statusFrom(j['status'] as String?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (ipAddress != null) 'ipAddress': ipAddress,
    if (cameraModel != null) 'cameraModel': cameraModel,
    if (ingestSource != null) 'ingestSource': ingestSource,
    if (streamKey != null) 'streamKey': streamKey,
    if (hlsUrl != null) 'hlsUrl': hlsUrl,
    if (videoPlaylistUrl != null) 'videoPlaylistUrl': videoPlaylistUrl,
    'status': status.name,
  };
}

class CameraRequest {
  final String? ipAddress;
  final String? cameraModel;
  final String? ingestSource;

  CameraRequest({this.ipAddress, this.cameraModel, this.ingestSource});

  Map<String, dynamic> toJson() => {
    if (ipAddress != null && ipAddress!.isNotEmpty) 'ipAddress': ipAddress,
    if (cameraModel != null && cameraModel!.isNotEmpty)
      'cameraModel': cameraModel,
    if (ingestSource != null && ingestSource!.isNotEmpty)
      'ingestSource': ingestSource,
  };
}
