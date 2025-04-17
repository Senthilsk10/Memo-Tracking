import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TaggedMemoTab extends StatefulWidget {
  final String userType;
  final String institutionalId;
  final FirebaseFirestore firestore;
  final List<String> responderTypes;

  const TaggedMemoTab({
    Key? key,
    required this.userType,
    required this.institutionalId,
    required this.firestore,
    required this.responderTypes,
  }) : super(key: key);

  @override
  State<TaggedMemoTab> createState() => _TaggedMemoTabState();
}

class _TaggedMemoTabState extends State<TaggedMemoTab> {
  // Speech to text related
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _currentWords = '';
  String _selectedLanguage = 'English';
  final translator = GoogleTranslator();
  final Color primaryColor = Color(0xFF4285F4); // Google Blue
  final Color secondaryColor = Color(0xFF34A853); // Google Green

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  // Request microphone permissions
  Future<void> _requestPermissions() async {
    // Request microphone permission
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      _initSpeech();
    } else {
      _showToast('Microphone permission is required for speech recognition',
          isError: true);
    }
  }

  // Initialize speech recognition
  void _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'listening') {
            setState(() => _isListening = true);
          } else if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) {
          print('Speech error: $errorNotification');
          setState(() => _isListening = false);
          _showToast('Speech recognition error: ${errorNotification.errorMsg}',
              isError: true);
        },
        debugLogging: true,
      );

      setState(() {
        _speechAvailable = available;
      });

      if (!available) {
        _showToast('Speech recognition not available on this device',
            isError: true);
      }
    } catch (e) {
      print('Speech initialization error: $e');
      _showToast('Failed to initialize speech recognition', isError: true);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? Colors.red : secondaryColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // Toggle listening
  void _toggleListening(TextEditingController controller, String status) async {
    if (status != 'attended') {
      _showToast('Please set status to attended first', isError: true);
      return;
    }

    if (!_isListening) {
      if (!_speechAvailable) {
        // Retry initialization if not available
        if (!_speechAvailable) return;
      }

      setState(() => _isListening = true);
      _currentWords = '';

      // Set the language locale based on selection
      String locale = 'en_US'; // Default English
      if (_selectedLanguage == 'Tamil') {
        locale = 'ta_IN';
      } else if (_selectedLanguage == 'English to Tamil' ||
          _selectedLanguage == 'Tamil to English') {
        locale = _selectedLanguage.startsWith('English') ? 'en_US' : 'ta_IN';
      }

      try {
        await _speech.listen(
          onResult: (result) async {
            setState(() => _currentWords = result.recognizedWords);

            if (result.finalResult) {
              String recognizedText = result.recognizedWords;
              print('Final result: $recognizedText');

              // Handle translation if needed
              if (_selectedLanguage == 'Tamil to English' &&
                  recognizedText.isNotEmpty) {
                try {
                  _showToast('Translating from Tamil to English...');
                  var translation = await translator.translate(recognizedText,
                      from: 'ta', to: 'en');
                  recognizedText = translation.text;
                } catch (e) {
                  print('Translation error: $e');
                  _showToast('Translation error: $e', isError: true);
                }
              } else if (_selectedLanguage == 'English to Tamil' &&
                  recognizedText.isNotEmpty) {
                try {
                  _showToast('Translating from English to Tamil...');
                  var translation = await translator.translate(recognizedText,
                      from: 'en', to: 'ta');
                  recognizedText = translation.text;
                } catch (e) {
                  print('Translation error: $e');
                  _showToast('Translation error: $e', isError: true);
                }
              }

              setState(() {
                controller.text +=
                    (controller.text.isEmpty ? '' : ' ') + recognizedText;
                _isListening = false;
                _currentWords = '';
              });
            }
          },
          listenFor: Duration(seconds: 30),
          pauseFor: Duration(seconds: 3),
          partialResults: true,
          localeId: locale,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );
      } catch (e) {
        print('Listen error: $e');
        setState(() => _isListening = false);
        _showToast('Error starting speech recognition', isError: true);
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  Stream<QuerySnapshot> _getTaggedMemoStream() {
    return widget.firestore
        .collection('memo')
        .where('status', whereIn: ['approved', 'completed'])
        .where('tagUser', isEqualTo: widget.userType)
        .snapshots();
  }

  Color _getMemoColor(Map<String, dynamic> memoData) {
    List<dynamic> workStatuses = memoData['workerStatuses'] ?? [];
    if (workStatuses.isEmpty) {
      return Colors.white; // Not attended, incomplete
    }

    var lastStatus = workStatuses.last;
    bool isAttended = lastStatus['status'] == 'attended';
    bool isComplete = lastStatus['workStatus'] == 'complete';

    if (!isAttended && !isComplete) {
      return Colors.red[100]!; // Not attended, incomplete
    } else if (isAttended && !isComplete) {
      return Colors.white; // Attended, incomplete
    }
    return Colors.white; // Attended, complete
  }

  bool _shouldShowMemo(Map<String, dynamic> memoData) {
    List<dynamic> workStatuses = memoData['workerStatuses'] ?? [];
    if (workStatuses.isEmpty) return true;

    var lastStatus = workStatuses.last;
    String status = lastStatus['status'] ?? 'not attended';
    String workStatus = lastStatus['workStatus'] ?? 'incomplete';
    String tagUser = lastStatus['tagUser'] ?? 'no need';

    bool isAttended = status == 'attended';
    bool isComplete = workStatus == 'complete';
    bool isTaggedToOther = tagUser != 'no need' && tagUser != widget.userType;

    return !((isComplete && isTaggedToOther) ||
        (isComplete && tagUser == 'no need'));
  }

  void _showStatusDialog(BuildContext context, DocumentSnapshot memo) {
    List<dynamic> workStatuses = memo['workerStatuses'] ?? [];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
            data: ThemeData(
              canvasColor: Colors
                  .white, // Forces the dropdown menu background color to white
            ),
            child: AlertDialog(
              title: Text('Status History'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: workStatuses.map<Widget>((status) {
                    return Card(
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${status['status']}'),
                            Text('Work Status: ${status['workStatus']}'),
                            Text('Tag User: ${status['tagUser']}'),
                            Text('Remarks: ${status['remarks']}'),
                            Text(
                                'Time: ${DateTime.parse(status['timestamp']).toString()}'),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                ),
              ],
            ));
      },
    );
  }

  void _showUpdateDialog(BuildContext context, DocumentSnapshot memo) {
    Map<String, dynamic> memoData = memo.data() as Map<String, dynamic>;
    final _formKey = GlobalKey<FormState>();
    final _remarksController = TextEditingController();

    // Initialize with default values
    String _status = 'not attended';
    String _workStatus = 'incomplete';
    String _tagUser = 'no need';
    bool _isAttended = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Update Memo: ${memoData['memoId']}'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Complaint: ${memoData['complaints']}'),
                      Text('Department: ${memoData['department']}'),
                      Text('Block: ${memoData['blockName']}'),
                      Text('Ward No: ${memoData['wardNo']}'),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: ['not attended', 'attended']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _status = value!;
                            _isAttended = value == 'attended';
                            if (!_isAttended) {
                              _workStatus = 'incomplete';
                              _tagUser = 'no need';
                            }
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      if (_isAttended) ...[
                        DropdownButtonFormField<String>(
                          value: _workStatus,
                          decoration: InputDecoration(
                            labelText: 'Work Status',
                            border: OutlineInputBorder(),
                          ),
                          items: ['incomplete', 'complete']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _workStatus = value!;
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _tagUser,
                          decoration: InputDecoration(
                            labelText: 'Tag User',
                            border: OutlineInputBorder(),
                          ),
                          items: ['no need', ...widget.responderTypes]
                              .map((user) => DropdownMenuItem(
                                    value: user,
                                    child: Text(user),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _tagUser = value!;
                            });
                          },
                        ),
                        // Add speech language selector
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedLanguage,
                          decoration: InputDecoration(
                            labelText: 'Speech Language',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.language),
                          ),
                          items: [
                            'English',
                            'Tamil',
                            'English to Tamil',
                            'Tamil to English'
                          ]
                              .map((language) => DropdownMenuItem(
                                    value: language,
                                    child: Text(language),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedLanguage = value!;
                            });
                          },
                        ),
                      ],
                      SizedBox(height: 16),
                      // Remarks TextField with Speech Button
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _remarksController,
                              decoration: InputDecoration(
                                labelText: 'Remarks',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              enabled: _isAttended,
                            ),
                          ),
                          if (_isAttended) ...[
                            SizedBox(width: 10),
                            Container(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () => _toggleListening(
                                    _remarksController, _status),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(12),
                                ),
                                child: Icon(
                                  _isListening ? Icons.mic : Icons.mic_none,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Show listening indicator and current words
                      if (_isListening) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Listening... (${_selectedLanguage})',
                            style: TextStyle(
                              color: primaryColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        if (_currentWords.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Recognizing: $_currentWords',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      Map<String, dynamic> newStatus = {
                        'status': _status,
                        'workStatus': _workStatus,
                        'tagUser': _tagUser,
                        'remarks': _remarksController.text,
                        'timestamp': DateTime.now().toIso8601String(),
                        'institutionalId': widget.institutionalId,
                        'userType': widget.userType,
                      };

                      Map<String, dynamic> updateData = {
                        'workerStatuses': FieldValue.arrayUnion([newStatus]),
                      };

                      // Only update tagUser outside the array if it's not "no need" or attended and incomplete
                      if (!(_status == 'attended' &&
                          _workStatus == 'incomplete' &&
                          _tagUser == 'no need')) {
                        updateData['tagUser'] = _tagUser;
                      }

                      // Update status to completed only if all conditions are met
                      if (_status == 'attended' &&
                          _workStatus == 'complete' &&
                          _tagUser == 'no need') {
                        updateData['status'] = 'completed';
                      }

                      try {
                        await widget.firestore
                            .collection('memo')
                            .doc(memo.id)
                            .update(updateData);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Memo updated successfully')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating memo: $e')),
                        );
                      }
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getTaggedMemoStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No memos found'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot memo = snapshot.data!.docs[index];
            Map<String, dynamic> memoData = memo.data() as Map<String, dynamic>;

            if (!_shouldShowMemo(memoData)) {
              return SizedBox.shrink();
            }

            return Card(
              color: _getMemoColor(memoData),
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(
                  'Memo ID: ${memoData['memoId']}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Complaint: ${memoData['complaints']}'),
                    Text('Department: ${memoData['department']}'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _showStatusDialog(context, memo),
                          child: Text('View History'),
                        ),
                        ElevatedButton(
                          onPressed: () => _showUpdateDialog(context, memo),
                          child: Text('Update Status'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}
