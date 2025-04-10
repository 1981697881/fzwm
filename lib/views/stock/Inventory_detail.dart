import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:fzwm/model/currency_entity.dart';
import 'package:fzwm/model/submit_entity.dart';
import 'package:fzwm/utils/handler_order.dart';
import 'package:fzwm/utils/refresh_widget.dart';
import 'package:fzwm/utils/text.dart';
import 'package:fzwm/utils/toast_util.dart';
import 'package:fzwm/views/login/login_page.dart';
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
import 'package:fzwm/components/my_text.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InventoryDetail extends StatefulWidget {
  var FBillNo;

  InventoryDetail({Key? key, @required this.FBillNo}) : super(key: key);

  @override
  _InventoryDetailState createState() => _InventoryDetailState(FBillNo);
}

class _InventoryDetailState extends State<InventoryDetail> {
  var _remarkContent = new TextEditingController();
  GlobalKey<TextWidgetState> textKey = GlobalKey();
  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();

  final _textNumber = TextEditingController();
  var checkItem;
  String FBillNo = '';
  String FSaleOrderNo = '';
  String FName = '';
  String FNumber = '';
  String FDate = '';
  var customerName;
  var customerNumber;
  var departmentName;
  var departmentNumber;
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
  var departmentList = [];
  List<dynamic> departmentListObj = [];
  var customerList = [];
  List<dynamic> customerListObj = [];
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
  var fBillNo;

