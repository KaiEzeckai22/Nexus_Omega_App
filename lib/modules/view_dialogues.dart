import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexus_omega_app/model/dialogue.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';
import 'dev.dart';
import 'update_dialogue.dart';
import 'update_log.dart';

class ViewDialogue extends StatefulWidget {
  final String dialogueTitle, dialogueTags, dialogueID, dialogueAuthor;
  final List<dynamic> dialogueContents;
  const ViewDialogue(
      {Key? key,
      required this.dialogueTitle,
      required this.dialogueTags,
      required this.dialogueContents,
      required this.dialogueID,
      required this.dialogueAuthor})
      : super(key: key);
  @override
  _ViewDialogueState createState() => _ViewDialogueState();
}

class _ViewDialogueState extends State<ViewDialogue> {
  late SharedPreferences tokenStore;
  String debug = "";
  int numdeBug = 0;
  TextEditingController searchCtrlr = TextEditingController();
  bool promptLocked = false;
  String searchString = "";
  late String displayTitle, displayTag;
  late List<String> displayContent;
  late Dialogue dialogueBuffer;

  @override
  void initState() {
    super.initState();
    dialogueBuffer = new Dialogue(widget.dialogueTitle, widget.dialogueTags,
        widget.dialogueContents, widget.dialogueAuthor);
    //displayTitle = widget.dialogueTitle;
    //displayContent = widget.dialogueContents;
    //delayeddialoguein();
  }
  //

  List<PopupItem> menu = [
    PopupItem(1, 'Update'),
    PopupItem(2, 'Delete'),
    PopupItem(3, 'Modify Title Size'),
    PopupItem(4, 'Modify Content Size'),
    PopupItem(4, 'Modify Author ID Size'),
    // PopupItem(
    //     0, 'nukeTest'), // <<< UNCOMMENT THIS TO ACTIVATE NUKE TEST AREA/BUTTON
  ];
  String _selectedChoices = "none";
  Future<void> _select(String choice) async {
    setState(() {
      _selectedChoices = choice;
    });
    print(authorIDSize.toString() +
        ' / ' +
        titleSize.toString() +
        ' / ' +
        contentSize.toString());
    switch (_selectedChoices) {
      case 'Update':
        defocus();
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => new UpdateDialogue(
                      dialogueTitle: dialogueBuffer.title,
                      dialogueTags: dialogueBuffer.tags,
                      dialogueContents: dialogueBuffer.content,
                      dialogueID: widget.dialogueID.toString(),
                      dialogueAuthor: dialogueBuffer.author,
                    )));
        reExtract(widget.dialogueID);
        break;
      case 'Modify Title Size':
        disguisedPrompt(
            context: context,
            secDur: 0,
            closeAfter: false,
            dismissible: true,
            title: 'Modify Title Size',
            titleStyle: cxTextStyle(style: 'bold'),
            message: '(Slide to CLOSE menu)',
            messageStyle: cxTextStyle(style: 'italic', size: 16),
            button1Name: '+',
            button1Colour: colour('dgreen'),
            button1Callback: () => setState(() {
                  titleSize++;
                }),
            button2Name: '-',
            button2Colour: colour('red'),
            button2Callback: () => setState(() {
                  if (titleSize > 12) {
                    titleSize--;
                  }
                }));
        break;
      case 'Modify Content Size':
        disguisedPrompt(
            context: context,
            secDur: 0,
            closeAfter: false,
            dismissible: true,
            title: 'Modify Content Size',
            titleStyle: cxTextStyle(style: 'bold'),
            message: '(Slide to CLOSE menu)',
            messageStyle: cxTextStyle(style: 'italic', size: 16),
            button1Name: '+',
            button1Colour: colour('dgreen'),
            button1Callback: () => setState(() {
                  contentSize++;
                }),
            button2Name: '-',
            button2Colour: colour('red'),
            button2Callback: () => setState(() {
                  if (titleSize > 12) {
                    contentSize--;
                  }
                }));
        break;
      case 'Modify Author ID Size':
        disguisedPrompt(
            context: context,
            secDur: 0,
            closeAfter: false,
            dismissible: true,
            title: 'Modify Author ID Size',
            titleStyle: cxTextStyle(style: 'bold'),
            message: '(Slide to CLOSE menu)',
            messageStyle: cxTextStyle(style: 'italic', size: 16),
            button1Name: '+',
            button1Colour: colour('dgreen'),
            button1Callback: () => setState(() {
                  authorIDSize++;
                }),
            button2Name: '-',
            button2Colour: colour('red'),
            button2Callback: () => setState(() {
                  if (titleSize > 12) {
                    authorIDSize--;
                  }
                }));
        break;
      case 'Delete':
        deleteDialoguePrompt(widget.dialogueID, widget.dialogueTitle);
        break;
      case 'nukeTest':
        reExtract(widget.dialogueID);
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
        //           print(numdeBug);
        //         }),
        //     button2Name: 'No',
        //     button2Colour: colour('red'),
        //     button2Callback: () => setState(() {
        //           numdeBug--;
        //           print(numdeBug);
        //         }));
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

