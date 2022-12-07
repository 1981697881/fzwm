import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:fzwm/model/currency_entity.dart';
import 'package:fzwm/model/submit_entity.dart';
import 'package:fzwm/utils/handler_order.dart';
import 'package:fzwm/utils/refresh_widget.dart';
import 'package:fzwm/utils/toast_util.dart';
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

class ReceiveDetail extends StatefulWidget {
  var FBillNo;
  var FOrderNo;

  ReceiveDetail({Key? key, @required this.FBillNo, @required this.FOrderNo}) : super(key: key);

  @override
  _ReceiveDetailState createState() => _ReceiveDetailState(FBillNo,FOrderNo);
}

class _ReceiveDetailState extends State<ReceiveDetail> {
  var _remarkContent = new TextEditingController();
  GlobalKey<PartRefreshWidgetState> globalDateKey = GlobalKey();

  /*GlobalKey<TextWidgetState> textKey = GlobalKey();*/
  final _textNumber = TextEditingController();
  var checkItem;
  String FBillNo = '';
  String FName = '';
  String FNumber = '';
  String FDate = '';

  //产品名称
  var fMaterialName;

  //产品编码
  var fMaterialNumber;
  //移交数量
  var fOrderQty;
  //工艺路线
  var fProcessName;

  //流程卡号
  var fOrderNo;

  //已派工数量
  var fBaseQty;

  //未派工数量
  var fRemainOutQty;
  //工序号
  var fProcessNo;

