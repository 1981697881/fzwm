import 'dart:convert';
import 'package:fzwm/components/my_text.dart';
import 'package:fzwm/model/currency_entity.dart';
import 'package:fzwm/model/submit_entity.dart';
import 'package:fzwm/utils/refresh_widget.dart';
import 'package:fzwm/utils/text.dart';
import 'package:fzwm/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pickers/pickers.dart';
import 'package:flutter_pickers/more_pickers/init_data.dart';
import 'package:flutter_pickers/style/default_style.dart';
import 'package:flutter_pickers/time_picker/model/date_mode.dart';
import 'package:flutter_pickers/time_picker/model/pduration.dart';
import 'package:flutter_pickers/time_picker/model/suffix.dart';
import 'dart:io';
import 'package:flutter_pickers/utils/check.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';


final String _fontFamily = Platform.isWindows ? "Roboto" : "";

class PickingDetail extends StatefulWidget {
  var FBillNo;
  var FSeq;
  var FEntryId;
  var FID;
  var FProdOrder;
  var FBarcode;

  PickingDetail(
      {Key? key,
      @required this.FBillNo,
      @required this.FSeq,
      @required this.FEntryId,
      @required this.FID,
      @required this.FBarcode,
      @required this.FProdOrder})
      : super(key: key);

  @override
  _PickingDetailState createState() =>
      _PickingDetailState(FBillNo, FSeq, FEntryId, FID, FProdOrder,FBarcode);
}
class _PickingDetailState extends State<PickingDetail> {
  GlobalKey<TextWidgetState> textKey = GlobalKey();
  GlobalKey<TextWidgetState> FBillNoKey = GlobalKey();
  GlobalKey<TextWidgetState> FSaleOrderNoKey = GlobalKey();
  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();
  GlobalKey<PartRefreshWidgetState> FPrdOrgIdKey = GlobalKey();

  final _textNumber = TextEditingController();
  var checkItem;
  var FBillNo = '';
  var FSaleOrderNo = '';
  var FName = '';
  var FNumber = '';
  var FDate = '';
  var FStockOrgId = '';
  var FPrdOrgId = '';
  var show = false;
  var isSubmit = false;
  var isScanWork = false;
  var checkData;
  var checkDataChild;

  var selectData = {
    DateMode.YMD: "",
  };
  var stockList = [];
  List<dynamic> stockListObj = [];
  var selectStock = "";
  Map<String, dynamic> selectStockMap = Map();
  List<dynamic> orderDate = [];
  List<dynamic> collarOrderDate = [];
  final divider = Divider(height: 1, indent: 20);
  final rightIcon = Icon(Icons.keyboard_arrow_right);
  final scanIcon = Icon(Icons.filter_center_focus);
  static const scannerPlugin =
      const EventChannel('com.shinow.pda_scanner/plugin');
  StreamSubscription ?_subscription;
  var _code;
  var _FNumber;
  var FSeq;
  var fBillNo;
  var fEntryId;
  var fid;
  var FProdOrder;
  var FBarcode;

  _PickingDetailState(fBillNo, FSeq, fEntryId, fid, FProdOrder,FBarcode) {
    this.fBillNo = fBillNo['value'];
    this.FSeq = FSeq['value'];
    this.fEntryId = fEntryId['value'];
    this.fid = fid['value'];
    this.FProdOrder = FProdOrder['value'];
    this.FBarcode = FBarcode;
    this.getOrderList();
  }

