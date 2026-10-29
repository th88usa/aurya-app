String? reflectionIdFromUri(Uri uri){
 if(uri.scheme!='aurya'||uri.host!='reflection'||uri.query.isNotEmpty||uri.fragment.isNotEmpty||uri.pathSegments.length!=1)return null;
 final id=uri.pathSegments.single;
 return RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(id)?id:null;
}
