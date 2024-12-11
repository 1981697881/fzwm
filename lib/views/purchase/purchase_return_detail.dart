import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:decimal/decimal.dart';
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

class PurchaseReturnDetail extends StatefulWidget {
  var FBillNo;

  PurchaseReturnDetail({Key ?key, @required this.FBillNo}) : super(key: key);

  @override
  _ReturnGoodsDetailState createState() => _ReturnGoodsDetailState(FBillNo);
}

class _ReturnGoodsDetailState extends State<PurchaseReturnDetail> {
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
  String FDate = '';
  String xlmc = '';
  var supplierName;
  var supplierNumber;
  var typeName;
  var typeNumber;
  var show = false;
  var isSubmit = false;
  var isScanWork = false;
  var checkData;
  var fOrgID;
  var checkDataChild;
  var selectData = {
    DateMode.YMD: '',
  };
  var organizationsName;
  var organizationsNumber;
  //包装规格
  var bagList = [];
  var hobbyItem = [];
  List<dynamic> bagListObj = [];
  var typeList = [];
  List<dynamic> typeListObj = [];
  var organizationsList = [];
  List<dynamic> organizationsListObj = [];
  var supplierList = [];
  List<dynamic> supplierListObj = [];
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
  final controller = TextEditingController();
  _ReturnGoodsDetailState(FBillNo) {
    if (FBillNo != null) {
      this.fBillNo = FBillNo['value'];
      this.getOrderList();
      isScanWork = true;
    } else {
      isScanWork = false;
      this.fBillNo = '';
      getSupplierList();
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
    getBagList();
    /* getWorkShop();*/
  }
  //获取包装规格
  getBagList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BOS_ASSISTANTDATA_DETAIL';
    userMap['FieldKeys'] = 'FNumber,FDataValue,FId';
    userMap['FilterString'] = [{"Left":"(","FieldName":"FId","Compare":"67","Value":"64746193a3e99b","Right":")","Logic":"0"}];
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    bagListObj = jsonDecode(res);
    bagListObj.forEach((element) {
      bagList.add(element[1]);
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
  //获取供应商
  getSupplierList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_Supplier';
    userMap['FieldKeys'] = 'FSupplierId,FName,FNumber';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    supplierListObj = jsonDecode(res);
    supplierListObj.forEach((element) {
      supplierList.add(element[1]);
    });
  }
  //获取仓库
  getStockList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_STOCK';
    userMap['FieldKeys'] = 'FStockID,FName,FNumber,FIsOpenLocation';
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    if(fOrgID == null){
      this.fOrgID = tissue;
    }
    userMap['FilterString'] = "FForbidStatus = 'A' and FUseOrgId.FNumber='"+tissue+"'";//
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    var initial = jsonDecode(res);
    initial.forEach((element) {
      stockList.add(element[1]);
    });
    stockListObj = initial;
  }
  //获取组织
  getOrganizationsList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'ORG_Organizations';
    userMap['FieldKeys'] = 'FForbidStatus,FName,FNumber,FDocumentStatus';
    userMap['FilterString'] = "FForbidStatus = 'A' and FDocumentStatus = 'C'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    organizationsListObj = jsonDecode(res);
    organizationsListObj.forEach((element) {
      organizationsList.add(element[1]);
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
    userMap['FilterString'] = "fBillNo='$fBillNo'";
    userMap['FormId'] = 'STK_InStock';
    userMap['OrderString'] = 'FMaterialId.FNumber ASC';
    userMap['FieldKeys'] =
    'FBillNo,FPurchaseOrgId.FNumber,FPurchaseOrgId.FName,FDate,FInStockEntry_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FStockOrgId.FNumber,FStockOrgId.FName,FUnitID.FNumber,FUnitID.FName,FRealQty,FDate,FReturnJoinQty,FID,FSupplierId.FNumber,FSupplierId.FName,FStockID.FName,FStockID.FNumber,FLot.FNumber,FStockID.FIsOpenLocation,FMaterialId.FIsBatchManage,FPriceUnitID.FNumber,FTaxPrice,FEntryTaxRate,FBaseUnitID.FName,FBaseUnitID.FNumber,FDemandOrgId.FNumber,FAuxPropId,F_ora_BaseProperty2,FMaterialId.FIsKFPeriod,F_ora_Assistant.FNumber,F_ora_Assistant.FDataValue,F_ora_Assistant1.FNumber,FReceiveLot';
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
      this.supName = orderDate[0][17];
      this.xlmc = orderDate[0][33];
      hobby = [];
      for (var value in orderDate) {
        //orderDate.forEach((value) {
        fNumber.add(value[5]);
        List arr = [];
        arr.add({
          "title": "物料名称",
          "name": "FMaterial",
          "FEntryId": value[4],
          "FID": value[15],
          "FIsKFPeriod": value[31],
          "FPRICEUNITID": value[23],
          "FTAXPRICE": value[24],
          "FENTRYTAXRATE": value[25],
          "F_ora_Assistant": value[32],
          "F_ora_Assistant1": value[34],
          "FReceiveLot": value[35],
          "parseEntryID": -1,
          "isHide": false,
          "value": {
            "label": value[6] + "- (" + value[5] + ")",
            "value": value[5],
            "barcode": [],
            "kingDeeCode": [],
            "surplus": (value[12] - value[14])>0?(value[12] - value[14]): 0,
            "scanCode": []
          }
        });
        arr.add({
          "title": "规格型号",
          "isHide": false,
          "name": "FMaterialIdFSpecification",
          "value": {"label": value[7], "value": value[7]}
          //"value": {"label": value[29]==null?"":value[29], "value": value[29]==null?"":value[29]}
        });
        arr.add({
          "title": "单位名称",
          "name": "FUnitId",
          "isHide": false,
          "value": {"label": value[26], "value": value[27]}
        });
        Map<String, dynamic> inventoryMap = Map();
        inventoryMap['FormId'] = 'STK_Inventory';
        /*if(value[31] != '' && value[31] != null){
          inventoryMap['FilterString'] = "FMaterialId.FNumber='" + value[7] + "' and FStockId.FNumber='" + value[31] + "' and FBaseQty >0";// and FStockIds
        }else{
          inventoryMap['FilterString'] = "FMaterialId.FNumber='" + value[7] + "' and FBaseQty >0";// and FStockIds
        }*/
        inventoryMap['FilterString'] = "FMaterialId.FNumber='" + value[5] + "' and FBaseQty >0";
        inventoryMap['Limit'] = '20';
        inventoryMap['OrderString'] = 'FLot.FNumber DESC, FProduceDate DESC';
        inventoryMap['FieldKeys'] =
        'FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FStockId.FNumber,FBaseQty,FLot.FNumber,FAuxPropId,FStockId.FName,FStockLocId.FF100011.FNumber';
        Map<String, dynamic> inventoryDataMap = Map();
        inventoryDataMap['data'] = inventoryMap;
        String res = await CurrencyEntity.polling(inventoryDataMap);
        var stocks = jsonDecode(res);
        if (stocks.length > 0) {
          arr.add({
            "title": "实退数量",
            "name": "FBaseQty",
            "isHide": false,
            "value": {"label": "0", "value": "0" , "stocks": stocks}
          });

        }else{
          arr.add({
            "title": "实退数量",
            "name": "FBaseQty",
            "isHide": false,
            "value": {"label": "0", "value": "0" , "stocks": []}
          });
        }
        arr.add({
          "title": "仓库",
          "name": "FStockID",
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
        /* Map<String, dynamic> inventoryMap = Map();
        inventoryMap['FormId'] = 'STK_Inventory';
        inventoryMap['FilterString'] = "FMaterialId.FNumber='" + value[5] + "' and FBaseQty >0";
        inventoryMap['Limit'] = '50';
        inventoryMap['OrderString'] = 'FLot.FNumber DESC, FProduceDate DESC';
        inventoryMap['FieldKeys'] =
        'FMaterialId.FNumber,F_UUAC_BaseProperty,FMaterialId.FSpecification,FStockId.FName,FBaseQty,FLot.FNumber,FAuxPropId.FF100002.FNumber';
        Map<String, dynamic> inventoryDataMap = Map();
        inventoryDataMap['data'] = inventoryMap;
        String res = await CurrencyEntity.polling(inventoryDataMap);
        var stocks = jsonDecode(res);
        if (stocks.length > 0) {
          arr.add({
            "title": "批号",
            "name": "FLot",
            "isHide": value[22] != true,
            "value": {"label": '', "value": '',"fLotList": stocks}
          });
        }else{
          arr.add({
            "title": "批号",
            "name": "FLot",
            "isHide": value[22] != true,
            "value": {"label": '', "value": '',"fLotList": []}
          });
        }*/
        arr.add({
          "title": "批号",
          "name": "FLot",
          "isHide": value[22] != true,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "仓位",
          "name": "FStockLocID",
          "isHide": false,
          "value": {"label": "", "value": "","hide": value[21]}
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
          "value": {"label": value[11], "value": value[10]}
        });
        arr.add({
          "title": "可退数量",
          "name": "",
          "isHide": false,
          "value": {"label": (value[12] - value[14])>0?(value[12] - value[14]): 0, "value": (value[12] - value[14])>0?(value[12] - value[14]): 0, "rateValue": (value[12] - value[14])>0?(value[12] - value[14]): 0}
        });
        arr.add({
          "title": "最后扫描数量",
          "name": "FLastQty",
          "isHide": true,
          "value": {"label": "0", "value": "0", "remainder": "0", "representativeQuantity": "0"}
        });
        arr.add({
          "title": "包装数量",
          "name": "",
          "isHide": true,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "包数",
          "name": "",
          "isHide": true,
          "value": {"label": "", "value": ""}
        });
        arr.add({
          "title": "明细",
          "name": "",
          "isHide": true,
          "value": {"label": "", "value": "", "itemList": []}
        });
        arr.add({
          "title": "生产日期",
          "name": "FProduceDate",
          "isHide": !value[31],
          "value": {
            "label": '',
            "value": ''
          }
        });
        arr.add({
          "title": "有效期至",
          "name": "FExpiryDate",
          "isHide": !value[31],
          "value": {
            "label": '',
            "value": ''
          }
        });
        hobby.add(arr);
      };
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
  }

  void _onEvent(event) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var deptData = sharedPreferences.getString('menuList');
    var menuList = new Map<dynamic, dynamic>.from(jsonDecode(deptData));
    fBarCodeList = menuList['FBarCodeList'];
    if (event == "") {
      return;
    }
    if (fBarCodeList == 1) {
      Map<String, dynamic> barcodeMap = Map();
      barcodeMap['FilterString'] = "FBarCodeEn='" + event + "'";
      barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
      barcodeMap['FieldKeys'] =
      'FID,FInQtyTotal,FOutQtyTotal,FEntity_FEntryId,FRemainQty,FBarCodeQty,FStockID.FName,FStockID.FNumber,FMATERIALID.FNUMBER,FOwnerID.FNumber,FBarCode,FSN,FBatchNo,FPackageSpec,FProduceDate,FExpiryDate';
      Map<String, dynamic> dataMap = Map();
      dataMap['data'] = barcodeMap;
      String order = await CurrencyEntity.polling(dataMap);
      var barcodeData = jsonDecode(order);
      if (barcodeData.length > 0) {
        if (barcodeData[0][4] > 0) {
          var msg = "";
          var orderIndex = 0;
          for (var value in orderDate) {
            if (value[7] == barcodeData[0][8]) {
              msg = "";
              if (fNumber.lastIndexOf(barcodeData[0][8]) == orderIndex) {
                break;
              }
            } else {
              msg = '条码不在单据物料中';
            }
            orderIndex++;
          }
          ;
          if (msg == "") {
            _code = event;
            this.getMaterialList(
                barcodeData, barcodeData[0][10], barcodeData[0][11],barcodeData[0][13], barcodeData[0][14].substring(0, 10), barcodeData[0][15].substring(0, 10));//jsonDecode(stockOrder)[0][0]
            print("ChannelPage: $event");
          } else {
            ToastUtil.showInfo(msg);
          }
        } else {
          ToastUtil.showInfo('该条码已出库或没入库，数量为零');
        }
      } else {
        ToastUtil.showInfo('条码不在条码清单中');
      }
    } else {
      _code = event;
      this.getMaterialList("", _code, '', '', '', '');
      print("ChannelPage: $event");
    }
    print("ChannelPage: $event");
  }

  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
  }
  getMaterialList(barcodeData, code, fsn,fAuxPropId, fProduceDate, fExpiryDate) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    var scanCode = code.split(";");
    userMap['FilterString'] = "FNumber='" +
        scanCode[0] +
        "' and FForbidStatus = 'A' and  FUseOrgId.FNumber = '"+tissue+"'";
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
    'FMATERIALID,FName,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage,FStockId.FName,FStockId.FNumber,FIsKFPeriod';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    materialDate = [];
    materialDate = jsonDecode(order);
    if (materialDate.length > 0) {
      var number = 0;
      var barCodeScan;
      if (fBarCodeList == 1) {
        barCodeScan = barcodeData[0];
        barCodeScan[4] = barCodeScan[4].toString();
      } else {
        if(scanCode.length==1){
          barCodeScan = barcodeData[0];
        }else{
          barCodeScan = scanCode;
        }
      }
      var barcodeNum = barCodeScan[4];
      var barcodeQuantity = barCodeScan[4];
      var residue = double.parse(barCodeScan[4]);
      var hobbyIndex = 0;
      var insertIndex = 0;
      var surplus = 0.0;
      var parseEntryID = -1;
      var fIsKFPeriod = materialDate[0][7];
      this.hobbyItem = [];
      for(var i = 0;i<this.hobby.length;i++){
        if(this.hobbyItem.length==0){
          Map<String, dynamic> hobbyMap = Map();
          hobbyMap['number'] = this.hobby[i][0]['value']['value']+"-"+this.hobby[i][0]['FEntryID'].toString();
          hobbyMap['index'] = i;
          this.hobbyItem.add(hobbyMap);
        }else if(this.hobby[i][0]['FEntryID'] != 0){
          Map<String, dynamic> hobbyMap = Map();
          hobbyMap['number'] = this.hobby[i][0]['value']['value']+"-"+this.hobby[i][0]['FEntryID'].toString();
          hobbyMap['index'] = i;
          this.hobbyItem.add(hobbyMap);
        }
      }
      for (var element in hobby) {
        var entryIndex;
        if(this.fBillNo == ''){
          entryIndex = hobbyIndex;
        }else{
          if(element[0]['FEntryID'] == 0){
            entryIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (element[0]['value']['value']+'-'+element[0]['parseEntryID'].toString()))]['index'];
          }else{
            entryIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (element[0]['value']['value  ']+'-'+element[0]['FEntryID'].toString()))]['index'];
          }
        }

