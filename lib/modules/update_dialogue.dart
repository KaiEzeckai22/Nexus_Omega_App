import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:nexus_omega_app/model/dialogue.dart';
import 'package:nexus_omega_app/model/log.dart';
import 'dev.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';

class UpdateDialogue extends StatefulWidget {
  final String dialogueTitle, dialogueTags, dialogueID, dialogueAuthor;
  final List<dynamic> dialogueContents;
  const UpdateDialogue({
    Key? key,
    required this.dialogueTitle,
    required this.dialogueTags,
    required this.dialogueContents,
    required this.dialogueID,
    required this.dialogueAuthor,
    /*CONTACTS*/
  }) : super(key: key);
  @override
  _UpdateDialogueState createState() => _UpdateDialogueState();
}

class _UpdateDialogueState extends State<UpdateDialogue> {
  int key = 0, increments = 0, listSize = 1, _count = 1;
  late SharedPreferences tokenStore;
  String stringBuffer = '';

  TextEditingController titleCtrlr = TextEditingController();
  TextEditingController tagsCtrlr = TextEditingController();
  TextEditingController authorCtrlr = TextEditingController();

  List<TextEditingController> contentsCtrlr = <TextEditingController>[
    TextEditingController()
  ];

  List<String> colours = <String>[];

  late Dialogue previousDialogue, updatedDialogue;
  String dialogueIdentifier = '';
  late Flushbar flush;
  List<PopupItem> menu = [
    PopupItem(1, 'red'),
    PopupItem(2, 'orange'),
    PopupItem(3, 'yellow'),
    PopupItem(4, 'green'),
    PopupItem(4, 'blue'),
    PopupItem(5, 'violet'),
    PopupItem(6, 'pink'),
    PopupItem(7, 'grey'),
    PopupItem(8, 'cyan'),
    PopupItem(8, 'white'),
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
        break;
      default:
        print(_selectedChoices);
        _selectedChoices = "none";
        print(_selectedChoices);
    }
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
      Uri.parse('https://nexus-omega.herokuapp.com/dialouge/delete/' + id),
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

