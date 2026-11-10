// import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Provides reusable widget builders for displaying table headers and cells.
class TableWidgets {
  /// Builds a table header cell with configurable text size, weight, padding,
  /// and horizontal space allocation.
  ///
  /// The [flex] value determines how much horizontal space the cell occupies
  /// relative to other Expanded widgets in the same row.
  static Widget tableHeaderCell({
    required String text,
    required double maxFontSize,
    required double minFontSize,
    int flex = 1,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: padding,
        child: autoSizeText(
          text: text,
          maxFontSize: maxFontSize,
          minFontSize: minFontSize,
          fontWeightBold: true,
        ),
      ),
    );
  }

  /// Builds a regular table cell containing text.
  ///
  /// The [flex] parameter controls the cell's horizontal space allocation,
  /// while [maxFontSize] and [minFontSize] are passed to [autoSizeText].
  static Widget tableRowCell({
    required String text,
    int flex = 1,
    double maxFontSize = 18,
    double minFontSize = 12,
  }) {
    return Expanded(
      flex: flex,
      child: autoSizeText(
        text: text,
        maxFontSize: maxFontSize,
        minFontSize: minFontSize,
      ),
    );
  }

  /// Builds a text widget used inside table cells.
  ///
  /// Supports bold text and limits the content to two lines. Additional text
  /// is truncated with an ellipsis when it exceeds the available space.
  static Widget autoSizeText({
    required String text,
    required double maxFontSize,
    required double minFontSize,
    bool fontWeightBold = false,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontSize: maxFontSize,
        fontWeight: fontWeightBold ? FontWeight.bold : null,
      ),
      maxLines: 2,
      // minFontSize: minFontSize,
      overflow: TextOverflow.ellipsis,
    );
    // Previous implementation using AutoSizeText, which supported automatic
    // font-size adjustment between the specified minimum and maximum sizes.
    // return AutoSizeText(
    //   text,
    //   style: TextStyle(
    //     fontSize: maxFontSize,
    //     fontWeight: fontWeightBold ? FontWeight.bold : null,
    //   ),
    //   maxLines: 2,
    //   minFontSize: minFontSize,
    //   overflow: TextOverflow.ellipsis,
    // );
  }

  /// Builds a table cell that displays its full text in a tooltip when hovered.
  ///
  /// The visible text is limited to one line and truncated with an ellipsis
  /// if it exceeds the available width. An empty string displays the
  /// localized 'no_description' message in the tooltip.
  static Widget tableRowCellWithTooltip({
    required String text,
    int flex = 1,
    double maxFontSize = 16,
    double minFontSize = 12,
  }) {
    return Expanded(
      flex: flex,
      child: Tooltip(
        message: text.isEmpty ? 'no_description'.tr : text,
        waitDuration: Duration(milliseconds: 300),
        showDuration: Duration(seconds: 4),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: maxFontSize),
        ),
      ),
    );
  }
}
