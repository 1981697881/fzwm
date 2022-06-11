import 'dart:convert';
import 'package:fzwm/model/currency_entity.dart';
import 'package:fzwm/model/submit_entity.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fzwm/components/my_text.dart';
final String _fontFamily = Platform.isWindows ? "Roboto" : "";

class WarehousingDetail extends StatefulWidget {
  var FBillNo;
  var FSeq;
  var FEntryId;
  var FID;
  var FProdOrder;
  var FBarcode;

  WarehousingDetail({Key? key,  @required this.FBillNo,
    @required this.FSeq,
    @required this.FEntryId,
    @required this.FID,
    @required this.FBarcode,
    @required this.FProdOrder}) : super(key: key);

  @override
  _WarehousingDetailState createState() => _WarehousingDetailState(FBillNo, FSeq, FEntryId, FID, FProdOrder,FBarcode);
}

class _WarehousingDetailState extends State<WarehousingDetail> {
  GlobalKey<TextWidgetState> textKey = GlobalKey();
  GlobalKey<TextWidgetState> FBillNoKey = GlobalKey();
  GlobalKey<TextWidgetState> FSaleOrderNoKey = GlobalKey();
  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();
  GlobalKey<PartRefreshWidgetState> FPrdOrgIdKey = GlobalKey();

