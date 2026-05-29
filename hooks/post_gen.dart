import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

void run(HookContext context) {
  // Ambil input dari user
  final rawFeature = context.vars['feature_name'] as String? ?? '';
  final rawSubfeatures =
      (context.vars['subfeature_name'] as String?)?.trim() ?? '';

  if (rawFeature.trim().isEmpty) {
    context.logger.err('❌ Feature name tidak boleh kosong!');
    exit(1);
  }

  // --- ✨ Sanitasi feature name ---
  // Hilangkan spasi, slash berlebih, dan tanda miring di awal/akhir
  final normalizedFeaturePath = rawFeature
      .trim()
      .replaceAll('\\', '/')
      .replaceAll(RegExp(r'\s+'), '_') // spasi → underscore
      .replaceAll(RegExp(r'/+'), '/') // hilangkan double slash
      .replaceAll(RegExp(r'^/|/$'), ''); // hilangkan slash di awal/akhir

  // Nama feature terakhir (misal dari "balance/fund_transfer" → "fund_transfer")
  final featureName = p.basename(normalizedFeaturePath);

  // --- ✨ Sanitasi subfeatures ---
  final subfeatures = rawSubfeatures
      .split(',')
      .map((s) => s.trim().replaceAll(RegExp(r'\s+'), '_'))
      .where((s) => s.isNotEmpty)
      .toList();

  // Path dasar feature
  final featureBasePath = p.join('lib', 'features', normalizedFeaturePath);

  // Struktur folder default
  final dirs = [
    'data/datasources',
    'data/mappers',
    'data/models',
    'data/repositories',
    'domain/entities',
    'domain/repositories',
    'domain/usecases',
    'presentation/bloc',
    'presentation/pages',
    'presentation/widgets',
  ];

  // --- ✨ Generate struktur sesuai kondisi ---
  if (subfeatures.isEmpty) {
    // Case: tanpa subfeature
    _createFeatureStructure(context, featureBasePath, dirs);
    _createTemplateFiles(context, featureBasePath, featureName);
    _createInjector(context, featureBasePath, featureName, null);
  } else {
    // Case: dengan subfeature
    for (final sub in subfeatures) {
      final subPath = p.join(featureBasePath, sub.snakeCase);
      _createFeatureStructure(context, subPath, dirs);
      _createTemplateFiles(context, subPath, featureName, sub);
      _createInjector(context, subPath, featureName, sub);
    }

    // Root injector di feature utama
    _createRootInjector(context, featureBasePath, featureName, subfeatures);
  }

  context.logger.success(
    '✨ Feature "$normalizedFeaturePath" generated successfully!',
  );
}

/// Buat struktur folder dasar
void _createFeatureStructure(
  HookContext context,
  String basePath,
  List<String> dirs,
) {
  for (final dir in dirs) {
    final path = p.join(basePath, dir);
    Directory(path).createSync(recursive: true);
    context.logger.info('📂 Created $path');
  }
}

/// Buat file template placeholder di tiap folder
void _createTemplateFiles(
  HookContext context,
  String basePath,
  String feature, [
  String? subfeature,
]) {
  final sub = subfeature?.snakeCase ?? feature.snakeCase;

  final templates = {
    'data/repositories': ['${sub}_repository_impl.dart'],
    'data/mappers': ['${sub}_mapper.dart'],
    'data/datasources': ['${sub}_remote_datasource.dart'],
    'domain/entities': ['${sub}_entity.dart'],
    'domain/usecases': ['${sub}_usecase.dart'],
    'domain/repositories': ['${sub}_repository.dart'],
    'presentation/bloc': [
      '${sub}_bloc.dart',
      '${sub}_event.dart',
      '${sub}_state.dart'
    ],
    'presentation/pages': ['${sub}_page.dart'],
    'presentation/widgets': ['${sub}_widget.dart'],
  };

  templates.forEach((folder, files) {
    final folderPath = p.join(basePath, folder);
    for (final file in files) {
      final filePath = p.join(folderPath, file);
      if (!File(filePath).existsSync()) {
        File(filePath).writeAsStringSync('// TODO: Implement $file');
        context.logger.info('📄 Created template file: $filePath');
      }
    }
  });
}

/// Buat injector untuk tiap feature/subfeature
void _createInjector(
  HookContext context,
  String basePath,
  String feature, [
  String? subfeature,
]) {
  final fileName = subfeature == null
      ? '${feature.snakeCase}_injector.dart'
      : '${subfeature.snakeCase}_injector.dart';

  final injectorFile = File(p.join(basePath, fileName));

  if (!injectorFile.existsSync()) {
    final funcName = subfeature == null
        ? 'inject${feature.pascalCase}'
        : 'inject${subfeature.pascalCase}';

    injectorFile.writeAsStringSync('''
// ignore_for_file: depend_on_referenced_packages
import 'package:get_it/get_it.dart';
      
void $funcName(GetIt sl) {
  // TODO: Register your dependencies here.
}
    ''');

    context.logger.success('⚙️ Created injector file: ${injectorFile.path}');
  }
}

/// Buat root injector yang menggabungkan semua subfeature injector
void _createRootInjector(
  HookContext context,
  String basePath,
  String feature,
  List<String> subfeatures,
) {
  final fileName = '${feature.snakeCase}_injector.dart';
  final injectorFile = File(p.join(basePath, fileName));

  final imports = subfeatures.map((sub) {
    final subPath =
        p.join('.', sub.snakeCase, '${sub.snakeCase}_injector.dart');
    return "import '$subPath';";
  }).join('\n');

  final calls = subfeatures.map((sub) {
    return '  inject${sub.pascalCase}(sl);';
  }).join('\n');

  final content = '''
// ignore_for_file: depend_on_referenced_packages
import 'package:get_it/get_it.dart';
$imports

void inject${feature.pascalCase}(GetIt sl) {
$calls
}
  ''';

  injectorFile.writeAsStringSync(content);
  context.logger.success('🧩 Created root injector file: ${injectorFile.path}');
}
