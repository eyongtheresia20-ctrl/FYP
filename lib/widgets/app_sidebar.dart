import 'package:flutter/material.dart';
import 'app_logo.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

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
  final List? delegateItems;
  final List? adminItems;

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
    this.delegateItems,
    this.adminItems,
  });

  void _closeDrawerIfOpen(BuildContext context) {
    if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
  }

  Widget _navTile({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    final isSelected = selectedIndex == index;
    final effectiveTextColor = isSelected
        ? Colors.white
        : (textColor ?? (isDarkMode ? Colors.white70 : const Color(0xFF0F172A)));
    final effectiveIconColor = isSelected
        ? const Color(0xFF34D399)
        : (iconColor ?? (isDarkMode ? Colors.white70 : const Color(0xFF475569)));

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF006A4E) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [BoxShadow(color: const Color(0xFF006A4E).withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
            : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Icon(
          icon,
          color: effectiveIconColor,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: effectiveTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        onTap: () {
          _closeDrawerIfOpen(context);
          if (onTap != null) {
            onTap();
          } else {
            onItemSelected(index);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> defaultItems = (user.isPrincipal || user.isDeanOfStudies)
        ? ['1ère TI', 'Terminale TI', '2nde C', '1ère C', 'Terminale C']
        : user.isRegionalDelegate
            ? ['DJEREM', 'VINA', 'MAYO-BANYO', 'FARO-ET-DEO', 'MBERE']
            : user.isAdmin
                ? ['ADAMOUA', 'CENTRE', 'LITTORAL', 'NORD', 'EXTREME-NORD', 'OUEST', 'SUD', 'SUD-OUEST', 'NORD-OUEST', 'EST']
                : ['1ère TI', 'Terminale TI'];

    final classes = tickedClasses.isNotEmpty ? tickedClasses : defaultItems;
    final roleLabel = user.isDeanOfStudies
        ? (isEn ? 'DEAN OF STUDIES' : 'CENSEUR / D.E.')
        : user.role.toUpperCase().replaceAll('_', ' ');

    final initials = user.fullName.trim().split(' ')
        .take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    final Color _sidebarBg   = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final Color _cardBg      = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final Color _textColor   = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color _subTextColor= isDarkMode ? Colors.white70 : const Color(0xFF64748B);
    final Color _borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth < 380 ? screenWidth * 0.82 : 270.0;

    return Container(
      width: sidebarWidth,
      color: _sidebarBg,
      child: SafeArea(
        top: true,
        bottom: true,
        child: Column(
          children: [
            // 1. BRANDING HEADER (LOGO + APP NAME) — UNIFORM SEAMLESS
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: _sidebarBg,
              child: Row(
                children: [
                  const AppLogo(size: 46, showGlow: false),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'EDU PROFILE',
                      style: TextStyle(
                        color: isDarkMode ? const Color(0xFFFCD116) : const Color(0xFF006A4E),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 2. NAVIGATION MENU LINKS
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              children: [
                // STUDENT SPECIFIC LINKS
                if (user.isStudent) ...[
                  _navTile(
                    context: context,
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    label: isEn ? 'Dashboard Overview' : 'Tableau de Bord',
                  ),
                  _navTile(
                    context: context,
                    index: 1,
                    icon: Icons.assignment_turned_in_rounded,
                    label: isEn ? 'Take Assessment' : 'Passer l\'Évaluation',
                  ),
                  _navTile(
                    context: context,
                    index: 2,
                    icon: Icons.analytics_rounded,
                    label: isEn ? 'My Diagnostic Results' : 'Mes Résultats Diagnostics',
                  ),
                ],

                // TEACHER SPECIFIC LINKS
                if (user.isTeacher) ...[
                  _navTile(
                    context: context,
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
                      leading: Icon(Icons.class_rounded, color: _subTextColor, size: 20),
                      title: Text(
                        isEn ? 'Assigned Classes' : 'Classes Assignées',
                        style: TextStyle(color: _textColor, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      iconColor: _subTextColor,
                      collapsedIconColor: _subTextColor,
                      children: classes.map((cls) {
                        final isSelected = selectedClass == cls;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF006A4E) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            dense: true,
                            selected: isSelected,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            leading: Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.check_box_outlined,
                              color: isSelected ? const Color(0xFF34D399) : _subTextColor,
                              size: 16,
                            ),
                            title: Text(
                              cls,
                              style: TextStyle(
                                color: isSelected ? Colors.white : _textColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12.5,
                              ),
                            ),
                            onTap: () {
                              _closeDrawerIfOpen(context);
                              onItemSelected(1);
                              if (onClassSelected != null) onClassSelected!(cls);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // PRINCIPAL & DEAN OF STUDIES SPECIFIC LINKS
                if (user.isPrincipal || user.isDeanOfStudies) ...[
                  _navTile(
                    context: context,
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    label: isEn ? 'Dashboard Overview' : 'Tableau de Bord',
                  ),
                  _navTile(
                    context: context,
                    index: 1,
                    icon: Icons.school_rounded,
                    label: isEn ? 'School VARK Analytics' : 'Analyses VARK Établissement',
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: selectedIndex == 2,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                      childrenPadding: const EdgeInsets.only(left: 16),
                      leading: Icon(Icons.class_rounded, color: _subTextColor, size: 20),
                      title: Text(
                        isEn ? 'All School Classes' : 'Classes de l\'Établissement',
                        style: TextStyle(
                          color: selectedIndex == 2 ? const Color(0xFF006A4E) : _textColor,
                          fontSize: 13.5,
                          fontWeight: selectedIndex == 2 ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      iconColor: _subTextColor,
                      collapsedIconColor: _subTextColor,
                      children: classes.map((cls) {
                        final isSelected = selectedIndex == 2 && selectedClass == cls;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF006A4E) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            dense: true,
                            selected: isSelected,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            leading: Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.school_rounded,
                              color: isSelected ? const Color(0xFF34D399) : _subTextColor,
                              size: 16,
                            ),
                            title: Text(
                              'Classe $cls',
                              style: TextStyle(
                                color: isSelected ? Colors.white : _textColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12.5,
                              ),
                            ),
                            onTap: () {
                              _closeDrawerIfOpen(context);
                              onItemSelected(2);
                              if (onClassSelected != null) onClassSelected!(cls);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  _navTile(
                    context: context,
                    index: 4,
                    icon: Icons.manage_accounts_rounded,
                    label: isEn ? 'Manage Students' : 'Gestion des Élèves',
                  ),
                ],

                // REGIONAL DELEGATE SPECIFIC LINKS
                if (user.isRegionalDelegate) ...[
                  _navTile(
                    context: context,
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    label: isEn ? 'Dashboard Overview' : 'Tableau de Bord',
                  ),
                  _navTile(
                    context: context,
                    index: 1,
                    icon: Icons.map_rounded,
                    label: isEn ? 'Regional VARK Analytics' : 'Analyses VARK Régionales',
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: selectedIndex == 2,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                      childrenPadding: const EdgeInsets.only(left: 12),
                      leading: Icon(Icons.location_city_rounded, color: _subTextColor, size: 20),
                      title: Text(
                        isEn ? 'Divisions' : 'Départements',
                        style: TextStyle(
                          color: selectedIndex == 2 ? const Color(0xFF006A4E) : _textColor,
                          fontSize: 13.5,
                          fontWeight: selectedIndex == 2 ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      iconColor: _subTextColor,
                      collapsedIconColor: _subTextColor,
                      children: _buildDelegateChildren(context, _textColor, _subTextColor),
                    ),
                  ),
                ],

                // ADMIN SPECIFIC LINKS
                if (user.isAdmin) ...[
                  _navTile(
                    context: context,
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    label: isEn ? 'Dashboard Overview' : 'Tableau de Bord',
                  ),
                  _navTile(
                    context: context,
                    index: 1,
                    icon: Icons.public_rounded,
                    label: isEn ? 'National VARK Overview' : 'Aperçu National VARK',
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: selectedIndex == 2,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                      childrenPadding: const EdgeInsets.only(left: 16),
                      leading: Icon(Icons.map_rounded, color: _subTextColor, size: 20),
                      title: Text(
                        isEn ? 'Regional Delegations' : 'Délégations Régionales',
                        style: TextStyle(
                          color: selectedIndex == 2 ? const Color(0xFF006A4E) : _textColor,
                          fontSize: 13.5,
                          fontWeight: selectedIndex == 2 ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      iconColor: _subTextColor,
                      collapsedIconColor: _subTextColor,
                      children: _buildAdminChildren(context, _textColor, _subTextColor),
                    ),
                  ),
                  _navTile(
                    context: context,
                    index: 3,
                    icon: Icons.manage_accounts_rounded,
                    label: isEn ? 'User & Security Admin' : 'Gestion Utilisateurs & Sécurité',
                  ),
                ],

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Divider(height: 1, thickness: 0.8),
                ),
                ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.settings_rounded, color: Color(0xFF34D399), size: 20),
                  title: Text(
                    isEn ? 'Settings' : 'Paramètres',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    _closeDrawerIfOpen(context);
                    onOpenProfile();
                  },
                ),
              ],
            ),
          ),

          // 3. BOTTOM USER PROFILE CARD (INTEGRATED LOGOUT)
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    _closeDrawerIfOpen(context);
                    onOpenProfile();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: CircleAvatar(
                    radius: 19,
                    backgroundColor: const Color(0xFF006A4E),
                    child: Text(
                      initials.isEmpty ? 'U' : initials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _closeDrawerIfOpen(context);
                      onOpenProfile();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 12.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          roleLabel,
                          style: TextStyle(color: _subTextColor, fontSize: 10.0),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: isEn ? 'Logout' : 'Déconnexion',
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    icon: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.35)),
                      ),
                      child: const Icon(Icons.logout_rounded, color: Color(0xFFFF5252), size: 16),
                    ),
                    onPressed: () async {
                      _closeDrawerIfOpen(context);
                      await AuthService.logout();
                      if (context.mounted) {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      }
                    },
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

  List<Widget> _buildDelegateChildren(BuildContext context, Color textColor, Color subTextColor) {
    if (user.isRegionalDelegate && delegateItems != null && delegateItems!.isNotEmpty) {
      return delegateItems!.map((divObjRaw) {
        final divObj = Map<String, dynamic>.from(divObjRaw as Map);
        final divName = (divObj['name'] ?? '').toString();
        final isDivSelected = selectedIndex == 2 && selectedClass == divName;

        final rawScList = divObj['schools'] as List? ?? [];
        final divSchools = rawScList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: isDivSelected,
            tilePadding: const EdgeInsets.only(left: 8, right: 8),
            childrenPadding: const EdgeInsets.only(left: 14),
            leading: Icon(
              isDivSelected ? Icons.check_circle_rounded : Icons.location_city_rounded,
              color: isDivSelected ? const Color(0xFF34D399) : subTextColor,
              size: 16,
            ),
            title: Text(
              divName,
              style: TextStyle(
                color: isDivSelected ? const Color(0xFF006A4E) : textColor,
                fontWeight: isDivSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            iconColor: subTextColor,
            collapsedIconColor: subTextColor,
            children: divSchools.map((scObj) {
              final scName = (scObj['name'] ?? '').toString();
              final isSelected = selectedIndex == 2 && (selectedClass == scName || selectedClass.endsWith('::$scName'));

              return Container(
                margin: const EdgeInsets.only(bottom: 2),
                child: ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.school_rounded,
                    color: isSelected ? const Color(0xFF34D399) : subTextColor,
                    size: 15,
                  ),
                  title: Text(
                    scName,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF34D399) : textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 11.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    _closeDrawerIfOpen(context);
                    onItemSelected(2);
                    if (onClassSelected != null) {
                      onClassSelected!('$divName::$scName');
                    }
                  },
                ),
              );
            }).toList(),
          ),
        );
      }).toList();
    }

    return (tickedClasses.isNotEmpty ? tickedClasses : ['LYCEE TECHNIQUE DE NGAOUNDAL', 'LYCEE CLASSIQUE DE NGAOUNDAL', 'LYCEE BILINGUE DE NGAOUNDAL']).map((scItem) {
      final isSelected = selectedIndex == 2 && selectedClass == scItem;
      return Container(
        margin: const EdgeInsets.only(bottom: 2),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          leading: Icon(
            isSelected ? Icons.check_circle_rounded : Icons.school_rounded,
            color: isSelected ? const Color(0xFF34D399) : subTextColor,
            size: 15,
          ),
          title: Text(
            scItem,
            style: TextStyle(
              color: isSelected ? const Color(0xFF34D399) : textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 11.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            _closeDrawerIfOpen(context);
            onItemSelected(2);
            if (onClassSelected != null) onClassSelected!(scItem);
          },
        ),
      );
    }).toList();
  }

  List<Widget> _buildAdminChildren(BuildContext context, Color textColor, Color subTextColor) {
    if (adminItems != null && adminItems!.isNotEmpty) {
      return adminItems!.map((regObjRaw) {
        final regObj = Map<String, dynamic>.from(regObjRaw as Map);
        final regName = (regObj['name'] ?? '').toString();
        final isRegSelected = selectedIndex == 2 && selectedClass == regName;

        final rawDivList = regObj['divisions'] as List? ?? [];
        final regDivisions = rawDivList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: isRegSelected,
            tilePadding: const EdgeInsets.only(left: 8, right: 8),
            childrenPadding: const EdgeInsets.only(left: 12),
            leading: Icon(
              isRegSelected ? Icons.check_circle_rounded : Icons.map_rounded,
              color: isRegSelected ? const Color(0xFF34D399) : subTextColor,
              size: 16,
            ),
            title: Text(
              'Région $regName',
              style: TextStyle(
                color: isRegSelected ? const Color(0xFF006A4E) : textColor,
                fontWeight: isRegSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            iconColor: subTextColor,
            collapsedIconColor: subTextColor,
            children: regDivisions.isNotEmpty
                ? regDivisions.map((divObj) {
                    final divName = (divObj['name'] ?? '').toString();
                    final rawScList = divObj['schools'] as List? ?? [];
                    final divSchools = rawScList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

                    return Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.only(left: 8, right: 8),
                        childrenPadding: const EdgeInsets.only(left: 12),
                        leading: Icon(Icons.location_city_rounded, color: subTextColor, size: 15),
                        title: Text(
                          'Dép: $divName',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.0,
                          ),
                        ),
                        iconColor: subTextColor,
                        collapsedIconColor: subTextColor,
                        children: divSchools.isNotEmpty
                            ? divSchools.map((scObj) {
                                final scName = (scObj['name'] ?? '').toString();
                                final isSelected = selectedIndex == 2 && (selectedClass == scName || selectedClass.endsWith('::$scName'));

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 2),
                                  child: ListTile(
                                    dense: true,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    leading: Icon(
                                      isSelected ? Icons.check_circle_rounded : Icons.school_rounded,
                                      color: isSelected ? const Color(0xFF34D399) : subTextColor,
                                      size: 14,
                                    ),
                                    title: Text(
                                      scName,
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFF34D399) : textColor,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 11.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () {
                                      _closeDrawerIfOpen(context);
                                      onItemSelected(2);
                                      if (onClassSelected != null) {
                                        onClassSelected!('$regName::$divName::$scName');
                                      }
                                    },
                                  ),
                                );
                              }).toList()
                            : [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  child: Text(
                                    isEn ? '(No schools in DB)' : '(Aucun établissement en BD)',
                                    style: TextStyle(color: subTextColor, fontSize: 10.5, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                      ),
                    );
                  }).toList()
                : [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Text(
                        isEn ? '(No divisions in DB)' : '(Aucun département en BD)',
                        style: TextStyle(color: subTextColor, fontSize: 10.5, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
          ),
        );
      }).toList();
    }

    return (tickedClasses.isNotEmpty ? tickedClasses : ['ADAMOUA', 'CENTRE', 'EST', 'EXTREME-NORD', 'LITTORAL', 'NORD', 'NORD-OUEST', 'OUEST', 'SUD', 'SUD-OUEST']).map((reg) {
      final isSelected = selectedIndex == 2 && selectedClass == reg;
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: ListTile(
          dense: true,
          selected: isSelected,
          selectedTileColor: const Color(0xFF006A4E).withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Icon(
            isSelected ? Icons.check_circle_rounded : Icons.map_rounded,
            color: isSelected ? const Color(0xFF34D399) : subTextColor,
            size: 16,
          ),
          title: Text(
            'Région: $reg',
            style: TextStyle(
              color: isSelected ? const Color(0xFF006A4E) : textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12.0,
            ),
          ),
          onTap: () {
            _closeDrawerIfOpen(context);
            onItemSelected(2);
            if (onClassSelected != null) onClassSelected!(reg);
          },
        ),
      );
    }).toList();
  }
}