  Future<int> reExtract(String id) async {
    disguisedToast(
        secDur: 2,
        context: context,
        message: 'Updating Dialogue',
        messageStyle: cxTextStyle(style: 'bold', colour: colour('blue')));
    await Future.delayed(Duration(seconds: 2), () {});
    String retrievedToken = '';
    await prefSetup().then((value) => {retrievedToken = value!});
    final response = await http.get(
      Uri.parse('https://nexus-omega.herokuapp.com/dialogue/get/' + id),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: "Bearer " + retrievedToken
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        dialogueBuffer = new Dialogue.fromJson(json.decode(response.body));
      });
      disguisedToast(
          secDur: 2,
          context: context,
          message: 'Update Successful',
          messageStyle: cxTextStyle(style: 'bold', colour: colour('dgreen')));
    } else {
      disguisedToast(
          secDur: 5,
          context: context,
          message:
              'Something Happened: [' + response.statusCode.toString() + ']',
          messageStyle: cxTextStyle(style: 'bold', colour: colour('lred')));
    }

    return (response.statusCode);
  }

  Future<int> deleteDialogue(String id) async {
    disguisedToast(
        context: context,
        message: 'Deleting Dialogue',
        messageStyle: cxTextStyle(colour: colour('lred')));
    await Future.delayed(Duration(seconds: 2), () {});
    String retrievedToken = '';
    await prefSetup().then((value) => {retrievedToken = value!});
    final response = await http.delete(
      Uri.parse('https://nexus-omega.herokuapp.com/dialogue/delete/' + id),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: "Bearer " + retrievedToken
      },
    );
    return (response.statusCode);
  }

  deleteDialoguePrompt(String id, String title) {
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
        final statusCode = await deleteDialogue(id);
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

  late Flushbar flush;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colour('black'),
      appBar: AppBar(
        backgroundColor: colour('dblue'),
        title: cText(text: "Dialogues " /*+ numdeBug.toString()*/),
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
            child: ListTile(
              title: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding:
                      EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 3),
                  child: Text(
                    dialogueBuffer.title,
                    style: cxTextStyle(style: 'bold', size: titleSize),
                  ),
                ),
              ),
              subtitle: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(left: 5, right: 5, bottom: 3),
                  child: Text(
                    'by: ' + dialogueBuffer.author,
                    style: cxTextStyle(style: 'bold', size: authorIDSize),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: _contentsOfIndex()),
        ],
      ),
      persistentFooterButtons: <Widget>[hfill(25)],
    );
  }

  Widget _contentsOfIndex() {
    List<dynamic> temp = dialogueBuffer.content;
    return ListView.builder(
        shrinkWrap: true,
        itemCount: temp.length,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: EdgeInsets.only(left: 24, bottom: 16, right: 24),
            child: Text('     ' + temp[index][1],
                textAlign: TextAlign.left,
                style: cxTextStyle(
                    style: 'bold',
                    colour: colour(temp[index][0]),
                    size: contentSize)),
          );
        });
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