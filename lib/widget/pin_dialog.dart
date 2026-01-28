import 'package:flutter/cupertino.dart';

class PinAuthDialog extends StatefulWidget {
  final String correctPin;
  const PinAuthDialog({super.key, required this.correctPin});

  @override
  State<PinAuthDialog> createState() => _PinAuthDialogState();
}

class _PinAuthDialogState extends State<PinAuthDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  void _validate() {
    if (_controller.text == widget.correctPin) {
      Navigator.of(context).pop(true); // Success
    } else {
      setState(() {
        _errorText = "Incorrect PIN";
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text("Enter PIN"),
      content: Column(
        children: [
          const Text("Please enter your master PIN to continue."),
          const SizedBox(height: 15),
          CupertinoTextField(
            controller: _controller,
            placeholder: "PIN",
            keyboardType: TextInputType.number,
            obscureText: true,
            textAlign: TextAlign.center,
            autofocus: true,
            onSubmitted: (_) => _validate(),
          ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_errorText!,
                  style: const TextStyle(
                      color: CupertinoColors.destructiveRed, fontSize: 13)),
            ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text("Cancel"),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _validate,
          child: const Text("Verify"),
        ),
      ],
    );
  }
}