  Future<int> uploadUpdated(
      String title, String tags, List content, String id, String author) async {
    String retrievedToken = '';
    disguisedToast(
        context: context,
        title: 'Updating Dialogue',
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
      Uri.parse('https://nexus-omega.herokuapp.com/dialogue/update/' + id),
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
    List<List<String>> listedContent = <List<String>>[];
    List<String> subContent = <String>[];
    for (int i = 0; i < _count; i++) {
      //print(colours[(_count - i - 1)]);
      subContent.add(colours[(_count - i - 1)]);
      subContent.add(contentsCtrlr[i].text);
      //print(subContent);
      listedContent.add(subContent.toList());
      //print(listedContent);

      subContent.clear();
      if (contentsCtrlr[i].text.isEmpty) {
        emptyDetect = true;
      }
    }
    print(listedContent.reversed);
    setState(() {
      updatedDialogue = new Dialogue(titleCtrlr.text, tagsCtrlr.text,
          listedContent.reversed.toList(), authorCtrlr.text);
    });
    print(subContent.reversed);

    //print(updatedDialogue.toJson());
    if (updatedDialogue.title.isEmpty || updatedDialogue.tags.isEmpty) {
      emptyDetect = true;
    }

    if (!emptyDetect) {
      statusCode = await uploadUpdated(
        updatedDialogue.title,
        updatedDialogue.tags,
        listedContent.reversed.toList(),
        dialogueIdentifier,
        updatedDialogue.author,
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
      previousDialogue = new Dialogue(widget.dialogueTitle, widget.dialogueTags,
          widget.dialogueContents, widget.dialogueAuthor);
      dialogueIdentifier = widget.dialogueID;
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
      colours.clear();
      contentsCtrlr = <TextEditingController>[TextEditingController()];
      titleCtrlr = TextEditingController(text: previousDialogue.title);
      tagsCtrlr = TextEditingController(text: previousDialogue.tags);
      authorCtrlr = TextEditingController(text: previousDialogue.author);
      final int edge = previousDialogue.content.length;
      for (int i = 0; i < edge; i++) {
        if (i < edge) {
          contentsCtrlr.insert(
              0, TextEditingController(text: previousDialogue.content[i][1]));
          colours.add(previousDialogue.content[i][0]);
        }

        _count++;
        listSize = previousDialogue.content.length;
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
          title: cText(text: "Update Dialogue", colour: colour('')),
          actions: [
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                resetCtrlrFields();
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
                    fieldPrompt: "Title",
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
                    autoFocus: false),
                hfill(10),
                ctrlrField(
                    context: context,
                    fieldPrompt: "Tags",
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
                  deleteDialoguePrompt(dialogueIdentifier, titleCtrlr.text);
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
                  colours.add('white');
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

  colorSelect() {
    disguisedToast(
        context: context,
        title: 'Select Colour',
        message: 'Touch to Toggle',
        callback: () => doNoting());
  }

  _contentInput(int index, context) {
    //print(contentColours[index]);
    Color currentColor = colour(colours[_count - index - 1]);
    return Column(children: <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          cxIconButton(
            onPressed: () {
              //FocusManager.instance.primaryFocus?.unfocus();
              if (_count != 1) {
                setState(() {
                  _count--;
                  increments--;
                  listSize--;
                  contentsCtrlr.removeAt(index);
                  colours.removeAt(_count - index);
                });
              }
            },
            icon: (_count != 1) ? Icon(Icons.remove) : null,
            iconColour: colour(''),
          ),
          Column(children: <Widget>[
            cxIconButton(
              onPressed: () {
                setState(() {
                  if (index < contentsCtrlr.length - 2) {
                    stringBuffer = contentsCtrlr[index].text;
                    contentsCtrlr[index].text = contentsCtrlr[index + 1].text;
                    contentsCtrlr[index + 1].text = stringBuffer;

                    stringBuffer = colours[_count - index - 1];
                    colours[_count - index - 1] = colours[_count - index - 2];
                    colours[_count - index - 2] = stringBuffer;
                  }
                });
              },
              height: 35,
              width: 35,
              iconSize: 11,
              icon: ((index == 0) && (index == contentsCtrlr.length - 2))
                  ? null
                  : (index == contentsCtrlr.length - 2)
                      ? Icon(Icons.not_interested)
                      : Icon(Icons.arrow_upward),
              iconColour: colour(''),
            ),
            cxIconButton(
              onPressed: () {
                setState(() {
                  if (index > 0) {
                    //  WORKING TEXT SWAP
                    stringBuffer = contentsCtrlr[index].text;
                    contentsCtrlr[index].text = contentsCtrlr[index - 1].text;
                    contentsCtrlr[index - 1].text = stringBuffer;

                    stringBuffer = colours[_count - index - 1];
                    colours[_count - index - 1] = colours[_count - index];
                    colours[_count - index] = stringBuffer;
                  }
                });
              },
              height: 35,
              width: 35,
              iconSize: 11,
              icon: ((index == 0) && (index == contentsCtrlr.length - 2))
                  ? null
                  : (index == 0)
                      ? Icon(Icons.not_interested)
                      : Icon(Icons.arrow_downward),
              iconColour: colour(''),
            ),
          ]),
          popUpMenu(
            selectables: menu,
            onSelection: (value) {
              setState(() {
                currentColor = colour(value);
                colours[_count - index - 1] = value;
              });
            },
            icon: Icon(Icons.color_lens, color: currentColor),
            backgroundColour: colour('black'),
            borderColour: currentColor,
            buttonColour: colour('black'),
            popupColour: colour('black'),
            fontSize: 15,
          ),
          Expanded(
            child: ctrlrField(
              context: context,
              fieldPrompt: "Par #" + (_count - index).toString(),
              ctrlrID: contentsCtrlr[index],
              defaultColor: currentColor,
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
}
