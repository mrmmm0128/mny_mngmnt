import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  Color gradientEndColor = const Color(0xFFFEF9E7);
  bool gradation = true;
  String formattedDate = DateFormat('MM/dd').format(DateTime.now());

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
      gradientEndColor = Provider.of<ColorNotifier>(context).gradientEndColor;
      gradation = Provider.of<ColorNotifier>(context).gradation;
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
    return Scaffold(
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

  Widget _buildContext() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日付表示
          Center(
            child: Text(
              formattedDate,
              style: GoogleFonts.coustard(
                fontSize: 70, // 大きく表示
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // タスク表示
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : tasks.isEmpty
                      ? _buildNoTasksUI()
                      : _buildTaskList(),
            ),
          ),
        ],
      ),
    );
  }

// タスクがないときのUI
  Widget _buildNoTasksUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (selectedChild.isEmpty) ...[
            const SizedBox(height: 40),
            const Text(
              '子供が選択されていません。',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Image.asset("image/children.png", height: 150),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
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
              child: Text(
                '現在選択されている子供: $selectedChild',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'タスクはありません！ \nおつかれさまでした!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Image.asset("image/reading.png", height: 150),
          ],
        ],
      ),
    );
  }

// タスクリストのUI
  Widget _buildTaskList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            selectedChild.isEmpty
                ? "子供が選択されていません"
                : '現在選択されている子供: $selectedChild',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.task_alt, color: Colors.green),
                  title: Text(
                    tasks[index]['taskName'],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('報酬: ${tasks[index]['reward']}円'),
                  trailing: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _confirmTaskCompletion(index),
                    child: const Text('達成'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

// 達成確認のダイアログ
  void _confirmTaskCompletion(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "このタスクを達成しますか？",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("キャンセル"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        completeTask(selectedChild, index);
                        Navigator.pop(context);
                      },
                      child: const Text("達成"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
