import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:fzwm/model/currency_entity.dart';
import 'package:fzwm/model/submit_entity.dart';
import 'package:fzwm/utils/handler_order.dart';
import 'package:fzwm/utils/refresh_widget.dart';
import 'package:fzwm/utils/toast_util.dart';
import 'package:fzwm/views/login/login_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pickers/pickers.dart';
import 'package:flutter_pickers/style/default_style.dart';
import 'package:flutter_pickers/time_picker/model/date_mode.dart';
import 'package:flutter_pickers/time_picker/model/pduration.dart';
import 'package:flutter_pickers/time_picker/model/suffix.dart';
import 'dart:io';
import 'package:flutter_pickers/utils/check.dart';
import 'package:flutter/cupertino.dart';
import 'package:fzwm/components/my_text.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qrscan/qrscan.dart' as scanner;
final String _fontFamily = Platform.isWindows ? "Roboto" : "";

class ProductionReportDetail extends StatefulWidget {
  var FBillNo;

  ProductionReportDetail({Key ?key, @required this.FBillNo}) : super(key: key);

  @override
  _ReturnGoodsDetailState createState() => _ReturnGoodsDetailState(FBillNo);
}

class _ReturnGoodsDetailState extends State<ProductionReportDetail> {
  var _remarkContent = new TextEditingController();
  var _FVBMYContent = new TextEditingController();
  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();

  final _textNumber = TextEditingController();
  var checkItem;
  String FBillNo = '';
  String FSaleOrderNo = '';
  String FName = '';
  String FNumber = '';
  String supName = '';
  String jdh = '';
  String xlmc = '';
  String FDate = '';
  var supplierName;
  var supplierNumber;
  var typeName;
  var typeNumber;
  var qcName;
  var qcNumber;
  var businessTypeName;
  var businessTypeNumber;
  var departmentName;
  var departmentNumber;
  var show = false;
  var isSubmit = false;
  var isScanWork = false;
  var checkData;
  var fOrgID;
  var checkDataChild;
  var selectData = {
    DateMode.YMD: '',
  };
  var qcList = [];
  List<dynamic> qcListObj = [];
  var typeList = [];
  List<dynamic> typeListObj = [];
  var departmentList = [];
  List<dynamic> departmentListObj = [];
  var supplierList = [];
  List<dynamic> supplierListObj = [];
  var decisionList = [];
  List<dynamic> decisionListObj = [];
  var stockList = [];
  List<dynamic> stockListObj = [];
  List<dynamic> orderDate = [];
  List<dynamic> materialDate = [];
  final divider = Divider(height: 1, indent: 20);
  final rightIcon = Icon(Icons.keyboard_arrow_right);
  final scanIcon = Icon(Icons.filter_center_focus);
  static const scannerPlugin =
  const EventChannel('com.shinow.pda_scanner/plugin');
  StreamSubscription ?_subscription;
  var _code;
  var _FNumber;
  var fBillNo;
  var fBarCodeList;
  _ReturnGoodsDetailState(FBillNo) {
    if (FBillNo != null) {
      this.fBillNo = FBillNo['value'];
      this.getOrderList();
      isScanWork = true;
    } else {
      isScanWork = false;
      this.fBillNo = '';
      getStockList();
    }
  }

