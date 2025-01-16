import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mny_mngm/model/getDeviceId.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  List<String> childrenList = [];
  String selectedChild = "";
  bool isLoading = true;
  final TextEditingController _childNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchChildList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchChildList();
    setState(() {});
  }

  Future<void> fetchChildList() async {
    try {
      isLoading = true;
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
          selectedChild = childrenList.isNotEmpty ? childrenList[0] : "";
        });
      } else {
        setState(() {
          childrenList = [];
          selectedChild = "";
          isLoading = false;
        });
      }
    } catch (e) {
      print("エラーが発生しました: $e");
      setState(() {
        childrenList = [];
        selectedChild = "";
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
    setState(() {});
  }

  void deleteChildName(String Name) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String deviceID = getDeviceIDweb();
    List<String> documentList = ["Streek", "completedTasks", "task", "reward"];

    childrenList.remove(Name);
    await firestore
        .collection(deviceID)
        .doc("children")
        .set({"List": childrenList});
    setState(() {});

    try {
      for (String docId in documentList) {
        QuerySnapshot subcollectionSnapshot = await firestore
            .collection(deviceID)
            .doc(docId)
            .collection(Name)
            .get();
        for (QueryDocumentSnapshot doc in subcollectionSnapshot.docs) {
          await firestore
              .collection(deviceID)
              .doc(docId)
              .collection(Name)
              .doc(doc.id)
              .delete();
        }
      }
      setState(() {});
    } catch (e) {
      print("エラー $e");
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
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<int>(
            onSelected: (int result) {
              if (result == -1) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('子供を追加'),
                      content: TextField(
                        controller: _childNameController,
                        decoration: const InputDecoration(
                          labelText: '子供の名前',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () {
                            addChild(_childNameController.text);
                            Navigator.pop(context);
                          },
                          child: const Text('追加'),
                        ),
                      ],
                    );
                  },
                );
              } else {}
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
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const Text(
              "毎日成長アプリへようこそ",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "毎日一歩ずつ成長しましょう！",
              style: TextStyle(
                fontSize: 18,
                color: Color.fromARGB(255, 23, 22, 22),
              ),
            ),
            const SizedBox(height: 32),
            const Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Color.fromARGB(255, 230, 167, 72),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "このアプリは、日々の「やること」を管理し、達成することで「おこづかい」を獲得するためのものです。以下の機能をお楽しみください：\n\n"
                "1. 「やること」の追加：やることリストに新しいタスクを追加し、「おこづかい」を設定します。\n"
                "2. 「やること」の達成：完了したタスクをマークして「おこづかい」を獲得しましょう。\n"
                "3. 「おこづかい」の管理：獲得した報酬を確認し、モチベーションを高めます。\n\n"
                "一緒に毎日成長していきましょう！",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "登録している子供のリスト",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400, // Change height according to your requirement
              child: ListView.builder(
                itemCount: childrenList.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text(
                        childrenList[index],
                        style: const TextStyle(fontSize: 18),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                deleteChildName(childrenList[index]),
                          ),
                        ],
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
