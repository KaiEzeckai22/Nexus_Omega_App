import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexus_omega_app/model/log.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nexus_omega_app/modules/dialogues.dart';
import 'package:nexus_omega_app/modules/logs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';

import 'dev.dart';
import 'login.dart';

class MainMenu extends StatefulWidget {
  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  late SharedPreferences tokenStore;
  List<Log> contactsList = [];
  List<String> main_menu_options = ['Logs', 'Dialogues'];
  String debug = "";
  int numdeBug = 0;
  TextEditingController searchCtrlr = TextEditingController();
  bool promptLocked = false;
  String searchString = "";
  //

  List<PopupItem> menu = [
    PopupItem(1, "Log-in"),
    PopupItem(2, "Log-out"),
    //PopupItem(3, "DevTest-sp"),
    //PopupItem(4, "DevTest-sb"),
    //PopupItem(5, "DevTest-newGet"),
    //PopupItem(0, "nukeTest"), // <<< UNCOMMENT THIS TO ACTIVATE NUKE TEST AREA/BUTTON
  ];
  String _selectedChoices = "none";
  void _select(String choice) {
    setState(() {
      _selectedChoices = choice;
    });
    switch (_selectedChoices) {
      case 'Log-in':
        loginTrigger();
        break;
      case 'Log-out':
        //print("Log-out OTW");
        break;
      /*
      case 'DevTest-sp':
        prefSetup()
            .then((value) => {print("TOKEN FROM PREFERENCES: " + value!)});
        print(tokenStore.getString('token'));
        break;
      case 'DevTest-newGet':
        //newGet();
        break;*/
      case 'nukeTest':
        // NUKE AREA
        disguisedPrompt(
            context: context,
            title: 'Confirm Delete',
            titleStyle: cxTextStyle(style: 'bold'),
            message: '   Would you like\n   to proceed?',
            messageStyle: cxTextStyle(style: 'italic', size: 16),
            button1Name: 'Yes',
            button1Colour: colour('dgreen'),
            button1Callback: () => setState(() {
                  numdeBug++;
                  print(numdeBug);
                }),
            button2Name: 'No',
            button2Colour: colour('red'),
            button2Callback: () => setState(() {
                  numdeBug--;
                  print(numdeBug);
                }));
        break;
      default:
        print(_selectedChoices);
        _selectedChoices = "none";
        print(_selectedChoices);
    }
  }

  none() {}

  late Flushbar flush;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colour('black'),
      appBar: AppBar(
        backgroundColor: colour('dblue'),
        title: cText(text: "Main Menu "),
        actions: [
          SelectionMenu(
            selectables: menu,
            onSelection: (String value) => setState(() {
              _select(value);
              FocusManager.instance.primaryFocus?.unfocus();
            }),
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // SEARCH BAR SHOULD BE HERE
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              cText(text: " LOG-IN "),
              cxIconButton(
                  onPressed: () {
                    loginTrigger();
                  },
                  icon: Icon(Icons.login),
                  borderColour: colour('grey'),
                  buttonColour: colour('blue')),
              vfill(12),
            ],
          ),

          //TextFormField(decoration: new InputDecoration(labelText: "test")),
          Expanded(
            child: Container(
                padding: EdgeInsets.only(bottom: 60),
                height: double.infinity,
                width: double.infinity,
                color: Colors.black,
                child: FutureBuilder<List<Log>>(builder: (context, snapshot) {
                  return new SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: 100),
                      physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      child: ListView.builder(
                          key: UniqueKey(),
                          padding: EdgeInsetsDirectional.all(10), // MARK
                          itemCount: main_menu_options.length,
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemBuilder: (BuildContext context, int index) {
                            return GestureDetector(
                              onTap: () async {
                                // >>>>>>>>>>>>>>>>>>>>>>>>>>>> PUSH TO NEXT UPDATE SCREEN <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                nextMenu(index);
                              },
                              child: Card(
                                color: Colors.black,
                                shape: BeveledRectangleBorder(
                                    side: BorderSide(
                                        color: colour('blue'), width: 1.5),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  children: <Widget>[
                                    ListTile(
                                      title: Text(main_menu_options[index],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          )),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }));
                })),
          ),
        ],
      ),
      /*
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          
          FAB(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            icon: Icon(Icons.refresh),
            text: "Refresh",
            background: colour('dblue'),
          ),
          vfill(12),
          FAB(
            onPressed: () async {
              // >>>>>>>>>>>>>>>>>>>>>>>>>>>> PUSH TO ADD SCREEN <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
              /*print((tokenStore.getString('token').toString().isNotEmpty &&
                  tokenStore.getString('token').toString() != 'rejected'));*/
              //FocusManager.instance.primaryFocus?.unfocus();
              if (tokenStore.getString('token').toString().isNotEmpty &&
                  tokenStore.getString('token').toString() != 'rejected') {
                /*
                final statusCode = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CreateNewContact()));
                await Future.delayed(Duration(seconds: 2), () {});
                statusCodeEval(statusCode);*/
              } else {}
            },
            icon: Icon(Icons.phone),
            text: "Add New",
            background: colour('dblue'),
          ),
        ],
      ),*/
    );
  }

  loginTrigger() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (context) => LoginScreen()));
    await Future.delayed(Duration(seconds: 1), () {});
  }

  nextMenu(int index) {
    disguisedToast(
        context: context,
        title: "Redirecting to",
        titleStyle: cxTextStyle(style: 'bold'),
        message: '  ' + main_menu_options[index],
        messageStyle: cxTextStyle());
    switch (index) {
      case 0:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => new LogList()));
        //disguisedToast(context: context, message: main_menu_options[index]);
        break;
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => new DialogueList()));
        //disguisedToast(context: context, message: main_menu_options[index]);
        break;
        break;
      default:
        break;
    }
  }
}