        hobbyIndex++;
        //判断是否启用批号
        if (element[5]['isHide']) {
          //不启用  && element[4]['value']['value'] == barCodeScan[6]
          if (element[0]['value']['value'] == scanCode[0]) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              if (scanCode.length > 4) {
                element[0]['value']['barcode'].add(code);
                if (scanCode[5] == "N") {
                  if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                    if (element[4]['value']['value'] == "") {
                      element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                      element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                    }
                    if (element[14]['value']['value'] == "") {
                      element[14]['value']['label'] = fProduceDate == null? "":fProduceDate;
                      element[14]['value']['value'] =fProduceDate == null? "":fProduceDate;
                      element[15]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                      element[15]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
                    }
                    element[3]['value']['value'] =
                        (double.parse(element[3]['value']['value']) +
                            double.parse(barcodeNum))
                            .toString();
                    element[3]['value']['label'] = element[3]['value']['value'];
                    var item =
                        barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                    element[0]['value']['kingDeeCode'].add(item);
                    element[0]['value']['scanCode'].add(code);
                    element[10]['value']['label'] = barcodeNum.toString();
                    element[10]['value']['value'] = barcodeNum.toString();
                    element[10]['value']['remainder'] = "0";
                    element[10]['value']['representativeQuantity'] = barcodeQuantity;
                    barcodeNum =
                        (double.parse(barcodeNum) - double.parse(barcodeNum))
                            .toString();
                  }
                  number++;
                  break;
                }
              }
              print(this.hobbyItem);
              print(entryIndex);
              print(element[0]['value']['value']);
              print(element[0]['FEntryID']);
              //判断扫描数量是否大于单据数量
              if (double.parse(element[3]['value']['value']) >=
                  hobby[entryIndex][9]['value']['label']) {
                continue;
              } else {
                //判断条码数量
                if ((double.parse(element[3]['value']['value']) + residue) >
                    0 &&
                    residue > 0) {
                  //判断条码是否重复
                  if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                    if (element[4]['value']['value'] == "") {
                      element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                      element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                    }
                    if (element[14]['value']['value'] == "") {
                      element[14]['value']['label'] = fProduceDate == null? "":fProduceDate;
                      element[14]['value']['value'] =fProduceDate == null? "":fProduceDate;
                      element[15]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                      element[15]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
                    }
                    //判断末尾
                    /*if (fNumber.lastIndexOf(
                            element[0]['value']['value'].toString()) ==
                        (hobbyIndex - 1)) {
                      var item = barCodeScan[0].toString() +
                          "-" +
                          residue.toString() +
                          "-" +
                          fsn;
                      element[10]['value']['label'] = residue.toString();
                      element[10]['value']['value'] = residue.toString();
                      element[3]['value']['label'] =
                          (double.parse(element[3]['value']['value']) + residue)
                              .toString();
                      element[3]['value']['value'] =
                          element[3]['value']['label'];
                      residue = (residue * 100 -
                              double.parse(element[10]['value']['value']) *
                                  100) /
                          100;
                      element[0]['value']['surplus'] =
                          (element[9]['value']['value'] * 100 -
                                  double.parse(element[3]['value']['value']) *
                                      100) /
                              100;
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                    } else {*/
                    //判断剩余数量是否大于扫码数量
                    if (hobby[entryIndex][0]['value']['surplus'] >= residue) {
                      var item = barCodeScan[0].toString() +
                          "-" +
                          residue.toString() +
                          "-" +
                          fsn;
                      element[10]['value']['label'] = residue.toString();
                      element[10]['value']['value'] = residue.toString();
                      element[10]['value']['remainder'] = "0";
                      element[10]['value']['representativeQuantity'] = barcodeQuantity;
                      element[3]['value']['label'] =
                          (double.parse(element[3]['value']['value']) +
                              residue)
                              .toString();
                      element[3]['value']['value'] =
                      element[3]['value']['label'];
                      residue = 0.0;
                      hobby[entryIndex][0]['value']['surplus'] =
                          (hobby[entryIndex][9]['value']['value'] * 100 -
                              double.parse(element[3]['value']['value']) *
                                  100) /
                              100;
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                      number++;
                      break;
                    } else {
                      var item = barCodeScan[0].toString() +
                          "-" +
                          hobby[entryIndex][0]['value']['surplus'].toString() +
                          "-" +
                          fsn;
                      element[10]['value']['label'] =
                          hobby[entryIndex][0]['value']['surplus'].toString();
                      element[10]['value']['value'] =
                          hobby[entryIndex][0]['value']['surplus'].toString();

                      element[3]['value']['label'] = (hobby[entryIndex][0]['value']
                      ['surplus'] +
                          double.parse(element[3]['value']['value']))
                          .toString();
                      element[3]['value']['value'] =
                      element[3]['value']['label'];
                      residue = (residue * 100 -
                          double.parse(element[10]['value']['value']) *
                              100) /
                          100;
                      hobby[entryIndex][0]['value']['surplus'] =
                          (hobby[entryIndex][9]['value']['value'] * 100 -
                              double.parse(element[3]['value']['value']) *
                                  100) /
                              100;
                      element[10]['value']['remainder'] = residue.toString();
                      element[10]['value']['representativeQuantity'] = barcodeQuantity;
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                      number++;
                    }
                    // }
                  }
                }
              }
            } else {
              ToastUtil.showInfo('该标签已扫描');
              number++;
              break;
            }
            surplus = hobby[entryIndex][0]['value']['surplus'];
            parseEntryID = hobby[entryIndex][0]['FEntryID'];
            fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
            insertIndex = hobbyIndex;
          }
        } else {
          //启用批号 && element[4]['value']['value'] == barCodeScan[6]
          if (element[0]['value']['value'] == scanCode[0]) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              if (scanCode.length > 4) {
                element[0]['value']['barcode'].add(code);
                if (scanCode[5] == "N") {
                  if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                    if (element[4]['value']['value'] == "") {
                      element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                      element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                    }
                    if (element[14]['value']['value'] == "") {
                      element[14]['value']['label'] = fProduceDate == null? "":fProduceDate;
                      element[14]['value']['value'] =fProduceDate == null? "":fProduceDate;
                      element[15]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                      element[15]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
                    }
                    element[3]['value']['value'] =
                        (double.parse(element[3]['value']['value']) +
                            double.parse(barcodeNum))
                            .toString();
                    element[3]['value']['label'] = element[3]['value']['value'];
                    var item =
                        barCodeScan[0].toString() + "-" + barcodeNum + "-" + fsn;
                    element[0]['value']['kingDeeCode'].add(item);
                    element[0]['value']['scanCode'].add(code);
                    element[10]['value']['label'] = barcodeNum.toString();
                    element[10]['value']['value'] = barcodeNum.toString();
                    element[10]['value']['remainder'] = "0";
                    element[10]['value']['representativeQuantity'] = barcodeQuantity;
                    barcodeNum =
                        (double.parse(barcodeNum) - double.parse(barcodeNum))
                            .toString();
                  }
                  number++;
                  break;
                }
              }
              if (element[5]['value']['value'] == barCodeScan[1]) {
                print(this.hobbyItem);
                print(entryIndex);
                print(element[0]['value']['value']);
                print(element[0]['FEntryID']);
                //判断扫描数量是否大于单据数量
                if (double.parse(element[3]['value']['value']) >=
                    hobby[entryIndex][9]['value']['label']) {
                  continue;
                } else {
                  //判断条码数量
                  if ((double.parse(element[3]['value']['value']) + residue) >
                      0 &&
                      residue > 0) {
                    //判断条码是否重复
                    if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                      if (element[4]['value']['value'] == "") {
                        element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                        element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                      }
                      if (element[14]['value']['value'] == "") {
                        element[14]['value']['label'] = fProduceDate == null? "":fProduceDate;
                        element[14]['value']['value'] =fProduceDate == null? "":fProduceDate;
                        element[15]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                        element[15]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
                      }
                      //判断末尾
                      /*if (fNumber.lastIndexOf(
                              element[0]['value']['value'].toString()) ==
                          (hobbyIndex - 1)) {
                        var item = barCodeScan[0].toString() +
                            "-" +
                            residue.toString() +
                            "-" +
                            fsn;
                        element[10]['value']['label'] = residue.toString();
                        element[10]['value']['value'] = residue.toString();
                        element[3]['value']['label'] =
                            (double.parse(element[3]['value']['value']) +
                                    residue)
                                .toString();
                        element[3]['value']['value'] =
                            element[3]['value']['label'];
                        residue = (residue * 100 -
                                double.parse(element[10]['value']['value']) *
                                    100) /
                            100;
                        element[0]['value']['surplus'] =
                            (element[9]['value']['value'] * 100 -
                                    double.parse(element[3]['value']['value']) *
                                        100) /
                                100;
                        ;
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                      } else {*/
                      //判断剩余数量是否大于扫码数量
                      if (hobby[entryIndex][0]['value']['surplus'] >= residue) {
                        var item = barCodeScan[0].toString() +
                            "-" +
                            residue.toString() +
                            "-" +
                            fsn;
                        element[10]['value']['label'] = residue.toString();
                        element[10]['value']['value'] = residue.toString();
                        element[10]['value']['remainder'] = "0";
                        element[10]['value']['representativeQuantity'] = barcodeQuantity;
                        element[3]['value']['label'] =
                            (double.parse(element[3]['value']['value']) +
                                residue)
                                .toString();
                        element[3]['value']['value'] =
                        element[3]['value']['label'];
                        residue = 0.0;
                        hobby[entryIndex][0]['value']['surplus'] = (hobby[entryIndex][9]['value']
                        ['value'] *
                            100 -
                            double.parse(element[3]['value']['value']) *
                                100) /
                            100;
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                        number++;
                        break;
                      } else {
                        var item = barCodeScan[0].toString() +
                            "-" +
                            hobby[entryIndex][0]['value']['surplus'].toString() +
                            "-" +
                            fsn;
                        element[10]['value']['label'] =
                            hobby[entryIndex][0]['value']['surplus'].toString();
                        element[10]['value']['value'] =
                            hobby[entryIndex][0]['value']['surplus'].toString();
                        element[3]['value']['label'] = (element[0]['value']
                        ['surplus'] +
                            double.parse(element[3]['value']['value']))
                            .toString();
                        element[3]['value']['value'] =
                        element[3]['value']['label'];
                        residue = (residue * 100 -
                            double.parse(element[10]['value']['value']) *
                                100) /
                            100;
                        hobby[entryIndex][0]['value']['surplus'] = (hobby[entryIndex][9]['value']
                        ['value'] *
                            100 -
                            double.parse(element[3]['value']['value']) *
                                100) /
                            100;
                        element[10]['value']['remainder'] = residue.toString();
                        element[10]['value']['representativeQuantity'] = barcodeQuantity;
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                        number++;
                      }
                      //}
                    }
                  }
                }
              } else {
                if (element[5]['value']['value'] == "") {
                  element[5]['value']['label'] = barCodeScan[1];
                  element[5]['value']['value'] = barCodeScan[1];

                  print(this.hobbyItem);
                  print(entryIndex);
                  print(element[0]['value']['value']);
                  print(element[0]['FEntryID']);
                  //判断扫描数量是否大于单据数量
                  if (double.parse(element[3]['value']['value']) >=
                      hobby[entryIndex][9]['value']['label']) {
                    continue;
                  } else {
                    //判断条码数量
                    if ((double.parse(element[3]['value']['value']) + residue) >
                        0 &&
                        residue > 0) {
                      //判断条码是否重复
                      if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                        if (element[4]['value']['value'] == "") {
                          element[4]['value']['label'] = barcodeData[0][6] == null? "":barcodeData[0][6];
                          element[4]['value']['value'] = barcodeData[0][7] == null? "":barcodeData[0][7];
                        }
                        if (element[14]['value']['value'] == "") {
                          element[14]['value']['label'] = fProduceDate == null? "":fProduceDate;
                          element[14]['value']['value'] =fProduceDate == null? "":fProduceDate;
                          element[15]['value']['label'] =fExpiryDate == null? "":fExpiryDate;
                          element[15]['value']['value'] =fExpiryDate == null? "":fExpiryDate;
                        }
                        //判断末尾
                        /* if (fNumber.lastIndexOf(
                                element[0]['value']['value'].toString()) ==
                            (hobbyIndex - 1)) {
                          var item = barCodeScan[0].toString() +
                              "-" +
                              residue.toString() +
                              "-" +
                              fsn;
                          element[10]['value']['label'] = residue.toString();
                          element[10]['value']['value'] = residue.toString();
                          element[3]['value']['label'] =
                              (double.parse(element[3]['value']['value']) +
                                      residue)
                                  .toString();
                          element[3]['value']['value'] =
                              element[3]['value']['label'];
                          residue = (residue * 100 -
                                  double.parse(element[10]['value']['value']) *
                                      100) /
                              100;
                          element[0]['value']['surplus'] = (element[9]['value']
                                          ['value'] *
                                      100 -
                                  double.parse(element[3]['value']['value']) *
                                      100) /
                              100;
                          ;
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                        } else {*/
                        //判断剩余数量是否大于扫码数量
                        if (hobby[entryIndex][0]['value']['surplus'] >= residue) {
                          var item = barCodeScan[0].toString() +
                              "-" +
                              residue.toString() +
                              "-" +
                              fsn;
                          element[10]['value']['label'] = residue.toString();
                          element[10]['value']['value'] = residue.toString();
                          element[10]['value']['remainder'] = "0";
                          element[10]['value']['representativeQuantity'] = barcodeQuantity;
                          element[3]['value']['label'] =
                              (double.parse(element[3]['value']['value']) +
                                  residue)
                                  .toString();
                          element[3]['value']['value'] =
                          element[3]['value']['label'];
                          residue = 0.0;
                          hobby[entryIndex][0]['value']['surplus'] = (hobby[entryIndex][9]
                          ['value']['value'] *
                              100 -
                              double.parse(element[3]['value']['value']) *
                                  100) /
                              100;
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                          number++;
                          break;
                        } else {
                          var item = barCodeScan[0].toString() +
                              "-" +
                              hobby[entryIndex][0]['value']['surplus'].toString() +
                              "-" +
                              fsn;
                          element[10]['value']['label'] =
                              hobby[entryIndex][0]['value']['surplus'].toString();
                          element[10]['value']['value'] =
                              hobby[entryIndex][0]['value']['surplus'].toString();

                          element[3]['value']['label'] = (element[0]['value']
                          ['surplus'] +
                              double.parse(element[3]['value']['value']))
                              .toString();
                          element[3]['value']['value'] =
                          element[3]['value']['label'];
                          residue = (residue * 100 -
                              double.parse(
                                  element[10]['value']['value']) *
                                  100) /
                              100;
                          hobby[entryIndex][0]['value']['surplus'] = (hobby[entryIndex][9]
                          ['value']['value'] *
                              100 -
                              double.parse(element[3]['value']['value']) *
                                  100) /
                              100;
                          element[10]['value']['remainder'] = residue.toString();
                          element[10]['value']['representativeQuantity'] = barcodeQuantity;
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                          number++;
                        }
                        //}
                      }
                    }
                  }
                }
              }
            } else {
              ToastUtil.showInfo('该标签已扫描');
              number++;
              break;
            }
            surplus = hobby[entryIndex][0]['value']['surplus'];
            parseEntryID = hobby[entryIndex][0]['FEntryID'];
            fIsKFPeriod = hobby[entryIndex][0]['FIsKFPeriod'];
            insertIndex = hobbyIndex;
          }
        }
      }
      if (number == 0 ) {
        var inserNum = 0.0;
        print("剩余");
        print(surplus);
        if(double.parse(barCodeScan[4]) >= surplus && this.fBillNo!=''){
          inserNum = surplus;
        }else{
          inserNum = double.parse(barCodeScan[4]);
        }

        /*if(inserNum == 0){
          ToastUtil.showInfo('该物料领料数量已达上限');
          return;
        }*/
        for(var value in materialDate){
          if(this.hobbyItem.indexWhere((v)=> v['number'] == (value[2]+'-'+parseEntryID.toString())) != -1){
            var parentIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (value[2]+'-'+parseEntryID.toString()))]['index'];
            hobby[parentIndex][0]['value']['surplus'] = (surplus - inserNum >0?surplus - inserNum:0);
          }
          List arr = [];
          arr.add({
            "title": "物料名称",
            "name": "FMaterial",
            "FEntryID": 0,
            "parseEntryID": parseEntryID,
            "FIsKFPeriod": fIsKFPeriod,
            "isHide": false,
            "value": {
              "label": value[1] + "- (" + value[2] + ")",
              "value": value[2],
              "barcode": [code],
              "surplus": surplus,
              "kingDeeCode": [barCodeScan[0].toString()+"-"+barCodeScan[4]+"-"+fsn],
              "scanCode": [barCodeScan[0].toString()+"-"+barCodeScan[4]]
            }
          });
          arr.add({
            "title": "规格型号",
            "isHide": false,
            "name": "FMaterialIdFSpecification",
            "value": {"label": value[3], "value": value[3]}
          });
          arr.add({
            "title": "单位名称",
            "name": "FUnitId",
            "isHide": false,
            "value": {"label": value[4], "value": value[5]}
          });
          Map<String, dynamic> inventoryMap = Map();
          inventoryMap['FormId'] = 'STK_Inventory';
          inventoryMap['FilterString'] = "FMaterialId.FNumber='" + value[2] + "' and FBaseQty >0";// and FStockIds
          inventoryMap['Limit'] = '20';
          inventoryMap['OrderString'] = 'FLot.FNumber DESC, FProduceDate DESC';
          inventoryMap['FieldKeys'] =
          'FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FStockId.FNumber,FBaseQty,FLot.FNumber,FAuxPropId,FStockId.FName,FStockLocId.FF100011.FNumber';
          Map<String, dynamic> inventoryDataMap = Map();
          inventoryDataMap['data'] = inventoryMap;
          String res = await CurrencyEntity.polling(inventoryDataMap);
          var stocks = jsonDecode(res);
          if (stocks.length > 0) {
            arr.add({
              "title": "退货数量",
              "name": "FBaseQty",
              "isHide": false,
              "value": {"label": "0", "value": "0" , "stocks": stocks}
            });

          }else{
            arr.add({
              "title": "退货数量",
              "name": "FBaseQty",
              "isHide": false,
              "value": {"label": "0", "value": "0" , "stocks": []}
            });
          }
          arr.add({
            "title": "仓库",
            "name": "FStockID",
            "isHide": false,
            "value": {"label": barcodeData[0][6], "value": barcodeData[0][7]}
          });

          arr.add({
            "title": "批号",
            "isHide": value[6] != true,
            "value": {"label": '', "value": ''}
          });
          arr.add({
            "title": "仓位",
            "name": "FStockLocID",
            "isHide": false,
            "value": {"label": "", "value": "", "hide": false}
          });
          arr.add({
            "title": "操作",
            "name": "",
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "基本单位",
            "name": "",
            "isHide": true,
            "value": {"label": value[4], "value": value[5]}
          });
          arr.add({
            "title": "可退数量",
            "name": "FPrdOrgId",
            "isHide": false,
            "value": {"label": surplus, "value": surplus}
          });
          arr.add({
            "title": "最后扫描数量",
            "name": "FLastQty",
            "isHide": false,
            "value": {
              "label": inserNum.toString(),
              "value": inserNum.toString(),"remainder": (double.parse(barCodeScan[4]) - inserNum).toString(),"representativeQuantity": barCodeScan[4]
            }
          });
          arr.add({
            "title": "包装数量",
            "name": "",
            "isHide": true,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "包数",
            "name": "",
            "isHide": true,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "生产日期",
            "name": "FProduceDate",
            "isHide": !fIsKFPeriod,
            "value": {
              "label": fProduceDate,
              "value": fProduceDate
            }
          });
          arr.add({
            "title": "有效期至",
            "name": "FExpiryDate",
            "isHide": !fIsKFPeriod,
            "value": {
              "label": fExpiryDate,
              "value": fExpiryDate
            }
          });
          hobby.insert(insertIndex, arr);
        }
      }
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
          } else if (hobby == 'organizations') {
            organizationsName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                organizationsNumber = organizationsListObj[elementIndex][2];
              }
              elementIndex++;
            });
            getStockList();
          }else{
            setState(() {
              hobby['value']['label'] = p;
            });
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                hobby['value']['value'] = stockListObj[elementIndex][2];
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
                            if(checkItem=="bagNum"){
                              if(this.hobby[checkData][3]['value'] != '0'){
                                var realQty = 0.0;
                                realQty = double.parse(this.hobby[checkData][3]["value"]["label"]) / double.parse(_FNumber);
                                this.hobby[checkData][12]["value"]["value"] = (realQty.ceil()).toString();
                                this.hobby[checkData][12]["value"]["label"] = (realQty.ceil()).toString();
                                this.hobby[checkData][checkDataChild]["value"]
                                ["label"] = _FNumber;
                                this.hobby[checkData][checkDataChild]['value']
                                ["value"] = _FNumber;
                              }else{
                                ToastUtil.showInfo('请输入出库数量');
                              }
                            }else if (checkItem == "FLastQty") {
                              if(double.parse(_FNumber) <= double.parse(this.hobby[checkData][checkDataChild]["value"]['representativeQuantity'])){
                                if (this.hobby[checkData][0]['value']['kingDeeCode'].length > 0) {
                                  var kingDeeCode = this.hobby[checkData][0]['value']['kingDeeCode'][this.hobby[checkData][0]['value']['kingDeeCode'].length - 1].split("-");
                                  var realQty = 0.0;
                                  this.hobby[checkData][0]['value']['kingDeeCode'].forEach((item) {
                                    var qty = item.split("-")[1];
                                    realQty += double.parse(qty);
                                  });
                                  realQty = realQty - double.parse(this.hobby[checkData][10]
                                  ["value"]["label"]);
                                  realQty = realQty + double.parse(_FNumber);
                                  this.hobby[checkData][10]["value"]["remainder"] = (Decimal.parse(this.hobby[checkData][10]["value"]["representativeQuantity"]) - Decimal.parse(_FNumber)).toString();
                                  this.hobby[checkData][3]["value"]["value"] = realQty.toString();
                                  this.hobby[checkData][3]["value"]["label"] = realQty.toString();
                                  if(this.fBillNo!="") {
                                    var entryIndex;
                                    if (this.hobby[checkData][0]['FEntryID'] ==
                                        0) {
                                      entryIndex =
                                      this.hobbyItem[this.hobbyItem.indexWhere((
                                          v) => v['number'] == (this
                                          .hobby[checkData][0]['value']['value'] +
                                          '-' + this
                                          .hobby[checkData][0]['parseEntryID']
                                          .toString()))]['index'];
                                    } else {
                                      entryIndex =
                                      this.hobbyItem[this.hobbyItem.indexWhere((
                                          v) => v['number'] == (this
                                          .hobby[checkData][0]['value']['value'] +
                                          '-' +
                                          this.hobby[checkData][0]['FEntryID']
                                              .toString()))]['index'];
                                    }
                                    hobby[entryIndex][0]['value']['surplus'] = (hobby[entryIndex][9]['value']['value'] * 100 - double.parse(this.hobby[checkData][3]['value']['value']) * 100) / 100;
                                  }
                                  this.hobby[checkData][checkDataChild]["value"]["label"] = _FNumber;
                                  this.hobby[checkData][checkDataChild]['value']["value"] = _FNumber;
                                  this.hobby[checkData][0]['value']['kingDeeCode'][this.hobby[checkData][0]['value']['kingDeeCode'].length - 1] = kingDeeCode[0] + "-" + _FNumber + "-" + kingDeeCode[2];
                                } else {
                                  ToastUtil.showInfo('无条码信息，输入失败');
                                }
                              }else{
                                ToastUtil.showInfo('输入数量大于条码可用数量');
                              }
                            }else{
                              setState(() {
                                this.hobby[checkData][checkDataChild]["value"]
                                ["label"] = _FNumber;
                                this.hobby[checkData][checkDataChild]['value']
                                ["value"] = _FNumber;
                              });

                            }
                            checkItem = '';
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
  //调出弹窗 扫码
  void inNumDialog(childList, val, index, stockId,stockName, fLot,position) {
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
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('库存数量为('+val.toString()+')',
                        style: TextStyle(
                            fontSize: 16, decoration: TextDecoration.none)),
                  ),
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

                          setState(() {
                            /*dataItem[3]['value']['value'] = options[index][5];
                            dataItem[3]['value']['label'] = options[index][5];
                            dataItem[13]['value']['itemList'].add(childList);*/
                            print(_FNumber);
                            print(_FNumber is String);
                            if(_FNumber != '0' && _FNumber != ''&& _FNumber != null){
                              if(double.parse(_FNumber) <= double.parse(val)){
                                if(double.parse(_FNumber) <= this.hobby[checkData][9]["value"]["value"]){

                                  this.hobby[checkData][checkDataChild]["value"]
                                  ["stocks"][index][4] = Decimal.parse(val) +Decimal.parse(this.hobby[checkData][checkDataChild]["value"]["label"]) - Decimal.parse(_FNumber);
                                  this.hobby[checkData][checkDataChild]["value"]
                                  ["label"] = (Decimal.parse(_FNumber)).toString();
                                  this.hobby[checkData][checkDataChild]['value']
                                  ["value"] = this.hobby[checkData][checkDataChild]["value"]["label"] ;
                                  childList = childList +"-"+ _FNumber;
                                  this.hobby[checkData][13]['value']
                                  ["itemList"].add(childList);
                                  this.hobby[checkData][4]['value']
                                  ["value"] = stockId;
                                  this.hobby[checkData][4]['value']
                                  ["label"] = stockName;
                                  this.hobby[checkData][5]['value']
                                  ["value"] = fLot;
                                  this.hobby[checkData][5]['value']
                                  ["label"] = fLot;
                                  this.hobby[checkData][6]['value']
                                  ["value"] = position;
                                  this.hobby[checkData][6]['value']
                                  ["label"] = position;
                                  if(this.fBillNo!="") {
                                    var entryIndex;
                                    if(this.hobbyItem.length>0){
                                      if (this.hobby[checkData][0]['FEntryID'] == 0) {
                                        entryIndex = this.hobbyItem[this.hobbyItem.indexWhere((v) => v['number'] == (this.hobby[checkData][0]['value']['value'] + '-' + this.hobby[checkData][0]['parseEntryID'].toString()))]['index'];
                                      } else {
                                        entryIndex = this.hobbyItem[this.hobbyItem.indexWhere((v) => v['number'] == (this.hobby[checkData][0]['value']['value'] + '-' + this.hobby[checkData][0]['FEntryID'].toString()))]['index'];
                                      }
                                    }else{
                                      entryIndex = checkData;
                                    }
                                    hobby[entryIndex][0]['value']['surplus'] = (hobby[entryIndex][9]['value']['value'] * 100 - double.parse(this.hobby[checkData][3]['value']['value']) * 100) / 100;
                                  }
                                  Navigator.pop(context);
                                }else{
                                  ToastUtil.showInfo('输入数量大于可退数量');
                                }
                              }else{
                                ToastUtil.showInfo('输入数量大于库存数量');
                              }
                            }else{
                              ToastUtil.showInfo('请输入数量');
                            }

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
  Future<List<int>?> _showModalBottomSheet(
      BuildContext context, List<dynamic> options, List<dynamic> dataItem) async {
    return showModalBottomSheet<List<int>?>(
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context1, setState) {
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(10.0),
                topRight: const Radius.circular(10.0),
              ),
            ),
            height: MediaQuery.of(context).size.height / 2.0,
            child: Column(children: [
              Expanded(
                child: ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    return Column(
                      children: <Widget>[
                        ListTile(
                          title: Text('批号:'+options[index][5]+';仓库:'+options[index][7]+';数量:'+options[index][4].toString()),
                          onTap: () {
                            setState(() {
                              print(dataItem);
                              var childList = options[index][6] == null?  options[index][5].toString() +"-无":options[index][5].toString() +"-"+ options[index][6].toString();
                              Navigator.pop(context);
                              inNumDialog(childList, options[index][4].toString(),index,options[index][3],options[index][7], options[index][5].toString(), options[index][8].toString());
                            });
                            print(options[index]);
                            // Do something

                          },
                        ),
                        Divider(height: 1.0),
                      ],
                    );
                  },
                  itemCount: options.length,
                ),
              ),
            ]),
          );
        });
      },
    );
  }
  setClickData(Map<dynamic,dynamic> dataItem, val) async{
    setState(() {
      dataItem['value']['value'] = val;
      dataItem['value']['label'] = val;
    });
  }

  List<Widget> _getHobby() {
    List<Widget> tempList = [];
    for (int i = 0; i < this.hobby.length; i++) {
      List<Widget> comList = [];
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (!this.hobby[i][j]['isHide']) {
          if (j == 3) {
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
                              icon: new Icon(Icons.search),
                              tooltip: '选择库存',
                              padding: EdgeInsets.only(left: 30),
                              onPressed: () async{
                                if(this.hobby[i][j]["value"]["stocks"].length>0){
                                  await _showModalBottomSheet(
                                      context, this.hobby[i][j]["value"]["stocks"],this.hobby[i]);
                                  checkData = i;
                                  checkDataChild = j;
                                  _FNumber = '0';
                                  this._textNumber.value =
                                      _textNumber.value.copyWith(
                                        text: '0',
                                      );
                                }else{
                                  ToastUtil.showInfo('无库存');
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
          } else if (j == 10) {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                      title: Text(this.hobby[i][j]["title"] +
                          '：' +
                          this.hobby[i][j]["value"]["label"].toString()+'剩余('+this.hobby[i][j]["value"]["remainder"].toString()+')'),
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
                                checkItem = 'FLastQty';
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
            );
          }else if (j == 4) {
            comList.add(
              _item('仓库:', stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],stock:this.hobby[i]),
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
                            Visibility(
                              maintainSize: false,
                              maintainState: false,
                              maintainAnimation: false,
                              visible: this.hobby[i][0]["FEntryID"]!=0,
                              child: new FlatButton(
                                color: Colors.blue,
                                textColor: Colors.white,
                                child: new Text('添加行'),
                                onPressed: () {
                                  if(this.hobby[i][9]["value"]["value"] <= double.parse(this.hobby[i][3]["value"]["value"])){
                                    ToastUtil.showInfo('该物料退料数量已达上限');
                                  }else{
                                    if(double.parse(this.hobby[i][3]["value"]["value"]) == 0){
                                      ToastUtil.showInfo('请完成当前分录再添加分录');
                                    }else{
                                      this.hobby[i][9]["value"]["value"] = double.parse(this.hobby[i][3]["value"]["value"]);
                                      this.hobby[i][9]["value"]["label"] = this.hobby[i][9]["value"]["value"];
                                      this.getMaterialList([[this.hobby[i][0]["value"]["value"],"","","","0"]], this.hobby[i][0]["value"]["value"], '', '', '', '');
                                    }
                                  }
                                },
                              ),
                            ),

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

  pushDown(val, type) async {
    //下推
    Map<String, dynamic> pushMap = Map();
    pushMap['EntryIds'] = val;
    pushMap['RuleId'] = "PUR_MRAPP-PUR_MRB";
    pushMap['TargetFormId'] = "PUR_MRB";
    pushMap['IsEnableDefaultRule'] = "false";
    pushMap['IsDraftWhenSaveFail'] = "false";
    var downData =
    await SubmitEntity.pushDown({"formid": "PUR_MRAPP", "data": pushMap});
    var res = jsonDecode(downData);
    print(res);
    //判断成功
    if (res['Result']['ResponseStatus']['IsSuccess']) {
      //查询入库单
      var entitysNumber =
      res['Result']['ResponseStatus']['SuccessEntitys'][0]['Number'];
      Map<String, dynamic> inOrderMap = Map();
      inOrderMap['FormId'] = 'PUR_MRB';
      inOrderMap['FilterString'] = "FBillNo='$entitysNumber'";
      inOrderMap['FieldKeys'] =
      'FPURMRBENTRY_FEntryId,FMATERIALID.FNumber,FMATERIALID.FName,FUnitId.FNumber';
      String order = await CurrencyEntity.polling({'data': inOrderMap});
      print(order);
      var resData = jsonDecode(order);
      //组装数据
      Map<String, dynamic> dataMap = Map();
      dataMap['data'] = inOrderMap;
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedUpDataFields'] = ['FEntity','FSerialSubEntity','FSerialNo'];
      orderMap['NeedReturnFields'] = ['FEntity','FSerialSubEntity','FSerialNo'];
      orderMap['IsDeleteEntry'] = true;
      Map<String, dynamic> Model = Map();
      Model['FID'] = res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id'];
      var FEntity = [];
      for (int entity = 0; entity < resData.length; entity++) {
        for (int element = 0; element < this.hobby.length; element++) {
          if (resData[entity][1].toString() ==
              this.hobby[element][0]['value']['value'].toString()) {
            Map<String, dynamic> FEntityItem = Map();
            FEntityItem['FEntryID'] = resData[entity][0];
            FEntityItem['FRMREALQTY'] =
            this.hobby[element][3]['value']['value'];
            FEntityItem['FSTOCKID'] = {
              "FNumber": this.hobby[element][4]['value']['value']
            };
            FEntityItem['FAuxPropId'] = {
              "FAUXPROPID__FF100002": {"FNumber": this.hobby[element][1]['value']['value']}
            };
            /*FEntityItem['FStockStatusId'] = {"FNumber": "KCZT01_SYS"};*/
            var fSerialSub = [];
            var kingDeeCode = this.hobby[element][0]['value']['kingDeeCode'];
            for (int subj = 0; subj < kingDeeCode.length; subj++) {
              Map<String, dynamic> subObj = Map();
              var itemCode = kingDeeCode[subj].split("-");
              if(itemCode.length>2){
                if(itemCode.length > 3){
                  subObj['FSerialNo'] = itemCode[2]+'-'+itemCode[3];
                }else{
                  subObj['FSerialNo'] = itemCode[2];
                }
              }
              fSerialSub.add(subObj);
            }
            FEntityItem['FSerialSubEntity'] = fSerialSub;
            FEntity.add(FEntityItem);
          }
        }
      }
      Model['FEntity'] = FEntity;
      orderMap['Model'] = Model;
      dataMap = {"formid": "PUR_MRB", "data": orderMap, "isBool": true};
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
  saveOrder() async {
    //获取登录信息
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      Map<String, dynamic> dataMap = Map();
      dataMap['formid'] = 'PUR_MRB';
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedReturnFields'] = [
        'FBillNo',
      ];
      orderMap['IsDeleteEntry'] = false;
      Map<String, dynamic> Model = Map();
      Model['FID'] = 0;
      Model['FBillTypeID'] = {"FNUMBER": "TLD01_SYS"};
      Model['FDate'] = FDate;
      Model['FOwnerTypeIdHead'] = "BD_OwnerOrg";
      Model['FMRTYPE'] = "B";
      Model['FMRMODE'] = "A";
      Model['FOwnerIdHead'] = {"FNumber": this.fOrgID};
      //判断有源单 无源单
      if(this.isScanWork){
        Model['FStockOrgId'] = {"FNumber": orderDate[0][8].toString()};
        Model['FPurchaseOrgId'] = {"FNumber": orderDate[0][1].toString()};
        Model['FSupplierID'] = {"FNumber": orderDate[0][16].toString()};
        //Model['F_ora_Assistant1'] = {"FNumber": this.hobby[0][0]['F_ora_Assistant1']};
      }else{
        if (this.supplierNumber == null) {
          this.isSubmit = false;
          ToastUtil.showInfo('请选择供应商');
          return;
        }
        Model['FStockOrgId'] = {"FNumber": this.fOrgID};
        Model['FPurchaseOrgId'] = {"FNumber": this.fOrgID};
        Model['FSupplierID'] = {"FNumber": this.supplierNumber};
      }
      var FEntity = [];
      var hobbyIndex = 0;
      this.hobbyItem = [];
      for(var i = 0;i<this.hobby.length;i++){
        if(this.hobbyItem.length==0){
          Map<String, dynamic> hobbyMap = Map();
          hobbyMap['number'] = this.hobby[i][0]['value']['value']+"-"+this.hobby[i][0]['FEntryID'].toString();
          hobbyMap['index'] = i;
          this.hobbyItem.add(hobbyMap);
        }else if(this.hobby[i][0]['FEntryID'] != 0){
          Map<String, dynamic> hobbyMap = Map();
          hobbyMap['number'] = this.hobby[i][0]['value']['value']+"-"+this.hobby[i][0]['FEntryID'].toString();
          hobbyMap['index'] = i;
          this.hobbyItem.add(hobbyMap);
        }
      }
      this.hobby.forEach((element) {
        if (element[3]['value']['value'] != '0' && element[3]['value']['value'] != '' &&
            element[4]['value']['value'] != '') {
          var entryIndex;
          Map<String, dynamic> FEntityItem = Map();
          FEntityItem['FMaterialId'] = {"FNumber": element[0]['value']['value']};
          FEntityItem['FUnitID'] = {"FNumber": element[2]['value']['value']};
          FEntityItem['FSTOCKID'] = {"FNumber": element[4]['value']['value']};
          FEntityItem['FLot'] = {"FNumber": element[5]['value']['value']};
          FEntityItem['FSRCBillTypeId'] = "STK_InStock";

          FEntityItem['FSTOCKLOCID'] = {
            "FSTOCKLOCID__FF100011": {
              "FNumber": element[6]['value']['value']
            }
          };
          FEntityItem['FRMREALQTY'] = element[3]['value']['value'];
          FEntityItem['FOWNERTYPEID'] = "BD_OwnerOrg";
          FEntityItem['FOWNERID'] = {"FNumber": this.fOrgID};
          FEntityItem['FSRCBillNo'] = this.fBillNo;
          if(orderDate.length>0){
            if(element[0]['FEntryID'] == 0){
              entryIndex = this.hobbyItem[this.hobbyItem.indexWhere((v)=> v['number'] == (element[0]['value']['value']+'-'+element[0]['parseEntryID'].toString()))]['index'];
              FEntityItem['FPRICEUNITID'] = {"FNumber": this.hobby[entryIndex][0]['FPRICEUNITID']};
              //FEntityItem['F_ora_Assistant'] = {"FNumber": this.hobby[entryIndex][0]['F_ora_Assistant']};
              FEntityItem['FTAXPRICE'] = this.hobby[entryIndex][0]['FTAXPRICE'];
              FEntityItem['FENTRYTAXRATE'] = this.hobby[entryIndex][0]['FENTRYTAXRATE'];
              FEntityItem['FReceiveLot'] = {"FNumber": this.hobby[entryIndex][0]['FReceiveLot']};
              FEntityItem['FPURMRBENTRY_Link'] = [
                {
                  "FPURMRBENTRY_Link_FRuleId": "STK_InStock-PUR_MRB",
                  "FPURMRBENTRY_Link_FSTableName": "T_STK_INSTOCKENTRY",
                  "FPURMRBENTRY_Link_FSBillId": this.hobby[entryIndex][0]['FID'],
                  "FPURMRBENTRY_Link_FSId": this.hobby[entryIndex][0]['FEntryId'],
                  "FPURMRBENTRY_Link_FCarryBaseQty": element[3]['value']['value'],
                  "FPURMRBENTRY_Link_FBASEUNITQTY": element[3]['value']['value'],
                }
              ];
            }else{
              FEntityItem['FPRICEUNITID'] = {"FNumber": element[0]['FPRICEUNITID']};
              //FEntityItem['F_ora_Assistant'] = {"FNumber": element[0]['F_ora_Assistant']};
              FEntityItem['FTAXPRICE'] = element[0]['FTAXPRICE'];
              FEntityItem['FENTRYTAXRATE'] = element[0]['FENTRYTAXRATE'];
              FEntityItem['FReceiveLot'] = {"FNumber": element[0]['FReceiveLot']};
              FEntityItem['FPURMRBENTRY_Link'] = [
                {
                  "FPURMRBENTRY_Link_FRuleId": "STK_InStock-PUR_MRB",
                  "FPURMRBENTRY_Link_FSTableName": "T_STK_INSTOCKENTRY",
                  "FPURMRBENTRY_Link_FSBillId": element[0]['FID'],
                  "FPURMRBENTRY_Link_FSId": element[0]['FEntryId'],
                  "FPURMRBENTRY_Link_FCarryBaseQty": element[3]['value']['value'],
                  "FPURMRBENTRY_Link_FBASEUNITQTY": element[3]['value']['value'],
                }
              ];
            }
          }
          var fSerialSub = [];
          var kingDeeCode = element[0]['value']['kingDeeCode'];
          for (int subj = 0; subj < kingDeeCode.length; subj++) {
            Map<String, dynamic> subObj = Map();
            var itemCode = kingDeeCode[subj].split("-");
            if(itemCode.length>2){
              if(itemCode.length > 3){
                subObj['FSerialNo'] = itemCode[2]+'-'+itemCode[3];
              }else{
                subObj['FSerialNo'] = itemCode[2];
              }
            }
            fSerialSub.add(subObj);
          }
          FEntityItem['FSerialSubEntity'] = fSerialSub;

          FEntity.add(FEntityItem);
        }
        hobbyIndex++;
      });
      if(FEntity.length==0){
        this.isSubmit = false;
        ToastUtil.showInfo('请输入数量,仓库');
        return;
      }
      Model['FPURMRBENTRY'] = FEntity;
      orderMap['Model'] = Model;
      dataMap['data'] = orderMap;
      var datass = jsonEncode(dataMap);
      String order = await SubmitEntity.save(dataMap);
      var res = jsonDecode(order);
      print(res);
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        Map<String, dynamic> submitMap = Map();
        var returnData = res['Result']['NeedReturnData'];
        submitMap = {
          "formid": "PUR_MRB",
          "data": {
            'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
          }
        };
        //提交
        HandlerOrder.orderHandler(
            context,
            submitMap,
            1,
            "PUR_MRB",
            SubmitEntity.submit(submitMap))
            .then((submitResult) async{
          if (submitResult) {
            //审核
            HandlerOrder.orderHandler(
                context,
                submitMap,
                1,
                "PUR_MRB",
                SubmitEntity.audit(submitMap))
                .then((auditResult) async{
              if (auditResult) {
            var errorMsg = "";
            if(fBarCodeList == 1){
              for (int i = 0; i < this.hobby.length; i++) {
                if (this.hobby[i][3]['value']['value'] != '0' &&
                    this.hobby[i][4]['value']['value'] != '') {
                  var kingDeeCode = this.hobby[i][0]['value']['kingDeeCode'];
                  for(int j = 0;j<kingDeeCode.length;j++){
                    Map<String, dynamic> dataCodeMap = Map();
                    dataCodeMap['formid'] = 'QDEP_Cust_BarCodeList';
                    Map<String, dynamic> orderCodeMap = Map();
                    orderCodeMap['NeedReturnFields'] = [];
                    orderCodeMap['IsDeleteEntry'] = false;
                    Map<String, dynamic> codeModel = Map();
                    var itemCode = kingDeeCode[j].split("-");
                    codeModel['FID'] = itemCode[0];
                    codeModel['FOwnerID'] = {
                      "FNUMBER": tissue
                    };
                    codeModel['FStockOrgID'] = {
                      "FNUMBER": tissue
                    };
                    codeModel['FStockID'] = {
                      "FNUMBER": this.hobby[i][4]['value']['value']
                    };
                    Map<String, dynamic> codeFEntityItem = Map();
                    codeFEntityItem['FBillDate'] = FDate;
                    codeFEntityItem['FInQty'] = itemCode[1];
                    if(orderDate.length>0){
                      codeFEntityItem['FEntryBillNo'] = orderDate[0][0];
                    }else{
                      codeFEntityItem['FEntryBillNo'] = returnData[0]['FBillNo'];
                    }
                    codeFEntityItem['FEntryStockID'] ={
                      "FNUMBER": this.hobby[i][4]['value']['value']
                    };
                    var codeFEntity = [codeFEntityItem];
                    codeModel['FEntity'] = codeFEntity;
                    orderCodeMap['Model'] = codeModel;
                    dataCodeMap['data'] = orderCodeMap;
                    print(dataCodeMap);
                    String codeRes = await SubmitEntity.save(dataCodeMap);
                    var barcodeRes = jsonDecode(codeRes);
                    if(!barcodeRes['Result']['ResponseStatus']['IsSuccess']){
                      errorMsg +="错误反馈："+itemCode[1]+":"+barcodeRes['Result']['ResponseStatus']['Errors'][0]['Message'];
                    }
                    print(codeRes);
                  }
                }
              }
            }
            if(errorMsg !=""){
              ToastUtil.errorDialog(context,
                  errorMsg);
              this.isSubmit = false;
            }
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
                    "PUR_MRB",
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
                  saveOrder();
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
            title: Text("采购退货"),
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
                  ),
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("线路名称：$xlmc"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  Visibility(
                    maintainSize: false,
                    maintainState: false,
                    maintainAnimation: false,
                    visible: isScanWork,
                    child: Column(
                      children: [
                        Container(
                          color: Colors.white,
                          child: ListTile(
                            /* title: TextWidget(FBillNoKey, '生产订单：'),*/
                            title: Text("供应商：$supName"),
                          ),
                        ),
                        divider,
                      ],
                    ),
                  ),
                  _dateItem('日期：', DateMode.YMD),
                  Visibility(
                    maintainSize: false,
                    maintainState: false,
                    maintainAnimation: false,
                    visible: !isScanWork,
                    child: _item('供应商:', this.supplierList, this.supplierName,
                        'supplier'),
                  ),
                  /* Visibility(
                    maintainSize: false,
                    maintainState: false,
                    maintainAnimation: false,
                    visible: isScanWork,
                    child: Column(
                      children: [
                        Container(
                          color: Colors.white,
                          child: ListTile(
                            title: Text("组织：$organizationsName"),
                          ),
                        ),
                        divider,
                      ],
                    ),
                  ),
                  Visibility(
                    maintainSize: false,
                    maintainState: false,
                    maintainAnimation: false,
                    visible: !isScanWork,
                    child: _item('组织:', this.organizationsList, this.organizationsName,
                        'organizations'),
                  ),*/
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