  @override
  void initState() {
    super.initState();
    DateTime dateTime = DateTime.now();
    var nowDate = "${dateTime.year}-${dateTime.month}-${dateTime.day}";
    selectData[DateMode.YMD] = nowDate;
    /// 开启监听
    if (_subscription == null) {
      _subscription = scannerPlugin
          .receiveBroadcastStream()
          .listen(_onEvent, onError: _onError);
    }
    EasyLoading.dismiss();
    getWorkShop();
    getStockList();
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
      _subscription!.cancel();;
    }
  }

  //获取仓库
  getStockList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_STOCK';
    userMap['FieldKeys'] = 'FStockID,FName,FNumber,FIsOpenLocation';
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    userMap['FilterString'] = "FUseOrgId.FNumber ="+deptData[1];
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    stockListObj = jsonDecode(res);
    stockListObj.forEach((element) {
      stockList.add(element[1]);
    });
  }

  // 查询数据集合
  List hobby = [];

  //获取订单信息
  getOrderList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FilterString'] =
        "FNoPickedQty>0 and FMOBillNO='$fBillNo' and FMOEntrySeq = '$FSeq'";
    userMap['FormId'] = 'PRD_PPBOM';
    userMap['FieldKeys'] =
        'FBillNo,FPrdOrgId.FNumber,FPrdOrgId.FName,FMOBillNO,FMOEntrySeq,FEntity_FEntryId,FEntity_FSeq,FMaterialID2.FNumber,FMaterialID2.FName,FMaterialID2.FSpecification,FUnitID2.FNumber,FUnitID2.FName,FNoPickedQty,FID,FLot.FNumber,FMaterialId.FIsBatchManage';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    orderDate = jsonDecode(order);
    DateTime dateTime = DateTime.now();
    FDate =
        "${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}";
    if (orderDate.length > 0) {
      FStockOrgId = orderDate[0][1].toString();
      FPrdOrgId = orderDate[0][1].toString();
      hobby = [];
      orderDate.forEach((value) {
        List arr = [];
        arr.add({
          "title": "物料编码",
          "name": "FMaterialId",
          "isHide": true,
          "value": {"label": value[7], "value": value[7]}
        });
        arr.add({
          "title": "物料名称",
          "isHide": false,
          "name": "FDate",
          "value": {"label": value[8], "value": value[8]}
        });
        arr.add({
          "title": "单位",
          "name": "FStockOrgNumber",
          "isHide": true,
          "value": {"label": value[10], "value": value[10]}
        });
        arr.add({
          "title": "单位",
          "name": "FStockOrgName",
          "isHide": false,
          "value": {"label": value[11], "value": value[11]}
        });
        arr.add({
          "title": "用量",
          "name": "FPrdOrgId",
          "isHide": false,
          "value": {"label": value[12], "value": value[12]}
        });
        arr.add({
          "title": "领料数量",
          "name": "FBaseQty",
          "isHide": false,
          "value": {"label": value[12], "value": value[12]}
        });
        /*arr.add({
          "title": "仓库",
          "name": "FStockId",
          "isHide": false,
          "value": {"label": value[18], "value": value[19]}
        });
        arr.add({
          "title": "批号",
          "name": "",
          "isHide": value[15] != true,
          "value": {"label": value[14] == null? "":value[14], "value": value[14] == null? "":value[14]}
        });*/
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
  }

  void _onEvent(event) async {
    _code = event;
    print("ChannelPage: $event");
  }

  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
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
              PartRefreshWidget(globalKey, () {
                //2、使用 创建一个widget
                return MyText(
                    (PicketUtil.strEmpty(selectData[model])
                        ? '暂无'
                        : selectData[model])!,
                    color: Colors.grey,
                    rightpadding: 18);
              }),
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
        setState(() async {
          switch (model) {
            case DateMode.YMD:
              Map<String, dynamic> userMap = Map();
              selectData[model] = '${p.year}-${p.month}-${p.day}';
              FDate = '${p.year}-${p.month}-${p.day}';
              await getOrderList();
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
          selectStock = p;
          var elementIndex = 0;
          stockList.forEach((element) {
            if (element == p) {
              selectStockMap['FID'] = stockListObj[elementIndex][0];
              selectStockMap['FName'] = stockListObj[elementIndex][1];
              selectStockMap['FNumber'] = stockListObj[elementIndex][2];
            }
            elementIndex++;
          });
        });
      },
    );
  }
  List<Widget> _getHobby() {
    List<Widget> tempList = [];
    for (int i = 0; i < this.hobby.length; i++) {
      List<Widget> comList = [];
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (!this.hobby[i][j]['isHide']) {
          if (j == 5) {
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
                              icon: new Icon(Icons.mode_edit),
                              tooltip: '输入数量',
                              padding: EdgeInsets.only(left: 30),
                              onPressed: () {
                                this._textNumber.text =
                                    this.hobby[i][j]["value"]["label"].toString();
                                this._FNumber =
                                    this.hobby[i][j]["value"]["label"].toString();
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

  //修改状态
  alterStatus(dataMap) async {
    var status = await SubmitEntity.alterStatus(dataMap);
    print(status);
    if (status != null) {
      var res = jsonDecode(status);
      print(res);
      if (res != null) {
        return res;
      }
    }
  }

  /*this.hobby = [];
          this.orderDate = [];
          this.FBillNo = '';
          this.FSaleOrderNo = '';
          ToastUtil.showInfo('提交成功');*/

  // 领料后操作
  handlerStatus() async {
    //修改为开工状态
    Map<String, dynamic> dataMap = Map();
    var numbers = [];
    dataMap['formid'] = 'PRD_MO';
    dataMap['opNumber'] = 'toStart';
    Map<String, dynamic> entityMap = Map();
    entityMap['Id'] = fid;
    entityMap['EntryIds'] = fEntryId;
    numbers.add(entityMap);
    dataMap['data'] = {'PkEntryIds': numbers};
    var startRes = await this.alterStatus(dataMap);
    print(startRes);
    if (startRes['Result']['ResponseStatus']['IsSuccess']) {
      var serialNum = FProdOrder.truncate();
      for(var i = serialNum;i<=4;i++){
        //查询生产订单
        Map<String, dynamic> userMap = Map();
        userMap['FilterString'] = "FSaleOrderNo='$FBarcode' and FProdOrder >= " + (serialNum).toString() + " and FProdOrder <" + (serialNum + 1).toString();
        userMap['FormId'] = "PRD_MO";
        userMap['FieldKeys'] =
        'FBillNo,FTreeEntity_FEntryId,FID,FProdOrder,FTreeEntity_FSeq';
        Map<String, dynamic> proMoDataMap = Map();
        proMoDataMap['data'] = userMap;
        String order = await CurrencyEntity.polling(proMoDataMap);
        var orderRes = jsonDecode(order);
        if(orderRes.length > 0){
          break;
        }
      }
      //查询生产订单
      Map<String, dynamic> userMap = Map();
      userMap['FilterString'] = "FSaleOrderNo='$FBarcode' and FProdOrder >= " + (serialNum+1).toString() + " and FProdOrder <" + (serialNum + 2).toString();
      userMap['FormId'] = "PRD_MO";
      userMap['FieldKeys'] =
      'FBillNo,FTreeEntity_FEntryId,FID,FProdOrder,FTreeEntity_FSeq';
      Map<String, dynamic> proMoDataMap = Map();
      proMoDataMap['data'] = userMap;
      String order = await CurrencyEntity.polling(proMoDataMap);
      var orderRes = jsonDecode(order);
      if(orderRes.length > 0){
        orderRes.forEach((element) async {
          //查询用料清单
          Map<String, dynamic> materialsMap = Map();
          var FMOEntrySeq = element[4];
          var FMOBillNo = element[0];
          materialsMap['FilterString'] = "FMOBillNO=" +
              FMOBillNo.toString() +
              " and FMOEntrySeq = " +
              FMOEntrySeq.toString();
          materialsMap['FormId'] = 'PRD_PPBOM';
          materialsMap['FieldKeys'] =
          'FID';
          Map<String, dynamic> materialsDataMap = Map();
          materialsDataMap['data'] = materialsMap;
          String materialsMapOrder =
          await CurrencyEntity.polling(materialsDataMap);
          //修改用料清单为审核状态
          Map<String, dynamic> auditDataMap = Map();
          auditDataMap = {
            "formid": "PRD_PPBOM",
            "data": {'Ids': materialsMapOrder[0][0]}
          };
          await SubmitEntity.submit(auditDataMap);
          var auditRes = await SubmitEntity.audit(auditDataMap);
          //修改为下达状态
          Map<String, dynamic> releaseDataMap = Map();
          var releaseNumbers = [];
          releaseDataMap['formid'] = 'PRD_MO';
          releaseDataMap['opNumber'] = 'ToRelease';
          Map<String, dynamic> releaseEntityMap = Map();
          releaseEntityMap['Id'] = element[2];
          releaseEntityMap['EntryIds'] = element[1];
          releaseNumbers.add(releaseEntityMap);
          releaseDataMap['data'] = {'PkEntryIds': releaseNumbers};
          var releaseRes = await this.alterStatus(releaseDataMap);
          if (releaseRes['Result']['ResponseStatus']['IsSuccess']) {
            this.hobby = [];
            this.orderDate = [];
            this.FBillNo = '';
            ToastUtil.showInfo('提交成功');
            Navigator.of(context).pop("refresh");
          } else {
            setState(() {
              ToastUtil.showInfo(releaseRes['Result']['ResponseStatus']
              ['Errors'][0]['Message']);
            });
          }
        });
      }else{
        this.hobby = [];
        this.orderDate = [];
        this.FBillNo = '';
        ToastUtil.showInfo('提交成功');
        Navigator.of(context).pop("refresh");
      }
    } else {
      setState(() {
        this.isSubmit = false;
        ToastUtil.errorDialog(context,
            startRes['Result']['ResponseStatus']['Errors'][0]['Message']);
      });

    }
  }
  //删除
  deleteOrder(Map<String, dynamic> map,title) async {
    var subData = await SubmitEntity.delete(map);
    print(subData);
    if (subData != null) {
      var res = jsonDecode(subData);
      if (res != null) {
        if (res['Result']['ResponseStatus']['IsSuccess']) {
         /* this.hobby = [];
          this.orderDate = [];
          this.FBillNo = '';
          ToastUtil.showInfo('提交成功');
          Navigator.of(context).pop("refresh");*/
          setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(context,
                title);
          });
        } else {
          setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(context,
                res['Result']['ResponseStatus']['Errors'][0]['Message']);
          });
        }
      }
    }
  }
  //反审核
  unAuditOrder(Map<String, dynamic> map,title) async {
    var subData = await SubmitEntity.unAudit(map);
    print(subData);
    if (subData != null) {
      var res = jsonDecode(subData);
      if (res != null) {
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          //提交清空页面
          Map<String, dynamic> deleteMap = Map();
          deleteMap = {
            "formid": "PRD_PickMtrl",
            "data": {
              'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
            }
          };
          deleteOrder(deleteMap,title);
        } else {
          setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(context,
                res['Result']['ResponseStatus']['Errors'][0]['Message']);
          });
        }
      }
    }
  }
  //审核
  auditOrder(Map<String, dynamic> auditMap) async {
    var subData = await SubmitEntity.audit(auditMap);
    print(subData);
    if (subData != null) {
      var res = jsonDecode(subData);
      if (res != null) {
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          //提交清空页面
          /*handlerStatus();*/
          this.hobby = [];
          this.orderDate = [];
          this.FBillNo = '';
          ToastUtil.showInfo('提交成功');
          Navigator.of(context).pop("refresh");
        } else {
          unAuditOrder(auditMap,res['Result']['ResponseStatus']['Errors'][0]['Message']);
          /*setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(context,
                res['Result']['ResponseStatus']['Errors'][0]['Message']);
          });*/
        }
      }
    }
  }

  //提交
  submitOrder(Map<String, dynamic> submitMap) async {
    var subData = await SubmitEntity.submit(submitMap);
    print(subData);
    if (subData != null) {
      var res = jsonDecode(subData);
      if (res != null) {
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          //提交清空页面
          Map<String, dynamic> auditMap = Map();
          auditMap = {
            "formid": "PRD_PickMtrl",
            "data": {
              'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
            }
          };
          auditOrder(auditMap);
        } else {
          setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(context,
                res['Result']['ResponseStatus']['Errors'][0]['Message']);
          });
        }
      }
    }
  }

  //保存
  saveOrder() async {
    Map<String, dynamic> dataMap = Map();
    dataMap['formid'] = 'PRD_PickMtrl';
    Map<String, dynamic> orderMap = Map();
    orderMap['NeedReturnFields'] = [];
    orderMap['IsDeleteEntry'] = true;
    Map<String, dynamic> Model = Map();
    Model['FID'] = collarOrderDate[0][0];
    var FEntity = [];
    var hobbyIndex = 0;
    this.hobby.forEach((element) {
      if (element[5]['value']['value'] != '0') {
        Map<String, dynamic> FEntityItem = Map();
        FEntityItem['FActualQty'] = element[5]['value']['value'];
        FEntityItem['FEntryID'] = collarOrderDate[hobbyIndex][1];
       /* FEntityItem['FUnitId'] = {"FNumber": element[2]['value']['value']};*/
       /* FEntityItem['FStockId'] = {
          "FNumber": fBillNo.substring(0, 2) == "FO"
              ? 'XBC001'
              : collarOrderDate[hobbyIndex][2]
        };*/
        FEntityItem['FStockId'] = {
          "FNumber": collarOrderDate[hobbyIndex][2]
        };
        FEntity.add(FEntityItem);
      }
      hobbyIndex++;
    });
    if(FEntity.length==0){
      this.isSubmit = false;
      ToastUtil.showInfo('请输入数量和录入仓库');
      return;
    }
    Model['FEntity'] = FEntity;
    orderMap['Model'] = Model;
    dataMap['data'] = orderMap;
    print(jsonEncode(dataMap));
    String order = await SubmitEntity.save(dataMap);
    var res = jsonDecode(order);
    print(res);
    if (res['Result']['ResponseStatus']['IsSuccess']) {
      Map<String, dynamic> submitMap = Map();
      submitMap = {
        "formid": "PRD_PickMtrl",
        "data": {
          'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
        }
      };
      submitOrder(submitMap);
    } else {
      Map<String, dynamic> deleteMap = Map();
      deleteMap = {
        "formid": "PRD_PickMtrl",
        "data": {
          'Ids': collarOrderDate[0][0]
        }
      };
      deleteOrder(deleteMap,res['Result']['ResponseStatus']['Errors'][0]['Message']);
     /* setState(() {
        this.isSubmit = false;
        ToastUtil.errorDialog(context,
            res['Result']['ResponseStatus']['Errors'][0]['Message']);
      });*/
    }
  }

  pushDown() async {
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      //下推
      Map<String, dynamic> pushMap = Map();
      pushMap['Ids'] = orderDate[0][13];
      pushMap['RuleId'] = "PRD_IssueMtrl2PickMtrl";
      pushMap['TargetFormId'] = "PRD_PickMtrl";
      print(pushMap);
      var downData =
      await SubmitEntity.pushDown({"formid": "PRD_PPBOM", "data": pushMap});
      print(downData);
      var res = jsonDecode(downData);
      //判断成功
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        //查询生产领料单
        var entitysNumber =
        res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id'];
        Map<String, dynamic> OrderMap = Map();
        OrderMap['FormId'] = 'PRD_PickMtrl';
        OrderMap['FilterString'] = "FID='$entitysNumber'";
        OrderMap['FieldKeys'] =
        'FID,FEntity_FEntryId,FStockId.FNumber,FMaterialId.FNumber';
        String order = await CurrencyEntity.polling({'data': OrderMap});
        var resData = jsonDecode(order);
        collarOrderDate = resData;
        saveOrder();
      } else {
        setState(() {
          this.isSubmit = false;
          ToastUtil.errorDialog(context,
              res['Result']['ResponseStatus']['Errors'][0]['Message']);
        });
      }
    } else {
      ToastUtil.showInfo('无提交数据');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterEasyLoading(
      child: Scaffold(
          appBar: AppBar(
            title: Text("领料"),
            centerTitle: true,
            leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: (){
              Navigator.of(context).pop("refresh");
            }),
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
                          title: Text("单据编号：$fBillNo"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  /* Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("日期：$FDate"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  _item('仓库:', stockList, selectStock),*/
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
                        onPressed: () async=> this.isSubmit ? null : pushDown(),
                        /*onPressed: () async {
                          if (this.hobby.length > 0) {
                            setState(() {
                              this.isSubmit = true;
                            });
                            pushDown();
                          } else {
                            ToastUtil.showInfo('无提交数据');
                          }
                        },*/
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
