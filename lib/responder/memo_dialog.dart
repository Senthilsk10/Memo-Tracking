import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';
import 'package:permission_handler/permission_handler.dart'; // Add this for permissions

class MemoDialog extends StatefulWidget {
  final DocumentSnapshot memo;
  final Map<String, dynamic>? lastStatus;
  final String userType;
  final String institutionalId;
  final FirebaseFirestore firestore;
  final List<String> responderTypes;

  const MemoDialog({
    Key? key,
    required this.memo,
    required this.lastStatus,
    required this.userType,
    required this.institutionalId,
    required this.firestore,
    required this.responderTypes,
  }) : super(key: key);

  @override
  _MemoDialogState createState() => _MemoDialogState();
}

class _MemoDialogState extends State<MemoDialog> {
  late TextEditingController _remarksController;
  late String _status;
  late String _workStatus;
  late String _tagUser;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final Color primaryColor = Color(0xFF4285F4); // Google Blue
  final Color secondaryColor = Color(0xFF34A853); // Google Green
  final Color backgroundColor = Color(0xFFF1F3F4); // Light grey background

  // Speech to text related
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _currentWords = '';
  String _selectedLanguage = 'English';
  final translator = GoogleTranslator();

  @override
  void initState() {
    super.initState();
    _status = widget.lastStatus?['status'] ?? 'not attended';
    _workStatus = widget.lastStatus?['workStatus'] ?? 'incomplete';
    _tagUser = widget.lastStatus?['tagUser'] ?? 'no need';
    _remarksController =
        TextEditingController(text: widget.lastStatus?['remarks'] ?? '');
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

  // Toggle listening
  void _toggleListening() async {
    if (_status != 'attended') {
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
                _remarksController.text +=
                    (_remarksController.text.isEmpty ? '' : ' ') +
                        recognizedText;
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        return Theme(
            data: ThemeData(
              canvasColor: Colors.white,
            ),
            child: AlertDialog(
              title: Text('Memo Details: ${widget.memo['memoId']}'),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 500,
                    minWidth: 300,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Memo Details with Responsive Layout
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildDetailChip(
                              'Complaint', widget.memo['complaints']),
                          _buildDetailChip(
                              'Department', widget.memo['department']),
                          _buildDetailChip('Block', widget.memo['blockName']),
                          _buildDetailChip('Floor No', widget.memo['floorNo']),
                          _buildDetailChip('Ward No', widget.memo['wardNo']),
                        ],
                      ),

                      SizedBox(height: 20),

                      // Status Dropdowns with Responsive Layout
                      if (isNarrow)
                        Column(
                          children: [
                            _buildStatusDropdown(),
                            SizedBox(height: 10),
                            _buildWorkStatusDropdown(),
                            SizedBox(height: 10),
                            _buildTagUserDropdown(),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(child: _buildStatusDropdown()),
                            SizedBox(width: 10),
                            Expanded(child: _buildWorkStatusDropdown()),
                            SizedBox(width: 10),
                            Expanded(child: _buildTagUserDropdown()),
                          ],
                        ),

                      SizedBox(height: 20),

                      // Speech language selector
                      _buildLanguageSelector(),

                      SizedBox(height: 10),

                      // Remarks TextField with Speech Button
                      _buildRemarksFieldWithSpeech(),

                      // Show current words being recognized
                      if (_isListening && _currentWords.isNotEmpty)
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
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _submitMemoUpdate();
                    Navigator.of(context).pop();
                  },
                  child: Text('Submit'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
              ],
            ));
      },
    );
  }

  Widget _buildDetailChip(String label, String value) {
    return Chip(
      label: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
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
          // Reset work status and tag user if status changes to 'not attended'
          if (_status == 'not attended') {
            _workStatus = 'incomplete';
            _tagUser = 'no need';
          }
        });
      },
    );
  }

  Widget _buildWorkStatusDropdown() {
    return DropdownButtonFormField<String>(
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
      onChanged: _status == 'attended'
          ? (value) {
              setState(() {
                _workStatus = value!;
              });
            }
          : null,
    );
  }

  Widget _buildTagUserDropdown() {
    return DropdownButtonFormField<String>(
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
      onChanged: _status == 'attended'
          ? (value) {
              setState(() {
                _tagUser = value!;
              });
            }
          : null,
    );
  }

  Widget _buildLanguageSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedLanguage,
      decoration: InputDecoration(
        labelText: 'Speech Language',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.language),
      ),
      items: ['English', 'Tamil', 'English to Tamil', 'Tamil to English']
          .map((language) => DropdownMenuItem(
                value: language,
                child: Text(language),
              ))
          .toList(),
      onChanged: _status == 'attended'
          ? (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }
          : null,
    );
  }

  Widget _buildRemarksFieldWithSpeech() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _remarksController,
                decoration: InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                ),
                enabled: _status == 'attended',
                maxLines: 3,
              ),
            ),
            SizedBox(width: 10),
            // Speech button
            Container(
              height: 56,
              child: ElevatedButton(
                onPressed: _status == 'attended' ? _toggleListening : null,
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
        ),
        if (_isListening)
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
      ],
    );
  }

  void _submitMemoUpdate() {
    try {
      widget.firestore.collection('memo').doc(widget.memo.id).update({
        'tagUser': _tagUser,
        'workerStatuses': FieldValue.arrayUnion([
          {
            'status': _status,
            'workStatus': _workStatus,
            'tagUser': _tagUser,
            'remarks': _remarksController.text,
            'timestamp': DateTime.now().toIso8601String(),
            'institutionalId': widget.institutionalId,
            'userType': widget.userType,
          }
        ]),
      });
      _showToast('Memo updated successfully');
    } catch (e) {
      _showToast('Error updating memo: ${e.toString()}', isError: true);
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

  @override
  void dispose() {
    _remarksController.dispose();
    _speech.cancel();
    super.dispose();
  }
}
