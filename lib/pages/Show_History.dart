import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mny_mngm/model/getDeviceId.dart';
import 'package:mny_mngm/model/provider.dart';
import 'package:provider/provider.dart';

class RewardPage extends StatefulWidget {
  const RewardPage({super.key});

  @override
  _RewardPageState createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  String selectedChild = "";
  late Future<int> _reward;
  late Future<int> _streek;
  bool isLoading = true;
  List<String> childrenList = [];
  final TextEditingController _childNameController = TextEditingController();
  Color gradientEndColor = const Color(0xFFFEF9E7);
  Color pickerColor = const Color(0xFFFEF9E7);
  bool gradation = true;

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    if (childrenList.isNotEmpty) {
      _reward = _getReward(selectedChild);
      _streek = _getStreek(selectedChild);
    }
    setState(() {
      isLoading = false;
    });
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
    _reward = _getReward(selectedChild);
    _streek = _getStreek(selectedChild);
    setState(() {});
  }

  Future<int> _getReward(String child) async {
    String deviceID = await getDeviceIDweb(); // deviceIDを取得する関数を使用
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection(deviceID)
        .doc('reward')
        .collection(child)
        .doc("reward")
        .get();

    if (snapshot.exists) {
      return snapshot['円'];
    } else {
      return 0;
    }
  }

  Future<int> _getStreek(String child) async {
    String deviceID = await getDeviceIDweb(); // deviceIDを取得する関数を使用
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection(deviceID)
        .doc('Streek')
        .collection(child)
        .doc("Streek")
        .get();

    if (snapshot.exists) {
      return snapshot['日'];
    } else {
      return 0;
    }
  }

  void _resetReward(String child) async {
    String deviceID = await getDeviceIDweb();
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    firestore
        .collection(deviceID)
        .doc("reward")
        .collection(child)
        .doc("reward")
        .set({"円": 0});
    setState(() {});
  }

  Widget _buildContext() {
    return isLoading
        ? const Center(
            child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator()),
          )
        : Center(
            child: selectedChild.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        '子供が選択されていません。',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Poppins",
                        ),
                      ),
                      const SizedBox(height: 16),
                      Image.asset("image/children.png", height: 150),
                    ],
                  )
                : Column(
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset("image/happiness.png", height: 20),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '現在選択されている子供: $selectedChild',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Image.asset("image/jumping-man.png", height: 20),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: FutureBuilder<int>(
                              future: _streek,
                              builder: (context, streekSnapshot) {
                                if (streekSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator()));
                                } else if (streekSnapshot.hasError) {
                                  return Text(
                                    'エラー: ${streekSnapshot.error}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.red,
                                      fontFamily: 'Poppins',
                                    ),
                                  );
                                } else if (streekSnapshot.hasData) {
                                  return Card(
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    color: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          Image.asset(
                                            'image/money.png',
                                            height: 100,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '${streekSnapshot.data} 日間連続で達成しています！',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  return const Text(
                                    'ストリークデータがありません',
                                    style: TextStyle(
                                        fontSize: 18, fontFamily: 'Poppins'),
                                  );
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: FutureBuilder<int>(
                              future: _reward,
                              builder: (context, rewardSnapshot) {
                                if (rewardSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator()));
                                } else if (rewardSnapshot.hasError) {
                                  return Text(
                                    'エラー: ${rewardSnapshot.error}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.red,
                                      fontFamily: 'Poppins',
                                    ),
                                  );
                                } else if (rewardSnapshot.hasData) {
                                  return Card(
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    color: const Color(0xFFFFF3E0),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          Image.asset(
                                            'image/child_money.png',
                                            height: 100,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '今のおこづかい: ${rewardSnapshot.data} 円',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  return const Text(
                                    '報酬データがありません',
                                    style: TextStyle(
                                        fontSize: 18, fontFamily: 'Poppins'),
                                  );
                                }
                              },
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset(
                                  "image/midasi.png",
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                const Positioned(
                                  top: 50, // ここを調整して上に移動
                                  left: 0,
                                  right: 0,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "おこづかいを受け取りますか？",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                          color: Colors.black,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(1.5, 1.5),
                                              blurRadius: 2.0,
                                              color: Colors.black54,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      const Text(
                                        "受け取った場合、溜まっているお小遣いは０円になります",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(1.5, 1.5),
                                              blurRadius: 2.0,
                                              color: Colors.black54,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                _resetReward(selectedChild);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: gradientEndColor,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                "受け取る",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "これまでのがんばり",
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        automaticallyImplyLeading: true,
        backgroundColor: gradientEndColor, // ビビッドなオレンジ
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // プロフィールページに移動する処理
            },
          ),
        ],
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
              child: _buildContext(), // 共通の子ウィジェットを関数化
            )
          : Container(
              color: const Color(0xFFFFF3E0),
              child: _buildContext(),
            ),
    );
  }
}
