import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:StamComm/utils/stamp_utils.dart';

class NFCButton extends StatefulWidget {
  final VoidCallback? onSnapComplete;

  const NFCButton({super.key, this.onSnapComplete});
  @override
  State<NFCButton> createState() => _NFCButtonState();
}

class _NFCButtonState extends State<NFCButton> {
  bool _isProcessing = false;
  bool _isSessionActive = false;

  @override
  void dispose() {
    if (_isSessionActive) {
      NfcManager.instance.stopSession();
    }
    super.dispose();
  }

  // NFCの読み取り
  Future<void> readNfc() async {
    if (_isProcessing || !mounted) return;

    final bool isNfcAvailable = await NfcManager.instance.isAvailable();
    if (!isNfcAvailable) {
      if (mounted) _showErrorDialog('NFCはこのデバイスで利用できません');
      return;
    }

    if (mounted) {
      setState(() => _isProcessing = true);
    }

    // NFCスキャンダイアログを表示
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('NFCをスキャン'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('NFCタグをスキャンしてください'),
            ],
          ),
        ),
      );
    }

    _isSessionActive = true;
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          Ndef? ndef = Ndef.from(tag);
          if (ndef == null) {
            if (mounted) _showErrorDialog('このタグはNDEF非対応です');
            return;
          }

          NdefMessage message = await ndef.read();
          String? id = _extractIdFromNdefMessage(message);

          if (id == null) {
            if (mounted) _showErrorDialog('有効なIDが見つかりません');
            return;
          }

          final event = await fetchStampInfo(id);
          if (event == null) {
            if (mounted) _showErrorDialog('対応するイベントが見つかりません');
            return;
          }

          bool locationValid =
              await validateLocation(event['latitude'], event['longitude']);
          if (!locationValid) {
            if (mounted) _showErrorDialog('現在位置とイベントの位置が遠すぎます');
            return;
          }

          if (mounted) {
            await handleSuccessfulScan(context, event, id,
                onSnapComplete: widget.onSnapComplete);
          }
        } catch (e) {
          if (mounted) _showErrorDialog('エラーが発生しました: $e');
        } finally {
          _isSessionActive = false;
          NfcManager.instance.stopSession();
          if (mounted) {
            setState(() => _isProcessing = false);
          }
        }
      },
    );
  }

  String? _extractIdFromNdefMessage(NdefMessage message) {
    for (NdefRecord record in message.records) {
      if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
          record.type.isNotEmpty &&
          record.type[0] == 0x54) {
        return utf8.decode(record.payload.sublist(3));
      }
    }
    return null;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: readNfc,
      child: const Icon(Icons.nfc),
    );
  }
}
