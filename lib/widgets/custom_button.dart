import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isText;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final double? borderRadius;
  final EdgeInsets? padding;
  final IconData? icon;
  final bool iconTrailing;
  final bool fullWidth;
  final bool disabled;
  final String? tooltip;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isText = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
    this.icon,
    this.iconTrailing = false,
    this.fullWidth = false,
    this.disabled = false,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onPressed == null || isLoading;
    
    Widget button = _buildButton(isDisabled);
    
    if (tooltip != null && !isDisabled) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }
    
    return button;
  }

  Widget _buildButton(bool isDisabled) {
    if (isText) {
      return _buildTextButton(isDisabled);
    } else if (isOutlined) {
      return _buildOutlinedButton(isDisabled);
    } else {
      return _buildFilledButton(isDisabled);
    }
  }

  Widget _buildFilledButton(bool isDisabled) {
    return Container(
      width: fullWidth ? double.infinity : width,
      height: height ?? AppSizes.buttonHeightMd,
      decoration: BoxDecoration(
        color: isDisabled 
            ? AppColors.greyLight 
            : (backgroundColor ?? AppColors.primary),
        borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.radiusMd),
        boxShadow: isDisabled ? null : [
          BoxShadow(
            color: (backgroundColor ?? AppColors.primary).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.radiusMd),
          child: _buildButtonContent(),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(bool isDisabled) {
    return Container(
      width: fullWidth ? double.infinity : width,
      height: height ?? AppSizes.buttonHeightMd,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.radiusMd),
        border: Border.all(
          color: isDisabled 
              ? AppColors.greyLight 
              : (borderColor ?? AppColors.primary),
              width: 2,
            ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.radiusMd),
          child: _buildButtonContent(),
        ),
        ),
      );
    }

  Widget _buildTextButton(bool isDisabled) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.radiusMd),
        child: Container(
          width: fullWidth ? double.infinity : width,
          height: height ?? AppSizes.buttonHeightMd,
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          child: _buildButtonContent(),
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    return Center(
      child: isLoading 
          ? _buildLoadingContent()
          : _buildNormalContent(),
    );
  }

  Widget _buildLoadingContent() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isOutlined || isText 
                  ? (textColor ?? AppColors.primary)
                  : Colors.white,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
          Text(
          'Loading...',
          style: TextStyle(
            color: _getTextColor(),
            fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

  Widget _buildNormalContent() {
    final content = <Widget>[];
    
    if (icon != null && !iconTrailing) {
      content.addAll([
        Icon(
          icon,
          size: 20,
          color: _getTextColor(),
        ),
        const SizedBox(width: AppSizes.sm),
      ]);
    }
    
    content.add(
      Flexible(
        child: Text(
            text,
          style: TextStyle(
            color: _getTextColor(),
            fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    
    if (icon != null && iconTrailing) {
      content.addAll([
        const SizedBox(width: AppSizes.sm),
        Icon(
          icon,
          size: 20,
          color: _getTextColor(),
        ),
      ]);
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: content,
    );
  }

  Color _getTextColor() {
    if (textColor != null) return textColor!;
    
    if (isOutlined) {
      return AppColors.primary;
    } else if (isText) {
      return AppColors.primary;
    } else {
      return Colors.white;
    }
  }
}

// Specialized button variants
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool fullWidth;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.icon,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: AppColors.primary,
      width: width,
      height: height,
      icon: icon,
      fullWidth: fullWidth,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool fullWidth;

  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.icon,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isOutlined: true,
      borderColor: AppColors.secondary,
      textColor: AppColors.secondary,
      width: width,
      height: height,
      icon: icon,
      fullWidth: fullWidth,
    );
  }
}

class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool fullWidth;

  const DangerButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.icon,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: AppColors.error,
      width: width,
      height: height,
      icon: icon,
      fullWidth: fullWidth,
    );
  }
}

class SuccessButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool fullWidth;

  const SuccessButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.icon,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: AppColors.success,
      width: width,
      height: height,
      icon: icon,
      fullWidth: fullWidth,
    );
  }
}

class TextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? textColor;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool fullWidth;

  const TextButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.textColor,
    this.width,
    this.height,
    this.icon,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isText: true,
      textColor: textColor ?? AppColors.primary,
      width: width,
      height: height,
      icon: icon,
      fullWidth: fullWidth,
    );
  }
}
