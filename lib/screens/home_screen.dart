import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/dark_theme.dart';
import '../providers/theme_provider.dart';
import 'upload_screen.dart';
import 'image_editor_screen.dart';
import 'question_generator_screen.dart';
import 'document_viewer_screen.dart';
import 'batch_processing_screen.dart';
import 'dashboard_screen.dart';
import 'theme_customization_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: DarkTheme.mediumAnimation,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: DarkTheme.longAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: DarkTheme.primaryDark,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(DarkTheme.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        _buildHeader(),
                        const SizedBox(height: DarkTheme.spacingL),
                        
                        // Top Action Buttons (2x3 grid)
                        _buildTopActionGrid(),
                        const SizedBox(height: DarkTheme.spacingL),
                        
                        // Quick Actions Section
                        _buildQuickActionsSection(),
                        const SizedBox(height: DarkTheme.spacingL),
                        
                        // Document Cards Grid (3x3)
                        _buildDocumentGrid(),
                        const SizedBox(height: DarkTheme.spacingL),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DarkTheme.spacingM),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DarkTheme.accentBlue,
            DarkTheme.accentPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(DarkTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: DarkTheme.accentBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Master',
                  style: TextStyle(
                    color: DarkTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: DarkTheme.spacingXS),
                Text(
                  'Ready to process your documents with AI?',
                  style: TextStyle(
                    color: DarkTheme.textPrimary.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: DarkTheme.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DarkTheme.spacingS,
                    vertical: DarkTheme.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: DarkTheme.textPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(DarkTheme.radiusS),
                  ),
                  child: const Text(
                    'AI Document Master',
                    style: TextStyle(
                      color: DarkTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DarkTheme.spacingM),
          GestureDetector(
            onTap: () => _showProfileMenu(),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DarkTheme.accentBlue,
                    DarkTheme.accentPurple,
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: DarkTheme.accentBlue.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: DarkTheme.textPrimary,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopActionGrid() {
    final actions = [
      {
        'title': 'Profile',
        'icon': Icons.person,
        'color': DarkTheme.accentGreen,
        'gradient': [DarkTheme.accentGreen, const Color(0xFF66BB6A)],
      },
      {
        'title': 'Messages',
        'icon': Icons.mail,
        'color': DarkTheme.accentBlue,
        'gradient': [DarkTheme.accentBlue, const Color(0xFF42A5F5)],
      },
      {
        'title': 'Documents',
        'icon': Icons.description,
        'color': DarkTheme.accentBlue,
        'gradient': [DarkTheme.accentBlue, const Color(0xFF42A5F5)],
      },
      {
        'title': 'Upload',
        'icon': Icons.upload,
        'color': DarkTheme.accentOrange,
        'gradient': [DarkTheme.accentOrange, const Color(0xFFFFB74D)],
      },
      {
        'title': 'Analytics',
        'icon': Icons.analytics,
        'color': DarkTheme.accentPurple,
        'gradient': [DarkTheme.accentPurple, const Color(0xFFBA68C8)],
      },
      {
        'title': 'AI Tools',
        'icon': Icons.auto_awesome,
        'color': const Color(0xFFE91E63),
        'gradient': [const Color(0xFFE91E63), const Color(0xFFF48FB1)],
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: DarkTheme.spacingS,
        mainAxisSpacing: DarkTheme.spacingS,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * _fadeAnimation.value),
              child: _buildActionButton(
                title: action['title'] as String,
                icon: action['icon'] as IconData,
                gradient: action['gradient'] as List<Color>,
                onTap: () => _handleActionTap(action['title'] as String),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                color: DarkTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DarkTheme.spacingS,
                vertical: DarkTheme.spacingXS,
              ),
              decoration: BoxDecoration(
                color: DarkTheme.accentBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(DarkTheme.radiusS),
              ),
              child: const Text(
                '3 Actions',
                style: TextStyle(
                  color: DarkTheme.accentBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DarkTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'OCR Process',
                Icons.text_fields,
                Icons.arrow_forward,
                [DarkTheme.accentBlue, const Color(0xFF42A5F5)],
              ),
            ),
            const SizedBox(width: DarkTheme.spacingS),
            Expanded(
              child: _buildQuickActionButton(
                'Upload Doc',
                Icons.upload_file,
                Icons.arrow_forward,
                [DarkTheme.accentGreen, const Color(0xFF66BB6A)],
              ),
            ),
            const SizedBox(width: DarkTheme.spacingS),
            Expanded(
              child: _buildQuickActionButton(
                'AI Generate',
                Icons.auto_awesome,
                Icons.arrow_forward,
                [DarkTheme.accentPurple, const Color(0xFFBA68C8)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentGrid() {
    final documents = [
      {
        'title': 'Recent Docs',
        'icon': Icons.description,
        'badge': '5',
        'color': DarkTheme.accentBlue,
        'gradient': [DarkTheme.accentBlue, const Color(0xFF42A5F5)],
      },
      {
        'title': 'Tables',
        'icon': Icons.table_chart,
        'badge': null,
        'color': DarkTheme.accentGreen,
        'gradient': [DarkTheme.accentGreen, const Color(0xFF66BB6A)],
      },
      {
        'title': 'AI Network',
        'icon': Icons.account_tree,
        'badge': null,
        'color': DarkTheme.accentPurple,
        'gradient': [DarkTheme.accentPurple, const Color(0xFFBA68C8)],
      },
      {
        'title': 'Settings',
        'icon': Icons.settings,
        'badge': '2',
        'color': DarkTheme.accentOrange,
        'gradient': [DarkTheme.accentOrange, const Color(0xFFFFB74D)],
      },
      {
        'title': 'Desktop',
        'icon': Icons.desktop_windows,
        'badge': null,
        'color': const Color(0xFF607D8B),
        'gradient': [const Color(0xFF607D8B), const Color(0xFF90A4AE)],
      },
      {
        'title': 'Analytics',
        'icon': Icons.bar_chart,
        'badge': '1',
        'color': const Color(0xFFE91E63),
        'gradient': [const Color(0xFFE91E63), const Color(0xFFF48FB1)],
      },
      {
        'title': 'Reports',
        'icon': Icons.assessment,
        'badge': null,
        'color': const Color(0xFF795548),
        'gradient': [const Color(0xFF795548), const Color(0xFFA1887F)],
      },
      {
        'title': 'Archive',
        'icon': Icons.archive,
        'badge': null,
        'color': const Color(0xFF9E9E9E),
        'gradient': [const Color(0xFF9E9E9E), const Color(0xFFBDBDBD)],
      },
      {
        'title': 'More',
        'icon': Icons.more_horiz,
        'badge': null,
        'color': const Color(0xFF424242),
        'gradient': [const Color(0xFF424242), const Color(0xFF616161)],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Document Library',
              style: TextStyle(
                color: DarkTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DarkTheme.spacingS,
                vertical: DarkTheme.spacingXS,
              ),
              decoration: BoxDecoration(
                color: DarkTheme.accentBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(DarkTheme.radiusS),
              ),
              child: const Text(
                '9 Categories',
                style: TextStyle(
                  color: DarkTheme.accentBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DarkTheme.spacingM),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: DarkTheme.spacingS,
            mainAxisSpacing: DarkTheme.spacingS,
            childAspectRatio: 1.0,
          ),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            return AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.9 + (0.1 * _fadeAnimation.value),
                  child: _buildDocumentCard(
                    title: doc['title'] as String,
                    icon: doc['icon'] as IconData,
                    badge: doc['badge'] as String?,
                    gradient: doc['gradient'] as List<Color>,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        _animateButtonPress();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(DarkTheme.radiusM),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DarkTheme.spacingS),
              decoration: BoxDecoration(
                color: DarkTheme.textPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(DarkTheme.radiusS),
              ),
              child: Icon(
                icon,
                color: DarkTheme.textPrimary,
                size: 24,
              ),
            ),
            const SizedBox(height: DarkTheme.spacingXS),
            Text(
              title,
              style: const TextStyle(
                color: DarkTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _animateButtonPress() {
    // Add haptic feedback
    // HapticFeedback.lightImpact();
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    IconData arrowIcon,
    List<Color> gradient,
  ) {
    return GestureDetector(
      onTap: () => _handleQuickActionTap(title),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(DarkTheme.radiusM),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(DarkTheme.spacingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DarkTheme.spacingS),
                      decoration: BoxDecoration(
                        color: DarkTheme.textPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(DarkTheme.radiusS),
                      ),
                      child: Icon(
                        icon,
                        color: DarkTheme.textPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: DarkTheme.spacingS),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: DarkTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DarkTheme.spacingS),
              Icon(
                arrowIcon,
                color: DarkTheme.textPrimary.withOpacity(0.8),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required IconData icon,
    String? badge,
    required List<Color> gradient,
  }) {
    return GestureDetector(
      onTap: () => _handleDocumentTap(title),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DarkTheme.secondaryDark,
              DarkTheme.secondaryDark.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(DarkTheme.radiusM),
          border: Border.all(
            color: gradient.first.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(DarkTheme.spacingS),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient,
                      ),
                      borderRadius: BorderRadius.circular(DarkTheme.radiusS),
                    ),
                    child: Icon(
                      icon,
                      color: DarkTheme.textPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: DarkTheme.spacingS),
                  Text(
                    title,
                    style: const TextStyle(
                      color: DarkTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: DarkTheme.spacingXS,
                right: DarkTheme.spacingXS,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: DarkTheme.textPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DarkTheme.primaryDark,
            DarkTheme.secondaryDark,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: DarkTheme.accentBlue.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem('Home', Icons.home, true),
          _buildNavItem('Docs', Icons.folder, false),
          _buildNavItem('Grid', Icons.grid_view, false),
          _buildNavItem('Search', Icons.search, false),
          _buildNavItem('Settings', Icons.settings, false),
          _buildNavItem('Menu', Icons.menu, false),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => _handleNavTap(label),
      child: AnimatedContainer(
        duration: DarkTheme.shortAnimation,
        padding: const EdgeInsets.symmetric(
          horizontal: DarkTheme.spacingS,
          vertical: DarkTheme.spacingXS,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DarkTheme.accentBlue.withOpacity(0.2),
                    DarkTheme.accentPurple.withOpacity(0.2),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(DarkTheme.radiusS),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? DarkTheme.accentBlue : DarkTheme.textMuted,
              size: 22,
            ),
            const SizedBox(height: DarkTheme.spacingXS),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? DarkTheme.accentBlue : DarkTheme.textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    switch (index) {
      case 0:
        // Already on home screen
        break;
      case 1:
        _navigateToScreen(context, UploadScreen());
        break;
      case 2:
        _navigateToScreen(context, DashboardScreen());
        break;
      case 3:
        _navigateToScreen(context, BatchProcessingScreen());
        break;
    }
  }

  void _handleActionTap(String action) {
    switch (action) {
      case 'Profile':
        _showProfileMenu();
        break;
      case 'Messages':
        _navigateToScreen(context, DocumentViewerScreen());
        break;
      case 'Documents':
        _navigateToScreen(context, DocumentViewerScreen());
        break;
      case 'Upload':
        _navigateToScreen(context, UploadScreen());
        break;
      case 'Analytics':
        _navigateToScreen(context, DashboardScreen());
        break;
      case 'AI Tools':
        _navigateToScreen(context, QuestionGeneratorScreen());
        break;
    }
  }

  void _handleQuickActionTap(String action) {
    switch (action) {
      case 'OCR Process':
        _navigateToScreen(context, ImageEditorScreen());
        break;
      case 'Upload Doc':
        _navigateToScreen(context, UploadScreen());
        break;
      case 'AI Generate':
        _navigateToScreen(context, QuestionGeneratorScreen());
        break;
    }
  }

  void _handleDocumentTap(String document) {
    switch (document) {
      case 'Recent Docs':
        _navigateToScreen(context, DocumentViewerScreen());
        break;
      case 'Tables':
        _navigateToScreen(context, DocumentViewerScreen());
        break;
      case 'AI Network':
        _navigateToScreen(context, DashboardScreen());
        break;
      case 'Settings':
        _navigateToScreen(context, ThemeCustomizationScreen());
        break;
      case 'Desktop':
        _navigateToScreen(context, DashboardScreen());
        break;
      case 'Analytics':
        _navigateToScreen(context, DashboardScreen());
        break;
      case 'Reports':
        _navigateToScreen(context, DocumentViewerScreen());
        break;
      case 'Archive':
        _navigateToScreen(context, DocumentViewerScreen());
        break;
      case 'More':
        _showMenu();
        break;
    }
  }

  void _handleNavTap(String nav) {
    switch (nav) {
      case 'Home':
        // Already on home
        break;
      case 'Docs':
        _navigateToScreen(context, DocumentViewerScreen());
        break;
      case 'Grid':
        _navigateToScreen(context, DashboardScreen());
        break;
      case 'Search':
        _navigateToScreen(context, DocumentViewerScreen());
        break;
      case 'Settings':
        _navigateToScreen(context, ThemeCustomizationScreen());
        break;
      case 'Menu':
        _showMenu();
        break;
    }
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DarkTheme.secondaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(DarkTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: DarkTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: DarkTheme.spacingL),
            const Text(
              'Profile Menu',
              style: TextStyle(
                color: DarkTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DarkTheme.spacingL),
            _buildMenuOption('View Profile', Icons.person, () {
              Navigator.pop(context);
              // TODO: Navigate to profile screen
            }),
            _buildMenuOption('Edit Profile', Icons.edit, () {
              Navigator.pop(context);
              // TODO: Navigate to edit profile screen
            }),
            _buildMenuOption('Settings', Icons.settings, () {
              Navigator.pop(context);
              _navigateToScreen(context, ThemeCustomizationScreen());
            }),
            _buildMenuOption('Logout', Icons.logout, () {
              Navigator.pop(context);
              // TODO: Implement logout
            }),
          ],
        ),
      ),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DarkTheme.secondaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(DarkTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: DarkTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: DarkTheme.spacingL),
            const Text(
              'App Menu',
              style: TextStyle(
                color: DarkTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DarkTheme.spacingL),
            _buildMenuOption('Settings', Icons.settings, () {
              Navigator.pop(context);
              _navigateToScreen(context, ThemeCustomizationScreen());
            }),
            _buildMenuOption('Help & Support', Icons.help, () {
              Navigator.pop(context);
              _showHelpDialog();
            }),
            _buildMenuOption('About App', Icons.info, () {
              Navigator.pop(context);
              _showAboutDialog();
            }),
            _buildMenuOption('Rate App', Icons.star, () {
              Navigator.pop(context);
              // TODO: Open app store rating
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: DarkTheme.spacingXS),
      decoration: BoxDecoration(
        color: DarkTheme.primaryDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(DarkTheme.radiusS),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(DarkTheme.spacingS),
          decoration: BoxDecoration(
            color: DarkTheme.accentBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(DarkTheme.radiusS),
          ),
          child: Icon(
            icon,
            color: DarkTheme.accentBlue,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: DarkTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: DarkTheme.textMuted,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DarkTheme.secondaryDark,
        title: const Text(
          'Help & Support',
          style: TextStyle(color: DarkTheme.textPrimary),
        ),
        content: const Text(
          'Need help with AI Document Master? Contact our support team or check our FAQ section.',
          style: TextStyle(color: DarkTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Open support contact
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DarkTheme.secondaryDark,
        title: const Text(
          'About AI Document Master',
          style: TextStyle(color: DarkTheme.textPrimary),
        ),
        content: const Text(
          'Version 1.0.0\n\nAI-powered document processing with OCR, handwriting recognition, and intelligent question generation.',
          style: TextStyle(color: DarkTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
