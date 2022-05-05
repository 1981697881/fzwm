import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fzwm/model/currency_entity.dart';
import 'package:fzwm/utils/toast_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:shared_preferences/shared_preferences.dart';

class DrawingPage extends StatefulWidget {
  DrawingPage( {Key key}) : super(key: key);

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final controller = TextEditingController();
  static const scannerPlugin =
      const EventChannel('com.shinow.pda_scanner/plugin');
  StreamSubscription _subscription;
  final divider = Divider(height: 1, indent: 20);
  String pdfUrl = "";
  String pathPDF = "";
  String keyWord = '';
  var _code;
  List<dynamic> orderDate = [];

  @override
  void initState() {
    super.initState();

    /// 开启监听
    /*if (_subscription == null) {
      _subscription = scannerPlugin
          .receiveBroadcastStream()
          .listen(_onEvent, onError: _onError);
    }*/
  }

  void _onEvent(Object event) async {
    /*  setState(() {*/
    _code = event;
    keyWord = _code;
    this.controller.text = _code;
    await getOrderList();
    /*});*/
  }

  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
  }

  @override
  void dispose() {
    this.controller.dispose();
    super.dispose();

    /// 取消监听
    /* if (_subscription != null) {
      _subscription.cancel();
    }*/
  }

  getOrderList() async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    userMap['FilterString'] = "FNumber='$_code' and FForbidStatus = 'A' and FUseOrgId.FNumber = "+deptData[1];
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] = 'F_ora_Text';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    orderDate = jsonDecode(order);
    if (orderDate.length > 0) {
      print(orderDate);
      pdfUrl = orderDate[0][0];
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PDFScreen(
                pathPDF:
                    "https://tz.xinyuanhengye.cn:8088/tz.html?file=$pdfUrl.pdf")),
      );
      /*createFileOfPdfUrl().then((f) {
        setState(() {
          pathPDF = f.path;
          print(pathPDF);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PDFScreen(pathPDF: pathPDF)),
          );
        });
      });*/
    } else {
      ToastUtil.showInfo('无数据');
    }
  }

  Future<File> createFileOfPdfUrl() async {
    var url = "https://tz.xinyuanhengye.cn:8088/tz.html?file=$pdfUrl.pdf";
    /* var url = "http://africau.edu/images/default/sample.pdf";*/
    print(url);
    final filename = url.substring(url.lastIndexOf("/") + 1);
    HttpClient client = HttpClient();
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      return true;
    };
    String result;
    var bytes;
    try {
      var request = await client.getUrl(Uri.parse(url));
      var response = await request.close();
      if (response.statusCode == 200) {
        bytes = await consolidateHttpClientResponseBytes(response);
        var responseBody = await response.transform(utf8.decoder).join();
        var json = responseBody;
        var data = jsonDecode(json);
        print(data.toString());
        print("data----$data");
        result = 'HttpStatus.ok';
      } else {
        result =
            'Error getting IP address:\nHttp status ${response.statusCode}';
      }
    } catch (exception) {
      result = 'Failed getting IP address';
    }
    print("result----$result");
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = new File('$dir/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }
//扫码函数,最简单的那种
  Future scan() async {
    String cameraScanResult = await scanner.scan(); //通过扫码获取二维码中的数据
    getScan(cameraScanResult); //将获取到的参数通过HTTP请求发送到服务器
    print(cameraScanResult); //在控制台打印
  }

//get请求，用于验证数据(也可以在控制台直接打印，但模拟器体验不好)
  void getScan(String scan) async {
    keyWord = scan;
    this.controller.text = scan;
    await getOrderList();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: scan,
          tooltip: 'Increment',
          child: Icon(Icons.filter_center_focus),
        ),
        appBar: AppBar(title: const Text('图纸查询'), centerTitle: true),
        body: CustomScrollView(
          slivers: <Widget>[
            SliverPersistentHeader(
              pinned: true,
              delegate: StickyTabBarDelegate(
                minHeight: 50, //收起的高度
                maxHeight: 50, //展开的最大高度
                child: Container(
                  color: Theme.of(context).primaryColor,
                  child: Padding(
                    padding: EdgeInsets.only(top: 2.0),
                    child: Container(
                      height: 52.0,
                      child: new Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: new Card(
                            child: new Container(
                              child: new Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  SizedBox(
                                    width: 6.0,
                                  ),
                                  Icon(
                                    Icons.search,
                                    color: Colors.grey,
                                  ),
                                  Expanded(
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: TextField(
                                        controller: this.controller,
                                        decoration: new InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(bottom: 12.0),
                                            hintText: '输入关键字',
                                            border: InputBorder.none),
                                        onSubmitted: (value) {
                                          setState(() {
                                            this.keyWord  = value;
                                            this.getOrderList();
                                          });
                                        },
                                        // onChanged: onSearchTextChanged,
                                      ),
                                    ),
                                  ),
                                  new IconButton(
                                    icon: new Icon(Icons.cancel),
                                    color: Colors.grey,
                                    iconSize: 18.0,
                                    onPressed: () {
                                      this.controller.clear();
                                      // onSearchTextChanged('');
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}

// ignore: must_be_immutable
class PDFScreen extends StatelessWidget {
  final String pathPDF;

  PDFScreen({@required this.pathPDF});

  @override
  Widget build(BuildContext context) {
    return WebviewScaffold(
      appBar: AppBar(
        title: Text("图纸"),
      ),
      url: pathPDF,
      // 登录的URL
      withZoom: true,
      // 允许网页缩放
      withLocalStorage: true,
      // 允许LocalStorage
      withJavascript: true, // 允
    );
  }
/* Widget build(BuildContext context) {
    return PDFViewerScaffold(
        appBar: AppBar(
          title: Text("图纸"),
        ),
        path: pathPDF);
  }*/
}

class StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Container child;
  final double minHeight;
  final double maxHeight;

  StickyTabBarDelegate(
      {@required this.minHeight,
      @required this.maxHeight,
      @required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return this.child;
  }

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => max(maxHeight, minHeight);

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
