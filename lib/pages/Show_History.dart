import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> fetchChildList() async {
    try {
      String deviceID = getDeviceIDweb();
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
    String deviceID = getDeviceIDweb();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("これまでのがんばり"),
        foregroundColor: Colors.black,
        backgroundColor: const Color.fromARGB(255, 230, 167, 72),
        centerTitle: true,
        actions: [
          PopupMenuButton<int>(
            onSelected: (int result) {
              if (result == -1) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('子供を追加'),
                      content: TextField(
                        controller: _childNameController,
                        decoration: const InputDecoration(
                          labelText: '子供の名前',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () {
                            addChild(_childNameController.text);
                            Navigator.pop(context);
                          },
                          child: Text('追加'),
                        ),
                      ],
                    );
                  },
                );
              } else {
                changeSelectedChild(result);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                ...List.generate(childrenList.length, (index) {
                  return PopupMenuItem<int>(
                    value: index,
                    child: Text(childrenList[index]),
                  );
                }),
                const PopupMenuItem<int>(
                  value: -1,
                  child: Text('子供を追加'),
                ),
              ];
            },
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : FutureBuilder<int>(
                future: _streek,
                builder: (context, streekSnapshot) {
                  if (streekSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (streekSnapshot.hasError) {
                    return Text(
                      'エラー: ${streekSnapshot.error}',
                      style: TextStyle(fontSize: 24, color: Colors.red),
                    );
                  } else if (streekSnapshot.hasData) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '現在 ${streekSnapshot.data} 日間連続で達成しています！',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FutureBuilder<int>(
                          future: _reward,
                          builder: (context, rewardSnapshot) {
                            if (rewardSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (rewardSnapshot.hasError) {
                              return Text(
                                'エラー: ${rewardSnapshot.error}',
                                style:
                                    TextStyle(fontSize: 24, color: Colors.red),
                              );
                            } else if (rewardSnapshot.hasData) {
                              return Column(
                                children: [
                                  Text(
                                    'いまのおこずかい: ${rewardSnapshot.data} 円',
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'よくがんばりました！',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return const Text(
                                '報酬データがありません',
                                style: TextStyle(fontSize: 24),
                              );
                            }
                          },
                        ),
                      ],
                    );
                  } else {
                    return const Text(
                      'ストリークデータがありません',
                      style: TextStyle(fontSize: 24),
                    );
                  }
                },
              ),
      ),
    );
  }
}