  final _textNumber = TextEditingController();
  var checkItem;
  String FBillNo = '';
  String FSaleOrderNo = '';
  String FName = '';
  String FNumber = '';
  String FDate = '';
  var show = false;
  var isScanWork = false;
  var isSubmit = false;
  var checkData;
  var checkDataChild;
  //仓库
  var stockList = [];
  List<dynamic> stockListObj = [];
  var selectData = {
    DateMode.YMDHMS: '',
  };
  List<dynamic> orderDate = [];
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
  _WarehousingDetailState(fBillNo, FSeq, fEntryId, fid, FProdOrder,FBarcode) {
    this.FBillNo = fBillNo['value'];
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

    /// 开启监听
    if (_subscription == null) {
      _subscription = scannerPlugin
          .receiveBroadcastStream()
          .listen(_onEvent, onError: _onError);
    }
   /* getWorkShop();*/
    getStockList();
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

  // 查询数据集合
  List hobby = [];

  getOrderList() async {
    if (FBillNo != '') {
      Map<String, dynamic> userMap = Map();
      userMap['FilterString'] =
      "FBillNo='$FBillNo' and FNoStockInQty>0 and FStatus in (4)";
      userMap['FormId'] = 'PRD_MO';
      userMap['FieldKeys'] =
      'FBillNo,FPrdOrgId.FNumber,FPrdOrgId.FName,FDate,FSaleOrderNo,FTreeEntity_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FWorkShopID.FNumber,FWorkShopID.FName,FUnitId.FNumber,FUnitId.FName,FQty,FPlanStartDate,FPlanFinishDate,FSrcBillNo,FNoStockInQty,FID,FStatus,FStockId.FNumber,FStockId.FName,FRequestOrgId.FNumber';
      Map<String, dynamic> dataMap = Map();
      dataMap['data'] = userMap;
      String order = await CurrencyEntity.polling(dataMap);
      orderDate = [];
      orderDate = jsonDecode(order);
      if (orderDate.length > 0) {
        FDate = orderDate[0][3].substring(0, 10);
        selectData[DateMode.YMDHMS] = orderDate[0][3].substring(0, 10);
        FSaleOrderNo = orderDate[0][4];
        globalKey.currentState!.update();
        /*FBillNoKey.currentState.onPressed(orderDate[0][0]);
    FSaleOrderNoKey.currentState.onPressed(orderDate[0][4]);*/
        hobby = [];
        orderDate.forEach((value) {
          List arr = [];
          arr.add({
            "title": "物料子码",
            "name": "FMaterialId",
            "value": {"label": value[6], "value": value[6]}
          });
          arr.add({
            "title": "生产车间",
            "name": "FWorkShopID",
            "value": {"label": value[10], "value": value[9]}
          });
          arr.add({
            "title": "预测批号",
            "name": "",
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "需生产数量",
            "name": "FQty",
            "value": {"label": value[13], "value": value[13]}
          });
          arr.add({
            "title": "良品数量",
            "name": "goodProductNumber",
            "value": {"label": value[13], "value": value[13]}
          });
          arr.add({
            "title": "良品仓库",
            "name": "goodProductStock",
            "value": {"label": value[21], "value": value[20]}
          });
          arr.add({
            "title": "不良品数量",
            "name": "rejectsNumber",
            "value": {"label": "0", "value": "0"}
          });
          arr.add({
            "title": "不良品仓库",
            "name": "rejectsStock",
            "value": {"label": "", "value": ""}
          });
          hobby.add(arr);
        });
        checkItem = '';
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
    } else {
      EasyLoading.dismiss();
      _code = '';
      textKey.currentState!.onPressed(_code);
      if (FNumber == '') {
        checkItem = 'FPrdOrgId';
        ToastUtil.showInfo('请扫描生产车间');
      } else if (FBillNo == '') {
        checkItem = 'FBillNo';
        ToastUtil.showInfo('请扫描生产单号');
      }
      scanDialog();
    }
  }

  void _onEvent(event) async {
    /*  setState(() {*/
    _code = event;
    if (textKey.currentState != null) {
      textKey.currentState!.onPressed(_code);
      switch (checkItem) {
        case 'FBillNo':
          EasyLoading.show(status: 'loading...');
          Navigator.pop(context);
          FBillNo = _code;
          await getOrderList();
          break;
        case 'FPrdOrgId':
          EasyLoading.show(status: 'loading...');
          Navigator.pop(context);
          FName = _code.split(',')[1];
          FNumber = _code.split(',')[0];
          await getOrderList();
          break;
        case 'FNumber':
          Navigator.pop(context);
          setState(() {
            this.hobby[checkData][checkDataChild]["value"]["label"] = _FNumber;
            this.hobby[checkData][checkDataChild]['value']["value"] = _FNumber;
          });
          break;
        case 'FStock':
          Navigator.pop(context);
          setState(() {
            this.hobby[checkData][checkDataChild]["value"]['label'] =
            _code.split(',')[1];
            this.hobby[checkData][checkDataChild]['value']["value"] =
            _code.split(',')[0];
          });
          break;
      }
    } else {
      ToastUtil.showInfo('请点击扫描行扫描图标');
    }
    print("ChannelPage: $event");
    /*});*/
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
            case DateMode.YMDHMS:
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
          setState(() {
            hobby['value']['label'] = p;
          });
          var elementIndex = 0;
          data.forEach((element) {
            if (element == p) {
              hobby['value']['value'] = stockListObj[elementIndex][2];
              /*stock[6]['value']['hide'] = stockListObj[elementIndex][3];*/
            }
            elementIndex++;
          });
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
        if (j == 4 || j == 6) {
          /*comList.add(
            _item(this.hobby[j]["title"], ['PHP', 'JAVA', 'C++', 'Dart', 'Python', 'Go'],
                this.hobby[j]["value"]),
          );*/
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
        } else if (j == 5) {
          comList.add(
            _item('良品仓库:', stockList, this.hobby[i][j]['value']['label'],
                this.hobby[i][j],stock:this.hobby[i]),
          );
        } else if (j == 7) {
          comList.add(
            _item('不良品仓库:', stockList, this.hobby[i][j]['value']['label'],
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
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('扫描',
                        style: TextStyle(
                            fontSize: 16, decoration: TextDecoration.none)),
                  ),
                  if (!show)
                    Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Card(
                            child: Column(children: <Widget>[
                              TextField(
                                style: TextStyle(color: Colors.black87),
                                keyboardType: TextInputType.number,
                                controller: this._textNumber,
                                decoration: InputDecoration(hintText: "输入或者扫描数量"),
                                onChanged: (value) {
                                  setState(() {
                                    this._FNumber = value;
                                  });
                                },
                              ),
                            ]))),
                  if (show)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: TextWidget(textKey, ''),
                    ),
                  Padding(
                    padding: EdgeInsets.only(top: 15, bottom: 8),
                    child: FlatButton(
                        color: Colors.grey[100],
                        onPressed: () {
                          // 关闭 Dialog
                          Navigator.pop(context);
                          if (checkItem == 'FNumber') {
                            setState(() {
                              this.hobby[checkData][checkDataChild]["value"]
                              ["label"] = _FNumber;
                              this.hobby[checkData][checkDataChild]['value']
                              ["value"] = _FNumber;
                            });
                          }
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

  //删除
  deleteOrder(Map<String, dynamic> map,msg) async {
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
                msg);
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
  unAuditOrder(Map<String, dynamic> map,msg) async {
    var subData = await SubmitEntity.unAudit(map);
    print(subData);
    if (subData != null) {
      var res = jsonDecode(subData);
      if (res != null) {
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          //提交清空页面
          Map<String, dynamic> deleteMap = Map();
          deleteMap = {
            "formid": "PRD_INSTOCK",
            "data": {
              'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
            }
          };
          deleteOrder(deleteMap,msg);
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
  // 入库后操作
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
        userMap['FilterString'] = "FSaleOrderNo='$FBarcode' and FStatus in (2) and FProdOrder >= " + (i).toString() + " and FProdOrder <" + (i + 1).toString();
        userMap['FormId'] = "PRD_MO";
        userMap['FieldKeys'] =
        'FBillNo,FTreeEntity_FEntryId,FID,FProdOrder,FTreeEntity_FSeq';
        Map<String, dynamic> proMoDataMap = Map();
        proMoDataMap['data'] = userMap;
        String order = await CurrencyEntity.polling(proMoDataMap);
        var orderRes = jsonDecode(order);
        serialNum = i;
        //判断同级
        if(orderRes.length > 0){
          break;
        }
      }
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
  //审核
  auditOrder(Map<String, dynamic> auditMap,index, bool type) async {
    await SubmitEntity.submit(auditMap);
    var subData = await SubmitEntity.audit(auditMap);
    var res = jsonDecode(subData);
    if (res != null) {
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        if(type){
          if(index == 1){
            /*this.handlerStatus();*/
            setState(() {
                this.hobby = [];
                this.orderDate = [];
                this.FBillNo = '';
                this.FSaleOrderNo = '';
              });
              ToastUtil.showInfo('提交成功');
              Navigator.of(context).pop("refresh");
          }
        }else{
          /*this.handlerStatus();*/
          setState(() {
                this.hobby = [];
                this.orderDate = [];
                this.FBillNo = '';
                this.FSaleOrderNo = '';
              });
              ToastUtil.showInfo('提交成功');
              Navigator.of(context).pop("refresh");
        }
        //提交清空页面
      } else {
        unAuditOrder(auditMap,res['Result']['ResponseStatus']['Errors'][0]['Message']);
        /*setState(() {
            ToastUtil.errorDialog(context,
                res['Result']['ResponseStatus']['Errors'][0]['Message']);
          });*/
      }
    }
  }

  pushDown(val, type) async {
    //下推
    Map<String, dynamic> pushMap = Map();
    pushMap['EntryIds'] = val;
    pushMap['RuleId'] = "MSD_MO2INSTOCK_PDA";
    pushMap['TargetFormId'] = "PRD_INSTOCK";
    pushMap['IsEnableDefaultRule'] = "false";
    pushMap['IsDraftWhenSaveFail'] = "false";
    print(pushMap);
    var downData =
    await SubmitEntity.pushDown({"formid": "PRD_MO", "data": pushMap});
    print(downData);
    var res = jsonDecode(downData);
    //判断成功
    if (res['Result']['ResponseStatus']['IsSuccess']) {
      //查询入库单
      var entitysNumber =
      res['Result']['ResponseStatus']['SuccessEntitys'][0]['Number'];
      Map<String, dynamic> inOrderMap = Map();
      inOrderMap['FormId'] = 'PRD_INSTOCK';
      inOrderMap['FilterString'] = "FBillNo='$entitysNumber'";
      inOrderMap['FieldKeys'] =
      'FEntity_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FUnitId.FNumber,FMoBillNo';
      String order = await CurrencyEntity.polling({'data': inOrderMap});
      print(order);
      var resData = jsonDecode(order);
      //组装数据
      Map<String, dynamic> dataMap = Map();
      dataMap['data'] = inOrderMap;
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedUpDataFields'] = [
        'FStockStatusId',
        'FRealQty',
        'FInStockType'
      ];
      orderMap['IsDeleteEntry'] = false;
      Map<String, dynamic> Model = Map();
      Model['FID'] = res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id'];
      // ignore: non_constant_identifier_names
      var FEntity = [];
      for (int entity = 0; entity < resData.length; entity++) {
        /*resData.forEach((entity) {*/
        for (int element = 0; element < this.hobby.length; element++) {
          /*this.hobby.forEach((element) {*/
          if (resData[entity][1].toString() ==
              this.hobby[element][0]['value']['value'].toString()) {
            // ignore: non_constant_identifier_names
            //判断不良品还是良品
            if (type == "defective") {
              Map<String, dynamic> FEntityItem = Map();
              FEntityItem['FEntryID'] = resData[entity][0];
              FEntityItem['FStockStatusId'] = {"FNumber": "KCZT01_SYS"};
              FEntityItem['FInStockType'] = '1';
              FEntityItem['FRealQty'] =
              this.hobby[element][4]['value']['value'];
              FEntityItem['FStockId'] = {
                "FNumber": this.hobby[element][5]['value']['value']
              };
              FEntity.add(FEntityItem);
            } else {
              Map<String, dynamic> FEntityItem = Map();
              FEntityItem['FInStockType'] = '2';
              FEntityItem['FStockStatusId'] = {"FNumber": "KCZT01_SYS"};
              FEntityItem['FEntryID'] = resData[entity][0];
              FEntityItem['FRealQty'] =
              this.hobby[element][6]['value']['value'];
              FEntityItem['FStockId'] = {
                "FNumber": this.hobby[element][7]['value']['value']
              };
              FEntity.add(FEntityItem);
            }
          }
        } /*);*/
      }
      /*);*/
      Model['FEntity'] = FEntity;
      /* Model['FStockOrgId'] = {"FNumber": orderDate[0][22]};
      Model['FPrdOrgId'] = {"FNumber": orderDate[0][22]};*/
      orderMap['Model'] = Model;
      dataMap = {"formid": "PRD_INSTOCK", "data": orderMap, "isBool": true};
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
  submitOder() async {
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      var EntryIds1 = '';
      var EntryIds2 = '';
      //分两次读取良品，不良品数据
      for (var i = 0; i < 2; i++) {
        var hobbyIndex = 0;
        this.hobby.forEach((element) {
          if (i == 0) {
            if (element[4]['value']['value'] is String) {
              if (double.parse(element[4]['value']['value']) > 0) {
                if (EntryIds1 == '') {
                  EntryIds1 = orderDate[hobbyIndex][5].toString();
                } else {
                  EntryIds1 =
                      EntryIds1 + ',' + orderDate[hobbyIndex][5].toString();
                }
              }
            } else {
              if (element[4]['value']['value'] > 0) {
                if (EntryIds1 == '') {
                  EntryIds1 = orderDate[hobbyIndex][5].toString();
                } else {
                  EntryIds1 =
                      EntryIds1 + ',' + orderDate[hobbyIndex][5].toString();
                }
              }
            }
          } else {
            if (element[6]['value']['value'] is String) {
              if (double.parse(element[6]['value']['value']) > 0) {
                if (EntryIds2 == '') {
                  EntryIds2 = orderDate[hobbyIndex][5].toString();
                } else {
                  EntryIds2 =
                      EntryIds2 + ',' + orderDate[hobbyIndex][5].toString();
                }
              }
            } else {
              if (element[6]['value']['value'] > 0) {
                if (EntryIds2 == '') {
                  EntryIds2 = orderDate[hobbyIndex][5].toString();
                } else {
                  EntryIds2 =
                      EntryIds2 + ',' + orderDate[hobbyIndex][5].toString();
                }
              }
            }
          }
          hobbyIndex++;
        });
      }
      //判断是否填写数量
      if (EntryIds1 == '' && EntryIds2 == '') {
        ToastUtil.showInfo('无提交数据');
      } else {
        var checkList = [];
        //循环下推单据
        for (var i = 0; i < 2; i++) {
          if (EntryIds1 != '' && i == 0) {
            checkList.add(EntryIds1);
            var resCheck = await this.pushDown(EntryIds1, 'defective');
            if (resCheck['isBool'] != false) {
              var subData = await SubmitEntity.save(resCheck);
              var res = jsonDecode(subData);
              if (res != null) {
                if (res['Result']['ResponseStatus']['IsSuccess']) {
                  //提交清空页面
                  Map<String, dynamic> auditMap = Map();
                  auditMap = {
                    "formid": "PRD_INSTOCK",
                    "data": {
                      'Ids': res['Result']['ResponseStatus']['SuccessEntitys']
                      [0]['Id']
                    }
                  };
                  await auditOrder(auditMap,i,EntryIds2 != '');
                } else {
                  Map<String, dynamic> deleteMap = Map();
                  deleteMap = {
                    "formid": "PRD_INSTOCK",
                    "data": {'Ids': resCheck['data']["Model"]["FID"]}
                  };
                  deleteOrder(deleteMap,res['Result']['ResponseStatus']['Errors'][0]
                  ['Message']);
                }
              }
            } else {
              setState(() {
                this.isSubmit = false;
                ToastUtil.errorDialog(context, resCheck['msg']);
              });
              break;
            }
          } else if (EntryIds2 != '' && i == 1) {
            checkList.add(EntryIds2);
            var resCheck = await this.pushDown(EntryIds2, 'nonDefective');
            if (resCheck['isBool'] != false) {
              var subData = await SubmitEntity.save(resCheck);
              print(subData);
              var res = jsonDecode(subData);
              if (res != null) {
                if (res['Result']['ResponseStatus']['IsSuccess']) {
                  //提交清空页面
                  Map<String, dynamic> auditMap = Map();
                  auditMap = {
                    "formid": "PRD_INSTOCK",
                    "data": {
                      'Ids': res['Result']['ResponseStatus']['SuccessEntitys']
                      [0]['Id']
                    }
                  };
                  await auditOrder(auditMap,i,EntryIds1 != '');
                } else {
                  Map<String, dynamic> deleteMap = Map();
                  deleteMap = {
                    "formid": "PRD_INSTOCK",
                    "data": {'Ids': resCheck['data']["Model"]["FID"]}
                  };
                  deleteOrder(deleteMap,res['Result']['ResponseStatus']['Errors'][0]
                  ['Message']);
                }
              }
            } else {
              setState(() {
                this.isSubmit = false;
                ToastUtil.errorDialog(context, resCheck['msg']);
              });
              break;
            }
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
            title: Text("入库"),
            centerTitle: true,
            leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop("refresh");
                }),
            /*actions: <Widget>[
              new IconButton(
                  icon: new Icon(Icons.settings), onPressed: _pushSaved),
            ],*/
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
                          title: Text("生产订单：$FBillNo"),
                          /*trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  icon: new Icon(Icons.filter_center_focus),
                                  tooltip: '点击扫描',
                                  onPressed: () {
                                    checkItem = 'FBillNo';
                                    this.show = true;
                                    scanDialog();
                                  },
                                ),
                              ]),*/
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
                          title: Text("来源单号：$FSaleOrderNo"),
                          /*title: TextWidget(FSaleOrderNoKey, '来源单号：'),*/
                          trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                MyText('',
                                    color: Colors.grey, rightpadding: 18),
                              ]),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  _dateItem('生产日期：', DateMode.YMDHMS),
                  /* _item('生产车间', ['PHP', 'JAVA', 'C++', 'Dart', 'Python', 'Go'], selectSex),*/
                  // _item('Laber', [123, 23,235,3,14545,15,123163,18548,9646,1313], 235, label: 'kg')
                  /*Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: PartRefreshWidget(FPrdOrgIdKey, () {
                            //2、使用 创建一个widget
                            return Text('生产车间：$FName');
                          }),
                          trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                if (!isScanWork)
                                  IconButton(
                                    icon: new Icon(Icons.filter_center_focus),
                                    tooltip: '点击扫描',
                                    onPressed: () {
                                      checkItem = 'FPrdOrgId';
                                      this.show = true;
                                      scanDialog();
                                    },
                                  ),
                              ]),
                        ),
                      ),
                      divider,
                    ],
                  ),*/
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text('生产详细信息：'),
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
                        color: this.isSubmit
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                        textColor: Colors.white,
                        onPressed: () async =>
                        this.isSubmit ? null : submitOder(),
                        /*onPressed: () async {
                          if(this.hobby.length>0){
                            setState(() {
                              this.isSubmit = true;
                            });
                            submitOder();
                           */ /* Map<String, dynamic> dataMap = Map();
                            var numbers = [];
                            dataMap['formid'] = 'PRD_MO';
                            dataMap['opNumber'] = 'toStart';
                            var hobbyIndex = 0;
                            this.hobby.forEach((list) {
                              Map<String, dynamic> entityMap = Map();
                              entityMap['Id'] = orderDate[hobbyIndex][18];
                              entityMap['EntryIds'] = orderDate[hobbyIndex][5];
                              numbers.add(entityMap);
                               hobbyIndex++;
                            });
                            dataMap['data'] = {'PkEntryIds':numbers};
                            var status = await SubmitEntity.alterStatus(dataMap);
                            print(status);
                            if(status != null){
                              var res = jsonDecode(status);
                              print(res);
                              if(res != null){
                                if(res['Result']['ResponseStatus']['IsSuccess']){
                                  submitOder();
                                }else{
                                  ToastUtil.showInfo(res['Result']['ResponseStatus']['Errors'][0]['Message']);
                                }
                              }
                            }*/ /*
                          }else{
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
