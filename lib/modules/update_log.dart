import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:nexus_omega_app/model/log.dart';
import 'dev.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';

class UpdateLog extends StatefulWidget {
  final String logTitle, logTags, logID, logAuthor;
  final List<String> logContents;
  const UpdateLog({
    Key? key,
    required this.logTitle,
    required this.logTags,
    required this.logContents,
    required this.logID,
    required this.logAuthor,
    /*CONTACTS*/
  }) : super(key: key);
  @override
  _UpdateLogState createState() => _UpdateLogState();
}

class _UpdateLogState extends State<UpdateLog> {
  int key = 0, increments = 0, listSize = 1, _count = 1;
  late SharedPreferences tokenStore;

  TextEditingController titleCtrlr = TextEditingController();
  TextEditingController tagsCtrlr = TextEditingController();
  TextEditingController authorCtrlr = TextEditingController();

  List<TextEditingController> contentsCtrlr = <TextEditingController>[
    TextEditingController()
  ];

  late Log previousLog, updatedLog;
  String logIdentifier = '';
  late Flushbar flush;

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
        Navigator.pop(context, statusCode);
      },
      button2Name: 'No',
      button2Colour: colour('red'),
      button2Callback: () async {
        flush.dismiss(true);
      },
    );
  }

  Future<int> uploadUpdated(
      String title, String tags, List content, String id, String author) async {
    String retrievedToken = '';
    disguisedToast(
        context: context,
        title: 'Updating Log',
        titleStyle: cxTextStyle(
          style: 'bold',
          colour: colour('blue'),
        ),
        message: 'Title: ' + title + '\n Tags: ' + tags,
        messageStyle: cxTextStyle(size: 15),
        secDur: 2);
    //await Future.delayed(Duration(seconds: 3), () {});
    await prefSetup().then((value) => {retrievedToken = value!});
    final response = await http.patch(
      Uri.parse('https://nexus-omega.herokuapp.com/update/' + id),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: "Bearer " + retrievedToken
      },
      body: jsonEncode({
        'title': title,
        'tags': tags,
        'content': content,
        'author': author,
      }),
    );
    //print(response.body);
    //print('here1');
    if (response.statusCode == 200) {
      // >>>>>>>>>>>>>>>>>>>>>>>>>>>> RETURN OR UNDO PROMPT <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
      //print('here2');
      flush = disguisedPrompt(
          dismissible: false,
          secDur: 0,
          context: context,
          title: "Update Successful",
          titleStyle: cxTextStyle(style: 'bold'),
          message: "Undo or commit changes?\n(Press save again to commit undo)",
          messageStyle: cxTextStyle(size: 14),
          button1Name: 'Commit',
          button1Colour: colour('dgreen'),
          button1Callback: () async {
            flush.dismiss(true);
            Navigator.pop(context, response.statusCode);
          },
          button2Name: 'Undo',
          button2Colour: colour('red'),
          button2Callback: () async {
            flush.dismiss(true);
            resetCtrlrFields();
            //saveContact();
            //s await Future.delayed(Duration(seconds: 2), () {});
          });
    } else {
      disguisedToast(
          context: context,
          message: 'ERROR ' + response.statusCode.toString(),
          messageStyle: cxTextStyle(style: 'bold', colour: colour('red')));
    }
    return (response.statusCode);
  }

  Future<String?> prefSetup() async {
    tokenStore = await SharedPreferences.getInstance();
    return tokenStore.getString('token');
  }

  void saveContact() async {
    int statusCode = 0;
    bool emptyDetect = false;
    List<String> listedContent = <String>[];
    for (int i = 0; i < _count; i++) {
      listedContent.add(contentsCtrlr[i].text);
      if (contentsCtrlr[i].text.isEmpty) {
        emptyDetect = true;
      }
    }
    setState(() {
      updatedLog = new Log(titleCtrlr.text, tagsCtrlr.text,
          listedContent.reversed.toList(), authorCtrlr.text);
    });
    if (updatedLog.title.isEmpty || updatedLog.tags.isEmpty) {
      emptyDetect = true;
    }

    if (!emptyDetect) {
      statusCode = await uploadUpdated(
        updatedLog.title,
        updatedLog.tags,
        listedContent.reversed.toList(),
        logIdentifier,
        updatedLog.author,
      );
    } else {
      disguisedToast(
        context: context,
        title: 'Warning!',
        titleStyle: cxTextStyle(style: 'bold', colour: colour('lred')),
        message: 'Please fill all empty fields',
        messageStyle: cxTextStyle(colour: colour('')),
      );
      emptyDetect = false;
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _count = 0;
      previousLog = new Log(widget.logTitle, widget.logTags, widget.logContents,
          widget.logAuthor);
      logIdentifier = widget.logID;
      resetCtrlrFields();
    });
  }

  resetCtrlrFields() {
    setState(() {
      key = 0;
      increments = 0;
      listSize = 0;
      _count = 0;
      titleCtrlr.clear();
      tagsCtrlr.clear();
      contentsCtrlr.clear();
      contentsCtrlr = <TextEditingController>[TextEditingController()];
      titleCtrlr = TextEditingController(text: previousLog.title);
      tagsCtrlr = TextEditingController(text: previousLog.tags);
      authorCtrlr = TextEditingController(text: previousLog.author);
      List<String> contactsToDisplay = <String>[];
      contactsToDisplay.clear();
      final int edge = previousLog.content.length;
      for (int i = 0; i < edge; i++) {
        contactsToDisplay.add(previousLog.content[i]);
        if (i < edge) {
          contentsCtrlr.insert(
              0, TextEditingController(text: previousLog.content[i]));
        }
        _count++;
        listSize = previousLog.content.length;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: colour('black'),
        appBar: AppBar(
          centerTitle: true,
          title: cText(text: "Update Log", colour: colour('')),
          actions: [
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() {
                  key = 0;
                  increments = 0;
                  listSize = 1;
                  _count = 0;
                  titleCtrlr.clear();
                  tagsCtrlr.clear();
                  contentsCtrlr.clear();
                  contentsCtrlr = <TextEditingController>[
                    TextEditingController()
                  ];
                  titleCtrlr = TextEditingController(text: previousLog.title);
                  tagsCtrlr = TextEditingController(text: previousLog.tags);
                  authorCtrlr = TextEditingController(text: previousLog.author);
                  List<String> contactsToDisplay = <String>[];
                  contactsToDisplay.clear();
                  final int edge = previousLog.content.length;
                  for (int i = 0; i < edge; i++) {
                    contactsToDisplay.add(previousLog.content[i]);
                    if (i < edge) {
                      contentsCtrlr.insert(0,
                          TextEditingController(text: previousLog.content[i]));
                    }
                    _count++;
                    listSize = widget.logContents.length;
                  }
                });
              },
            )
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                ctrlrField(
                    context: context,
                    fieldPrompt: "First Name",
                    ctrlrID: titleCtrlr,
                    defaultColor: colour(''),
                    selectedColor: colour('sel'),
                    next: true,
                    autoFocus: false),
                hfill(10),
                ctrlrField(
                    context: context,
                    fieldPrompt: "Author",
                    ctrlrID: authorCtrlr,
                    defaultColor: colour(''),
                    selectedColor: colour('sel'),
                    errorColor: Colors.red,
                    next: true,
                    autoFocus: true),
                hfill(10),
                ctrlrField(
                    context: context,
                    fieldPrompt: "Last Name",
                    ctrlrID: tagsCtrlr,
                    defaultColor: colour(''),
                    selectedColor: colour('sel'),
                    next: true,
                    autoFocus: false),
                hfill(10),
                Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(bottom: 8, left: 8),
                  child: Text("#s: $_count",
                      style: cxTextStyle(
                          style: 'italic', colour: Colors.grey, size: 12)),
                ),
                hfill(5),
                Flexible(
                  child: ListView.builder(
                      reverse: true,
                      shrinkWrap: true,
                      itemCount: _count,
                      itemBuilder: (context, index) {
                        return _contentInput(index, context);
                      }),
                ),
                hfill(45),
              ],
            ),
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FAB(
                onPressed: () async {
                  // >>>>>>>>>>>>>>>>>>>>>>>>>>>> DELETE BUTTON HERE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                  deleteLogPrompt(logIdentifier, titleCtrlr.text);
                },
                icon: Icon(Icons.delete_forever),
                text: "Delete",
                background: colour('dred')),
            vfill(48),
            FAB(
              onPressed: () {
                // >>>>>>>>>>>>>>>>>>>>>>>>>>>> ADD BUTTON HERE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                setState(() {
                  _count++;
                  increments++;
                  listSize++;
                  contentsCtrlr.insert(0, TextEditingController());
                });
              },
              icon: Icon(Icons.add),
              text: "Add",
              background: colour('dblue'),
            ),
            vfill(12),
            FAB(
              onPressed: () {
                // >>>>>>>>>>>>>>>>>>>>>>>>>>>> SAVE BUTTON HERE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                saveContact();
              },
              icon: Icon(Icons.save),
              text: "Save",
              background: colour('dblue'),
            ),
          ],
        ),
        persistentFooterButtons: <Widget>[]);
  }

  _contentInput(int index, context) {
    return Column(children: <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: SizedBox(
              width: 24,
              height: 24,
              child: _removeButton(index),
            ),
          ),
          Expanded(
            child: ctrlrField(
              context: context,
              fieldPrompt: "Par #" + (_count - index).toString(),
              ctrlrID: contentsCtrlr[index],
              defaultColor: colour(''),
              selectedColor: colour('sel'),
              next: true,
              autoFocus: false,
              inputType: TextInputType.multiline,
              maxLines: null,
              onSubmit: () => {
                setState(() {
                  _count++;
                  increments++;
                  listSize++;
                  contentsCtrlr.insert(0, TextEditingController());
                  //nodes.insert(_count, FocusNode());
                  //FocusScope.of(context).autofocus(nodes[_count]);
                }),
              },
            ),
          ),
        ],
      ),
      hfill(12),
    ]);
  }

  Widget _removeButton(int index) {
    return InkWell(
      onTap: () {
        //FocusManager.instance.primaryFocus?.unfocus();
        if (_count != 1) {
          setState(() {
            _count--;
            increments--;
            listSize--;
            contentsCtrlr.removeAt(index);
          });
        }
      },
      child: (_count != 1)
          ? Container(
              alignment: Alignment.center,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.cancel,
                color: Colors.white70,
              ),
            )
          : null,
    );
  }
}
