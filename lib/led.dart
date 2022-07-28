import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({required this.server});

  @override
  _ChatPage createState() => new _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {
  static final clientID = 0;
  late BluetoothConnection connection;

  List<_Message> messages = <_Message>[];
  String value = '0.0';
  String _messageBuffer = '';
  double _currentSliderValue = 0;

  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection.input?.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double valueProgress;
    if (value.length <= 8) {
      valueProgress = (1.0 * double.parse(value.toString().trim())) / 200.0;
    } else {
      valueProgress = 0.5;
    }

    final List<Row> list = messages.map((_message) {
      return Row(
        children: <Widget>[
          Container(
            child: Text(
                (text) {
                  return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
                }(
                  _message.text.trim(),
                ),
                style: TextStyle(color: Colors.white)),
            padding: EdgeInsets.all(12.0),
            margin: EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
            width: 100.0,
            decoration: BoxDecoration(color: _message.whom == clientID ? Colors.blueAccent : Colors.grey, borderRadius: BorderRadius.circular(7.0)),
          ),
        ],
        mainAxisAlignment: _message.whom == clientID ? MainAxisAlignment.end : MainAxisAlignment.start,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 10,
        shape: const RoundedRectangleBorder(
          side: BorderSide(
            color: Colors.yellow,
            width: 1,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        toolbarHeight: 80,
        title: (isConnecting
            ? Center(child: Text('Conectando a ${widget.server.name}...'))
            : isConnected
                ? Center(child: Text('Conectando con ${widget.server.name}'))
                : Center(child: Text('Registro de chat con ${widget.server.name}'))),
      ),
      body: ListView(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 350,
                  height: 400,
                  child: Stack(
                    alignment: AlignmentDirectional.center,
                    fit: StackFit.loose,
                    children: [
                      const Positioned(
                          top: 10,
                          left: 10,
                          child: Icon(
                            Icons.thermostat_rounded,
                            color: Colors.red,
                            size: 40,
                          )),
                      const Positioned(
                        top: 5,
                        child: Text(
                          'Temperatura',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.normal,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          color: Colors.yellow[200],
                          strokeWidth: 150,
                          value: 1.0,
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: CircularProgressIndicator(
                          strokeWidth: 10,
                          value: valueProgress,
                        ),
                      ),
                      SizedBox(
                        height: 250,
                        width: 250,
                        child: CircularProgressIndicator(
                          color: Colors.yellowAccent,
                          strokeWidth: 2,
                          value: valueProgress,
                        ),
                      ),
                      Positioned(
                        top: 130,
                        child: Text(
                          '${value} °C',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.normal,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ),
                      const Positioned(
                        top: 350,
                        child: Text(
                          'Valvula proporcional',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.normal,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.yellow[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: SizedBox(
                    width: 350,
                    height: 150,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Porcentaje de apertura de valvula: ${_currentSliderValue.round().toString()} %',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.normal,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        Slider(
                          value: _currentSliderValue,
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: _currentSliderValue.round().toString(),
                          onChanged: (value) {
                            setState(() {
                              _sendMessage(_currentSliderValue.round().toString() + '#');
                              _currentSliderValue = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(
                  height: 20,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.yellow[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    'Presentado \nEquipo 1',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.normal,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                ),

                // Flexible(
                //   child: ListView(padding: const EdgeInsets.all(12.0), controller: listScrollController, children: list),
                // ),
                // Container(
                //   padding: const EdgeInsets.all(5),
                //   width: double.infinity,
                //   child: FittedBox(
                //     child: Row(
                //       children: [
                //         FlatButton(
                //           onPressed: isConnected ? () => _sendMessage(_currentSliderValue.toString()) : null,
                //           child: ClipOval(child: Image.asset('assets/images/ledOn.png')),
                //         ),
                //         FlatButton(
                //           onPressed: isConnected ? () => _sendMessage('0') : null,
                //           child: ClipOval(child: Image.asset('assets/images/ledOff.png')),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),

                // Row(
                //   children: <Widget>[
                //     Flexible(
                //       child: Container(
                //         margin: const EdgeInsets.only(left: 16.0),
                //         child: TextField(
                //           style: const TextStyle(fontSize: 15.0),
                //           controller: textEditingController,
                //           decoration: InputDecoration.collapsed(
                //             hintText: isConnecting
                //                 ? 'Wait until connected...'
                //                 : isConnected
                //                     ? 'Type your message...'
                //                     : 'Chat got disconnected',
                //             hintStyle: const TextStyle(color: Colors.grey),
                //           ),
                //           enabled: isConnected,
                //         ),
                //       ),
                //     ),
                //     Container(
                //       margin: const EdgeInsets.all(8.0),
                //       child: IconButton(icon: const Icon(Icons.send), onPressed: isConnected ? () => _sendMessage(textEditingController.text) : null),
                //     ),
                //   ],
                // )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    //print(String.fromCharCode(data));
    int backspacesCounter = 0;
    data.forEach(
      (byte) {
        if (byte == 8 || byte == 127) {
          backspacesCounter++;
        }
      },
    );
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;

    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(
        () {
          messages.add(
            _Message(
              1,
              backspacesCounter > 0 ? _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter) : _messageBuffer + dataString.substring(0, index),
            ),
          );
          value = backspacesCounter > 0 ? _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter) : _messageBuffer + dataString.substring(0, index);
          _messageBuffer = dataString.substring(index);
        },
      );
    } else {
      _messageBuffer = (backspacesCounter > 0 ? _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter) : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();
    if (text.length > 0) {
      try {
        //text = text + "\r\n";
        List<int> list = text.codeUnits;
        Uint8List bytes = Uint8List.fromList(list);
        connection.output.add(bytes);
        await connection.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(listScrollController.position.maxScrollExtent, duration: Duration(milliseconds: 333), curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}
