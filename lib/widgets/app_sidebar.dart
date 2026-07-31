import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AppSidebar extends StatelessWidget {
  final UserModel user;
  final bool isDarkMode;
  final bool isEn;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onOpenProfile;
  final VoidCallback? onStartAssessment;
  final VoidCallback? onViewResults;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  final List<String> tickedClasses;
  final String selectedClass;
  final Function(String)? onClassSelected;

  const AppSidebar({
    super.key,
    required this.user,
    required this.isDarkMode,
    required this.isEn,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onOpenProfile,
    this.onStartAssessment,
    this.onViewResults,
    required this.onToggleTheme,
    required this.onToggleLanguage,
    this.tickedClasses = const [],
    this.selectedClass = '1ère TI',
    this.onClassSelected,
  });

  Widget _navTile({
    required int index,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        selected: isSelected,
        selectedTileColor: const Color(0xFF006A4E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF34D399) : Colors.white70,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        onTap: onTap ?? () => onItemSelected(index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classes = tickedClasses.isNotEmpty ? tickedClasses : ['1ère TI', 'Terminale TI'];
    final roleLabel = user.role.toUpperCase();

    final initials = user.fullName.trim().split(' ')
        .take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    final Color _sidebarBg = isDarkMode ? const Color(0xFF0B132B) : const Color(0xFF0F172A);
    final Color _cardBg    = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFF1E293B);

    return Container(
      width: 260,
      color: _sidebarBg,
      child: Column(
        children: [
          // 1. BRANDING HEADER (LOGO + APP NAME)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/minesec_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, _, __) => const Icon(Icons.school_rounded, color: Color(0xFF006A4E), size: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EDU PROFILE',
                      style: TextStyle(
                        color: Color(0xFFFCD116),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      isEn ? 'MINESEC Cameroon' : 'MINESEC Cameroun',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // 2. NAVIGATION MENU LINKS
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              children: [
                // STUDENT SPECIFIC LINKS
                if (user.isStudent) ...[
                  _navTile(
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    label: isEn ? 'Dashboard Overview' : 'Tableau de Bord',
                  ),
                  _navTile(
                    index: 1,
                    icon: Icons.assignment_turned_in_rounded,
                    label: isEn ? 'Take Assessment' : 'Passer l\'Évaluation',
                  ),
                  _navTile(
                    index: 2,
                    icon: Icons.analytics_rounded,
                    label: isEn ? 'My Diagnostic Results' : 'Mes Résultats Diagnostics',
                  ),
                ],

                // TEACHER SPECIFIC LINKS
                if (user.isTeacher) ...[
                  _navTile(
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    label: isEn ? 'Dashboard Overview' : 'Tableau de Bord',
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                      childrenPadding: const EdgeInsets.only(left: 16),
                      leading: const Icon(Icons.class_rounded, color: Colors.white70, size: 20),
                      title: Text(
                        isEn ? 'Assigned Classes' : 'Classes Assignées',
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      iconColor: Colors.white70,
                      collapsedIconColor: Colors.white54,
                      children: classes.map((cls) {
                        final isSelected = selectedClass == cls;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            dense: true,
                            selected: isSelected,
                            selectedTileColor: const Color(0xFF006A4E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            leading: Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.check_box_outlined,
                              color: isSelected ? const Color(0xFF34D399) : Colors.white60,
                              size: 16,
                            ),
                            title: Text(
                              cls,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12.5,
                              ),
                            ),
                            onTap: () {
                              onItemSelected(1);
                              if (onClassSelected != null) onClassSelected!(cls);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 3. BOTTOM USER PROFILE CARD (CLEAN)
          InkWell(
            onTap: onOpenProfile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF006A4E),
                    child: Text(
                      initials.isEmpty ? 'U' : initials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          roleLabel,
                          style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
