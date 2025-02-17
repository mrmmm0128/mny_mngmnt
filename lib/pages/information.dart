import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mny_mngm/model/getDeviceId.dart';
import 'package:mny_mngm/model/provider.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
// ignore: must_be_immutable
class UserInfoPage extends StatefulWidget {
  final String childName;

  UserInfoPage({super.key, required this.childName});

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final List<String> fields = ['学年', '目標'];
  Map<String, String> dictionary = {
    '学年': '',
    '目標': '',
  };

  List<TextEditingController> controllers = [];

  @override
  void initState() {
    super.initState();
    // 各フィールドに対するコントローラーを初期化
    fields.forEach((field) {
      controllers.add(TextEditingController(text: dictionary[field]));
    });
  }

  @override
  void dispose() {
    // コントローラーを破棄
    controllers.forEach((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  Future<void> updateInformation() async {
    String deviceID = getDeviceIDweb();
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore
        .collection(deviceID)
        .doc("information")
        .collection(widget.childName)
        .doc("information")
        .set(dictionary);
  }

  Future<void> fetchInformation() async {
    String deviceID = getDeviceIDweb(); // デバイスIDの取得
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Firestoreから情報を取得
      DocumentSnapshot snapshot = await firestore
          .collection(deviceID)
          .doc("information")
          .collection(widget.childName)
          .doc("information")
          .get();

      if (snapshot.exists) {
        // Firestoreから取得したデータが存在する場合、Mapに変換してdictionary_originに格納
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        // 必要であれば、Map<String, String>に変換する処理
        Map<String, String> dictionary_origin = {};
        data.forEach((key, value) {
          if (value is String) {
            dictionary_origin[key] = value;
          }
        });

        // dictionary_originを利用して何か処理を行う
        print(dictionary_origin);
      } else {
        print("ドキュメントが存在しません");
      }
    } catch (e) {
      // エラーハンドリング
      print("エラーが発生しました: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    Color gradientEndColor =
        Provider.of<ColorNotifier>(context).gradientEndColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.childName),
        foregroundColor: Colors.black,
        backgroundColor: gradientEndColor,
        automaticallyImplyLeading: true,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFEF9E7), gradientEndColor], // 柔らかい色合いのグラデーション
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(
              height: 16,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => updateInformation(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gradientEndColor,
                    elevation: 5,
                    shadowColor: gradientEndColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "編集",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16.0),
              itemCount: fields.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: controllers[index],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0), // ここで角を丸くする
                      ),
                      labelText: fields[index],
                    ),
                    onChanged: (value) {
                      setState(() {
                        dictionary[fields[index]] = value;
                      });
                    },
                  ),
                );
              },
            ),
            ElevatedButton(
              onPressed: () => updateInformation(),
              style: ElevatedButton.styleFrom(
                backgroundColor: gradientEndColor,
                elevation: 5,
                shadowColor: gradientEndColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "みんなの目標を見る",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
