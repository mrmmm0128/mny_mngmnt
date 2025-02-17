import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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
  Color gradientEndColor = const Color(0xFFFEF9E7);
  bool gradation = true;
  Color pickerColor = const Color(0xFFFEF9E7);

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

  void updateBool(bool newBool) {
    setState(() {
      gradation = newBool;
      final colorNotifier = Provider.of<ColorNotifier>(context, listen: false);
      colorNotifier.setGradation(gradation); // Provider にも色を設定
    });
  }

  void updateColor(Color color) {
    setState(() {
      pickerColor = color;
      gradientEndColor = pickerColor; // 色を更新
      final colorNotifier = Provider.of<ColorNotifier>(context, listen: false);
      gradation = Provider.of<ColorNotifier>(context).gradation;
      colorNotifier.setEndColor(gradientEndColor); // Provider にも色を設定
    });
  }

  Widget _buildContext() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : childrenList.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // アプリへようこそ！のテキスト
                    const Text(
                      "へようこそ！",
                      style: TextStyle(
                        fontSize: 30, // 大きな文字サイズ
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // 明るい色で目立たせる
                      ),
                    ),
                    const SizedBox(height: 24),

                    // アイコン画像 (円形にする)

                    Image.asset(
                      "image/go.png", // 画像のパスを指定
                      width: 120, // アイコンの幅
                      height: 120, // アイコンの高さ
                      fit: BoxFit.cover, // 画像をうまく収める
                    ),

                    const SizedBox(height: 24),

                    // 説明テキスト
                    const Text(
                      "さっそく名前を入力しておこづかいをためよう！",
                      style: TextStyle(
                        fontSize: 20, // 少し大きめの文字サイズ
                        fontWeight: FontWeight.w500,
                        color: Colors.black87, // 見やすい色
                      ),
                      textAlign: TextAlign.center, // 中央揃え
                    ),
                    const SizedBox(height: 24),

                    // 名前入力フィールド
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white, // 背景を白に
                        borderRadius: BorderRadius.circular(15), // 丸みをつける
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1), // 影の色
                            spreadRadius: 3, // 影の広がり
                            blurRadius: 6, // 影のぼかし
                            offset: const Offset(0, 4), // 影の位置
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _childNameController,
                        decoration: const InputDecoration(
                          border: InputBorder.none, // 枠線なし
                          labelText: '名前',
                          hintText: '名前を入力してください',
                          hintStyle: TextStyle(color: Colors.grey), // ヒントテキストの色
                          labelStyle: TextStyle(color: Colors.black), // ラベルの色
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 追加ボタン
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30), // 丸みを帯びたボタン
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2), // 影の色
                            spreadRadius: 3, // 影の広がり
                            blurRadius: 6, // 影のぼかし
                            offset: const Offset(0, 4), // 影の位置
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => addChild(_childNameController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gradientEndColor, // 背景色
                          foregroundColor: Colors.white, // テキスト色
                          elevation: 0, // ボタンに影を追加
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 16), // パディングの調整
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(30), // 丸みを帯びたボタン
                          ),
                        ),
                        child: const Text(
                          "追加",
                          style: TextStyle(
                            fontSize: 20, // 少し大きめのフォント
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // ユーザーに選択された子供の表示
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white, // 背景を白に
                                          borderRadius: BorderRadius.circular(
                                              15), // 丸みをつける
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.1), // 影の色
                                              spreadRadius: 3, // 影の広がり
                                              blurRadius: 6, // 影のぼかし
                                              offset:
                                                  const Offset(0, 4), // 影の位置
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            '現在選択されている子供: $selectedChild',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      const Text(
                                        'タスクを追加して毎日継続して達成しよう！',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),

                                      const SizedBox(height: 24),

                                      // イメージ（掃除・勉強のタスクを示す）
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Card(
                                              elevation: 5,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              color: const Color(0xFFFFF3E0),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Column(
                                                  children: [
                                                    Image.asset(
                                                      'image/cleaning.png',
                                                      height: 100,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    const Text(
                                                      "掃除",
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Card(
                                              elevation: 5,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              color: const Color(0xFFFFF3E0),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Column(
                                                  children: [
                                                    Image.asset(
                                                      'image/studying.png',
                                                      height: 100,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    const Text(
                                                      "勉強",
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 24),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Card(
                                              elevation: 5,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              color: const Color(0xFFFFF3E0),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Column(
                                                  children: [
                                                    Image.asset(
                                                      'image/cooking.png',
                                                      height: 100,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    const Text(
                                                      "料理",
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Card(
                                              elevation: 5,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              color: const Color(0xFFFFF3E0),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Column(
                                                  children: [
                                                    Image.asset(
                                                      'image/training.png',
                                                      height: 100,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    const Text(
                                                      "運動",
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 24,
                                      ),

                                      // タスク追加ボタン
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        child: ElevatedButton.icon(
                                          onPressed: _showAddTaskDialog,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: gradientEndColor,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 32, vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          icon: const Icon(Icons.add,
                                              color: Colors.black),
                                          label: const Text(
                                            "タスクを追加する",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
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
                                      return InkWell(
                                        onTap: () {
                                          print(
                                              "タスクを選択: ${tasks[index]['task']}");
                                        },
                                        child: Card(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          elevation: 4, // 影をつけて視覚的に強調
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                12), // カードの角を丸くする
                                          ),
                                          child: ListTile(
                                            title: Text(
                                              tasks[index]['task'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Text(
                                              'おこづかい: ${tasks[index]['reward']}円',
                                              style: const TextStyle(
                                                  color: Colors.green),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      color: Colors.blue),
                                                  onPressed: () =>
                                                      _showEditTaskDialog(
                                                          index,
                                                          tasks[index]
                                                              ['reward']),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.red),
                                                  onPressed: () =>
                                                      deleteTaskFromFirestore(
                                                          selectedChild, index),
                                                ),
                                              ],
                                            ),
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
                                        backgroundColor: gradientEndColor,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        elevation: 0),
                                    child: const Text(
                                      "追加",
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("やることリスト"),
        foregroundColor: Colors.black,
        backgroundColor: gradientEndColor,
        centerTitle: true,
        automaticallyImplyLeading: true,
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
