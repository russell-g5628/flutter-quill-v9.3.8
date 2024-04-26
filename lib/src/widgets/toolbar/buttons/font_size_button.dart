import 'package:flutter/material.dart';

import '../../../../extensions.dart';
import '../../../extensions/quill_configurations_ext.dart';
import '../../../l10n/extensions/localizations.dart';
import '../../../models/documents/attribute.dart';
import '../../../models/themes/quill_icon_theme.dart';
import '../../../utils/font.dart';
import '../../quill/quill_controller.dart';
import '../base_toolbar.dart';

class QuillToolbarFontSizeButton extends StatefulWidget {
  QuillToolbarFontSizeButton({
    required this.controller,
    @Deprecated('Please use the default display text from the options') this.defaultDisplayText,
    this.options = const QuillToolbarFontSizeButtonOptions(),
    this.isIconBottom = false,
    super.key,
  })  : assert(options.rawItemsMap?.isNotEmpty ?? true),
        assert(options.initialValue == null || (options.initialValue?.isNotEmpty ?? true));

  final QuillToolbarFontSizeButtonOptions options;

  final String? defaultDisplayText;

  /// Since we can't get the state from the instace of the widget for comparing
  /// in [didUpdateWidget] then we will have to store reference here
  final QuillController controller;

  bool isIconBottom = false;

  @override
  QuillToolbarFontSizeButtonState createState() => QuillToolbarFontSizeButtonState();
}

class QuillToolbarFontSizeButtonState
    extends State<QuillToolbarFontSizeButton> {
  final _menuController = MenuController();
  final _menuKey = GlobalKey();
  String _currentValue = '';
  ScrollController? scrollController;

  QuillToolbarFontSizeButtonOptions get options {
    return widget.options;
  }

  Map<String, String> get rawItemsMap {
    final fontSizes = options.rawItemsMap ??
        context.quillSimpleToolbarConfigurations?.fontSizesValues ??
        {
          context.loc.small: 'small',
          context.loc.large: 'large',
          context.loc.huge: 'huge',
          context.loc.clear: '0'
        };
    return fontSizes;
  }

  String? getLabel(String? currentValue) {
    return switch (currentValue) {
      'small' => context.loc.small,
      'large' => context.loc.large,
      'huge' => context.loc.huge,
      String() => currentValue,
      null => null,
    };
  }

  String get _defaultDisplayText {
    return options.initialValue ??
        widget.options.defaultDisplayText ??
        widget.defaultDisplayText ??
        context.loc.fontSize;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentValue = _defaultDisplayText;
  }

  @override
  void dispose() {
    scrollController?.dispose();
    super.dispose();
  }

  String? _getKeyName(dynamic value) {
    for (final entry in rawItemsMap.entries) {
      if (getFontSize(entry.value) == getFontSize(value)) {
        return entry.key;
      }
    }
    return null;
  }

  QuillController get controller {
    return widget.controller;
  }

  double get iconSize {
    final baseFontSize = context.quillToolbarBaseButtonOptions?.iconSize;
    final iconSize = options.iconSize;
    return iconSize ?? baseFontSize ?? kDefaultIconSize;
  }

  double get iconButtonFactor {
    final baseIconFactor =
        context.quillToolbarBaseButtonOptions?.iconButtonFactor;
    final iconButtonFactor = options.iconButtonFactor;
    return iconButtonFactor ?? baseIconFactor ?? kDefaultIconButtonFactor;
  }

  VoidCallback? get afterButtonPressed {
    return options.afterButtonPressed ??
        context.quillToolbarBaseButtonOptions?.afterButtonPressed;
  }

  QuillIconTheme? get iconTheme {
    return options.iconTheme ??
        context.quillToolbarBaseButtonOptions?.iconTheme;
  }

  String get tooltip {
    return options.tooltip ??
        context.quillToolbarBaseButtonOptions?.tooltip ??
        context.loc.fontSize;
  }

  void _onDropdownButtonPressed() {
    if (_menuController.isOpen) {
      _menuController.close();
    } else {
      if (widget.isIconBottom) {
        final position = (_menuKey.currentContext!.findRenderObject() as RenderBox)
            .localToGlobal(Offset.zero); //this is global position

        _menuController.open(
            position: Offset(10, position.dy - MediaQuery.of(context).viewInsets.bottom));
      } else {
        _menuController.open();
      }
    }
    afterButtonPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final baseButtonConfigurations = context.quillToolbarBaseButtonOptions;
    final childBuilder =
        options.childBuilder ?? baseButtonConfigurations?.childBuilder;
    if (childBuilder != null) {
      return childBuilder(
        options,
        QuillToolbarFontSizeButtonExtraOptions(
          controller: controller,
          currentValue: _currentValue,
          defaultDisplayText: _defaultDisplayText,
          context: context,
          onPressed: _onDropdownButtonPressed,
        ),
      );
    }

    scrollController = ScrollController();
    return MenuAnchor(
      key: _menuKey,
      controller: _menuController,
      menuChildren: <Widget>[
        RawScrollbar(
          controller: scrollController,
          padding: const EdgeInsets.all(0),
          child: LimitedBox(
            maxHeight: 256,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                  children: rawItemsMap.entries.map((fontSize) {
                return MenuItemButton(
                  key: ValueKey(fontSize.key),
                  onPressed: () {
                    final newValue = fontSize.value;

                    final keyName = _getKeyName(newValue);
                    setState(() {
                      if (keyName != context.loc.clear) {
                        _currentValue = keyName ?? _defaultDisplayText;
                      } else {
                        _currentValue = _defaultDisplayText;
                      }
                      if (keyName != null) {
                        controller.formatSelection(
                          Attribute.fromKeyValue(
                            Attribute.size.key,
                            newValue == '0' ? null : getFontSize(newValue),
                          ),
                        );
                        options.onSelected?.call(newValue);
                      }
                    });

                    if (fontSize.value == '0') {
                      controller.selectFontSize(null);
                      return;
                    }
                    controller.selectFontSize(fontSize);
                  },
                  child: Text(
                    fontSize.key.toString(),
                    style: TextStyle(
                      color: fontSize.value == '0' ? options.defaultItemColor : null,
                    ),
                  ),
                );
              }).toList()),
            ),
          ),
        )
      ],
      child: Builder(
        builder: (context) {
          final isMaterial3 = Theme.of(context).useMaterial3;
          if (!isMaterial3) {
            return RawMaterialButton(
              onPressed: _onDropdownButtonPressed,
              child: _buildContent(context),
            );
          }
          return QuillToolbarIconButton(
            tooltip: tooltip,
            isSelected: false,
            iconTheme: iconTheme,
            onPressed: _onDropdownButtonPressed,
            icon: _buildContent(context),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final hasFinalWidth = options.width != null;
    return Padding(
      padding: options.padding ?? const EdgeInsets.fromLTRB(10, 0, 0, 0),
      child: Row(
        mainAxisSize: !hasFinalWidth ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          UtilityWidgets.maybeWidget(
            enabled: hasFinalWidth,
            wrapper: (child) => Expanded(child: child),
            child: Text(
              getLabel(widget.controller.selectedFontSize?.key) ??
                  getLabel(_currentValue) ??
                  '',
              overflow: options.labelOverflow,
              style: options.style ??
                  TextStyle(
                    fontSize: iconSize / 1.15,
                  ),
            ),
          ),
          Icon(
            Icons.arrow_drop_down,
            size: iconSize * iconButtonFactor,
          )
        ],
      ),
    );
  }
}
