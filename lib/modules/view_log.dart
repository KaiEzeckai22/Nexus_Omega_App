import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexus_omega_app/model/log.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';

import 'dev.dart';
import 'login.dart';
import 'update_log.dart';

class ViewLog extends StatefulWidget {
  final String logTitle, logTags, logID;
  final List<String> logContents;
  const ViewLog(
      {Key? key,
      required this.logTitle,
      required this.logTags,
      required this.logContents,
      required this.logID})
      : super(key: key);
  @override
  _ViewLogState createState() => _ViewLogState();
}

class _ViewLogState extends State<ViewLog> {
  late SharedPreferences tokenStore;
  String debug = "";
  int numdeBug = 0;
  TextEditingController searchCtrlr = TextEditingController();
  bool promptLocked = false;
  String searchString = "";
  //

  List<PopupItem> menu = [
    PopupItem(1, "Update"),
    PopupItem(2, "Delete"),
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
      case 'Update':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => new UpdateLog(
                      logTitle: widget.logTitle,
                      logTags: widget.logTags,
                      logContents:
                          widget.logContents.map((s) => s as String).toList(),
                      logID: widget.logID.toString(),
                    )));
        break;
      case 'Delete':
        break;
      case 'nukeTest':
        // NUKE AREA
        disguisedPrompt(
            context: context,
            title: 'Confirm Delete',
            titleStyle: cxTextStyle(style: 'bold'),
            message: '   Would you like\n   to proceed?',
            messageStyle: cxTextStyle(style: 'italic', size: 16),
            button1Name: 'Yes',
            button1Colour: colour('green'),
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

  Future<String?> prefSetup() async {
    tokenStore = await SharedPreferences.getInstance();
    if (tokenStore.getString('token') != null) {
      print(tokenStore.getString('token'));
      return tokenStore.getString('token');
    } else {
      print(tokenStore.getString('token'));
      tokenStore.setString('token', 'empty');
      return 'empty token';
    }
  }

  Future<int> deleteLog(String id) async {
    disguisedToast(
        context: context,
        message: 'Deleting Contact',
        messageStyle: cxTextStyle(colour: colour('lred')));
    await Future.delayed(Duration(seconds: 2), () {});
    String retrievedToken = '';
    await prefSetup().then((value) => {retrievedToken = value!});
    final response = await http.delete(
      Uri.parse('https://nexus-omega.herokuapp.com/delete/' + id),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: "Bearer " + retrievedToken
      },
    );
    return (response.statusCode);
  }

  deleteLogPrompt(String id, String title) {
    flush = disguisedPrompt(
      dismissible: false,
      secDur: 0,
      context: context,
      title: 'Confirm Delete',
      titleStyle: cxTextStyle(style: 'bold', colour: colour('blue')),
      message: 'Do you really wish to delete\n"' + title + '"?',
      messageStyle: cxTextStyle(style: 'bold', size: 14),
      button1Name: 'Yes',
      button1Colour: colour('green'),
      button1Callback: () async {
        flush.dismiss(true);
        final statusCode = await deleteLog(id);
        await Future.delayed(Duration(seconds: 2), () {});
        if (statusCode == 200) {}
        statusCodeEval(statusCode);
      },
      button2Name: 'No',
      button2Colour: colour('red'),
      button2Callback: () async {
        flush.dismiss(true);
      },
    );
  }

  late Flushbar flush;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colour('black'),
      appBar: AppBar(
        backgroundColor: colour('dblue'),
        title: cText(text: "Logs " /*+ numdeBug.toString()*/),
        actions: [
          SelectionMenu(
            selectables: menu,
            onSelection: (String value) => setState(() {
              _select(value);
            }),
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Card(
            margin: EdgeInsets.all(15),
            color: Colors.black,
            shape: BeveledRectangleBorder(
                side: BorderSide(color: colour('blue'), width: 1.5),
                borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Text(
                widget.logTitle,
                style: cxTextStyle(style: 'bold', size: 40),
              ),
            ),
          ),
          Expanded(child: _contentsOfIndex()),
        ],
      ),
      persistentFooterButtons: <Widget>[hfill(25)],
      /*
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FAB(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              reloadList();
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
              } else {
                rejectAccess();
              }
            },
            icon: Icon(Icons.phone),
            text: "Add New",
            background: colour('dblue'),
          ),
        ],
      ),*/
    );
  }

  Widget _contentsOfIndex() {
    List<String> temp = widget.logContents;
    return ListView.builder(
        shrinkWrap: true,
        itemCount: temp.length,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        itemBuilder: (BuildContext context, int contactsIndex) {
          return Padding(
            padding: EdgeInsets.only(left: 24, bottom: 16, right: 24),
            child: Text('     ' + temp[contactsIndex],
                textAlign: TextAlign.left,
                style: cxTextStyle(
                    style: 'bold', colour: colour('white'), size: 15)),
          );
        });
  }

  @override
  void initState() {
    super.initState();
    //delayedLogin();
  }

  statusCodeEval(int? statusCode) async {
    if (statusCode == 200) {
      disguisedToast(context: context, message: "Successful Update");
    } else if (statusCode == null) {
      // IN CASE NULL STATUS CODE ERRORS OCCUR DO SOMETHING HERE
    } else {
      disguisedToast(
          context: context,
          message:
              "Something else happened\n Error Code: " + statusCode.toString());
      //await Future.delayed(Duration(seconds: 3), () {});
    }
  }
}