  _InventoryDetailState(FBillNo) {
    if (FBillNo != null) {
      this.fBillNo = FBillNo['value'];
      this.getOrderList();
    }else{
      this.fBillNo = '';
    }
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
    getDepartmentList();
    //_onEvent("12.0100");
  }
  //获取部门
  getDepartmentList() async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var tissue = sharedPreferences.getString('tissue');
    userMap['FormId'] = 'BD_Department';
    userMap['FieldKeys'] = 'FUseOrgId,FName,FNumber';
    userMap['FilterString'] = "FUseOrgId.FNumber ='"+tissue+"'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    departmentListObj = jsonDecode(res);
    departmentListObj.forEach((element) {
      departmentList.add(element[1]);
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

  getOrderList() async {
    Map<String, dynamic> userMap = Map();
    print(fBillNo);
    userMap['FilterString'] = "FRemainStockINQty>0 and FBillNo='$fBillNo'";
    userMap['FormId'] = 'PUR_PurchaseOrder';
    userMap['FieldKeys'] =
    'FBillNo,FSupplierId.FNumber,FSupplierId.FName,FDate,FDetailEntity_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FPurOrgId.FNumber,FPurOrgId.FName,FUnitId.FNumber,FUnitId.FName,FInStockQty,FSrcBillNo,FID,FStockId,FStockOrgId';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    orderDate = jsonDecode(order);
    FDate = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    if (orderDate.length > 0) {
      hobby = [];
      orderDate.forEach((value) {
        List arr = [];
        arr.add({
          "title": "物料名称",
          "name": "FMaterial",
          "isHide": false,
          "value": {"label": value[6] + "- (" + value[5] + ")", "value": value[5]}
        });
        arr.add({
          "title": "规格型号",
          "isHide": false,
          "name": "FMaterialIdFSpecification",
          "value": {"label": value[7], "value": value[7]}
        });
        arr.add({
          "title": "单位名称",
          "name": "FUnitId",
          "isHide": false,
          "value": {"label": value[11], "value": value[10]}
        });
        arr.add({
          "title": "帐存数量",
          "name": "FRealQty",
          "isHide": false,
          "value": {"label": value[12], "value": value[12]}
        });
        arr.add({
          "title": "盘点数量",
          "name": "FRealQty",
          "isHide": false,
          "value": {"label": "0", "value": "0"}
        });
        arr.add({
          "title": "仓库",
          "name": "FStockID",
          "isHide": false,
          "value": {"label": value[15], "value": value[15]}
        });
        arr.add({
          "title": "FStockOrgId",
          "name": "FStockOrgId",
          "isHide": true,
          "value": {"label": value[15], "value": value[15]}
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
  }

  void _onEvent(event) async {
    /*  setState(() {*/
    _code = event;
    EasyLoading.show(status: 'loading...');
    this.getMaterialList();
    print("ChannelPage: $event");
    /*});*/
  }

  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
  }
  getMaterialList() async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    var scanCode = _code.split(",");
    userMap['FilterString'] = "FMaterialId.FNumber='"+scanCode[0]+"' and FBaseQty>0 and FStockOrgId.FNumber = "+deptData[1];
    if(scanCode.length > 1){
      userMap['FilterString'] = "FMaterialId.FNumber='"+scanCode[0]+"' and FBaseQty>0 and FLot.FNumber='"+scanCode[1]+"' and FStockOrgId.FNumber = "+deptData[1];
    }
    userMap['FormId'] = 'STK_Inventory';
    userMap['FieldKeys'] =
    'FStockOrgId,FMaterialId.FName,FMaterialId.FNumber,FMaterialId.FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FStockId.FNumber,FBaseQty,FStockName,FLot.FNumber';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    orderDate = jsonDecode(order);
    FDate = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    if (orderDate.length > 0) {
      hobby = [];
      orderDate.forEach((value) {
        List arr = [];
        arr.add({
          "title": "物料名称",
          "name": "FMaterial",
          "isHide": false,
          "value": {"label": value[1] + "- (" + value[2] + ")", "value": value[2]}
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
        arr.add({
          "title": "账存数量",
          "name": "FRealQty",
          "isHide": false,
          "value": {"label": value[7], "value": value[7]}
        });
        /*arr.add({
          "title": "实存数量",
          "name": "FRealQty",
          "isHide": false,
          "value": {"label": value[6], "value": value[6]}
        });*/
        arr.add({
          "title": "盘点数量",
          "name": "FCountQty",
          "isHide": false,
          "value": {"label": value[7].toString(), "value": value[7].toString()}
        });
        arr.add({
          "title": "仓库",
          "name": "FStockID",
          "isHide": false,
          "value": {"label": value[8], "value": value[6]}
        });
        arr.add({
          "title": "批号",
          "name": "FLot",
          "isHide": false,
          "value": {"label": value[9], "value": value[9]}
        });
        arr.add({
          "title": "FStockOrgId",
          "name": "FStockOrgId",
          "isHide": true,
          "value": {"label": value[0], "value": value[0]}
        });
        arr.add({
          "title": "操作",
          "name": "",
          "isHide": false,
          "value": {"label": "", "value": ""}
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
          if(hobby  == 'customer'){
            customerName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                customerNumber = customerListObj[elementIndex][2];
              }
              elementIndex++;
            });
          } else if(hobby  == 'department'){
            departmentName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                departmentNumber = departmentListObj[elementIndex][2];
              }
              elementIndex++;
            });
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
  List<Widget> _getHobby() {
    List<Widget> tempList = [];
    for (int i = 0; i < this.hobby.length; i++) {
      List<Widget> comList = [];
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (!this.hobby[i][j]['isHide']) {
          if (j == 4) {
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
          } else if (j == 8) {
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
                            new MaterialButton(
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
          }else {
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
  //保存
  saveOrder() async {
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      if (this.departmentNumber == null) {
        this.isSubmit = false;
        ToastUtil.showInfo('请选择部门');
        return;
      }
      Map<String, dynamic> dataMap = Map();
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedReturnFields'] = [];
      orderMap['IsDeleteEntry'] = false;
      Map<String, dynamic> Model = Map();
      Model['FID'] = 0;
      Model['FDate'] = FDate;
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var menuData = sharedPreferences.getString('MenuPermissions');
      var deptData = jsonDecode(menuData)[0];
      Model['FStockOrgId'] = {"FNumber": deptData[1]};
      Model['FDeptId'] = {"FNumber": this.departmentNumber};
      Model['FOwnerTypeIdHead'] = "BD_OwnerOrg";
      var FEntity1 = [];
      var FEntity = [];
      var FEntity2 = [];
      var hobbyIndex = 0;
      this.hobby.forEach((element) {
        if (element[4]['value']['value'] != '0' &&
            element[4]['value']['value'] != '') {
          Map<String, dynamic> FEntityItem = Map();
          FEntityItem['FMaterialId'] = {
            "FNumber": element[0]['value']['value']
          };
          FEntityItem['FUnitID'] = {
            "FNumber": element[2]['value']['value']
          };
          FEntityItem['FStockId'] = {
            "FNumber": element[5]['value']['value']
          };
          FEntityItem['FOwnerid'] = {
            "FNumber": deptData[1]
          };
          FEntityItem['FLOT'] = {
            "FNumber": element[6]['value']['value']
          };
          /*FEntityItem['FReturnType'] = 1;*/
          FEntityItem['FCountQty'] = element[4]['value']['value'];
          if(double.parse(element[4]['value']['value']) > element[3]['value']['value']){
            FEntity1.add(FEntityItem);
          }else{
            FEntity2.add(FEntityItem);
          }
          FEntity.add(FEntityItem);
        }
        hobbyIndex++;
      });
      if (FEntity.length == 0 ) {
        this.isSubmit = false;
        ToastUtil.showInfo('请输入盘点数量');
        return;
      }
      for(var i=0;i<2;i++){
        //盘盈
        if(FEntity1.length>0){
          dataMap['formid'] = 'STK_StockCountGain';
          Model['FBillEntry'] = FEntity1;
          Model['FBillTypeID'] = {"FNUMBER": "PY01_SYS"};
          orderMap['Model'] = Model;
          dataMap['data'] = orderMap;
          print(jsonEncode(dataMap));
          String order = await SubmitEntity.save(dataMap);
          var res = jsonDecode(order);
          print(res);
          if (res['Result']['ResponseStatus']['IsSuccess']) {
            Map<String, dynamic> submitMap = Map();
            FEntity1 =  [];
            submitMap = {
              "formid": "STK_StockCountGain",
              "data": {
                'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
              }
            };
            //提交
            HandlerOrder.orderHandler(
                context,
                submitMap,
                1,
                "STK_StockCountGain",
                SubmitEntity.submit(submitMap))
                .then((submitResult) {
              if (submitResult) {
                //审核
                HandlerOrder.orderHandler(
                    context,
                    submitMap,
                    1,
                    "STK_StockCountGain",
                    SubmitEntity.audit(submitMap))
                    .then((auditResult) {
                  if (auditResult) {
                    //提交清空页面
                    setState(() {
                      if(FEntity1.length == 0 && FEntity2.length == 0){
                        this.hobby = [];
                        this.orderDate = [];
                        this.FBillNo = '';
                        ToastUtil.showInfo('提交成功');
                        Navigator.of(context).pop();
                      }
                    });
                  } else {
                    //失败后反审
                    HandlerOrder.orderHandler(
                        context,
                        submitMap,
                        0,
                        "STK_StockCountGain",
                        SubmitEntity.unAudit(submitMap))
                        .then((unAuditResult) {
                      if (unAuditResult) {
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
        }else{
          //盘亏
          dataMap['formid'] = 'STK_StockCountLoss';
          Model['FBillEntry'] = FEntity2;
          Model['FBillTypeID'] = {"FNUMBER": "PK01_SYS"};
          orderMap['Model'] = Model;
          dataMap['data'] = orderMap;
          print(jsonEncode(dataMap));
          String order = await SubmitEntity.save(dataMap);
          var res = jsonDecode(order);
          print(res);
          if (res['Result']['ResponseStatus']['IsSuccess']) {
            Map<String, dynamic> submitMap = Map();
            FEntity2 =  [];
            submitMap = {
              "formid": "STK_StockCountLoss",
              "data": {
                'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
              }
            };
            //提交
            HandlerOrder.orderHandler(
                context,
                submitMap,
                1,
                "STK_StockCountLoss",
                SubmitEntity.submit(submitMap))
                .then((submitResult) {
              if (submitResult) {
                //审核
                HandlerOrder.orderHandler(
                    context,
                    submitMap,
                    1,
                    "STK_StockCountLoss",
                    SubmitEntity.audit(submitMap))
                    .then((auditResult) {
                  if (auditResult) {
                    //提交清空页面
                    setState(() {
                      if(FEntity1.length == 0 && FEntity2.length == 0){
                        this.hobby = [];
                        this.orderDate = [];
                        this.FBillNo = '';
                        ToastUtil.showInfo('提交成功');
                        Navigator.of(context).pop();
                      }
                    });
                  } else {
                    //失败后反审
                    HandlerOrder.orderHandler(
                        context,
                        submitMap,
                        0,
                        "STK_StockCountLoss",
                        SubmitEntity.unAudit(submitMap))
                        .then((unAuditResult) {
                      if (unAuditResult) {
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
            title: Text("盘点"),
            centerTitle: true,
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: ListView(children: <Widget>[
                  /*Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          *//* title: TextWidget(FBillNoKey, '生产订单：'),*//*
                          title: Text("单号：$fBillNo"),
                        ),
                      ),
                      divider,
                    ],
                  ),*/
                  _dateItem('日期：', DateMode.YMD),
                  _item('部门',  this.departmentList, this.departmentName,
                      'department'),
                  /*Column(
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
                  ),*/
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
                        onPressed: () async=> this.isSubmit ? null : saveOrder(),
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