  @override
  void initState() {
    super.initState();

    DateTime dateTime = DateTime.now();
    var nowDate = "${dateTime.year}-${dateTime.month}-${dateTime.day}";
    selectData[DateMode.YMD] = nowDate;
    EasyLoading.dismiss();
    /// 开启监听
    if (_subscription == null) {
      _subscription = scannerPlugin
          .receiveBroadcastStream()
          .listen(_onEvent, onError: _onError);
    }
    /*getWorkShop();*/
    getDecisionList();
    getQcList();
    getDepartmentList();
  }
  //获取质检员
  getQcList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_Empinfo';
    userMap['FieldKeys'] = 'FId,FName,FNumber';
    userMap['FilterString'] = "FPost.FNumber ='GW000065'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    qcListObj = jsonDecode(res);
    qcListObj.forEach((element) {
      qcList.add(element[1]);
    });
  }
  //获取线路名称
  getTypeList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BOS_ASSISTANTDATA_DETAIL';
    userMap['FieldKeys'] = 'FId,FDataValue,FNumber';
    userMap['FilterString'] = "FId ='5fd715f4883532' and FForbidStatus='A'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    typeListObj = jsonDecode(res);
    typeListObj.forEach((element) {
      typeList.add(element[1]);
    });
  }
  //获取使用决策
  getDecisionList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BOS_EnumBill';
    userMap['FieldKeys'] = 'FName,FCategory,FValue,FCaption';
    userMap['FilterString'] = "FId ='a622a15f-c742-4143-8d02-f4d5b1a80a35'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    decisionListObj = jsonDecode(res);
    decisionListObj.forEach((element) {
      decisionList.add(element[3]);
    });
  }
  //获取部门
  getDepartmentList() async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');

    userMap['FormId'] = 'BD_Department';
    userMap['FilterString'] = "FUseOrgId.FNumber ='"+tissue+"'";
    userMap['FieldKeys'] = 'FUseOrgId,FName,FNumber';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    departmentListObj = jsonDecode(res);
    departmentListObj.forEach((element) {
      departmentList.add(element[1]);
    });
    setState(() {
      if(tissue == "101"){
        this.departmentName = "质检部";
        this.departmentNumber = "1010F";
      }else if(tissue == "102"){
        this.departmentName = "质检部";
        this.departmentNumber = "1010G";
      }
    });
  }
  //获取仓库
  getStockList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_STOCK';
    userMap['FieldKeys'] = 'FStockID,FName,FNumber,FIsOpenLocation';
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    userMap['FilterString'] = "FForbidStatus = 'A' and FUseOrgId.FNumber='"+tissue+"'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    stockListObj = jsonDecode(res);
    stockListObj.forEach((element) {
      stockList.add(element[1]);
    });
  }
  void getWorkShop() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      if (sharedPreferences.getString('FWorkShopName') != null) {
        FName = sharedPreferences.getString('FWorkShopName');
        FNumber = sharedPreferences.getString('FWorkShopNumber');
        isScanWork = true;
      } else {
        isScanWork = false;
      }
    });
  }

  @override
  void dispose() {
    this._textNumber.dispose();
    super.dispose();

    /// 取消监听
    if (_subscription != null) {
      _subscription!.cancel();
    }
  }

  // 查询数据集合
  List hobby = [];
  List fNumber = [];
  getOrderList() async {
    Map<String, dynamic> userMap = Map();
    print(fBillNo);
    userMap['FilterString'] = "FBillNo='$fBillNo'";
    userMap['FormId'] = 'PRD_MORPT';
    userMap['OrderString'] = 'FMaterialId.FNumber ASC';
    userMap['FieldKeys'] =
    'FBillNo,FPrdOrgId.FNumber,FPrdOrgId.FName,FDate,FMoBillNo,FEntity_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FWorkshipId.FNumber,FWorkshipId.FName,FUnitId.FNumber,FUnitId.FName,FFinishQty,FProduceDate,FExpiryDate,FSrcBillNo,FInspectQty,FID,FDocumentStatus,FStockId.FNumber,FStockId.FName,FStockInOrgId.FNumber,FMaterialId.FIsBatchManage,F_xlmc.FDataValue,F_jdh,FWorkshopId.FNumber,FLot.FNumber';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    orderDate = jsonDecode(order);
    FDate = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    if (orderDate.length > 0) {
      this.FBillNo = orderDate[0][0];
      this.fOrgID = orderDate[0][8];
      this.xlmc = orderDate[0][24];
      this.jdh = orderDate[0][25];
      hobby = [];
      orderDate.forEach((value) {
        fNumber.add(value[5]);
        List arr = [];
        arr.add({
          "title": "物料名称",
          "name": "FMaterial",
          "FID": value[18],
          "FEntryId": value[5],
          "FWorkshopId": value[26],
          "FLot": value[27],
          "isHide": false,
          "value": {"label": value[7] + "- (" + value[6] + ")", "value": value[6],"barcode": [],"kingDeeCode": [],"scanCode": []}
        });
        arr.add({
          "title": "规格型号",
          "isHide": false,
          "name": "FMaterialIdFSpecification",
          "value": {"label": value[8], "value": value[8]}
        });
        arr.add({
          "title": "单位名称",
          "name": "FUnitId",
          "isHide": false,
          "value": {"label": value[12], "value": value[11]}
        });
        arr.add({
          "title": "检验数量",
          "name": "FRealQty",
          "isHide": false,/*value[12]*/
          "value": {"label": ((value[13] - value[17])>0?value[13] - value[17]: 0).toString(), "value": ((value[13] - value[17])>0?value[13] - value[17]: 0).toString()}
        });
        arr.add({
          "title": "仓库",
          "name": "FStockID",
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "批号",
          "name": "FLot",
          "isHide": value[23] != true,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "仓位",
          "name": "FStockLocID",
          "isHide": false,
          "value": {"label": "", "value": "","hide": false}
        });
        arr.add({
          "title": "操作",
          "name": "",
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "库存单位",
          "name": "",
          "isHide": true,
          "value": {"label": value[12], "value": value[11]}
        });
        arr.add({
          "title": "剩余数量",
          "name": "",
          "isHide": false,
          "value": {
            "label": (value[13] - value[17])>0?value[13] - value[17]: 0,
            "value": (value[13] - value[17])>0?value[13] - value[17]: 0,
            "rateValue": (value[13] - value[17])>0?value[13] - value[17]: 0
          } /*+value[12]*0.1*/
        });
        arr.add({
          "title": "最后扫描数量",
          "name": "FLastQty",
          "isHide": true,
          "value": {
            "label": "0",
            "value": "0"
          }
        });
        arr.add({
          "title": "检验结果",
          "name": "FLastQty",
          "isHide": false,
          "value": {"label": true, "value": true}
        });
        arr.add({
          "title": "决策",
          "name": "FLastQty",
          "isHide": false,
          "value": {"label": "接收", "value": "A"}
        });
        arr.add({
          "title": "样本破坏数",
          "name": "FSampleDamageQty",
          "isHide": false,
          "value": {"label": "0", "value": "0"}
        });
        hobby.add(arr);
      });
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
      });
    } else {
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
      });
      ToastUtil.showInfo('无数据');
    }
    getStockList();
    /*_onEvent("68051032538-20230505-202305050080");*/
    /*_onEvent("@XJVZfEm+p8scb8gUJ5GdUX4bjgAdBc4iTucsyAUNYevlGnI5U2QVojk3pXGkrpC");*/
  }

  void _onEvent(event) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var deptData = sharedPreferences.getString('menuList');
    var menuList = new Map<dynamic, dynamic>.from(jsonDecode(deptData));
    fBarCodeList = menuList['FBarCodeList'];
    if(event == ""){
      return;
    }
    if (fBarCodeList == 1) {
      if(event.split('-').length>2){
        getMaterialListT(event,event.split('-')[2]);
      }else{
        if(event.length>15){
          Map<String, dynamic> barcodeMap = Map();
          barcodeMap['FilterString'] = "FBarCodeEn='" + event + "'";
          barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
          barcodeMap['FieldKeys'] =
          'FID,FInQtyTotal,FOutQtyTotal,FEntity_FEntryId,FRemainQty,FBarCodeQty,FStockID.FName,FStockID.FNumber,FMATERIALID.FNUMBER,FOwnerID.FNumber,FBarCode,FSN';
          Map<String, dynamic> dataMap = Map();
          dataMap['data'] = barcodeMap;
          String order = await CurrencyEntity.polling(dataMap);
          var barcodeData = jsonDecode(order);
          if (barcodeData.length > 0) {
            if (barcodeData[0][4] > 0) {
              var msg = "";
              var orderIndex = 0;
              for (var value in orderDate) {
                if(value[5] == barcodeData[0][8]){
                  msg = "";
                  if(fNumber.lastIndexOf(barcodeData[0][8])  == orderIndex){
                    break;
                  }
                }else{
                  msg = '条码不在单据物料中';
                }
                orderIndex++;
              };
              if(msg ==  ""){
                _code = event;
                this.getMaterialList(barcodeData, barcodeData[0][10], barcodeData[0][11]);
                print("ChannelPage: $event");
              }else{
                ToastUtil.showInfo(msg);
              }
            } else {
              ToastUtil.showInfo('该条码已出库或没入库，数量为零');
            }
          } else {
            ToastUtil.showInfo('条码不在条码清单中');
          }
        }else{
          getMaterialListTH(event,event.substring(9,15));
        }
      }
    } else {
      _code = event;
      this.getMaterialList("", _code,"");
      print("ChannelPage: $event");
    }
    print("ChannelPage: $event");
  }

  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
  }
  getMaterialList(barcodeData,code, fsn) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    var scanCode = code.split(";");
    userMap['FilterString'] = "FNumber='"+barcodeData[0][8]+"' and FForbidStatus = 'A' and FUseOrgId.FNumber = '"+tissue+"'";
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
    'FMATERIALID,FName,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage';/*,SubHeadEntity1.FStoreUnitID.FNumber*/
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    materialDate = [];
    materialDate = jsonDecode(order);
    FDate = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    if (materialDate.length > 0) {
      var number = 0;
      var barCodeScan;
      if(fBarCodeList == 1){
        barCodeScan = barcodeData[0];
        barCodeScan[4] = barCodeScan[4].toString();
      }else{
        barCodeScan = scanCode;
      }
      var barcodeNum = scanCode[3];
      for (var element in hobby) {
        var residue = 0.0;
        //判断是否启用批号
        if(element[5]['isHide']){//不启用
          if(element[0]['value']['value'] == scanCode[0]){
            if(element[0]['value']['barcode'].indexOf(code) == -1){
              if(scanCode.length>4) {
                element[0]['value']['barcode'].add(code);
              }
              if(scanCode[5] == "N" ){
                if(element[0]['value']['scanCode'].indexOf(code) == -1){
                  element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                  element[3]['value']['value']=element[3]['value']['label'];
                  var item =barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                  element[0]['value']['kingDeeCode'].add(item);
                  element[0]['value']['scanCode'].add(code);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                }
                break;
              }
              //判断扫描数量是否大于单据数量
              if(double.parse(element[3]['value']['label']) >= element[9]['value']['rateValue']) {
                continue;
              }else {
                //判断条码数量
                if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                  if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) >= element[9]['value']['rateValue']){
                    //判断条码是否重复
                    if(element[0]['value']['scanCode'].indexOf(code) == -1){
                      var item = barCodeScan[0].toString()+"-"+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['label'])).toStringAsFixed(2).toString() + "-" + fsn;
                      element[10]['value']['label'] =(element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                      element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                      barcodeNum = (double.parse(barcodeNum) - (element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                      element[3]['value']['label']=(double.parse(element[3]['value']['label'])+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                      element[3]['value']['value']=element[3]['value']['label'];
                      residue = element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']);
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                    }
                  }else{//数量不超出
                    //判断条码是否重复
                    if(element[0]['value']['scanCode'].indexOf(code) == -1){
                      element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                      element[3]['value']['value']=element[3]['value']['label'];
                      var item =barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                      element[10]['value']['label'] =barcodeNum.toString();
                      element[10]['value']['value'] = barcodeNum.toString();
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                      barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                    }
                  }
                }
              }
            }else{
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        }else{
          //启用批号
          if(element[0]['value']['value'] == scanCode[0]){
            if(element[0]['value']['barcode'].indexOf(code) == -1){
              if(scanCode.length>4) {
                element[0]['value']['barcode'].add(code);
              }
              if(scanCode[5] == "N" ){
                if(element[0]['value']['scanCode'].indexOf(code) == -1){
                  if(element[5]['value']['value'] == "") {
                    element[5]['value']['label'] = scanCode[1];
                    element[5]['value']['value'] = scanCode[1];
                  }
                  element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                  element[3]['value']['value']=element[3]['value']['label'];
                  var item =barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                  element[0]['value']['kingDeeCode'].add(item);
                  element[0]['value']['scanCode'].add(code);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                }
                break;
              }
              if(element[5]['value']['value'] == scanCode[1]){
                //判断扫描数量是否大于单据数量
                if(double.parse(element[3]['value']['label']) >= element[9]['value']['rateValue']) {
                  continue;
                }else {
                  //判断条码数量
                  if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                    if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) >= element[9]['value']['rateValue']){
                      //判断条码是否重复
                      if(element[0]['value']['scanCode'].indexOf(code) == -1){
                        var item = barCodeScan[0].toString()+"-"+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['label'])).toStringAsFixed(2).toString() + "-" + fsn;
                        element[10]['value']['label'] =(element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                        element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                        barcodeNum = (double.parse(barcodeNum) - (element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                        element[3]['value']['label']=(double.parse(element[3]['value']['label'])+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                        element[3]['value']['value']=element[3]['value']['label'];
                        residue = element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']);
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                      }
                    }else{//数量不超出
                      //判断条码是否重复
                      if(element[0]['value']['scanCode'].indexOf(code) == -1){
                        element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                        element[3]['value']['value']=element[3]['value']['label'];
                        var item =barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                        element[10]['value']['label'] =barcodeNum.toString();
                        element[10]['value']['value'] = barcodeNum.toString();
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                        barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                      }
                    }
                  }
                }
              }else{
                if(element[5]['value']['value'] == ""){
                  element[5]['value']['label'] = scanCode[1];
                  element[5]['value']['value'] = scanCode[1];
                  //判断扫描数量是否大于单据数量
                  if(double.parse(element[3]['value']['label']) >= element[9]['value']['rateValue']) {
                    continue;
                  }else {
                    //判断条码数量
                    if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                      if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) >= element[9]['value']['rateValue']){
                        //判断条码是否重复
                        if(element[0]['value']['scanCode'].indexOf(code) == -1){
                          var item = barCodeScan[0].toString()+"-"+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['label'])).toStringAsFixed(2).toString() + "-" + fsn;
                          element[10]['value']['label'] =(element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                          element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                          barcodeNum = (double.parse(barcodeNum) - (element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                          element[3]['value']['label']=(double.parse(element[3]['value']['label'])+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                          element[3]['value']['value']=element[3]['value']['label'];
                          residue = element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']);
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                        }
                      }else{//数量不超出
                        //判断条码是否重复
                        if(element[0]['value']['scanCode'].indexOf(code) == -1){
                          element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                          element[3]['value']['value']=element[3]['value']['label'];
                          var item =barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                          element[10]['value']['label'] =barcodeNum.toString();
                          element[10]['value']['value'] = barcodeNum.toString();
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                          barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                        }
                      }
                    }
                  }
                }
              }
            }else{
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        }
      }
      setState(() {
        EasyLoading.dismiss();
      });
    } else {
      setState(() {
        EasyLoading.dismiss();
      });
      ToastUtil.showInfo('无数据');
    }
  }
  getMaterialListT(code, fsn) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');

    userMap['FilterString'] = "F_UYEP_GYSTM='"+code.split('-')[0]+"' and FForbidStatus = 'A' and FUseOrgId.FNumber = '"+tissue+"'";
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
    'FMATERIALID,FName,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage';/*,SubHeadEntity1.FStoreUnitID.FNumber*/
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    materialDate = [];
    materialDate = jsonDecode(order);
    var scanCode = [materialDate[0][2],code.split("-")[1],"","","","N"];
    FDate = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    if (materialDate.length > 0) {
      var number = 0;
      var msg = "";
      var orderIndex = 0;
      for (var value in orderDate) {
        if(value[5] == materialDate[0][2]){
          msg = "";
          if(fNumber.lastIndexOf(materialDate[0][2])  == orderIndex){
            break;
          }
        }else{
          msg = '条码不在单据物料中';
        }
        orderIndex++;
      };
      if(msg !=  ""){
        ToastUtil.showInfo(msg);
        return;
      }
      var barcodeNum = '1';
      for (var element in hobby) {
        var residue = 0.0;
        //判断是否启用批号
        if(element[5]['isHide']){//不启用
          if(element[0]['value']['value'] == scanCode[0]){
            if(element[0]['value']['barcode'].indexOf(code) == -1){
              if(scanCode.length>4) {
                element[0]['value']['barcode'].add(code);
              }
              if(scanCode[5] == "N" ){
                if(element[0]['value']['scanCode'].indexOf(code) == -1){
                  element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                  element[3]['value']['value']=element[3]['value']['label'];
                  element[0]['value']['scanCode'].add(code);
                  element[0]['value']['kingDeeCode'].add(fsn);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                }
                break;
              }
              //判断扫描数量是否大于单据数量
              if(double.parse(element[3]['value']['label']) >= element[9]['value']['rateValue']) {
                continue;
              }else {
                //判断条码数量
                if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                  if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) >= element[9]['value']['rateValue']){
                    //判断条码是否重复
                    if(element[0]['value']['scanCode'].indexOf(code) == -1){
                      element[10]['value']['label'] =(element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                      element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                      barcodeNum = (double.parse(barcodeNum) - (element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                      element[3]['value']['label']=(double.parse(element[3]['value']['label'])+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                      element[3]['value']['value']=element[3]['value']['label'];
                      residue = element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']);
                      element[0]['value']['scanCode'].add(code);
                      element[0]['value']['kingDeeCode'].add(fsn);
                    }
                  }else{//数量不超出
                    //判断条码是否重复
                    if(element[0]['value']['scanCode'].indexOf(code) == -1){
                      element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                      element[3]['value']['value']=element[3]['value']['label'];
                      element[10]['value']['label'] =barcodeNum.toString();
                      element[10]['value']['value'] = barcodeNum.toString();
                      element[0]['value']['scanCode'].add(code);
                      element[0]['value']['kingDeeCode'].add(fsn);
                      barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                    }
                  }
                }
              }
            }else{
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        }else{
          //启用批号
          if(element[0]['value']['value'] == scanCode[0]){
            if(element[0]['value']['barcode'].indexOf(code) == -1){
              if(scanCode.length>4) {
                element[0]['value']['barcode'].add(code);
              }
              if(scanCode[5] == "N" ){
                if(element[0]['value']['scanCode'].indexOf(code) == -1){
                  if(element[5]['value']['value'] == "") {
                    element[5]['value']['label'] = scanCode[1];
                    element[5]['value']['value'] = scanCode[1];
                  }
                  element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                  element[3]['value']['value']=element[3]['value']['label'];
                  element[0]['value']['scanCode'].add(code);
                  element[0]['value']['kingDeeCode'].add(fsn);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                }
                break;
              }
              if(element[5]['value']['value'] == scanCode[1]){
                //判断扫描数量是否大于单据数量
                if(double.parse(element[3]['value']['label']) >= element[9]['value']['rateValue']) {
                  continue;
                }else {
                  //判断条码数量
                  if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                    if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) >= element[9]['value']['rateValue']){
                      //判断条码是否重复
                      if(element[0]['value']['scanCode'].indexOf(code) == -1){
                        element[10]['value']['label'] =(element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                        element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                        barcodeNum = (double.parse(barcodeNum) - (element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                        element[3]['value']['label']=(double.parse(element[3]['value']['label'])+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                        element[3]['value']['value']=element[3]['value']['label'];
                        residue = element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']);
                        element[0]['value']['scanCode'].add(code);
                        element[0]['value']['kingDeeCode'].add(fsn);
                      }
                    }else{//数量不超出
                      //判断条码是否重复
                      if(element[0]['value']['scanCode'].indexOf(code) == -1){
                        element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                        element[3]['value']['value']=element[3]['value']['label'];
                        element[10]['value']['label'] =barcodeNum.toString();
                        element[10]['value']['value'] = barcodeNum.toString();
                        element[0]['value']['scanCode'].add(code);
                        element[0]['value']['kingDeeCode'].add(fsn);
                        barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                      }
                    }
                  }
                }
              }else{
                if(element[5]['value']['value'] == ""){
                  element[5]['value']['label'] = scanCode[1];
                  element[5]['value']['value'] = scanCode[1];
                  //判断扫描数量是否大于单据数量
                  if(double.parse(element[3]['value']['label']) >= element[9]['value']['rateValue']) {
                    continue;
                  }else {
                    //判断条码数量
                    if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                      if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) >= element[9]['value']['rateValue']){
                        //判断条码是否重复
                        if(element[0]['value']['scanCode'].indexOf(code) == -1){
                          element[10]['value']['label'] =(element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                          element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                          barcodeNum = (double.parse(barcodeNum) - (element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                          element[3]['value']['label']=(double.parse(element[3]['value']['label'])+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                          element[3]['value']['value']=element[3]['value']['label'];
                          residue = element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']);
                          element[0]['value']['scanCode'].add(code);
                          element[0]['value']['kingDeeCode'].add(fsn);
                        }
                      }else{//数量不超出
                        //判断条码是否重复
                        if(element[0]['value']['scanCode'].indexOf(code) == -1){
                          element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                          element[3]['value']['value']=element[3]['value']['label'];
                          element[10]['value']['label'] =barcodeNum.toString();
                          element[10]['value']['value'] = barcodeNum.toString();
                          element[0]['value']['scanCode'].add(code);
                          element[0]['value']['kingDeeCode'].add(fsn);
                          barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                        }
                      }
                    }
                  }
                }
              }
            }else{
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        }
      }
      setState(() {
        EasyLoading.dismiss();
      });
    } else {
      setState(() {
        EasyLoading.dismiss();
      });
      ToastUtil.showInfo('无数据');
    }
  }
  getMaterialListTH(code, fsn) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');

    userMap['FilterString'] = "F_UYEP_GYSTM='"+code.substring(0,3)+"' and FForbidStatus = 'A' and FUseOrgId.FNumber = '"+tissue+"'";
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
    'FMATERIALID,FName,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage';/*,SubHeadEntity1.FStoreUnitID.FNumber*/
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    materialDate = [];
    materialDate = jsonDecode(order);
    var scanCode = [materialDate[0][2],code.substring(3,9),"","","","N"];
    FDate = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    if (materialDate.length > 0) {
      var number = 0;
      var msg = "";
      var orderIndex = 0;
      for (var value in orderDate) {
        if(value[5] == materialDate[0][2]){
          msg = "";
          if(fNumber.lastIndexOf(materialDate[0][2])  == orderIndex){
            break;
          }
        }else{
          msg = '条码不在单据物料中';
        }
        orderIndex++;
      };
      if(msg !=  ""){
        ToastUtil.showInfo(msg);
        return;
      }
      var barcodeNum = '1';
      for (var element in hobby) {
        var residue = 0.0;
        //判断是否启用批号
        if(element[5]['isHide']){//不启用
          if(element[0]['value']['value'] == scanCode[0]){
            if(element[0]['value']['barcode'].indexOf(code) == -1){
              if(scanCode.length>4) {
                element[0]['value']['barcode'].add(code);
              }
              if(scanCode[5] == "N" ){
                if(element[0]['value']['scanCode'].indexOf(code) == -1){
                  element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                  element[3]['value']['value']=element[3]['value']['label'];
                  element[0]['value']['scanCode'].add(code);
                  element[0]['value']['kingDeeCode'].add(fsn);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                }
                break;
              }
              //判断扫描数量是否大于单据数量
              if(double.parse(element[3]['value']['label']) >= element[9]['value']['rateValue']) {
                continue;
              }else {
                //判断条码数量
                if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                  if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) >= element[9]['value']['rateValue']){
                    //判断条码是否重复
                    if(element[0]['value']['scanCode'].indexOf(code) == -1){
                      element[10]['value']['label'] =(element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                      element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                      barcodeNum = (double.parse(barcodeNum) - (element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                      element[3]['value']['label']=(double.parse(element[3]['value']['label'])+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                      element[3]['value']['value']=element[3]['value']['label'];
                      residue = element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']);
                      element[0]['value']['scanCode'].add(code);
                      element[0]['value']['kingDeeCode'].add(fsn);
                    }
                  }else{//数量不超出
                    //判断条码是否重复
                    if(element[0]['value']['scanCode'].indexOf(code) == -1){
                      element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                      element[3]['value']['value']=element[3]['value']['label'];
                      element[10]['value']['label'] =barcodeNum.toString();
                      element[10]['value']['value'] = barcodeNum.toString();
                      element[0]['value']['scanCode'].add(code);
                      element[0]['value']['kingDeeCode'].add(fsn);
                      barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                    }
                  }
                }
              }
            }else{
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        }else{
          //启用批号
          if(element[0]['value']['value'] == scanCode[0]){
            if(element[0]['value']['barcode'].indexOf(code) == -1){
              if(scanCode.length>4) {
                element[0]['value']['barcode'].add(code);
              }
              if(scanCode[5] == "N" ){
                if(element[0]['value']['scanCode'].indexOf(code) == -1){
                  if(element[5]['value']['value'] == "") {
                    element[5]['value']['label'] = scanCode[1];
                    element[5]['value']['value'] = scanCode[1];
                  }
                  element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                  element[3]['value']['value']=element[3]['value']['label'];
                  element[0]['value']['scanCode'].add(code);
                  element[0]['value']['kingDeeCode'].add(fsn);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                }
                break;
              }
              if(element[5]['value']['value'] == scanCode[1]){
                //判断扫描数量是否大于单据数量
                if(double.parse(element[3]['value']['label']) >= element[9]['value']['rateValue']) {
                  continue;
                }else {
                  //判断条码数量
                  if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                    if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) >= element[9]['value']['rateValue']){
                      //判断条码是否重复
                      if(element[0]['value']['scanCode'].indexOf(code) == -1){
                        element[10]['value']['label'] =(element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                        element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                        barcodeNum = (double.parse(barcodeNum) - (element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                        element[3]['value']['label']=(double.parse(element[3]['value']['label'])+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                        element[3]['value']['value']=element[3]['value']['label'];
                        residue = element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']);
                        element[0]['value']['scanCode'].add(code);
                        element[0]['value']['kingDeeCode'].add(fsn);
                      }
                    }else{//数量不超出
                      //判断条码是否重复
                      if(element[0]['value']['scanCode'].indexOf(code) == -1){
                        element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                        element[3]['value']['value']=element[3]['value']['label'];
                        element[10]['value']['label'] =barcodeNum.toString();
                        element[10]['value']['value'] = barcodeNum.toString();
                        element[0]['value']['scanCode'].add(code);
                        element[0]['value']['kingDeeCode'].add(fsn);
                        barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                      }
                    }
                  }
                }
              }else{
                if(element[5]['value']['value'] == ""){
                  element[5]['value']['label'] = scanCode[1];
                  element[5]['value']['value'] = scanCode[1];
                  //判断扫描数量是否大于单据数量
                  if(double.parse(element[3]['value']['label']) >= element[9]['value']['rateValue']) {
                    continue;
                  }else {
                    //判断条码数量
                    if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) > 0 && double.parse(barcodeNum)>0){
                      if((double.parse(element[3]['value']['label'])+double.parse(barcodeNum)) >= element[9]['value']['rateValue']){
                        //判断条码是否重复
                        if(element[0]['value']['scanCode'].indexOf(code) == -1){
                          element[10]['value']['label'] =(element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                          element[10]['value']['value'] = (element[9]['value']['label'] - double.parse(element[3]['value']['label'])).toString();
                          barcodeNum = (double.parse(barcodeNum) - (element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                          element[3]['value']['label']=(double.parse(element[3]['value']['label'])+(element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']))).toString();
                          element[3]['value']['value']=element[3]['value']['label'];
                          residue = element[9]['value']['rateValue'] - double.parse(element[3]['value']['label']);
                          element[0]['value']['scanCode'].add(code);
                          element[0]['value']['kingDeeCode'].add(fsn);
                        }
                      }else{//数量不超出
                        //判断条码是否重复
                        if(element[0]['value']['scanCode'].indexOf(code) == -1){
                          element[3]['value']['label']=(double.parse(element[3]['value']['label'])+double.parse(barcodeNum)).toString();
                          element[3]['value']['value']=element[3]['value']['label'];
                          element[10]['value']['label'] =barcodeNum.toString();
                          element[10]['value']['value'] = barcodeNum.toString();
                          element[0]['value']['scanCode'].add(code);
                          element[0]['value']['kingDeeCode'].add(fsn);
                          barcodeNum = (double.parse(barcodeNum) - double.parse(barcodeNum)).toString();
                        }
                      }
                    }
                  }
                }
              }
            }else{
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        }
      }
      setState(() {
        EasyLoading.dismiss();
      });
    } else {
      setState(() {
        EasyLoading.dismiss();
      });
      ToastUtil.showInfo('无数据');
    }
  }

  Widget _item(title, var data, selectData, hobby, {String ?label,var stock}) {
    if (selectData == null) {
      selectData = "";
    }
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: ListTile(
            title: Text(title),
            onTap: () => data.length>0?_onClickItem(data, selectData, hobby, label: label,stock: stock):{ToastUtil.showInfo('无数据')},
            trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              MyText(selectData.toString()=="" ? '暂无':selectData.toString(),
                  color: Colors.grey, rightpadding: 18),
              rightIcon
            ]),
          ),
        ),
        divider,
      ],
    );
  }

  Widget _dateItem(title, model) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: ListTile(
            title: Text(title),
            onTap: () {
              _onDateClickItem(model);
            },
            trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              /*PartRefreshWidget(globalKey, () {*/
              //2、使用 创建一个widget
              /*return*/ MyText(
                  (PicketUtil.strEmpty(selectData[model])
                      ? '暂无'
                      : selectData[model])!,
                  color: Colors.grey,
                  rightpadding: 18),
              /* }),*/
              rightIcon
            ]),
          ),
        ),
        divider,
      ],
    );
  }

  void _onDateClickItem(model) {
    Pickers.showDatePicker(
      context,
      mode: model,
      suffix: Suffix.normal(),
      // selectDate: PDuration(month: 2),
      minDate: PDuration(year: 2020, month: 2, day: 10),
      maxDate: PDuration(second: 22),
      selectDate: (FDate == '' || FDate == null
          ? PDuration(year: 2021, month: 2, day: 10)
          : PDuration.parse(DateTime.parse(FDate))),
      // minDate: PDuration(hour: 12, minute: 38, second: 3),
      // maxDate: PDuration(hour: 12, minute: 40, second: 36),
      onConfirm: (p) {
        print('longer >>> 返回数据：$p');
        setState(() {
          switch (model) {
            case DateMode.YMD:
              Map<String, dynamic> userMap = Map();
              selectData[model] = formatDate(DateFormat('yyyy-MM-dd').parse('${p.year}-${p.month}-${p.day}'), [yyyy, "-", mm, "-", dd,]);
              FDate = formatDate(DateFormat('yyyy-MM-dd').parse('${p.year}-${p.month}-${p.day}'), [yyyy, "-", mm, "-", dd,]);
              break;
          }
        });
      },
      // onChanged: (p) => print(p),
    );
  }

  void _onClickItem(var data, var selectData, hobby, {String ?label,var stock}) {
    Pickers.showSinglePicker(
      context,
      data: data,
      selectData: selectData,
      pickerStyle: DefaultPickerStyle(),
      suffix: label,
      onConfirm: (p) {
        print('longer >>> 返回数据：$p');
        print('longer >>> 返回数据类型：${p.runtimeType}');
        setState(() {
          if(hobby  == 'supplier'){
            supplierName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                supplierNumber = supplierListObj[elementIndex][2];
              }
              elementIndex++;
            });
          }else if(hobby  == 'department'){
            departmentName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                departmentNumber = departmentListObj[elementIndex][2];
              }
              elementIndex++;
            });
          }else if(hobby  == 'qc'){
            qcName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                qcNumber = qcListObj[elementIndex][2];
              }
              elementIndex++;
            });
          }else if(hobby['title']  == '决策'){
            setState(() {
              hobby['value']['label'] = p;
            });
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                hobby['value']['value'] = decisionListObj[elementIndex][2];
              }
              elementIndex++;
            });
          } else{
            setState(() {
              hobby['value']['label'] = p;
            });
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                hobby['value']['value'] = stockListObj[elementIndex][2];
                stock[6]['value']['hide'] = stockListObj[elementIndex][3];
              }
              elementIndex++;
            });
          }
        });
      },
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          return new Scaffold(
            appBar: new AppBar(
              title: new Text('系统设置'),
              centerTitle: true,
              leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: (){
                Navigator.of(context).pop("refresh");
              }),
            ),
            body: new ListView(padding: EdgeInsets.all(10), children: <Widget>[
              /* ListTile(
                leading: Icon(Icons.search),
                title: Text('版本信息'),
              ),
              Divider(
                height: 10.0,
                indent: 0.0,
                color: Colors.grey,
              ),*/
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('退出登录'),
                onTap: () async {
                  SharedPreferences prefs =
                  await SharedPreferences.getInstance();
                  prefs.clear();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return LoginPage();
                      },
                    ),
                  );
                },
              ),
              Divider(
                height: 10.0,
                indent: 0.0,
                color: Colors.grey,
              ),
            ]),
          );
        },
      ),
    );
  }

  List<Widget> _getHobby() {
    List<Widget> tempList = [];
    for (int i = 0; i < this.hobby.length; i++) {
      List<Widget> comList = [];
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (!this.hobby[i][j]['isHide']) {
          /*if (j == 8 || j == 11) {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                      title: Text(this.hobby[i][j]["title"] +
                          '：' +
                          this.hobby[i][j]["value"]["label"].toString()),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: new Icon(Icons.filter_center_focus),
                              tooltip: '点击扫描',
                              onPressed: () {
                                this._textNumber.text =
                                this.hobby[i][j]["value"]["label"];
                                this._FNumber =
                                this.hobby[i][j]["value"]["label"];
                                checkData = i;
                                checkDataChild = j;
                                scanDialog();
                                if (this.hobby[i][j]["value"]["label"] != 0) {
                                  this._textNumber.value =
                                      _textNumber.value.copyWith(
                                        text: this.hobby[i][j]["value"]["label"],
                                      );
                                }
                              },
                            ),
                          ])),
                ),
                divider,
              ]),
            );
          } else*/ if (j == 4) {
            comList.add(
              _item('仓库:', stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],stock:this.hobby[i]),
            );
          }else if (j == 3 || j == 13) {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                      title: Text(this.hobby[i][j]["title"] +
                          '：' +
                          this.hobby[i][j]["value"]["label"].toString()),
                      trailing:
                      Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        IconButton(
                          icon: new Icon(Icons.filter_center_focus),
                          tooltip: '点击扫描',
                          onPressed: () {
                            this._textNumber.text =
                                this.hobby[i][j]["value"]["label"].toString();
                            this._FNumber =
                                this.hobby[i][j]["value"]["label"].toString();
                            checkItem = 'FNumber';
                            this.show = false;
                            checkData = i;
                            checkDataChild = j;
                            scanDialog();
                            print(this.hobby[i][j]["value"]["label"]);
                            if (this.hobby[i][j]["value"]["label"] != 0) {
                              this._textNumber.value = _textNumber.value.copyWith(
                                text:
                                this.hobby[i][j]["value"]["label"].toString(),
                              );
                            }
                          },
                        ),
                      ])),
                ),
                divider,
              ]),
            );
          }else if (j == 6) {
            comList.add(
              Visibility(
                maintainSize: false,
                maintainState: false,
                maintainAnimation: false,
                visible: this.hobby[i][j]["value"]["hide"],
                child: Column(children: [
                  Container(
                    color: Colors.white,
                    child: ListTile(
                        title: Text(this.hobby[i][j]["title"] +
                            '：' +
                            this.hobby[i][j]["value"]["label"].toString()),
                        trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                icon: new Icon(Icons.filter_center_focus),
                                tooltip: '点击扫描',
                                onPressed: () {
                                  this._textNumber.text = this
                                      .hobby[i][j]["value"]["label"]
                                      .toString();
                                  this._FNumber = this
                                      .hobby[i][j]["value"]["label"]
                                      .toString();
                                  checkItem = 'position';
                                  this.show = false;
                                  checkData = i;
                                  checkDataChild = j;
                                  scanDialog();
                                  print(this.hobby[i][j]["value"]["label"]);
                                  if (this.hobby[i][j]["value"]["label"] != 0) {
                                    this._textNumber.value =
                                        _textNumber.value.copyWith(
                                          text: this
                                              .hobby[i][j]["value"]["label"]
                                              .toString(),
                                        );
                                  }
                                },
                              ),
                            ])),
                  ),
                  divider,
                ]),
              ),
            );
          }else if (j == 7) {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                      title: Text(this.hobby[i][j]["title"] +
                          '：' +
                          this.hobby[i][j]["value"]["label"].toString()),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            new FlatButton(
                              color: Colors.red,
                              textColor: Colors.white,
                              child: new Text('删除'),
                              onPressed: () {
                                this.hobby.removeAt(i);
                                setState(() {});
                              },
                            )
                          ])),
                ),
                divider,
              ]),
            );
          }else if (j == 11) {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(this.hobby[i][j]["title"]+":"),
                    trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Checkbox(
                            value: this.hobby[i][j]["value"]["value"], // 当前复选框的值，表示是否选中
                            onChanged: (bool? newValue) {
                              setState(() {
                                this.hobby[i][j]["value"]["value"] = newValue!;
                              });
                            },
                          ),
                        ]),
                  ),
                ),
                divider,
              ]),
            );
          }else if (j == 12) {
            comList.add(
              _item(this.hobby[i][j]['title'], decisionList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],stock:this.hobby[i]),
            );
          } else {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(this.hobby[i][j]["title"] +
                        '：' +
                        this.hobby[i][j]["value"]["label"].toString()),
                    trailing:
                    Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      /* MyText(orderDate[i][j],
                        color: Colors.grey, rightpadding: 18),*/
                    ]),
                  ),
                ),
                divider,
              ]),
            );
          }
        }
      }
      tempList.add(
        SizedBox(height: 10),
      );
      tempList.add(
        Column(
          children: comList,
        ),
      );
    }
    return tempList;
  }

  //调出弹窗 扫码
  void scanDialog() {
    showDialog<Widget>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              color: Colors.white,
              child: Column(
                children: <Widget>[
                  /*  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('输入数量',
                        style: TextStyle(
                            fontSize: 16, decoration: TextDecoration.none)),
                  ),*/
                  Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Card(
                          child: Column(children: <Widget>[
                            TextField(
                              style: TextStyle(color: Colors.black87),
                              keyboardType: TextInputType.number,
                              controller: this._textNumber,
                              decoration: InputDecoration(hintText: "输入"),
                              onChanged: (value) {
                                setState(() {
                                  this._FNumber = value;
                                });
                              },
                            ),
                          ]))),
                  Padding(
                    padding: EdgeInsets.only(top: 15, bottom: 8),
                    child: FlatButton(
                        color: Colors.grey[100],
                        onPressed: () {
                          // 关闭 Dialog
                          Navigator.pop(context);
                          setState(() {
                            this.hobby[checkData][checkDataChild]["value"]
                            ["label"] = _FNumber;
                            this.hobby[checkData][checkDataChild]['value']
                            ["value"] = _FNumber;
                          });
                        },
                        child: Text(
                          '确定',
                        )),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    ).then((val) {
      print(val);
    });
  }
  pushDown(val, type) async {
    //下推
    Map<String, dynamic> pushMap = Map();
    pushMap['EntryIds'] = val;
    pushMap['RuleId'] = "OM_PRDMoRpt2Inspect";
    pushMap['TargetFormId'] = "QM_InspectBill";
    pushMap['IsEnableDefaultRule'] = "true";
    pushMap['IsDraftWhenSaveFail'] = "true";
    var pushData = jsonEncode(pushMap);
    var downData = await SubmitEntity.pushDown(
        {"formid": "PRD_MORPT", "data": pushMap});
    var res = jsonDecode(downData);
    print(res);
    //判断成功
    if (res['Result']['ResponseStatus']['IsSuccess']) {
      //查询下推单据
      var entitysNumber =
      res['Result']['ResponseStatus']['SuccessEntitys'][0]['Number'];
      Map<String, dynamic> inOrderMap = Map();
      inOrderMap['FormId'] = 'QM_InspectBill';
      inOrderMap['FilterString'] = "FBillNo='$entitysNumber'";
      inOrderMap['FieldKeys'] =
      'FEntity_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FUnitId.FNumber';
      String order = await CurrencyEntity.polling({'data': inOrderMap});
      print(order);
      var resData = jsonDecode(order);
      //组装数据
      Map<String, dynamic> dataMap = Map();
      dataMap['data'] = inOrderMap;
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedUpDataFields'] = [];
      orderMap['IsDeleteEntry'] = true;
      Map<String, dynamic> Model = Map();
      Model['FID'] = res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id'];
      Model['FBusinessType'] = "3";
      Model['FInspectDepId'] = {"FNumber": this.departmentNumber};
      Model['FInspectorId'] = {"FNumber": qcNumber};
      var FEntity = [];
      for (int entity = 0; entity < resData.length; entity++) {
        for (int element = 0; element < this.hobby.length; element++) {
          if (resData[entity][1].toString() ==
              this.hobby[element][0]['value']['value'].toString()) {
            Map<String, dynamic> FEntityItem = Map();
            var FPolicyDetail = [];
            Map<String, dynamic> FPolicyDetailItem = Map();
            FEntityItem['FEntryID'] = resData[entity][0];
            FEntityItem['FStockId'] = {"FNumber": this.hobby[element][4]['value']['value']};
            if(this.hobby[element][6]['value']['hide']){
              FEntityItem['FStockLocId'] = {
                "FSTOCKLOCID__FF100011": {"FNumber": this.hobby[element][6]['value']['value']}
              };
            }
            /*FEntityItem['FQCBusinessType'] = this.businessTypeNumber;
            FEntityItem['FInspectTimes'] = "1";
            FEntityItem['FQCStatus'] = "3";
            FEntityItem['FInspectStartDate'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd, " ", hh, ":", nn, ":", ss]);
            FEntityItem['FInspectEndDate'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd, " ", hh, ":", nn, ":", ss]);*/
            FEntityItem['FInspectResult1'] = this.hobby[element][11]['value']['value']?'1':'2';
            FEntityItem['FInspectQty'] = this.hobby[element][3]['value']['value'];
            //FEntityItem['FBaseInspectQty'] = this.hobby[element][3]['value']['value'];
            FPolicyDetailItem['FUsePolicy'] = this.hobby[element][12]['value']['value'];
            FPolicyDetailItem['FPolicyQty'] = this.hobby[element][3]['value']['value'];
            /*FPolicyDetailItem['FPolicyStatus'] = this.hobby[element][11]['value']['value']?'1':'2';
            FPolicyDetailItem['FBasePolicyQty'] = this.hobby[element][3]['value']['value'];*/
            FPolicyDetail.add(FPolicyDetailItem);
            FEntityItem['FPolicyDetail'] = FPolicyDetail;
            FEntity.add(FEntityItem);
          }
        }
      }
      Model['FEntity'] = FEntity;
      orderMap['Model'] = Model;
      dataMap = {"formid": "QM_InspectBill", "data": orderMap, "isBool": true};
      print(jsonEncode(dataMap));
      //返回保存参数
      return dataMap;
    } else {
      Map<String, dynamic> errorMap = Map();
      errorMap = {
        "msg": res['Result']['ResponseStatus']['Errors'][0]['Message'],
        "isBool": false
      };
      return errorMap;
    }
  }
  //保存
  saveOrder(type) async {
    //获取登录信息
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      if (this.departmentNumber  == null) {
        this.isSubmit = false;
        ToastUtil.showInfo('部门为空');
        return;
      }
      if (this.qcNumber  == null) {
        this.isSubmit = false;
        ToastUtil.showInfo('质检员不能为空');
        return;
      }
      if (type) {
        var hobbyIndex = 0;
        var EntryIds = '';
        this.hobby.forEach((element) {
          if (double.parse(element[3]['value']['value']) > 0) {
            if (EntryIds == '') {
              EntryIds = orderDate[hobbyIndex][4].toString();
            } else {
              EntryIds = EntryIds + ',' + orderDate[hobbyIndex][4].toString();
            }
          }
          hobbyIndex++;
        });
        var resCheck = await this.pushDown(EntryIds, 'defective');
        print(resCheck);
        if (resCheck['isBool'] != false) {
          var datass = jsonEncode(resCheck);
          String order = await SubmitEntity.save(resCheck);
          var res = jsonDecode(order);
          print(res);
          if (res['Result']['ResponseStatus']['IsSuccess']) {
            print(resCheck);
            Map<String, dynamic> submitMap = Map();
            submitMap = {
              "formid": "QM_InspectBill",
              "data": {'Ids': resCheck['data']['Model']['FID']}
            };
            //提交
            HandlerOrder.orderHandler(context, submitMap, 1, "QM_InspectBill",
                SubmitEntity.submit(submitMap))
                .then((submitResult) {
              if (submitResult) {
                //审核
                HandlerOrder.orderHandler(context, submitMap, 1,
                    "QM_InspectBill", SubmitEntity.audit(submitMap))
                    .then((auditResult) async {
                  if (auditResult) {
                    //提交清空页面
                    setState(() {
                      this.hobby = [];
                      this.orderDate = [];
                      this.FBillNo = '';
                      ToastUtil.showInfo('提交成功');
                      Navigator.of(context).pop("refresh");
                    });
                  } else {
                    //失败后反审
                    HandlerOrder.orderHandler(context, submitMap, 0,
                        "QM_InspectBill", SubmitEntity.unAudit(submitMap))
                        .then((unAuditResult) {
                      if (unAuditResult) {
                        this.isSubmit = false;
                      } else {
                        this.isSubmit = false;
                      }
                    });
                  }
                });
              } else {
                this.isSubmit = false;
              }
            });
          } else {
            setState(() {
              this.isSubmit = false;
              ToastUtil.errorDialog(
                  context, res['Result']['ResponseStatus']['Errors'][0]['Message']);
            });
          }
        } else {
          setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(context, resCheck['msg']);
          });
        }
      } else {
        Map<String, dynamic> dataMap = Map();
        dataMap['formid'] = 'QM_InspectBill';
        Map<String, dynamic> orderMap = Map();
        orderMap['NeedReturnFields'] = [];
        orderMap['IsDeleteEntry'] = false;
        Map<String, dynamic> Model = Map();
        Model['FID'] = 0;
        Model['FBillTypeID'] = {"FNUMBER": "JYD002_SYS"};
        Model['FDate'] = FDate;
        Model['FBusinessType'] = "3";
        Model['FSourceOrgId'] = {"FNumber": orderDate[0][1]};
        Model['FInspectDepId'] = {"FNumber": this.departmentNumber};
        Model['FInspectOrgId'] = {"FNumber": deptData[1]};
        Model['FInspectorId'] = {"FNUMBER": qcNumber};
        //判断有源单 无源单
        if(this.isScanWork){

        }else{

        }
        var FEntity = [];

        var hobbyIndex = 0;
        this.hobby.forEach((element) {
          if (element[3]['value']['value'] != '0'/* &&
            element[4]['value']['value'] != ''*/) {
            Map<String, dynamic> FEntityItem = Map();
            var FPolicyDetail = [];
            var FReferDetail = [];
            Map<String, dynamic> FPolicyDetailItem = Map();
            Map<String, dynamic> FReferDetailItem = Map();
            FEntityItem['FMaterialId'] = {"FNumber": element[0]['value']['value']};
            FEntityItem['FUnitID'] = {"FNumber": element[2]['value']['value']};
            FEntityItem['FStockId'] = {"FNumber": element[4]['value']['value']};
            FEntityItem['FWorkshopId'] = {"FNUMBER": element[0]['FWorkshopId']};
            FEntityItem['FLot'] = {"FNumber": element[0]['FLot']};
            if(element[6]['value']['hide']){
              FEntityItem['FStockLocId'] = {
                "FSTOCKLOCID__FF100011": {"FNumber": element[6]['value']['value']}
              };
            }

            FEntityItem['FInspectQty'] = element[3]['value']['value'];
            FEntityItem['FBaseWBInspectQty'] = element[3]['value']['value'];
            FEntityItem['FBaseInspectQty'] = element[3]['value']['value'];
            FEntityItem['FSampleDamageQty'] = element[13]['value']['value'];
            FEntityItem['FTimeUnit'] = "24";
            FEntityItem['FSampleDamageBearer'] = "2";
            FEntityItem['FQCStatus'] = "3";
            FEntityItem['FQCBusinessType'] = "3";
            FEntityItem['FInspectTimes'] = "1";
            FEntityItem['FCurrentStringency'] = "1";
            FEntityItem['FInspectResult'] = element[11]['value']['value']?'1':'2';
            if(element[11]['value']['value']){
              FEntityItem['FQualifiedQty'] = element[3]['value']['value'];
              FEntityItem['FBaseWBInspectQty'] = element[3]['value']['value'];
              FEntityItem['FBaseAcceptQty '] = element[3]['value']['value'];
            }else{
              FEntityItem['FUnqualifiedQty'] = element[3]['value']['value'];
            }

            FEntityItem['FSrcBillType0'] = "PRD_MORPT";
            FEntityItem['FSrcBillNo0'] = this.FBillNo;
            FEntityItem['FSrcInterId0'] = element[0]['FID'];
            FEntityItem['FSrcEntryId0'] = element[0]['FEntryId'];
            FReferDetailItem['FSrcInterId'] = element[0]['FID'];
            FReferDetailItem['FSrcEntryId'] = element[0]['FEntryId'];
            FPolicyDetailItem['FPolicyMaterialId'] = {"FNUMBER": element[0]['value']['value']};
            FPolicyDetailItem['FPolicyStatus'] = element[11]['value']['value']?'1':'2';
            FPolicyDetailItem['FUsePolicy'] = element[12]['value']['value'];
            FPolicyDetailItem['FPolicyQty'] = element[3]['value']['value'];
            FPolicyDetailItem['FBasePolicyQty'] = element[3]['value']['value'];
            FPolicyDetailItem['FBaseInspectQty'] = element[3]['value']['value'];

            FPolicyDetailItem['FInstockFlag'] = "0";
            FPolicyDetail.add(FPolicyDetailItem);
            FReferDetail.add(FReferDetailItem);
            FEntityItem['FPolicyDetail'] = FPolicyDetail;
            FEntityItem['FReferDetail'] = FReferDetail;
            FEntityItem['FEntity_Link'] = [
              {
                "FEntity_Link_FRuleId": "OM_PRDMoRpt2Inspect",
                "FEntity_Link_FSTableName": "T_PRD_MORPTENTRY",
                "FEntity_Link_FSBillId": element[0]['FID'],
                "FEntity_Link_FSId": element[0]['FEntryId'],
                "FEntity_Link_FInspectQty": element[3]['value']['value'],
                "FEntity_Link_FBaseInspectQty": element[3]['value']['value'],
                "FEntity_Link_FBaseWBInspectQty": element[3]['value']['value'],
                "FEntity_Link_FBaseAcceptQty": element[3]['value']['value'],
              }
            ];
            FEntity.add(FEntityItem);
          }
          hobbyIndex++;
        });
        if(FEntity.length==0){
          this.isSubmit = false;
          ToastUtil.showInfo('请输入数量');/*,仓库*/
          return;
        }
        Model['FEntity'] = FEntity;
        orderMap['Model'] = Model;
        dataMap['data'] = orderMap;
        var datass = jsonEncode(dataMap);
        String order = await SubmitEntity.save(dataMap);
        var res = jsonDecode(order);
        print(res);
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          Map<String, dynamic> submitMap = Map();
          submitMap = {
            "formid": "QM_InspectBill",
            "data": {
              'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
            }
          };
          //提交
          HandlerOrder.orderHandler(
              context,
              submitMap,
              1,
              "QM_InspectBill",
              SubmitEntity.submit(submitMap))
              .then((submitResult) {
            if (submitResult) {
              //审核
              HandlerOrder.orderHandler(
                  context,
                  submitMap,
                  1,
                  "QM_InspectBill",
                  SubmitEntity.audit(submitMap))
                  .then((auditResult) async{
                if (auditResult) {
                  //提交清空页面
                  setState(() {
                    this.hobby = [];
                    this.orderDate = [];
                    this.FBillNo = '';
                    ToastUtil.showInfo('提交成功');
                    Navigator.of(context).pop("refresh");
                  });
                } else {
                  //失败后反审
                  HandlerOrder.orderHandler(
                      context,
                      submitMap,
                      0,
                      "QM_InspectBill",
                      SubmitEntity.unAudit(submitMap))
                      .then((unAuditResult) {
                    if (unAuditResult) {
                      this.isSubmit = false;
                    }else{
                      this.isSubmit = false;
                    }
                  });
                }
              });
            } else {
              this.isSubmit = false;
            }
          });
        } else {
          setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(
                context, res['Result']['ResponseStatus']['Errors'][0]['Message']);
          });
        }
      }

    } else {
      ToastUtil.showInfo('无提交数据');
    }
  }
  /// 确认提交提示对话框
  Future<void> _showSumbitDialog() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("是否提交"),
            actions: <Widget>[
              new FlatButton(
                child: new Text('不了'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text('确定'),
                onPressed: () {
                  Navigator.of(context).pop();
                  saveOrder(true);
                },
              )
            ],
          );
        });
  }
  //扫码函数,最简单的那种
  Future scan() async {
    String cameraScanResult = await scanner.scan(); //通过扫码获取二维码中的数据
    getScan(cameraScanResult); //将获取到的参数通过HTTP请求发送到服务器
    print(cameraScanResult); //在控制台打印
  }

