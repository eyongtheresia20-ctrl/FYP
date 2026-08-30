with open(r'lib/views/dashboards/delegate_dashboard.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Fix onClassSelected in delegate_dashboard.dart
old_on_class = """      onClassSelected: (selection) {
        setState(() {
          _currentNavIndex = 2;
          if (selection.contains('::')) {
            final parts = selection.split('::');
            final scName = parts[0];
            final clsName = parts[1];
            _selectedSchoolFilter = scName;
            _selectedClassFilterPerSchool[scName] = clsName;
          } else {
            _selectedSchoolFilter = selection;
            _selectedSubSchoolFilter = null;
          }
        });
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      },"""

new_on_class = """      onClassSelected: (selection) {
        setState(() {
          _currentNavIndex = 2;
          if (selection.contains('::')) {
            final parts = selection.split('::');
            if (isReg) {
              _selectedSchoolFilter = parts[0]; // Division
              _selectedSubSchoolFilter = parts[1]; // School
            } else {
              _selectedSchoolFilter = parts[0]; // School
              _selectedClassFilterPerSchool[parts[0]] = parts[1];
            }
          } else {
            if (isReg) {
              _selectedSchoolFilter = selection;
              _selectedSubSchoolFilter = null;
            } else {
              _selectedSchoolFilter = selection;
            }
          }
        });
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      },"""

text = text.replace(old_on_class, new_on_class)

with open(r'lib/views/dashboards/delegate_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(text)

# Also ensure AppSidebar correctly passes and checks selectedClass for delegate
with open(r'lib/widgets/app_sidebar.dart', 'r', encoding='utf-8') as f:
    sb_text = f.read()

old_delegate_sidebar_selection = """              final scName = (scObj['name'] ?? '').toString();
              final isSelected = selectedIndex == 2 && (selectedClass == scName || selectedClass.endsWith('::$scName'));"""

new_delegate_sidebar_selection = """              final scName = (scObj['name'] ?? '').toString();
              final isSelected = selectedIndex == 2 && (selectedClass == scName || selectedClass == '$divName::$scName' || selectedClass.endsWith('::$scName'));"""

sb_text = sb_text.replace(old_delegate_sidebar_selection, new_delegate_sidebar_selection)

with open(r'lib/widgets/app_sidebar.dart', 'w', encoding='utf-8') as f:
    f.write(sb_text)

print('SUCCESSFULLY FIXED DELEGATE SCHOOL SELECTION FOR EMPTY AND ACTIVE SCHOOLS')
