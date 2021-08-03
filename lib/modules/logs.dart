import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nexus_omega_app/model/log.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';

import 'add_new_log.dart';
import 'dev.dart';
import 'login.dart';
import 'view_log.dart';

class LogList extends StatefulWidget {
  @override
  _LogListState createState() => _LogListState();
}

class _LogListState extends State<LogList> {
  late SharedPreferences tokenStore;
  List<Log> logsList = [];
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
    defocus();
    switch (_selectedChoices) {
      case 'Log-in':
        loginTrigger();
        break;
      case 'Log-out':
        //print("Log-out OTW");
        tokenStore.setString('token', '');
        reloadList();
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

  Future<int> extractData() async {
    String retrievedToken = '';
    await prefSetup().then((value) => {retrievedToken = value!});
    String extractionURL = "";
    if (searchString.isEmpty) {
      extractionURL = 'https://nexus-omega.herokuapp.com/all';
    } else {
      extractionURL =
          'https://nexus-omega.herokuapp.com/search/' + searchString;
    }
    final response = await http.get(
      Uri.parse(extractionURL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: "Bearer " + retrievedToken
      },
    );
    // print("RESPONSE BODY: " + response.body.toString());
    if (response.body.toString() == 'Forbidden') {
      rejectAccess();
      setState(() {
        logsList.clear();
      });
    } else {
      setState(() {
        Iterable list = json.decode(response.body);
        logsList = list.map((model) => Log.fromJson(model)).toList();
      });
    }
    return (response.statusCode);
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
        message: 'Deleting Log',
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
      button1Colour: colour('dgreen'),
      button1Callback: () async {
        flush.dismiss(true);
        final statusCode = await deleteLog(id);
        await Future.delayed(Duration(seconds: 2), () {});
        if (statusCode == 200) {
          logsList.clear();
        }
        statusCodeEval(statusCode);
      },
      button2Name: 'No',
      button2Colour: colour('red'),
      button2Callback: () async {
        flush.dismiss(true);
        setState(() {
          reloadList();
        });
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
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: ctrlrField(
                      context: context,
                      fieldPrompt: 'Search',
                      ctrlrID: searchCtrlr,
                      onChangeString: (String value) {
                        searchString = value;
                        reloadList();
                      },
                      defaultColor: colour(''),
                      selectedColor: colour('sel'),
                      next: true,
                      autoFocus: false),
                ),
              ),
              cxIconButton(
                  onPressed: () {
                    searchCtrlr.clear();
                    searchString = '';
                    reloadList();
                  },
                  icon: Icon(Icons.search_off),
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
                  return logsList.length != 0
                      ? RefreshIndicator(
                          child: new SingleChildScrollView(
                              padding: EdgeInsets.only(bottom: 100),
                              physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics()),
                              child: ListView.builder(
                                  key: UniqueKey(),
                                  padding:
                                      EdgeInsetsDirectional.all(10), // MARK
                                  itemCount: logsList.length,
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return Dismissible(
                                        direction: DismissDirection.horizontal,
                                        onDismissed: (direction) async {
                                          // >>>>>>>>>>>>>>>>>>>>>>>>>>>> DELETE ON DISMISS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                          deleteLogPrompt(logsList[index].id,
                                              logsList[index].title);
                                        },
                                        key: UniqueKey(),
                                        child: GestureDetector(
                                            onTap: () async {
                                              // >>>>>>>>>>>>>>>>>>>>>>>>>>>> PUSH TO NEXT UPDATE SCREEN <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                              final statusCode =
                                                  await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder:
                                                              (context) =>
                                                                  new ViewLog(
                                                                    logTitle: logsList[
                                                                            index]
                                                                        .title,
                                                                    logTags: logsList[
                                                                            index]
                                                                        .tags,
                                                                    logContents: logsList[
                                                                            index]
                                                                        .content
                                                                        .map((s) =>
                                                                            s as String)
                                                                        .toList(),
                                                                    logID: logsList[
                                                                            index]
                                                                        .id
                                                                        .toString(),
                                                                    logAuthor: logsList[
                                                                            index]
                                                                        .author,
                                                                  )));
                                              statusCodeEval(statusCode);
                                            },
                                            child: Card(
                                              color: Colors.black,
                                              shape: BeveledRectangleBorder(
                                                  side: BorderSide(
                                                      color: colour('blue'),
                                                      width: 1.5),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              child: Column(
                                                children: <Widget>[
                                                  ListTile(
                                                    title: Text(
                                                        logsList[index].title,
                                                        style: cxTextStyle(
                                                            style: 'normal',
                                                            size: 24,
                                                            colour: colour(
                                                                'white'))),
                                                    contentPadding:
                                                        EdgeInsets.only(
                                                      top: 6,
                                                      left: 12,
                                                      right: 12,
                                                    ),
                                                    subtitle: Padding(
                                                      padding: EdgeInsets.only(
                                                        top: 3,
                                                        left: 12,
                                                        right: 12,
                                                        bottom: 6,
                                                      ),
                                                      child: Text(
                                                        'by: ' +
                                                            logsList[index]
                                                                .author +
                                                            '\n  ' +
                                                            logsList[index]
                                                                .tags,
                                                        style: cxTextStyle(
                                                          style: 'normal',
                                                          size: 16,
                                                          colour:
                                                              colour('blue'),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  //_contentsOfIndex(index),
                                                ],
                                              ),
                                            )));
                                  })),
                          onRefresh: reloadList,
                        )
                      : Center(
                          child: CircularProgressIndicator(
                          color: colour('blue'),
                          backgroundColor: colour('dblue'),
                          strokeWidth: 5,
                        ));
                })),
          ),
        ],
      ),
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
                final statusCode = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => new CreateNewLog()));
                await Future.delayed(Duration(seconds: 2), () {});
                statusCodeEval(statusCode);
              } else {
                rejectAccess();
              }
            },
            icon: Icon(Icons.add),
            text: "Add New",
            background: colour('dblue'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    searchCtrlr.clear();
    extractData();
    prefSetup();
    //delayedLogin();
  }

  Future<void> reloadList() async {
    setState(() {
      searchString = searchCtrlr.text;
      logsList.clear();
    });
    //disguisedToast(context: context, message: "Reloading...");
    extractData();
  }

  rejectAccess() {
    if (promptLocked == false) {
      promptLocked = true;
      flush = disguisedToast(
        secDur: 0,
        context: context,
        title: "Warning",
        titleStyle: cxTextStyle(style: 'bold', colour: colour('lred')),
        message: "Forbidden Access..\n Please Log-In",
        buttonName: 'Log-in',
        buttonColour: colour('red'),
        callback: () async {
          FocusManager.instance.primaryFocus?.unfocus();
          flush.dismiss(true);
          promptLocked = false;
          loginTrigger();
        },
        dismissible: false,
      );
    }
  }

  statusCodeEval(int? statusCode) async {
    if (statusCode == 200) {
      setState(() {
        reloadList();
      });
      disguisedToast(context: context, message: "Successful Update");
    } else if (statusCode == null) {
      // IN CASE NULL STATUS CODE ERRORS OCCUR DO SOMETHING HERE
      setState(() {
        reloadList();
      });
    } else {
      setState(() {
        reloadList();
      });
      disguisedToast(
          context: context,
          message:
              "Something else happened\n Error Code: " + statusCode.toString());
      //await Future.delayed(Duration(seconds: 3), () {});
    }
  }

  loginTrigger() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (context) => new LoginScreen()));
    await Future.delayed(Duration(seconds: 1), () {});
    setState(() {
      reloadList();
    });
  }
}
