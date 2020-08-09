import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:geocoder/geocoder.dart';
import 'package:http/http.dart' as http;
import 'temps.dart';
import 'dart:convert';
import 'my_flutter_app_icons.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  Location location = new Location();
  LocationData position;
  try {
    position = (await location.getLocation()) ;
    print(position);
  } on PlatformException catch (e) {
    print("Erreur: $e");
  }
  if (position != null) {
    final latitude = position.latitude;
    final longitude = position.longitude;
    final Coordinates coordinates = new Coordinates(latitude, longitude);
    final ville = await Geocoder.local.findAddressesFromCoordinates(coordinates);
    if (ville != null) {
      print(ville.first.locality);
      runApp(new MyApp(ville.first.locality));
    }

  }
}

class MyApp extends StatelessWidget {
  MyApp(String ville) {
    this.ville = ville;
  }

  String ville;

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(ville, title: 'Coda Météo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage(String ville, {Key key, this.title}) : super(key: key) {
    this.villeDeLutilisateur = ville;
  }

  String villeDeLutilisateur;
  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String key = "villes";
  List<String> villes = [];
  String villeChoisie;
  Temps tempsActuel;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    obtenir();
    appelApi();
  }



  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        centerTitle: true,
        title: new Text(widget.title),
      ),
      drawer: new Drawer(
        child: new Container(
          child: new ListView.builder(
              itemCount: villes.length + 2,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return DrawerHeader(
                    child: new Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        texteAvecStyle("Mes Villes", fontSize: 22.0),
                        new RaisedButton(
                            color: Colors.white,
                            elevation: 8.0,
                            child: texteAvecStyle("Ajouter une ville", color: Colors.blue),
                            onPressed: ajoutVille
                        )

                      ],
                    ),
                  );
                } else if (i == 1) {
                  return new ListTile(
                    title: texteAvecStyle(widget.villeDeLutilisateur),
                    onTap: () {
                      setState(() {
                        villeChoisie = null;
                        appelApi();
                        Navigator.pop(context);

                      });
                    },
                  );
                } else {
                  String ville = villes[i - 2];
                  return new ListTile(
                    title: texteAvecStyle(ville),
                    trailing: new IconButton(
                        icon: new Icon(Icons.delete, color: Colors.white,),
                        onPressed: (() => supprimer(ville))),
                    onTap: () {
                      setState(() {
                        villeChoisie = ville;
                        appelApi();
                        Navigator.pop(context);
                      });
                    },
                  );
                }


              }),
          color: Colors.blue,
        ),
      ),
      body: (tempsActuel == null)
          ? new Center(
        child: new Text((villeChoisie == null)? widget.villeDeLutilisateur: villeChoisie),
      )
          : new Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: new BoxDecoration(
          image: new DecorationImage(
              image: new AssetImage(assetName()),
              fit: BoxFit.cover
          ),
        ),
        padding: EdgeInsets.all(20.0),
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            texteAvecStyle(tempsActuel.name, fontSize: 30.0),
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                texteAvecStyle("${tempsActuel.temp.toInt()}°C", fontSize: 60.0),
                new Image.asset(tempsActuel.icon)
              ],
            ),
            texteAvecStyle(tempsActuel.main, fontSize: 30.0),
            texteAvecStyle(tempsActuel.description, fontSize: 25.0),
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                new Column(
                  children: <Widget>[
                    new Icon(MyFlutterApp.temperatire, color: Colors.white, size: 30.0,),
                    texteAvecStyle("${tempsActuel.pressure}", fontSize: 20.0)
                  ],
                ),
                new Column(
                  children: <Widget>[
                    new Icon(MyFlutterApp.droplet, color: Colors.white, size: 30.0,),
                    texteAvecStyle("${tempsActuel.humidity}", fontSize: 20.0)
                  ],
                ),
                new Column(
                  children: <Widget>[
                    new Icon(MyFlutterApp.arrow_upward, color: Colors.white, size: 30.0,),
                    texteAvecStyle("${tempsActuel.temp_max}", fontSize: 20.0)
                  ],
                ),
                new Column(
                  children: <Widget>[
                    new Icon(MyFlutterApp.arrow_downward, color: Colors.white, size: 30.0,),
                    texteAvecStyle("${tempsActuel.temp_min}", fontSize: 20.0)
                  ],
                ),
              ],
            )
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  String assetName() {
    if (tempsActuel.icon.contains("d")) {
      return "assets/n.jpg";
    } else if (tempsActuel.icon.contains("01") || tempsActuel.icon.contains("02") || tempsActuel.icon.contains("03")) {
      return "assets/d1.jpg";
    } else {
      return "assets/d2.jpg";
    }
  }

  Text texteAvecStyle(String data, {color: Colors.white, fontSize: 18.0, fontStyle: FontStyle.italic, textAlign: TextAlign.center}) {
    return new Text(
      data,
      textAlign: textAlign,
      style: new TextStyle(
          color: color,
          fontStyle: fontStyle,
          fontSize: fontSize
      ),
    );
  }

  Future<Null> ajoutVille() async {
    return showDialog(
        barrierDismissible: true,
        builder: (BuildContext buildcontext) {
          return new SimpleDialog(
            contentPadding: EdgeInsets.all(20.0),
            title: texteAvecStyle("Ajoutez une ville", fontSize: 22.0, color: Colors.blue),
            children: <Widget>[
              new TextField(
                decoration: new InputDecoration(labelText: "ville: "),
                onSubmitted: (String str) {
                  ajouter(str);
                  Navigator.pop(buildcontext);
                },
              )
            ],

          );
        },
        context: context);
  }

  void obtenir() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    List<String> liste = await sharedPreferences.getStringList(key);
    if (liste != null) {
      setState(() {
        villes = liste;
      });
    }
  }

  void ajouter(String str) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    villes.add(str);
    await sharedPreferences.setStringList(key, villes);
    obtenir();
  }

  void supprimer(String str) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    villes.remove(str);
    await sharedPreferences.setStringList(key, villes);
    obtenir();
  }

  void appelApi() async {
    String str;
    if (villeChoisie == null) {
      str = widget.villeDeLutilisateur;
    } else {
      str = villeChoisie;
    }
    List<Address> coord = await Geocoder.local.findAddressesFromQuery(str);
    if (coord != null) {
      final lat = coord.first.coordinates.latitude;
      final lon = coord.first.coordinates.longitude;
      String lang = Localizations.localeOf(context).languageCode;
      final key = "5787a65c5e8819073a439d230e0e9e31";

      String urlApi = "http://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&lang=$lang&APPID=$key";

      final reponse = await http.get(urlApi);
      if (reponse.statusCode == 200) {
        Temps temps = new Temps();
        Map map = json.decode(reponse.body);
        temps.fromJSON(map);
        setState(() {
          tempsActuel = temps;
        });
      }
    }
  }

}







