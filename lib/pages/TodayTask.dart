import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mny_mngm/model/getDeviceId.dart';
import 'package:intl/intl.dart';
import 'package:mny_mngm/model/provider.dart';
import 'package:provider/provider.dart'; // 日付フォーマット用

class TodayTaskPage extends StatefulWidget {
  @override
  _TodayTaskPageState createState() => _TodayTaskPageState();
}

class _TodayTaskPageState extends State<TodayTaskPage> {
  String selectedChild = "";
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;
  String deviceID = getDeviceIDweb();
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
      await _fetchTasksFromFirestore(selectedChild);
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
    _fetchTasksFromFirestore(selectedChild);
  }

  Future<void> _fetchTasksFromFirestore(String child) async {
    try {
      String deviceID = await getDeviceIDweb(); // デバイスID取得
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      QuerySnapshot querySnapshot = await firestore
          .collection(deviceID) // デバイス固有のコレクション名
          .doc('task') // 固定のドキュメント名
          .collection(child) // サブコレクション
          .get();

      DocumentSnapshot completedSnapshot = await firestore
          .collection(deviceID)
          .doc('completedTasks')
          .collection(child)
          .doc('completedTasks')
          .get();

      Map<String, dynamic> completedTasks =
          completedSnapshot.data() as Map<String, dynamic>? ?? {};

      // タスクデータをリストに変換
      List<Map<String, dynamic>> fetchedTasks = querySnapshot.docs.map((doc) {
        return {
          'taskName': doc['task'],
          'reward': doc['reward'],
        };
      }).toList();

      DateTime now = DateTime.now();
      fetchedTasks = fetchedTasks.where((task) {
        Timestamp? completedTimestamp = completedTasks[task['taskName']];
        if (completedTimestamp == null) {
          return true;
        } else {
          DateTime completedDate = completedTimestamp.toDate();
          return now.year != completedDate.year ||
              now.month != completedDate.month ||
              now.day != completedDate.day;
        }
      }).toList();

      setState(() {
        tasks = fetchedTasks;
        isLoading = false;
      });
    } catch (e) {
      print("タスクの取得中にエラーが発生しました: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void completeTask(String child, int index) async {
    String completedTask = tasks[index]['taskName'];
    int completedReward = tasks[index]["reward"];
    setState(() {
      tasks.removeAt(index);
    });

    String deviceID = await getDeviceIDweb(); // デバイスID取得
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    DocumentReference rewardDocRef = firestore
        .collection(deviceID) // デバイス固有のコレクション名
        .doc('reward')
        .collection(child)
        .doc("reward");

    DocumentReference streekDocRef = firestore
        .collection(deviceID) // デバイス固有のコレクション名
        .doc('Streek')
        .collection(child)
        .doc("Streek");

    await firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(rewardDocRef);

      if (snapshot.exists) {
        // ドキュメントが存在する場合は更新
        transaction
            .update(rewardDocRef, {'円': FieldValue.increment(completedReward)});
      } else {
        // ドキュメントが存在しない場合は新しく作成
        transaction.set(rewardDocRef, {'円': completedReward});
      }
    });

    if (tasks.isEmpty) {
      await firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(streekDocRef);

        if (snapshot.exists) {
          // ドキュメントが存在する場合は更新
          transaction.update(streekDocRef, {'日': FieldValue.increment(1)});
        } else {
          // ドキュメントが存在しない場合は新しく作成
          transaction.set(streekDocRef, {'日': 1});
        }
      });
    }

    await firestore
        .collection(deviceID)
        .doc('completedTasks')
        .collection(child)
        .doc("completedTasks")
        .set({
      completedTask: Timestamp.now(), // タスクの達成日時を保存
    }, SetOptions(merge: true));

    // 達成メッセージを表示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('やること「$completedTask」を達成しました！'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 今日の日付を取得
    String formattedDate = DateFormat('MM/dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text("今日のやること"),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 今日の日付表示
            Center(
              child: Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 70, // 大きく表示
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // タスクリスト
            isLoading
                ? Center(child: CircularProgressIndicator())
                : tasks.isEmpty
                    ? Center(
                        child: Text(
                          '今日の「やること」は全て達成しました！',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: ListTile(
                                title: Text(
                                  tasks[index]['taskName'],
                                  style: TextStyle(fontSize: 18),
                                ),
                                subtitle:
                                    Text('報酬: ${tasks[index]['reward']}円'),
                                trailing: ElevatedButton(
                                  onPressed: () =>
                                      completeTask(selectedChild, index),
                                  child: Text('達成'),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}
