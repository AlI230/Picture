import 'dart:io';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:Picture/services/authentication.dart';
import 'package:Picture/services/admob_service.dart';

class FirestoreSlideshow extends StatefulWidget {
  FirestoreSlideshow({Key key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;

  createState() => FirestoreSlideshowState();
}

class FirestoreSlideshowState extends State<FirestoreSlideshow> {

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final ams = AdMobService();

  final PageController ctrl = PageController(viewportFraction: 0.8);

  final Firestore db = Firestore.instance;
  Stream slides;

  String activeTag = 'favorites';

  // Keep track of current page to avoid unnecessary renders
  int currentPage = 0;

  bool liked = false;

  @override
  void initState() {
    Admob.initialize(ams.getAdmobId());
    FirebaseAdMob.instance.initialize(appId: ams.getAdmobId());
    _queryDb();
    
    // Set state when page changes
    ctrl.addListener(() { 
      int next = ctrl.page.round();

      if(currentPage != next) { 
        setState(() {
          currentPage = next;
        });
      } 
    });
  }

  @override
  Widget build(BuildContext context) { 

      return new Scaffold(
        body: 
            
            StreamBuilder(
              stream: slides,
              initialData: [],
              builder: (context, AsyncSnapshot snap) { 

                List slideList = snap.data.toList();

                return PageView.builder(
                  controller: ctrl,
                  itemCount: slideList.length + 1,
                  itemBuilder: (context, int currentIdx) {
                  

                  if (currentIdx == 0) {
                    return _buildTagPage();
                  } else if (slideList.length >= currentIdx) {
                    // Active page
                    bool active = currentIdx == currentPage;
                    return _buildStoryPage(slideList[currentIdx - 1], active);
                  }
                }
              );
            }
    ),
      );
  }

  Stream _queryDb({ String tag ='favorites' }) {
    
    // Make a Query
    Query query = db.collection("pictures").where('userId', isEqualTo: widget.userId).where('tags', arrayContains: tag);

    // Map the documents to the data payload
    slides = query.snapshots().map((list) => list.documents.map((doc) => doc.data));

    // Update the active tag
    setState(() {
      activeTag = tag;
    });

  }


  // Builder Functions

  _buildStoryPage(Map data, bool active) {
     // Animated Properties
    final double blur = active ? 30 : 0;
    final double offset = active ? 20 : 0;
    final double top = active ? 100 : 200;


    return Center(
        child: AnimatedContainer(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeOutQuint,
            margin: EdgeInsets.only(top: top, bottom: 50, right: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),

              image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(data['img']),
              ),

              boxShadow: [BoxShadow(color: Colors.black87, blurRadius: blur, offset: Offset(offset, offset))]
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(left: 20, bottom: 10),
                      alignment: Alignment.bottomLeft,
                      child: RaisedButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)) 
                        ),
                        color: Colors.purple,
                        child: Text('# love', style: TextStyle(color: Colors.white),),
                        onPressed: () {
                          var id = data['id'];
                            Firestore.instance.collection('pictures').document(id).updateData({'tags': FieldValue.arrayUnion(['love'])});
                        }
                      ),
                    ),
                    Container(
                        margin: EdgeInsets.only(bottom: 10),
                        alignment: Alignment.bottomCenter,
                        child: FloatingActionButton(
                          child: Icon(liked ? Icons.favorite : Icons.favorite_border),
                          backgroundColor: Colors.purple,
                          onPressed: () {
                            var id = data['id'];
                            Firestore.instance.collection('pictures').document(id).updateData({'tags': FieldValue.arrayUnion(['favorites'])});
                          },
                        ),
                    ),
                    Container(
                      margin: EdgeInsets.only( bottom: 10, right:20),
                      alignment: Alignment.bottomLeft,
                      child: RaisedButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)) 
                        ),
                        color: Colors.purple,
                        child: Text('# vibes', style: TextStyle(color: Colors.white),),
                        onPressed: () {
                          var id = data['id'];
                            Firestore.instance.collection('pictures').document(id).updateData({'tags': FieldValue.arrayUnion(['vibes'])});
                        }
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                  child: new SizedBox(
                    width: 260,
                    child: RaisedButton(
                      elevation: 5.0,
                      shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(10.0)),
                      color: Colors.redAccent,
                      child: new Text('Delete',
                          style: new TextStyle( color: Colors.white)),
                      onPressed: () {
                        var id = data['id'];
                        Firestore.instance.collection('pictures').document(id).delete();

                         FirebaseStorage.instance
                            .getReferenceFromUrl(data["img"])
                            .then((res) {
                          res.delete().then((res) {
                            print("Deleted!");
                          });
                        });
                      },
                    ),
                  ),
                ),
              ]
            )
        )
      );
  }


  _buildTagPage() {
    return Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Pictures', style: TextStyle(fontSize: 32, color: Colors.black, fontWeight: FontWeight.bold),),
              Text('FILTER', style: TextStyle(fontSize: 16 , color: Colors.black26)),
              _buildButton('all'),
              _buildButton('favorites'),
              _buildButton('love'),
              _buildButton('vibes'),

              new Container(
                height: 60,
                width: 60,
                margin: EdgeInsets.only(top: 100),
                child: FloatingActionButton(
                  child: Icon(Icons.add, size: 50),
                  backgroundColor: Colors.purple,
                  onPressed: () {
                    upload();
                  },
                ),
              ),
              new Container(
                margin: EdgeInsets.only(top: 30),
                child: FlatButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)) 
                  ),
                  color: Colors.purple,
                  child: new Text('Logout',
                      style: new TextStyle(fontSize: 17.0, color: Colors.white)),
                  onPressed: signOut
                ),
              ),
              new Container(
                margin: EdgeInsets.only(top: 20),
                color: Colors.black,
                child: AdmobBanner(
                  adUnitId: AdMobService().getBannerId(),
                  adSize: AdmobBannerSize.BANNER,
                ),
              ),
            ],
          )
        
    );
  }

  signOut() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  FirebaseStorage _storage = FirebaseStorage.instance;
  final databaseReference = Firestore.instance;

  upload() async {
   //pick image   use ImageSource.camera for accessing camera. 
  File image = await ImagePicker.pickImage(source: ImageSource.gallery);

   //basename() function will give you the filename
  String fileName = basename(image.path);

   //passing your path with the filename to Firebase Storage Reference
  StorageReference reference = _storage.ref().child("images/$fileName");

   //upload the file to Firebase Storage
  StorageUploadTask uploadTask = reference.putFile(image);


   //Snapshot of the uploading task
  StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
// no need of the file extension, the name will do fine.
  String url = await reference.getDownloadURL();


  DocumentReference ref = await databaseReference.collection("pictures").document();

    ref.setData({
      'img': url,
      'tags': ["all"],
      'id': ref.documentID,
      'userId': widget.userId
    });
  }

  _buildButton(tag) {
    Color color = tag == activeTag ? Colors.purple : Colors.transparent;
    return FlatButton(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)) 
      ),
      color: color, 
      child: Text('# $tag', textAlign: TextAlign.left ,style: TextStyle(color: tag == activeTag ? Colors.white : Colors.black),), 
      onPressed: () => _queryDb(tag: tag));
  }
  
}