  //工序
  var fProcessID;
  var fProcessIDFDataValue;
  var isSubmit = false;
  var show = false;
  var isScanWork = false;
  var checkData;
  var checkDataChild;
  var selectData = {
    DateMode.YMD: '',
  };
  var departmentList = [];
  List<dynamic> departmentListObj = [];
  List<dynamic> orderDate = [];
  final divider = Divider(height: 1, indent: 20);
  final rightIcon = Icon(Icons.keyboard_arrow_right);
  final scanIcon = Icon(Icons.filter_center_focus);
  static const scannerPlugin =
  const EventChannel('com.shinow.pda_scanner/plugin');
  StreamSubscription ?_subscription;
  var _code;
  var _FNumber;
  var fBillNo;
  var fOrderNum;
  _ReceiveDetailState(FBillNo,FOrderNo) {
    if (FBillNo != null) {
      this.fBillNo = FBillNo['value'];
      this.fOrderNum = FOrderNo['value'];
      this.getOrderList();
    }else{
      this.fBillNo = '';
    }
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
    EasyLoading.dismiss();
    /* getWorkShop();*/
    getDepartmentList();
  }
  //获取部门
  getDepartmentList() async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    userMap['FormId'] = 'BD_Department';
    userMap['FieldKeys'] = 'FUseOrgId,FName,FNumber';
    userMap['FilterString'] = "FUseOrgId.FNumber ="+deptData[1]+" and FNumber like 'PW%'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    departmentListObj = jsonDecode(res);
    departmentListObj.forEach((element) {
      departmentList.add(element[1]);
    });
  }
  //获取职员
  getEmpList(department,emp) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    userMap['FormId'] = 'BD_Empinfo';
    userMap['FilterString'] =
        "FForbidStatus='A' and FUseOrgId.FNumber ="+deptData[1]+" and F_ora_Base.FNUMBER ='"+department+"'";
    userMap['FieldKeys'] = 'FUseOrgId.FNumber,FName,FNumber,FForbidStatus';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    if(jsonDecode(res).length>0){
      setState(() {
        emp[8]["empListObj"] = jsonDecode(res);
        emp[8]["empList"] = [];
        emp[8]["empListObj"].forEach((element) {
          emp[8]["empList"].add(element[1]);
        });
      });
    }else{
      ToastUtil.showInfo('无员工数据');
    }

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
    EasyLoading.show(status: 'loading...');
    Map<String, dynamic> userMap = Map();
    userMap['FilterString'] = "fBillNo='$fBillNo'";
    userMap['FormId'] = 'QDEP_Proc_HandOver';
    userMap['FieldKeys'] =
    'FBillNo,FCreateOrgId.FNumber,FCreateOrgId.FName,FDate,FEntity_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FOrderNo,FProcessLine,FHandQty,FPlanStarDate,FPlanEndDate,FID,FQty,FAcceptQty,FUnHandQty,FProcessID.FNumber,FProcessID.FNumber,FProcessNo,FKDNo1.FNumber,FOrderEntryID,FProcessNote,FProcessMulti,FProcessTypeID.FNumber,FKDNo';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    orderDate = jsonDecode(order);
    DateTime dateTime = DateTime.now();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    FDate = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);
    if (orderDate.length > 0) {
      this.FBillNo = orderDate[0][0];
      this.fOrderQty = orderDate[0][10];
      //产品名称
      fMaterialName = orderDate[0][6];
      //产品编码
      fMaterialNumber = orderDate[0][5];

      /*//工艺路线
      fProcessName = orderDate[0][9];
      //流程卡号
      fOrderNo = orderDate[0][8];
      //已派工数量
      fBaseQty = orderDate[0][15];
      //未派工数量
      fRemainOutQty = orderDate[0][16];
      fProcessID = orderDate[0][17];
      fProcessIDFDataValue = orderDate[0][18];
      //工序号
      fProcessNo = orderDate[0][19];*/
      hobby = [];
      orderDate.forEach((value) {
        List arr = [];
        arr.add({
          "title": "工艺路线",
          "name": "fProcessName",
          "isHide": false,
          "value": {"label": value[9], "value": value[9]}
        });
        arr.add({
          "title": "流程卡号",
          "name": "fOrderNo",
          "isHide": false,
          "value": {"label": value[8], "value": value[8]}
        });
        arr.add({
          "title": "产品名称",
          "name": "fMaterialName",
          "isHide": false,
          "value": {"label": value[6], "value": value[5]}
        });
        arr.add({
          "title": "工序",
          "name": "",
          "isHide": false,
          "value": {"label": value[18], "value": value[17]}
        });
        arr.add({
          "title": "移交数量",
          "name": "",
          "isHide": false,
          "value": {"label": value[10], "value": value[10]}
        });
        arr.add({
          "title": "已接收数量",
          "isHide": false,
          "name": "",
          "value": {"label": value[15], "value": value[15]}
        });
        arr.add({
          "title": "接收日期",
          "name": "",
          "isHide": false,
          "value": {"label": formatDate(DateTime.now(), [
            yyyy,
            "-",
            mm,
            "-",
            dd,
          ]), "value": formatDate(DateTime.now(), [
            yyyy,
            "-",
            mm,
            "-",
            dd,
          ])}
        });
        arr.add({
          "title": "班组",
          "name": "",
          "isHide": false,
          "value": {"label": deptData[28]==null?"":deptData[28], "value": deptData[27]==null?"":deptData[27]}
        });
        arr.add({
          "title": "人员",
          "name": "",
          "empList": [],
          "empListObj": [],
          "isHide": false,
          "value": {"label": "", "value": "", "hide": true}
        });
        arr.add({
          "title": "接收数量",
          "name": "",
          "isHide": false,
          "value": {"label": (value[10] - value[15]).toString(), "value": (value[10] - value[15]).toString()}
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

  void _onEvent(event) async {
    /*  setState(() {*/
    _code = event;
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

  Widget _dateItem(title, model,selectData, hobby) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: ListTile(
            title: Text(title),
            onTap: () {
              _onDateClickItem(model,hobby);
            },
            trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              //2、使用 创建一个widget
              MyText(
                  PicketUtil.strEmpty(selectData)
                      ? '暂无'
                      : selectData,
                  color: Colors.grey,
                  rightpadding: 18),
              rightIcon
            ]),
          ),
        ),
        divider,
      ],
    );
  }

  void _onDateClickItem(model,hobby) {
    Pickers.showDatePicker(
      context,
      mode: model,
      suffix: Suffix.normal(),
      // selectDate: PDuration(month: 2),
      minDate: PDuration(year: 2020, month: 2, day: 10),
      maxDate: PDuration(second: 22),
      selectDate: (hobby['value']['value'] == '' || hobby['value']['value'] == null
          ? PDuration(year: 2021, month: 2, day: 10)
          : PDuration.parse(DateTime.parse(hobby['value']['value']))),
      // minDate: PDuration(hour: 12, minute: 38, second: 3),
      // maxDate: PDuration(hour: 12, minute: 40, second: 36),
      onConfirm: (p) {
        print('longer >>> 返回数据：$p');
        setState(() {
          hobby['value']['label'] = formatDate(
              DateFormat('yyyy-MM-dd')
                  .parse('${p.year}-${p.month}-${p.day}'),
              [
                yyyy,
                "-",
                mm,
                "-",
                dd,
              ]);
          hobby['value']['value'] = formatDate(
              DateFormat('yyyy-MM-dd')
                  .parse('${p.year}-${p.month}-${p.day}'),
              [
                yyyy,
                "-",
                mm,
                "-",
                dd,
              ]);
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
        if(hobby  == 'emp'){
          setState(() {
            stock['value']['label'] = p;
          });
          var elementIndex = 0;
          data.forEach((element) {
            if (element == p) {
              stock['value']['value'] = stock['empListObj'][elementIndex][2];
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
              hobby['value']['value'] = departmentListObj[elementIndex][2];
            }
            elementIndex++;
          });
          print(1111111111);
          print(stock);
          getEmpList(hobby['value']['value'],stock);
          stock[8]['value']['hide'] = true;
          stock[8]['value']['value'] = "";
          stock[8]['value']['label'] = "";
        }
      },
    );
  }

  List<Widget> _getHobby() {
    List<Widget> tempList = [];
    for (int i = 0; i < this.hobby.length; i++) {
      List<Widget> comList = [];
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (!this.hobby[i][j]['isHide']) {
          if (j == 9) {
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
          } else if (j == 6) {
            comList.add(
              _dateItem('接收日期：', DateMode.YMD,this.hobby[i][j]['value']['label'], this.hobby[i][j]),
            );
          }else if (j == 7) {
            comList.add(
              _item(
                  '班组:', departmentList, this.hobby[i][j]['value']['label'], this.hobby[i][j],stock:this.hobby[i]),
            );
          }else if (j == 8) {
            comList.add(
              _item('人员:', this.hobby[i][j]['empList'], this.hobby[i][j]['value']['label'],
                  'emp',stock:this.hobby[i][j]),
            );
          }else if (j == 10) {
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
                            print((double.parse(_FNumber)));
                            print(this.fOrderQty);
                            print((double.parse(_FNumber)) <= this.fOrderQty);
                            if((double.parse(_FNumber)) <= this.fOrderQty){
                              this.hobby[checkData][checkDataChild]["value"]
                              ["label"] = _FNumber;
                              this.hobby[checkData][checkDataChild]['value']
                              ["value"] = _FNumber;
                            }else{
                              ToastUtil.showInfo('接收数量不能大于移交数量');
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
  //保存
  saveOrder() async {
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      //获取登录信息
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var menuData = sharedPreferences.getString('MenuPermissions');
      var deptData = jsonDecode(menuData)[0];
      Map<String, dynamic> dataMap = Map();
      dataMap['formid'] = 'QDEP_Proc_HandOver';
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedReturnFields'] = [];
      orderMap['IsDeleteEntry'] = false;
      Map<String, dynamic> Model = Map();
      Model['FID'] = orderDate[0][13];
      var FEntity = [];
      var hobbyIndex = 0;
      NumberFormat formatter = NumberFormat("00");
      this.hobby.forEach((element) {
        if (element[9]['value']['value'] != '0' && element[7]['value']['value'] != '' && element[8]['value']['value'] != '') {
          Map<String, dynamic> FEntityItem = Map();
          FEntityItem['FEntryID'] = orderDate[hobbyIndex][4];
          FEntityItem['FAcceptTeam'] = {
            "FNUMBER": element[7]['value']['value']
          };
          FEntityItem['FAcceptEmp'] = {
            "FSTAFFNUMBER": element[8]['value']['value']
          };
          FEntityItem['FAcceptQty'] = element[9]['value']['value'];
          FEntityItem['FAcceptDate'] = element[6]['value']['value'];
          FEntity.add(FEntityItem);
        }
        hobbyIndex++;
      });
      if (FEntity.length == 0) {
        this.isSubmit = false;
        ToastUtil.showInfo('请输入数量,班组,人员');
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
          "formid": "QDEP_Proc_HandOver",
          "data": {
            'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
          }
        };
        //提交
        HandlerOrder.orderHandler(
            context,
            submitMap,
            1,
            "QDEP_Proc_HandOver",
            SubmitEntity.submit(submitMap))
            .then((submitResult) {
          if (submitResult) {
            //审核
            HandlerOrder.orderHandler(
                context,
                submitMap,
                1,
                "QDEP_Proc_HandOver",
                SubmitEntity.audit(submitMap))
                .then((auditResult) {
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
                    "QDEP_Proc_HandOver",
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
    } else {
      ToastUtil.showInfo('无提交数据');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterEasyLoading(
      child: Scaffold(
          appBar: AppBar(
            title: Text("工序接收"),
            centerTitle: true,
            leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop(this.fOrderNum);
                }),
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: ListView(children: <Widget>[
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
                        this.isSubmit ? null : saveOrder(),
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
