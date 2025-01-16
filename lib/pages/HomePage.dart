import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mny_mngm/model/getDeviceId.dart';
import 'package:mny_mngm/model/provider.dart';
import 'package:provider/provider.dart';

class InputTaskPage extends StatefulWidget {
  @override
  _InputTaskPageState createState() => _InputTaskPageState();
}

class _InputTaskPageState extends State<InputTaskPage> {
  String selectedChild = "";
  List<Map<String, dynamic>> tasks = [];
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
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String deviceID = getDeviceIDweb();
      QuerySnapshot querySnapshot = await firestore
          .collection(deviceID)
          .doc('task')
          .collection(child)
          .get();

      List<Map<String, dynamic>> fetchedTasks = querySnapshot.docs.map((doc) {
        return {
          'task': doc['task'],
          'reward': doc['reward'],
        };
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

  Future<void> saveTasksToFirestore(
      String child, String task, int reward, BuildContext context) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String deviceID = getDeviceIDweb();

      QuerySnapshot querySnapshot = await firestore
          .collection(deviceID)
          .doc('task')
          .collection(child)
          .get();
      int length = querySnapshot.docs.length;

      await firestore
          .collection(deviceID)
          .doc('task')
          .collection(child)
          .doc('task_${length + 1}')
          .set({
        'task': task,
        'reward': reward,
      });

      setState(() {
        tasks.add({'task': task, 'reward': reward});
      });

      Navigator.pop(context); // モーダルを閉じる

      print("タスクが正常に保存されました");
    } catch (e) {
      print("タスク保存中にエラーが発生しました: $e");
    }
  }

  Future<void> editTaskInFirestore(String child, int index, int reward) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String defoltTask = tasks[index]["task"];
      String deviceID = getDeviceIDweb();

      await firestore
          .collection(deviceID)
          .doc('task')
          .collection(child)
          .doc('task_${index + 1}')
          .update({
        'task': defoltTask,
        'reward': reward,
      });

      setState(() {
        tasks[index] = {'task': defoltTask, 'reward': reward};
      });

      print("タスクが正常に更新されました");
    } catch (e) {
      print("タスク更新中にエラーが発生しました: $e");
    }
  }

  Future<void> deleteTaskFromFirestore(String child, int index) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String deviceID = getDeviceIDweb();

      await firestore
          .collection(deviceID)
          .doc('task')
          .collection(child)
          .doc('task_${index + 1}')
          .delete();

      setState(() {
        tasks.removeAt(index);
      });

      print("タスクが正常に削除されました");
    } catch (e) {
      print("タスク削除中にエラーが発生しました: $e");
    }
  }

  void _showAddTaskDialog() {
    final taskController = TextEditingController();
    final rewardController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('新しい「やること」を追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskController,
                decoration: const InputDecoration(hintText: '「やること」を入力してください'),
              ),
              TextField(
                controller: rewardController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'おこづかいを入力'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                final task = taskController.text;
                final reward = int.parse(rewardController.text);
                if (task.isNotEmpty && reward > 0) {
                  saveTasksToFirestore(selectedChild, task, reward, context);
                }
              },
              child: Text('追加'),
            ),
          ],
        );
      },
    );
  }

  void _showEditTaskDialog(int index, int reward) {
    final rewardController = TextEditingController(text: reward.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('おこづかいを編集'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rewardController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'おこづかいを入力してください'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                final editedReward = int.parse(rewardController.text);
                if (editedReward > 0) {
                  editTaskInFirestore(selectedChild, index, editedReward);
                  Navigator.pop(context); // モーダルを閉じる
                }
              },
              child: Text('更新'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("やることリスト"),
        foregroundColor: Colors.black,
        backgroundColor: const Color(0xFFFF9800),
        centerTitle: true,
        automaticallyImplyLeading: false,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE0B2), Color(0xFFFF9800)], // グラデーションの色
            begin: Alignment.topCenter, // グラデーションの開始位置
            end: Alignment.bottomCenter, // グラデーションの終了位置
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : childrenList.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "子供を追加してください",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _childNameController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '子供の名前',
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => addChild(_childNameController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 230, 167, 72),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "追加",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tasks.isEmpty
                            ? Center(
                                child: selectedChild == ""
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            height: 40,
                                          ),
                                          const Text(
                                            '子供が選択されていません。',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Image.asset(
                                            "image/children.png",
                                            height: 150,
                                          )
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '現在選択されている子供: $selectedChild\n「やること」がありません',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Image.asset(
                                            "image/cleaning-staff.png",
                                            height: 150,
                                          ),
                                          const SizedBox(
                                            height: 16,
                                          ),
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: _showAddTaskDialog,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                        255, 230, 167, 72),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 32,
                                                        vertical: 16),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: const Text(
                                                "「やること」を追加",
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              )
                            : Expanded(
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        // ignore: unnecessary_null_comparison
                                        selectedChild == ""
                                            ? "子供が選択されていません"
                                            : '現在選択されている子供: $selectedChild',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: tasks.length,
                                        itemBuilder: (context, index) {
                                          return Card(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            child: ListTile(
                                              title: Text(tasks[index]['task']),
                                              subtitle: Text(
                                                  'おこづかい: ${tasks[index]['reward']}円'),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon:
                                                        const Icon(Icons.edit),
                                                    onPressed: () =>
                                                        _showEditTaskDialog(
                                                            index,
                                                            tasks[index]
                                                                ['reward']),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.delete),
                                                    onPressed: () =>
                                                        deleteTaskFromFirestore(
                                                            selectedChild,
                                                            index),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 16,
                                    ),
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: _showAddTaskDialog,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                              255, 230, 167, 72),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32, vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: const Text(
                                          "「やること」を追加",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ],
                    ),
        ),
      ),
    );
  }
}
