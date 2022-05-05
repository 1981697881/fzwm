import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fzwm/http/api_response.dart';
import 'package:fzwm/http/httpUtils.dart';
import 'package:fzwm/server/api.dart';

VersionEntity versionEntityFromJson(String str) => VersionEntity.fromJson(json.decode(str));

String versionEntityToJson(VersionEntity data) => json.encode(data.toJson());

class VersionEntity {
  static Future<ApiResponse<VersionEntity>> getVersion(
      ) async {
    try {
      final response = await HttpUtils.post(API.VERSION_URL);
      final res = new Map<String, dynamic>.from(response);
      var data = VersionEntity.fromJson(res);
      return ApiResponse.completed(data);
    } on DioError catch (e) {
      return ApiResponse.error(e.error);
    }
  }
  VersionEntity({
    this.code,
    this.message,
    this.data,
  });

  int code;
  String message;
  Data data;

  factory VersionEntity.fromJson(Map<String, dynamic> json) => VersionEntity(
    code: json["code"],
    message: json["message"],
    data: Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "message": message,
    "data": data.toJson(),
  };
}

class Data {
  Data({
    this.buildBuildVersion,
    this.forceUpdateVersion,
    this.forceUpdateVersionNo,
    this.needForceUpdate,
    this.downloadUrl,
    this.buildHaveNewVersion,
    this.buildVersionNo,
    this.buildVersion,
    this.buildUpdateDescription,
    this.appKey,
    this.buildKey,
    this.buildName,
    this.buildIcon,
    this.buildFileKey,
    this.buildFileSize,
  });

  String buildBuildVersion;
  String forceUpdateVersion;
  String forceUpdateVersionNo;
  bool needForceUpdate;
  String downloadUrl;
  bool buildHaveNewVersion;
  String buildVersionNo;
  String buildVersion;
  String buildUpdateDescription;
  String appKey;
  String buildKey;
  String buildName;
  String buildIcon;
  String buildFileKey;
  String buildFileSize;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    buildBuildVersion: json["buildBuildVersion"],
    forceUpdateVersion: json["forceUpdateVersion"],
    forceUpdateVersionNo: json["forceUpdateVersionNo"],
    needForceUpdate: json["needForceUpdate"],
    downloadUrl: json["downloadURL"],
    buildHaveNewVersion: json["buildHaveNewVersion"],
    buildVersionNo: json["buildVersionNo"],
    buildVersion: json["buildVersion"],
    buildUpdateDescription: json["buildUpdateDescription"],
    appKey: json["appKey"],
    buildKey: json["buildKey"],
    buildName: json["buildName"],
    buildIcon: json["buildIcon"],
    buildFileKey: json["buildFileKey"],
    buildFileSize: json["buildFileSize"],
  );

  Map<String, dynamic> toJson() => {
    "buildBuildVersion": buildBuildVersion,
    "forceUpdateVersion": forceUpdateVersion,
    "forceUpdateVersionNo": forceUpdateVersionNo,
    "needForceUpdate": needForceUpdate,
    "downloadURL": downloadUrl,
    "buildHaveNewVersion": buildHaveNewVersion,
    "buildVersionNo": buildVersionNo,
    "buildVersion": buildVersion,
    "buildUpdateDescription": buildUpdateDescription,
    "appKey": appKey,
    "buildKey": buildKey,
    "buildName": buildName,
    "buildIcon": buildIcon,
    "buildFileKey": buildFileKey,
    "buildFileSize": buildFileSize,
  };
}
