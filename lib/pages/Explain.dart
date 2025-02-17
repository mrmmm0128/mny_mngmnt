import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mny_mngm/model/getDeviceId.dart';
import 'package:mny_mngm/model/provider.dart';
import 'package:mny_mngm/pages/information.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  List<String> childrenList = [];
  bool isLoading = true;
  Color gradientEndColor = const Color(0xFFFEF9E7);
  Color pickerColor = const Color(0xFFFEF9E7); // 初期色を設定
  List<bool> badges = List.generate(9, (index) => index % 13 == 0);
  final TextEditingController _childNameController = TextEditingController();
  bool gradation = true;
  String selectedChild = "";

  List<String> badgeslist = [
    "5日連続で達成",
    "10日連続で達成",
    "15日連続で達成",
    "20日連続で達成",
    "25日連続で達成",
    "30日連続で達成",
    "35日連続で達成",
    "40日連続で達成",
    "45日連続で達成"
  ];

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    setState(() {
      isLoading = true;
      gradientEndColor = Provider.of<ColorNotifier>(context).gradientEndColor;
      gradation = Provider.of<ColorNotifier>(context).gradation;
    });

    selectedChild = Provider.of<ChildNotifier>(context).selectedChild;
    await fetchChildList();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchChildList() async {
    try {
      String deviceID = await getDeviceIDweb();
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentSnapshot snapshot =
          await firestore.collection(deviceID).doc("children").get();
      var data = snapshot.data();
      if (data != null &&
          data is Map<String, dynamic> &&
          data.containsKey("List")) {
        List<dynamic> childrenData = data["List"];
        setState(() {
          childrenList = childrenData.cast<String>();
        });
      } else {
        setState(() {
          childrenList = [];
        });
      }
    } catch (e) {
      print("エラーが発生しました: $e");
      setState(() {
        childrenList = [];
      });
    }
  }

  void addChild(String NewChild) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String deviceID = await getDeviceIDweb();
    childrenList.add(NewChild);

    await firestore
        .collection(deviceID)
        .doc("children")
        .set({"List": childrenList});
    final childNotifier = Provider.of<ChildNotifier>(context, listen: false);
    childNotifier.setSelectedChild(NewChild);
    setState(() {});
  }

  void changeSelectedChild(int index) {
    final childNotifier = Provider.of<ChildNotifier>(context, listen: false);
    String newChild = childrenList[index];
    childNotifier.setSelectedChild(newChild);
    setState(() {});
  }

  void updateColor(Color color) {
    setState(() {
      pickerColor = color;
      gradientEndColor = pickerColor; // 色を更新
      final colorNotifier = Provider.of<ColorNotifier>(context, listen: false);
      colorNotifier.setEndColor(gradientEndColor); // Provider にも色を設定
    });
  }

  void updateBool(bool newBool) {
    setState(() {
      gradation = newBool;
      final colorNotifier = Provider.of<ColorNotifier>(context, listen: false);
      colorNotifier.setGradation(gradation); // Provider にも色を設定
    });
  }

  Widget _buildBodyContent() {
    return Column(
      children: [
        const Text(
          "子供の名前",
          style: TextStyle(color: Colors.black),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3列のグリッド
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                String textBadge = badgeslist[index];
                bool isLocked = !badges[index];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 3,
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isLocked
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock,
                                  size: 50, color: Colors.grey),
                              Text(
                                textBadge,
                                style: const TextStyle(color: Colors.black),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : const Icon(Icons.star,
                            size: 50, color: Colors.orange),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("バッチ図鑑"),
        foregroundColor: Colors.black,
        backgroundColor: gradientEndColor,
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ヘッダー部分
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                "子供選択",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "Poppins",
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // リスト部分
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: childrenList.length + 1,
                itemBuilder: (context, index) {
                  if (index == childrenList.length) {
                    // 「子供を追加」ボタン
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: ListTile(
                          leading: const Icon(Icons.add, color: Colors.blue),
                          title: const Text(
                            '子供を追加',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text(
                                    '子供を追加',
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                  content: TextField(
                                    controller: _childNameController,
                                    decoration: const InputDecoration(
                                      labelText: '子供の名前',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('キャンセル'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        addChild(_childNameController.text);
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF03A9F4),
                                      ),
                                      child: const Text('追加'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    );
                  }

                  // 子供リスト
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          childrenList[index],
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                        onTap: () {
                          changeSelectedChild(index);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const Text(
              "色を選択しましょう",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Center(
                child: SlidePicker(
              pickerColor: pickerColor,
              onColorChanged: updateColor,
            )),
            const SizedBox(height: 16),
            // Gradation チェックボックス
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'グラデーションを適用',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Checkbox(
                    value: gradation,
                    onChanged: (bool? newValue) {
                      if (newValue != null) {
                        updateBool(newValue);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: gradation
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFEF9E7), gradientEndColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: _buildBodyContent(), // 共通の子ウィジェットを関数化
            )
          : Container(
              color: const Color(0xFFFFF3E0),
              child: _buildBodyContent(),
            ),
    );
  }
}