//用于验证数据(也可以在控制台直接打印，但模拟器体验不好)
  void getScan(String scan) async {
    _onEvent(scan);
  }
  @override
  Widget build(BuildContext context) {
    return FlutterEasyLoading(
      child: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: scan,
            tooltip: 'Increment',
            child: Icon(Icons.filter_center_focus),
          ),
          appBar: AppBar(
            title: Text("检验"),
            centerTitle: true,
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: ListView(children: <Widget>[
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          /* title: TextWidget(FBillNoKey, '生产订单：'),*/
                          title: Text("单号：$FBillNo"),
                        ),
                      ),
                      divider,
                    ],
                  ),Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          /* title: TextWidget(FBillNoKey, '生产订单：'),*/
                          title: Text("金蝶号：$jdh"),
                        ),
                      ),
                      divider,
                    ],
                  ),Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          /* title: TextWidget(FBillNoKey, '生产订单：'),*/
                          title: Text("线路名称：$xlmc"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  _item('部门', this.departmentList, this.departmentName,
                      'department'),
                  _item('质检员', this.qcList, this.qcName,
                      'qc'),
                  _dateItem('日期：', DateMode.YMD),
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: TextField(
                            //最多输入行数
                            maxLines: 1,
                            decoration: InputDecoration(
                              hintText: "备注",
                              //给文本框加边框
                              border: OutlineInputBorder(),
                            ),
                            controller: this._remarkContent,
                            //改变回调
                            onChanged: (value) {
                              setState(() {
                                _remarkContent.value = TextEditingValue(
                                    text: value,
                                    selection: TextSelection.fromPosition(TextPosition(
                                        affinity: TextAffinity.downstream,
                                        offset: value.length)));
                              });
                            },
                          ),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  Column(
                    children: this._getHobby(),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RaisedButton(
                        padding: EdgeInsets.all(15.0),
                        child: Text("保存"),
                        color: this.isSubmit?Colors.grey:Theme.of(context).primaryColor,
                        textColor: Colors.white,
                        onPressed: () async=> this.isSubmit ? null : _showSumbitDialog(),
                      ),
                    ),
                  ],
                ),
              )
            ],
          )),
    );
  }
}
