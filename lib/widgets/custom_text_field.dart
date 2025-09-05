import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool isPassword;
  final bool isPasswordVisible;
  final ValueChanged<bool>? onPasswordVisibilityChanged;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool showCounter;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final bool expands;
  final TextAlign textAlign;
  final TextAlignVertical textAlignVertical;
  final EdgeInsets? contentPadding;
  final double? width;
  final double? height;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final double? borderWidth;
  final bool filled;
  final bool isDense;
  final bool isCollapsed;
  final String? counterText;
  final Widget? counter;
  final String? restorationId;
  final bool enableInteractiveSelection;
  final bool enableSuggestions;
  final bool autocorrect;
  final bool enableIMEPersonalizedLearning;
  final MouseCursor? mouseCursor;
  final String? obscuringCharacter;
  final bool scribbleEnabled;
  final bool canRequestFocus;
  final SpellCheckConfiguration? spellCheckConfiguration;
  final TextMagnifierConfiguration? magnifierConfiguration;
  final UndoHistoryController? undoController;
  final bool cursorOpacityAnimates;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final Color? cursorErrorColor;
  final double? cursorWidth;
  final double? cursorHeight;
  final TextSelectionControls? selectionControls;
  final bool showCursor;
  final bool showSelectionHandles;
  final bool selectionEnabled;
  final DragStartBehavior dragStartBehavior;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;
  final Iterable<String>? autofillHints;
  final Clip clipBehavior;
  final bool scribbleEnabledIOS;
  final bool canRequestFocusIOS;
  final AutovalidateMode? autovalidateMode;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  const CustomTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onPasswordVisibilityChanged,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.showCounter = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.inputFormatters,
    this.expands = false,
    this.textAlign = TextAlign.start,
    this.textAlignVertical = TextAlignVertical.center,
    this.contentPadding,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.borderWidth,
    this.filled = true,
    this.isDense = false,
    this.isCollapsed = false,
    this.counterText,
    this.counter,
    this.restorationId,
    this.enableInteractiveSelection,
    this.enableSuggestions,
    this.autocorrect,
    this.enableIMEPersonalizedLearning,
    this.mouseCursor,
    this.obscuringCharacter,
    this.scribbleEnabled,
    this.canRequestFocus,
    this.spellCheckConfiguration,
    this.magnifierConfiguration,
    this.undoController,
    this.cursorOpacityAnimates,
    this.cursorRadius,
    this.cursorColor,
    this.cursorErrorColor,
    this.cursorWidth,
    this.cursorHeight,
    this.selectionControls,
    this.showCursor,
    this.showSelectionHandles,
    this.selectionEnabled,
    this.dragStartBehavior,
    this.scrollController,
    this.scrollPhysics,
    this.autofillHints,
    this.clipBehavior,
    this.scribbleEnabledIOS,
    this.canRequestFocusIOS,
    this.autovalidateMode,
    this.keyboardDismissBehavior,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height ?? AppSizes.inputHeightMd,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        obscureText: widget.isPassword ? !widget.isPasswordVisible : widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        maxLength: widget.maxLength,
        showCounter: widget.showCounter,
        validator: widget.validator,
        onChanged: (value) {
          setState(() {
            _hasError = false;
          });
          widget.onChanged?.call(value);
        },
        onFieldSubmitted: widget.onSubmitted,
        onTap: widget.onTap,
        inputFormatters: widget.inputFormatters,
        expands: widget.expands,
        textAlign: widget.textAlign,
        textAlignVertical: widget.textAlignVertical,
        autofillHints: widget.autofillHints,
        clipBehavior: widget.clipBehavior,
        restorationId: widget.restorationId,
        enableInteractiveSelection: widget.enableInteractiveSelection,
        enableSuggestions: widget.enableSuggestions,
        autocorrect: widget.autocorrect,
        enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
        mouseCursor: widget.mouseCursor,
        obscuringCharacter: widget.obscuringCharacter,
        scribbleEnabled: widget.scribbleEnabled,
        canRequestFocus: widget.canRequestFocus,
        spellCheckConfiguration: widget.spellCheckConfiguration,
        magnifierConfiguration: widget.magnifierConfiguration,
        undoController: widget.undoController,
        cursorOpacityAnimates: widget.cursorOpacityAnimates,
        cursorRadius: widget.cursorRadius,
        cursorColor: widget.cursorColor,
        cursorErrorColor: widget.cursorErrorColor,
        cursorWidth: widget.cursorWidth,
        cursorHeight: widget.cursorHeight,
        selectionControls: widget.selectionControls,
        showCursor: widget.showCursor,
        showSelectionHandles: widget.showSelectionHandles,
        selectionEnabled: widget.selectionEnabled,
        dragStartBehavior: widget.dragStartBehavior,
        scrollController: widget.scrollController,
        scrollPhysics: widget.scrollPhysics,
        scribbleEnabledIOS: widget.scribbleEnabledIOS,
        canRequestFocusIOS: widget.canRequestFocusIOS,
        autovalidateMode: widget.autovalidateMode,
        keyboardDismissBehavior: widget.keyboardDismissBehavior,
          decoration: InputDecoration(
          hintText: widget.hintText,
          labelText: widget.labelText,
          helperText: widget.helperText,
          errorText: widget.errorText,
          prefixIcon: widget.prefixIcon != null
                ? Icon(
                  widget.prefixIcon,
                  color: _getIconColor(),
                    size: 20,
                  )
                : null,
          suffixIcon: _buildSuffixIcon(),
          filled: widget.filled,
          fillColor: _getBackgroundColor(),
          isDense: widget.isDense,
          isCollapsed: widget.isCollapsed,
          contentPadding: widget.contentPadding ??
              EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
          counterText: widget.counterText,
          counter: widget.counter,
          border: _buildBorder(),
          enabledBorder: _buildBorder(),
          focusedBorder: _buildBorder(isFocused: true),
          errorBorder: _buildBorder(hasError: true),
          focusedErrorBorder: _buildBorder(isFocused: true, hasError: true),
          disabledBorder: _buildBorder(isDisabled: true),
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          widget.isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          color: _getIconColor(),
          size: 20,
        ),
        onPressed: () {
          widget.onPasswordVisibilityChanged?.call(!widget.isPasswordVisible);
        },
      );
    } else if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          color: _getIconColor(),
          size: 20,
        ),
        onPressed: widget.onSuffixIconPressed,
      );
    }
    return null;
  }

  OutlineInputBorder _buildBorder({
    bool isFocused = false,
    bool hasError = false,
    bool isDisabled = false,
  }) {
    Color borderColor;
    double borderWidth = widget.borderWidth ?? 1.5;

    if (isDisabled) {
      borderColor = AppColors.greyLight;
    } else if (hasError) {
      borderColor = widget.errorBorderColor ?? AppColors.error;
    } else if (isFocused) {
      borderColor = widget.focusedBorderColor ?? AppColors.primary;
      borderWidth = 2.0;
    } else {
      borderColor = widget.borderColor ?? AppColors.border;
    }

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius ?? AppSizes.radiusMd),
              borderSide: BorderSide(
        color: borderColor,
        width: borderWidth,
      ),
    );
  }

  Color _getBackgroundColor() {
    if (!widget.enabled) {
      return AppColors.greyLight;
    }
    return widget.backgroundColor ?? AppColors.surface;
  }

  Color _getIconColor() {
    if (!widget.enabled) {
      return AppColors.textDisabled;
    }
    if (_hasError) {
      return AppColors.error;
    }
    if (_isFocused) {
      return AppColors.primary;
    }
    return AppColors.textSecondary;
  }
}

