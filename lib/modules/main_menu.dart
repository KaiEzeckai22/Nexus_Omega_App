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
  List<String> mainOptions = [
    'Logs',
    'Dialogues',
    // 'Nuke',
    // 'PJP',
    // 'Projects',
    // 'Casual Tragedy',
    // 'More',
  ];
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
        tokenStore.setString('token', '');
        disguisedToast(
            context: context,
            message: 'Logged out',
            messageStyle: cxTextStyle(style: 'bold', colour: colour('red')));
        break;
      case 'nukeTest':
        // NUKE AREA
        // disguisedPrompt(
        //     context: context,
        //     title: 'Confirm Delete',
        //     titleStyle: cxTextStyle(style: 'bold'),
        //     message: '   Would you like\n   to proceed?',
        //     messageStyle: cxTextStyle(style: 'italic', size: 16),
        //     button1Name: 'Yes',
        //     button1Colour: colour('dgreen'),
        //     button1Callback: () => setState(() {
        //           numdeBug++;
        //         }),
        //     button2Name: 'No',
        //     button2Colour: colour('red'),
        //     button2Callback: () => setState(() {
        //           numdeBug--;
        //         }));
        break;
      default:
    }
  }

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
                  iconColour: colour('blue')),
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
                          itemCount: mainOptions.length,
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
                                      title: Text(mainOptions[index],
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
        message: '  ' + mainOptions[index],
        messageStyle: cxTextStyle());
    switch (index) {
      case 0:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => new LogList()));
        //disguisedToast(context: context, message: mainOptions[index]);
        break;
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => new DialogueList()));
        //disguisedToast(context: context, message: mainOptions[index]);
        break;
      case 2:

        //disguisedToast(context: context, message: mainOptions[index]);
        break;
      default:
        break;
    }
  }
}
