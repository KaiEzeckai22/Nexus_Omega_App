import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexus_omega_app/model/log.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';
import 'dev.dart';
import 'update_log.dart';

class ViewLog extends StatefulWidget {
  final String logTitle, logTags, logID, logAuthor;
  final List<String> logContents;
  const ViewLog(
      {Key? key,
      required this.logTitle,
      required this.logTags,
      required this.logContents,
      required this.logID,
      required this.logAuthor})
      : super(key: key);
  @override
  _ViewLogState createState() => _ViewLogState();
}

class _ViewLogState extends State<ViewLog> {
  late SharedPreferences tokenStore;
  String debug = "";
  int numdeBug = 0,
      titleFontIndex = 0,
      authorFontIndex = 0,
      contentFontIndex = 0;
  TextEditingController searchCtrlr = TextEditingController();
  bool promptLocked = false;
  String searchString = "";
  String titleFont = importedFonts[0];
  String authorFont = importedFonts[0];
  String contentFont = importedFonts[0];
  late String displayTitle, displayTag;
  late List<String> displayContent;
  late Log logBuffer;

  @override
  void initState() {
    super.initState();
    logBuffer = new Log(
        widget.logTitle, widget.logTags, widget.logContents, widget.logAuthor);
    //displayTitle = widget.logTitle;
    //displayContent = widget.logContents;
    //delayedLogin();
  }

  void shareLog(BuildContext context, Log any) {
    //final RenderBox box = context.findRenderObject();
    String text = 'Title: ' + any.title + '\nAuthor: ' + any.author;
    int contentsSize = any.content.length;
    for (int i = 0; i < contentsSize - 1; i++) {
      text = text + '\n\n\t' + any.content[i];
    }
    text = text + '\n\nTags: ' + any.tags;
    Share.share(text, subject: any.title);
  }

  List<PopupItem> menu = [
    PopupItem(1, 'Update'),
    PopupItem(2, 'Delete'),
    PopupItem(3, 'Modify Title Size'),
    PopupItem(4, 'Modify Content Size'),
    PopupItem(4, 'Modify Author ID Size'),
    PopupItem(6, 'Font Style Toggle'),
    PopupItem(7, 'Share'),
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
        //defocus();
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => new UpdateLog(
                      logTitle: logBuffer.title,
                      logTags: logBuffer.tags,
                      logContents:
                          logBuffer.content.map((s) => s as String).toList(),
                      logID: widget.logID.toString(),
                      logAuthor: logBuffer.author,
                    )));
        reExtract(widget.logID);
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
        deleteLogPrompt(widget.logID, widget.logTitle);
        break;
      case 'Font Style Toggle':
        tripleDisguises(
          dismissible: true,
          secDur: 0,
          closeAfter: false,
          context: context,
          title: 'Modify Font Styles',
          titleStyle: cxTextStyle(style: 'bold', size: 15),
          message: 'Slide to Dismiss',
          messageStyle: cxTextStyle(style: 'normal', size: 16),
          button1Name: 'Title',
          button1Colour: colour('dblue'),
          button1Callback: () {
            setState(() {
              if (titleFontIndex < importedFonts.length - 1) {
                titleFontIndex++;
                titleFont = importedFonts[titleFontIndex];
              } else {
                titleFontIndex = 0;
                titleFont = importedFonts[titleFontIndex];
              }
            });
            //print(importedFonts[titleFontIndex]);
          },
          button2Name: 'Author',
          button2Colour: colour('dgreen'),
          button2Callback: () {
            setState(() {
              if (authorFontIndex < importedFonts.length - 1) {
                authorFontIndex++;
                authorFont = importedFonts[authorFontIndex];
              } else {
                authorFontIndex = 0;
                authorFont = importedFonts[authorFontIndex];
              }
            });
            //print(importedFonts[authorFontIndex]);
          },
          button3Name: 'Content',
          button3Colour: colour('dred'),
          button3Callback: () {
            setState(() {
              if (contentFontIndex < importedFonts.length - 1) {
                contentFontIndex++;
                contentFont = importedFonts[contentFontIndex];
              } else {
                contentFontIndex = 0;
                contentFont = importedFonts[contentFontIndex];
              }
            });
            //print(importedFonts[authorFontIndex]);
          },
        );
        break;
      case 'Share':
        shareLog(context, logBuffer);
        break;
      case 'nukeTest':
        reExtract(widget.logID);
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
        message: 'Updating Log',
        messageStyle: cxTextStyle(style: 'bold', colour: colour('blue')));
    await Future.delayed(Duration(seconds: 2), () {});
    String retrievedToken = '';
    await prefSetup().then((value) => {retrievedToken = value!});
    final response = await http.get(
      Uri.parse('https://nexus-omega.herokuapp.com/get/' + id),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: "Bearer " + retrievedToken
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        logBuffer = new Log.fromJson(json.decode(response.body));
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
            child: ListTile(
              title: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding:
                      EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 3),
                  child: Text(
                    logBuffer.title,
                    style: cxTextStyle(
                        style: 'normal',
                        size: titleSize,
                        fontFamily: titleFont),
                  ),
                ),
              ),
              subtitle: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(left: 5, right: 5, bottom: 3),
                  child: Text(
                    'by: ' + logBuffer.author,
                    style: cxTextStyle(
                        style: 'normal',
                        size: authorIDSize,
                        fontFamily: authorFont),
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
    List<dynamic> temp = logBuffer.content;
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
                    style: 'normal',
                    colour: colour('white'),
                    size: contentSize,
                    fontFamily: contentFont)),
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
