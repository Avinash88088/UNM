import 'package:flutter/material.dart';
import '../utils/constants.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color? backgroundColor;
  final Color? loadingColor;
  final String? loadingText;
  final double? opacity;
  final bool dismissible;
  final VoidCallback? onDismiss;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.backgroundColor,
    this.loadingColor,
    this.loadingText,
    this.opacity,
    this.dismissible = false,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return GestureDetector(
      onTap: dismissible ? onDismiss : null,
      child: Container(
        color: (backgroundColor ?? Colors.black).withOpacity(opacity ?? 0.5),
        child: Center(
          child: _buildLoadingContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Container(
      padding: EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                loadingColor ?? AppColors.primary,
              ),
            ),
          ),
          if (loadingText != null) ...[
            SizedBox(height: AppSizes.md),
            Text(
              loadingText!,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final VoidCallback? onPressed;
  final Color? loadingColor;
  final String? loadingText;
  final double? size;

  const LoadingButton({
    Key? key,
    required this.isLoading,
    required this.child,
    this.onPressed,
    this.loadingColor,
    this.loadingText,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }
    return child;
  }

  Widget _buildLoadingState() {
    return Container(
      width: size ?? 24,
      height: size ?? 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          loadingColor ?? AppColors.primary,
        ),
      ),
    );
  }
}

class LoadingCard extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final double? height;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const LoadingCard({
    Key? key,
    required this.isLoading,
    required this.child,
    this.height,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingCard();
    }
    return child;
  }

  Widget _buildLoadingCard() {
    return Container(
      height: height,
      padding: padding ?? EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(height: AppSizes.sm),
          Text(
            'Loading...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingList extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final int itemCount;
  final double? itemHeight;
  final EdgeInsets? itemPadding;
  final Color? backgroundColor;

  const LoadingList({
    Key? key,
    required this.isLoading,
    required this.child,
    this.itemCount = 5,
    this.itemHeight,
    this.itemPadding,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingList();
    }
    return child;
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return _buildLoadingItem();
      },
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      height: itemHeight ?? 80,
      margin: itemPadding ?? EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            // Loading avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            SizedBox(width: AppSizes.md),
            // Loading content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Loading title
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.greyLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  SizedBox(height: AppSizes.sm),
                  // Loading subtitle
                  Container(
                    height: 12,
                    width: 200, // Fixed width instead of MediaQuery
                    decoration: BoxDecoration(
                      color: AppColors.greyLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingGrid extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final int crossAxisCount;
  final int itemCount;
  final double? itemHeight;
  final EdgeInsets? itemPadding;
  final Color? backgroundColor;

  const LoadingGrid({
    Key? key,
    required this.isLoading,
    required this.child,
    this.crossAxisCount = 2,
    this.itemCount = 6,
    this.itemHeight,
    this.itemPadding,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingGrid();
    }
    return child;
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.0,
        crossAxisSpacing: AppSizes.sm,
        mainAxisSpacing: AppSizes.sm,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return _buildLoadingGridItem();
      },
    );
  }

  Widget _buildLoadingGridItem() {
    return Container(
      height: itemHeight,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            SizedBox(height: AppSizes.sm),
            // Loading text
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final Color? loadingColor;
  final bool barrierDismissible;

  const LoadingDialog({
    Key? key,
    this.title,
    this.message,
    this.loadingColor,
    this.barrierDismissible = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => barrierDismissible,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.md),
              ],
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    loadingColor ?? AppColors.primary,
                  ),
                ),
              ),
              if (message != null) ...[
                SizedBox(height: AppSizes.md),
                Text(
                  message!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    String? title,
    String? message,
    Color? loadingColor,
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => LoadingDialog(
        title: title,
        message: message,
        loadingColor: loadingColor,
        barrierDismissible: barrierDismissible,
      ),
    );
  }
}
