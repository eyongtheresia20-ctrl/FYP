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

  Widget _navTile({
    required int index,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    final effectiveTextColor = textColor ?? (isDarkMode ? Colors.white70 : const Color(0xFF475569));
    final effectiveIconColor = iconColor ?? (isDarkMode ? Colors.white70 : const Color(0xFF475569));
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
          color: isSelected ? const Color(0xFF34D399) : effectiveIconColor,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : effectiveTextColor,
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
    final List<String> defaultItems = user.isPrincipal
        ? ['1ère TI', 'Terminale TI', '2nde C', '1ère C', 'Terminale C']
        : user.isRegionalDelegate
            ? ['DJEREM', 'VINA', 'MAYO-BANYO', 'FARO-ET-DEO', 'MBERE']
            : user.isDivisionalDelegate
                ? ['LYCEE TECHNIQUE DE NGAOUNDAL', 'LYCEE CLASSIQUE DE NGAOUNDAL', 'LYCEE BILINGUE DE NGAOUNDAL']
                : user.isAdmin
                    ? ['ADAMOUA', 'CENTRE', 'LITTORAL', 'NORD', 'EXTREME-NORD', 'OUEST', 'SUD', 'SUD-OUEST', 'NORD-OUEST', 'EST']
                    : ['1ère TI', 'Terminale TI'];

    final classes = tickedClasses.isNotEmpty ? tickedClasses : defaultItems;
    final roleLabel = user.role.toUpperCase();

    final initials = user.fullName.trim().split(' ')
        .take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    final Color _sidebarBg   = isDarkMode ? const Color(0xFF0B132B) : Colors.white;
    final Color _cardBg      = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final Color _textColor   = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color _subTextColor= isDarkMode ? Colors.white70 : const Color(0xFF475569);
    final Color _borderColor = isDarkMode ? const Color(0x22FFFFFF) : const Color(0xFFE2E8F0);

    return Container(
      width: 260,
      color: _sidebarBg,
      child: Column(
        children: [
          // 1. BRANDING HEADER (LOGO + APP NAME) — LOCKED DARK
          Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(bottom: BorderSide(color: Color(0x22FFFFFF))),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/minesec_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, _, __) => const Icon(Icons.school_rounded, color: Color(0xFF006A4E), size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EDU PROFILE',
                        style: TextStyle(
                          color: Color(0xFFFCD116),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        isEn ? 'MINESEC Cameroon' : 'MINESEC Cameroun',
                        style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                          child: ListTile(
                            dense: true,
                            selected: isSelected,
                            selectedTileColor: const Color(0xFF006A4E),
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
                              onItemSelected(1);
                              if (onClassSelected != null) onClassSelected!(cls);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // PRINCIPAL SPECIFIC LINKS
                if (user.isPrincipal) ...[
                  _navTile(
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    label: isEn ? 'Dashboard Overview' : 'Tableau de Bord',
                  ),
                  _navTile(
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
                        isEn ? 'Classes' : 'Classes',
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
                          child: ListTile(
                            dense: true,
                            selected: isSelected,
                            selectedTileColor: const Color(0xFF006A4E),
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
                              onItemSelected(2);
                              if (onClassSelected != null) onClassSelected!(cls);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // DELEGATE SPECIFIC LINKS (REGIONAL OR DIVISIONAL)
                if (user.isRegionalDelegate || user.isDivisionalDelegate) ...[
                  _navTile(
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    label: isEn ? 'Dashboard Overview' : 'Tableau de Bord',
                  ),
                  _navTile(
                    index: 1,
                    icon: Icons.map_rounded,
                    label: user.isRegionalDelegate
                        ? (isEn ? 'Regional VARK Analytics' : 'Analyses VARK Régionales')
                        : (isEn ? 'Divisional VARK Analytics' : 'Analyses VARK Départementales'),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: selectedIndex == 2,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                      childrenPadding: const EdgeInsets.only(left: 12),
                      leading: Icon(Icons.location_city_rounded, color: _subTextColor, size: 20),
                      title: Text(
                        user.isRegionalDelegate
                            ? (isEn ? 'Divisions' : 'Départements')
                            : (isEn ? 'Schools' : 'Établissements'),
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
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    label: isEn ? 'Dashboard Overview' : 'Tableau de Bord',
                  ),
                  _navTile(
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
                    index: 3,
                    icon: Icons.manage_accounts_rounded,
                    label: isEn ? 'User & Security Admin' : 'Gestion Utilisateurs & Sécurité',
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
                border: Border.all(color: _borderColor),
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
                          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          roleLabel,
                          style: TextStyle(color: _subTextColor, fontSize: 10.5),
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
              final rawClsList = scObj['classes'] as List? ?? [];
              final scClasses = rawClsList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

              return Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.only(left: 8, right: 8),
                  childrenPadding: const EdgeInsets.only(left: 14),
                  leading: Icon(Icons.school_rounded, color: subTextColor, size: 14),
                  title: Text(
                    scName,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  iconColor: subTextColor,
                  collapsedIconColor: subTextColor,
                  children: scClasses.isNotEmpty
                      ? scClasses.map((clsObj) {
                          final clsName = (clsObj['class_name'] ?? '').toString();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            child: ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              leading: const Icon(Icons.class_rounded, color: Color(0xFF006A4E), size: 13),
                              title: Text(
                                'Classe $clsName',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11.0,
                                ),
                              ),
                              onTap: () {
                                onItemSelected(2);
                                if (onClassSelected != null) {
                                  onClassSelected!('$scName::$clsName');
                                }
                              },
                            ),
                          );
                        }).toList()
                      : [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: Text(
                              isEn ? '(No classes in DB)' : '(Aucune classe en BD)',
                              style: TextStyle(color: subTextColor, fontSize: 10.5, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                ),
              );
            }).toList(),
          ),
        );
      }).toList();
    }

    return (tickedClasses.isNotEmpty ? tickedClasses : ['LYCEE TECHNIQUE DE NGAOUNDAL', 'LYCEE CLASSIQUE DE NGAOUNDAL', 'LYCEE BILINGUE DE NGAOUNDAL']).map((scItem) {
      final List<String> scClasses = scItem.contains('TECHNIQUE')
          ? ['1ère TI', 'Terminale TI']
          : [];

      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.only(left: 12, right: 8),
          childrenPadding: const EdgeInsets.only(left: 20),
          leading: Icon(Icons.school_rounded, color: subTextColor, size: 16),
          title: Text(
            scItem,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12.0,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          iconColor: subTextColor,
          collapsedIconColor: subTextColor,
          children: scClasses.isNotEmpty
              ? scClasses.map((clsName) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      leading: const Icon(Icons.class_rounded, color: Color(0xFF006A4E), size: 14),
                      title: Text(
                        'Classe $clsName',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 11.5,
                        ),
                      ),
                      onTap: () {
                        onItemSelected(2);
                        if (onClassSelected != null) onClassSelected!('$scItem::$clsName');
                      },
                    ),
                  );
                }).toList()
              : [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Text(
                      isEn ? '(No classes in DB)' : '(Aucune classe en BD)',
                      style: TextStyle(color: subTextColor, fontSize: 10.5, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
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
                                final rawClsList = scObj['classes'] as List? ?? [];
                                final scClasses = rawClsList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

                                return Theme(
                                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    tilePadding: const EdgeInsets.only(left: 8, right: 8),
                                    childrenPadding: const EdgeInsets.only(left: 12),
                                    leading: Icon(Icons.school_rounded, color: subTextColor, size: 14),
                                    title: Text(
                                      scName,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    iconColor: subTextColor,
                                    collapsedIconColor: subTextColor,
                                    children: scClasses.isNotEmpty
                                        ? scClasses.map((clsObj) {
                                            final clsName = (clsObj['class_name'] ?? '').toString();
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 2),
                                              child: ListTile(
                                                dense: true,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                leading: const Icon(Icons.class_rounded, color: Color(0xFF006A4E), size: 13),
                                                title: Text(
                                                  'Classe $clsName',
                                                  style: TextStyle(
                                                    color: textColor,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 11.0,
                                                  ),
                                                ),
                                                onTap: () {
                                                  onItemSelected(2);
                                                  if (onClassSelected != null) {
                                                    onClassSelected!('$scName::$clsName');
                                                  }
                                                },
                                              ),
                                            );
                                          }).toList()
                                        : [
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                              child: Text(
                                                isEn ? '(No classes in DB)' : '(Aucune classe en BD)',
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

    return (tickedClasses.isNotEmpty ? tickedClasses : ['ADAMOUA', 'CENTRE', 'LITTORAL']).map((reg) {
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
            onItemSelected(2);
            if (onClassSelected != null) onClassSelected!(reg);
          },
        ),
      );
    }).toList();
  }
}
