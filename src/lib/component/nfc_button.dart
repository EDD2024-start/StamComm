import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NFCButton extends StatefulWidget {
  const NFCButton({super.key});

  @override
  State<NFCButton> createState() => _NFCButtonState();
}

class _NFCButtonState extends State<NFCButton> {
  String _message = '';

  void readNfc() async {
    final bool isNfcAvailable = await NfcManager.instance.isAvailable();
    print('NFC availability: $isNfcAvailable');
    if (!isNfcAvailable) {
      setState(() {
        _message = 'NFC is not available on this device';
      });
      return;
    } else {
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          Ndef? ndef = Ndef.from(tag);
          if (ndef == null) {
            print('Tag is not ndef');
            return;
          }
          NdefMessage message = await ndef.read();
          List<NdefRecord> records = message.records;
          String str = '';
          for (NdefRecord record in records) {
            Uint8List payload = record.payload;
            str += utf8.decode(payload);
          }
          setState(() {
            _message = 'Read OK: ${str.substring(3)}';
          });
          NfcManager.instance.stopSession();
        },
        onError: (dynamic error) {
          print(error.message);
          return Future.value();
        },
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final writeController = TextEditingController();
    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('NFC Operations'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_message),
                  TextButton(onPressed: readNfc, child: const Text('Read NFC')),
                ],
              ),
            );
          },
        );
      },
      child: const Icon(Icons.nfc),
    );
  }
}
