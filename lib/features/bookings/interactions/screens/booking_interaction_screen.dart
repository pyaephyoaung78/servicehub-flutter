import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/booking_interaction_models.dart';
import '../services/booking_interaction_api_service.dart';

class BookingInteractionScreen extends StatefulWidget {
  final int bookingId;
  final bool isStaff;
  const BookingInteractionScreen({
    required this.bookingId,
    required this.isStaff,
    super.key,
  });
  @override
  State<BookingInteractionScreen> createState() =>
      _BookingInteractionScreenState();
}

class _BookingInteractionScreenState extends State<BookingInteractionScreen> {
  late final BookingInteractionApiService api;
  final messageController = TextEditingController();
  List<BookingMessageModel> messages = [];
  List<ServiceProofModel> proofs = [];
  String? filePath;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    api = BookingInteractionApiService(
      apiClient: ApiClient(tokenStorage: TokenStorage()),
    );
    _load();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        api.messages(widget.bookingId),
        api.proofs(widget.bookingId),
      ]);
      if (mounted)
        setState(() {
          messages = results[0] as List<BookingMessageModel>;
          proofs = results[1] as List<ServiceProofModel>;
        });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pick({required bool imageOnly, String? proofKind}) async {
    final result = await FilePicker.pickFiles(
      type: imageOnly ? FileType.image : FileType.custom,
      allowedExtensions: imageOnly
          ? null
          : ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    if (!mounted || result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    if (proofKind != null) {
      setState(() => saving = true);
      try {
        await api.uploadProof(widget.bookingId, proofKind, path, null);
        await _load();
      } finally {
        if (mounted) setState(() => saving = false);
      }
    } else {
      setState(() => filePath = path);
    }
  }

  Future<void> _send() async {
    if (messageController.text.trim().isEmpty && filePath == null) return;
    setState(() => saving = true);
    try {
      await api.sendMessage(widget.bookingId, messageController.text, filePath);
      messageController.clear();
      filePath = null;
      await _load();
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Booking chat & proof')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.isStaff)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving
                        ? null
                        : () => _pick(imageOnly: true, proofKind: 'before'),
                    child: const Text('Upload before'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving
                        ? null
                        : () => _pick(imageOnly: true, proofKind: 'after'),
                    child: const Text('Upload after'),
                  ),
                ),
              ],
            ),
          if (proofs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Service proof',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...proofs.map(
              (proof) => ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text('${proof.kind.toUpperCase()} · ${proof.imageName}'),
                subtitle: Text(proof.note ?? 'Photo uploaded'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text('Conversation', style: Theme.of(context).textTheme.titleMedium),
          ...messages.map(
            (message) => Card(
              child: ListTile(
                title: Text('${message.senderName} (${message.senderRole})'),
                subtitle: Text(
                  [
                    if (message.body != null) message.body!,
                    if (message.attachmentName != null)
                      'Attachment: ${message.attachmentName}',
                  ].join('\n'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: messageController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
            ),
          ),
          TextButton.icon(
            onPressed: saving ? null : () => _pick(imageOnly: false),
            icon: const Icon(Icons.attach_file),
            label: Text(
              filePath == null
                  ? 'Attach image or PDF'
                  : filePath!.split(RegExp(r'[/\\]')).last,
            ),
          ),
          FilledButton.icon(
            onPressed: saving ? null : _send,
            icon: const Icon(Icons.send),
            label: const Text('Send message'),
          ),
        ],
      ),
    );
  }
}
