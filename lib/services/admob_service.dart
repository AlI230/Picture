import 'dart:io';

class AdMobService {
  
  String getAdmobId() {
    if(Platform.isIOS) {
      return 'ca-app-pub-6230550676129113~5980060850';
    } else if(Platform.isAndroid) {
      return 'ca-app-pub-6230550676129113~6597054247';
    } 
    return null;
  }

  String getBannerId() {
    if(Platform.isIOS) {
      return 'ca-app-pub-6230550676129113/9575351624';
    } else if(Platform.isAndroid) {
      return 'ca-app-pub-6230550676129113/3367174103';
    }
    return null;
  }

}