// Specialized text field variants
class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;

  const EmailTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      hintText: hintText ?? 'Enter your email',
      labelText: labelText ?? 'Email',
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      prefixIcon: Icons.email_outlined,
      validator: validator ?? Validators.email,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      autofocus: autofocus,
      focusNode: focusNode,
      autofillHints: [AutofillHints.email],
    );
  }
}

class PasswordTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool isPasswordVisible;
  final ValueChanged<bool>? onPasswordVisibilityChanged;

  const PasswordTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.isPasswordVisible = false,
    this.onPasswordVisibilityChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      hintText: hintText ?? 'Enter your password',
      labelText: labelText ?? 'Password',
      isPassword: true,
      isPasswordVisible: isPasswordVisible,
      onPasswordVisibilityChanged: onPasswordVisibilityChanged,
      textInputAction: TextInputAction.done,
      prefixIcon: Icons.lock_outlined,
      validator: validator ?? Validators.password,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      autofocus: autofocus,
      focusNode: focusNode,
      autofillHints: [AutofillHints.password],
    );
  }
}

class SearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool enabled;
  final bool autofocus;

  const SearchTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.enabled = true,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      hintText: hintText ?? 'Search...',
      prefixIcon: Icons.search,
      suffixIcon: controller?.text.isNotEmpty == true ? Icons.clear : null,
      onSuffixIconPressed: controller?.text.isNotEmpty == true ? onClear : null,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      autofillHints: [AutofillHints.searchQuery],
    );
  }
}

class NumberTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final double? min;
  final double? max;
  final int? decimalPlaces;

  const NumberTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.min,
    this.max,
    this.decimalPlaces,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      hintText: hintText ?? 'Enter a number',
      labelText: labelText ?? 'Number',
      keyboardType: TextInputType.numberWithOptions(decimal: decimalPlaces != null),
      textInputAction: TextInputAction.next,
      prefixIcon: Icons.numbers,
      validator: validator ?? (value) => Validators.number(value, min: min, max: max),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      autofocus: autofocus,
      focusNode: focusNode,
      inputFormatters: [
        if (decimalPlaces != null)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,$decimalPlaces}'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }
}
