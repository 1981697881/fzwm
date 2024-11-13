import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fzwm/views/drawing/drawing_page.dart';
import 'package:fzwm/views/index/index_page.dart';
import 'package:fzwm/views/production/picking_detail.dart';
import 'package:fzwm/views/production/picking_out_sourcing_page.dart';
import 'package:fzwm/views/production/picking_page.dart';
import 'package:fzwm/views/production/picking_return_sourcing_page.dart';
import 'package:fzwm/views/production/return_page.dart';
import 'package:fzwm/views/production/warehousing_detail.dart';
import 'package:fzwm/views/production/warehousing_page.dart';
import 'package:fzwm/views/purchase/purchase_return_page.dart';
import 'package:fzwm/views/purchase/purchase_warehousing_detail.dart';
import 'package:fzwm/views/purchase/purchase_warehousing_page.dart';
import 'package:fzwm/views/quality/production_report_page.dart';
import 'package:fzwm/views/quality/receiving_materials_page.dart';
import 'package:fzwm/views/sale/retrieval_detail.dart';
import 'package:fzwm/views/sale/retrieval_page.dart';
import 'package:fzwm/views/sale/return_goods_detail.dart';
import 'package:fzwm/views/sale/return_goods_page.dart';
import 'package:fzwm/views/stock/Inventory_detail.dart';
import 'package:fzwm/views/stock/Inventory_page.dart';
import 'package:fzwm/views/stock/allocation_detail.dart';
import 'package:fzwm/views/stock/ex_warehouse_detail.dart';
import 'package:fzwm/views/stock/ex_warehouse_page.dart';
import 'package:fzwm/views/stock/grounding_page.dart';
import 'package:fzwm/views/stock/other_warehousing_detail.dart';
import 'package:fzwm/views/stock/other_warehousing_page.dart';
import 'package:fzwm/views/stock/stock_page.dart';
import 'package:fzwm/views/stock/undercarriage_page.dart';
import 'package:fzwm/views/workshop/dispatch_detail.dart';
import 'package:fzwm/views/workshop/dispatch_page.dart';
import 'package:fzwm/views/workshop/receive_detail.dart';
import 'package:fzwm/views/workshop/receive_page.dart';
import 'package:fzwm/views/workshop/report_detail.dart';
import 'package:fzwm/views/workshop/report_page.dart';
import 'package:fzwm/views/workshop/submit_page.dart';

class MenuPermissions {
  static void getMenu() async {}

  static getMenuChild(item) {
    var list = jsonDecode(item)[0];
    /*[
      "201801004",
      "手机事业部",
      "A",
      true,
      "SCDD",
      false,
      "",
      true,
      "FHTZD",
      true,
      "THTZD",
      true,
      "SLTZD",
      true,
      "DTPD",
      true,
      "",
      true,
      "",
      false,
      "",
      false,
      "",
      false,
      false,
      false
    ];*/
    print(list);
    list.removeAt(0);
    list.removeAt(0);
    list.removeAt(0);
    list.removeAt(0);
    print(list.length);
    var menu = [];
    for (var i = 0; i < list.length; i++) {
      switch (i) {
        case 0:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "生产入库",
              "parentId": 1,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? WarehousingPage()
                  : WarehousingDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 2:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "生产领料",
              "parentId": 1,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? PickingPage()
                  : PickingDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 4:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "销售出库",
              "parentId": 2,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? RetrievalPage()
                  : RetrievalDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 6:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "销售退货",
              "parentId": 2,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? ReturnGoodsPage()
                  : ReturnGoodsDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 8:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "采购入库",
              "parentId": 5,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? PurchaseWarehousingPage()
                  : PurchaseWarehousingDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 10:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "盘点",
              "parentId": 3,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? InventoryPage()
                  : InventoryDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 12:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "其他入库",
              "parentId": 3,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? OtherWarehousingPage()
                  : OtherWarehousingDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 14:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "其他出库",
              "parentId": 3,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? ExWarehousePage()
                  : ExWarehouseDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 16:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "工序派工",
              "parentId": 4,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? DispatchPage()
                  : DispatchDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 18:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "工序汇报",
              "parentId": 4,
              "color": Colors.pink.withOpacity(0.7),
              "router": list[i + 1].length > 1
                  ? ReportPage()
                  : ReportDetail(FBillNo: null),
              "source": list[i + 1],
            };
            menu.add(obj);
          }
          break;
        case 20:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "上架",
              "parentId": 3,
              "color": Colors.pink.withOpacity(0.7),
              "router": GroundingPage(),
              "source": "",
            };
            menu.add(obj);
          }
          break;
        case 21:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "下架",
              "parentId": 3,
              "color": Colors.pink.withOpacity(0.7),
              "router": UndercarriagePage(),
              "source": '',
            };
            menu.add(obj);
          }
          break;
        case 22:
          if (list[i] == true) {
            var obj = {
              "icon": Icons.loupe,
              "text": "库存查询",
              "parentId": 3,
              "color": Colors.pink.withOpacity(0.7),
              "router": StockPage(),
              "source": '',
            };
            menu.add(obj);
          }
          break;
      }
    }
    menu.add({
      "icon": Icons.loupe,
      "text": "工序移交",
      "parentId": 4,
      "color": Colors.pink.withOpacity(0.7),
      "router": SubmitPage(),
      "source": '',  
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "工序接收",
      "parentId": 4,
      "color": Colors.pink.withOpacity(0.7),
      "router": ReceivePage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "图号查询",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": DrawingPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "调拨",
      "parentId": 3,
      "color": Colors.pink.withOpacity(0.7),
      "router": AllocationDetail(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "委外领料",
      "parentId": 6,
      "color": Colors.pink.withOpacity(0.7),
      "router": PickingOutSourcingPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "委外退料",
      "parentId": 6,
      "color": Colors.pink.withOpacity(0.7),
      "router": PickingReturnSourcingPage(),
      "source": '',
    });
    menu.add({
      "icon": Icons.loupe,
      "text": "生产退料",
      "parentId": 1,
      "color": Colors.pink.withOpacity(0.7),
      "router": ReturnPage(),
      "source": '',
    });menu.add({ 
      "icon": Icons.loupe,
      "text": "采购退货",
      "parentId": 5,
      "color": Colors.pink.withOpacity(0.7),
      "router": PurchaseReturnPage(),
      "source": '',
    });menu.add({
      "icon": Icons.loupe,
      "text": "收料检验",
      "parentId": 7,
      "color": Colors.pink.withOpacity(0.7),
      "router": ReceivingMaterialsPage(),
      "source": '',
    });menu.add({
      "icon": Icons.loupe,
      "text": "生产检验",
      "parentId": 7,
      "color": Colors.pink.withOpacity(0.7),
      "router": ProductionReportPage(),
      "source": '',
    });
    return menu;
  }
}
