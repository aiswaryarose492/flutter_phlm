class DrugInteractionChecker {
  static const Map<String, List<String>> interactions = {
    'Warfarin': ['Aspirin', 'Ibuprofen', 'Vitamin K'],
    'Aspirin': ['Warfarin', 'Ibuprofen', 'Clopidogrel'],
    'Ibuprofen': ['Warfarin', 'Aspirin', 'Lisinopril'],
    'Metformin': ['Alcohol', 'Contrast Dye'],
    'Alcohol': ['Metformin', 'Acetaminophen', 'Diazepam'],
    'Acetaminophen': ['Alcohol', 'Warfarin'],
    'Lisinopril': ['Ibuprofen', 'Potassium'],
    'Potassium': ['Lisinopril', 'Spironolactone'],
    'Spironolactone': ['Potassium', 'Lisinopril'],
    'Clopidogrel': ['Aspirin', 'Omeprazole'],
    'Omeprazole': ['Clopidogrel', 'Atazanavir'],
    'Atazanavir': ['Omeprazole', 'Rifampin'],
    'Rifampin': ['Atazanavir', 'Warfarin'],
    'Simvastatin': ['Grapefruit', 'Clarithromycin'],
    'Grapefruit': ['Simvastatin', 'Amlodipine'],
    'Amlodipine': ['Grapefruit', 'Simvastatin'],
    'Clarithromycin': ['Simvastatin', 'Colchicine'],
    'Colchicine': ['Clarithromycin', 'Cyclosporine'],
    'Cyclosporine': ['Colchicine', 'Potassium'],
    'Digoxin': ['Amiodarone', 'Verapamil'],
    'Amiodarone': ['Digoxin', 'Warfarin'],
    'Verapamil': ['Digoxin', 'Beta Blocker'],
    'Beta Blocker': ['Verapamil', 'Insulin'],
    'Insulin': ['Beta Blocker', 'Alcohol'],
    'Levothyroxine': ['Calcium', 'Iron'],
    'Calcium': ['Levothyroxine', 'Ciprofloxacin'],
    'Iron': ['Levothyroxine', 'Ciprofloxacin'],
    'Ciprofloxacin': ['Calcium', 'Iron'],
  };

  static List<String> findInteractions(List<String> medicines) {
    final normalized = medicines
        .map(_normalize)
        .where((name) => name.isNotEmpty)
        .toSet();
    final warnings = <String>{};
    for (final medicine in normalized) {
      final partners = interactions[medicine] ?? const [];
      for (final partner in partners) {
        final normalizedPartner = _normalize(partner);
        if (normalized.contains(normalizedPartner)) {
          final pair = [medicine, normalizedPartner]..sort();
          warnings.add(
            '⚠ ${pair[0]} and ${pair[1]} may interact — consult your doctor.',
          );
        }
      }
    }
    return warnings.toList();
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}
