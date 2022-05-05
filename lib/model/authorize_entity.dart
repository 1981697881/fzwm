// To parse this JSON data, do
//     final authorizeEntity = authorizeEntityFromJson(jsonString);
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:fzwm/http/api_response.dart';
import 'package:fzwm/http/httpUtils.dart';
import 'package:fzwm/server/api.dart';

AuthorizeEntity authorizeEntityFromJson(String str) => AuthorizeEntity.fromJson(json.decode(str));

String authorizeEntityToJson(AuthorizeEntity data) => json.encode(data.toJson());

class AuthorizeEntity {
  static Future<ApiResponse<AuthorizeEntity>> getAuthorize(Map<String, dynamic> map
      ) async {
    try {
      final response = await HttpUtils.post(API.AUTHORIZE_URL,data: map);
      final res = new Map<String, dynamic>.from(response);
      var data = AuthorizeEntity.fromJson(res);
      return ApiResponse.completed(data);
    } on DioError catch (e) {
      return ApiResponse.error(e.error);
    }
  }
  AuthorizeEntity({
    this.code,
    this.msg,
    this.success,
    this.data,
  });

  int code;
  dynamic msg;
  bool success;
  Data data;

  factory AuthorizeEntity.fromJson(Map<String, dynamic> json) => AuthorizeEntity(
    code: json["code"],
    msg: json["msg"],
    success: json["success"],
    data: Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "msg": msg,
    "success": success,
    "data": data.toJson(),
  };
}

class Data {
  Data({
    this.fid,
    this.fTargetKey,
    this.fSrvEDate,
    this.fCustName,
    this.fAuthList,
    this.fAuthSDate,
    this.furl,
    this.fCode,
    this.fPrjName,
    this.fPrjNo,
    this.fSrvPhone,
    this.fAuthEDate,
    this.fMessage,
    this.fPrjType,
    this.fAppSecret,
    this.fAppkey,
    this.fSrvSDate,
    this.fSupplier,
    this.fAuthNums,
    this.fStatus,
  });

  int fid;
  int fAuthNums;
  String fTargetKey;
  String fSrvEDate;
  String fCustName;
  String fAuthList;
  String fAuthSDate;
  String furl;
  String fCode;
  String fPrjName;
  String fPrjNo;
  String fSrvPhone;
  String fAuthEDate;
  String fMessage;
  String fPrjType;
  String fAppSecret;
  String fAppkey;
  String fSrvSDate;
  String fSupplier;
  String fStatus;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    fid: json["FID"],
    fTargetKey: json["FTargetKey"],
    fSrvEDate: json["FSrvEDate"],
    fCustName: json["FCustName"],
    fAuthList: json["FAuthList"],
    fAuthSDate: json["FAuthSDate"],
    furl: json["FURL"],
    fCode: json["FCode"],
    fPrjName: json["FPrjName"],
    fPrjNo: json["FPrjNo"],
    fSrvPhone: json["FSrvPhone"],
    fAuthEDate: json["FAuthEDate"],
    fMessage: json["FMessage"],
    fPrjType: json["FPrjType"],
    fAppSecret: json["FAppSecret"],
    fAppkey: json["FAppkey"],
    fSrvSDate: json["FSrvSDate"],
    fSupplier: json["FSupplier"],
    fStatus: json["FStatus"],
    fAuthNums: json["FAuthNums"],
  );

  Map<String, dynamic> toJson() => {
    "FID": fid,
    "FTargetKey": fTargetKey,
    "FSrvEDate": fSrvEDate,
    "FCustName": fCustName,
    "FAuthList": fAuthList,
    "FAuthSDate": fAuthSDate,
    "FURL": furl,
    "FCode": fCode,
    "FPrjName": fPrjName,
    "FPrjNo": fPrjNo,
    "FSrvPhone": fSrvPhone,
    "FAuthEDate": fAuthEDate,
    "FMessage": fMessage,
    "FPrjType": fPrjType,
    "FAppSecret": fAppSecret,
    "FAppkey": fAppkey,
    "FSrvSDate": fSrvSDate,
    "FSupplier": fSupplier,
    "FStatus": fStatus,
    "FAuthNums": fAuthNums,
  };
}
