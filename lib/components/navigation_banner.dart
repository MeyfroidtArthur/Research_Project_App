import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class NavigationBanner extends StatelessWidget {
  const NavigationBanner({
    super.key,
    required this.targetName,
    required this.isCalculating,
    required this.etaText,
    required this.onClose,
    this.maxWidth,
  });

  final String targetName;
  final bool isCalculating;
  final String? etaText;
  final VoidCallback onClose;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final availableWidth = maxWidth ?? MediaQuery.of(context).size.width - 24;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(maxWidth: availableWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.navigation, color: FlutterFlowTheme.of(context).primary),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Navigating to $targetName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCalculating
                      ? 'Calculating route...'
                      : 'ETA ${etaText ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Inter',
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
            color: FlutterFlowTheme.of(context).secondaryText,
          ),
        ],
      ),
    );
  }
}
