import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mny_mngm/model/getDeviceId.dart';

String selectedChild = "";
String deviceID = getDeviceIDweb();
List<String> childrenList = [];

Future<void> fetchChildList() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  DocumentReference Childrenlist =
      firestore.collection(deviceID).doc("children");
  childrenList = Childrenlist as List<String>;
  selectedChild = childrenList[0];
}

void addChild(String NewChild) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  childrenList.add(NewChild);

  await firestore
      .collection(deviceID)
      .doc("children")
      .set({"List": childrenList});
  fetchChildList();
}
