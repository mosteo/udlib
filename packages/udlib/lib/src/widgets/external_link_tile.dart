import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// A settings-style row for a link to somewhere outside the app:
/// tapping it opens [url], and its trailing edge carries a share
/// button (the OS share sheet, via whatever [onShare] wires in --
/// typically `share_plus`'s `Share.share`) and a QR button (shows
/// [url] as a scannable code in a dialog).
///
/// Built for Pilares' handful of "here is a link, go read it
/// elsewhere" rows (the official programme, the Play Store listing,
/// the privacy policy, the council's poster gallery) -- all four
/// were a `ListTile`, or code that painstakingly reproduced one, with
/// nothing at their trailing edge. Landing here ahead of this
/// package's usual "two apps first" bar (see AGENTS.md) by explicit
/// request, so the next app that wants the same thing does not have
/// to reinvent it.
///
/// [onShare] is a callback rather than a call straight into
/// `share_plus` for one reason only: this package DOES already
/// depend on `share_plus` directly (see this package's pubspec.yaml
/// for why that is judged acceptable despite this package's usual
/// "no native side" rule), so the indirection buys nothing today. It
/// stays a callback anyway so a consumer can swap in whatever share
/// API is current, or a test double, without this widget caring.
class ExternalLinkTile extends StatelessWidget {
  const ExternalLinkTile({
    super.key,
    required this.leading,
    required this.title,
    required this.url,
    required this.onShare,
    this.subtitle,
    this.tileColor,
    this.contentPadding,
    this.shareTooltip = 'Share link',
    this.qrTooltip = 'Show QR code',
    this.failedToOpenMessage,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final String url;

  /// Wire the OS share sheet here, e.g. `(url) => Share.share(url)`.
  final Future<void> Function(String url) onShare;

  final Color? tileColor;
  final EdgeInsetsGeometry? contentPadding;

  /// English defaults, meant to be overridden by an app in another
  /// language -- see this package's AGENTS.md: framework code stays
  /// in English, apps keep their own.
  final String shareTooltip;
  final String qrTooltip;

  /// Shown in a SnackBar if [url] could not be opened at all. English
  /// default for the same reason as the two tooltips above.
  ///
  /// The open strategy itself (in-app browser view, then an external
  /// app, then this message) mirrors pilares/sanlo's own
  /// `open_link.dart` -- kept self-contained here, rather than
  /// depending on either app's copy, so this widget works standalone
  /// with no other extraction phase landed yet.
  final String Function(String url)? failedToOpenMessage;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    ).catchError((_) => false);
    if (opened) return;

    final fellBack = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    if (!fellBack && context.mounted) {
      final message = failedToOpenMessage?.call(url) ?? 'Could not open $url';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showQr(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // A white plate under the QR regardless of theme: a
              // dark-themed background would otherwise sit directly
              // behind the code and confuse a scanner expecting a
              // light quiet zone.
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: QrImageView(data: url, size: 220),
              ),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      tileColor: tileColor,
      contentPadding: contentPadding,
      onTap: () => _open(context),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: shareTooltip,
            onPressed: () => onShare(url),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: qrTooltip,
            onPressed: () => _showQr(context),
          ),
        ],
      ),
    );
  }
}
