import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

void run(HookContext context) {
  final feature = context.vars['feature_name'] as String;
  final rawSubfeatures =
      (context.vars['subfeature_name'] as String?)?.trim() ?? '';

  // Pisahkan input subfeature berdasarkan koma
  final subfeatures = rawSubfeatures
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  final featureBasePath = p.join('lib', 'features', feature.snakeCase);

  // Struktur default folder untuk setiap feature/subfeature
  final dirs = [
    'data/datasources',
    'data/mappers',
    'data/models',
    'data/repositories',
    'domain/entities',
    'domain/repositories',
    'domain/usecases',
    'presentation/bloc',
    'presentation/page',
    'presentation/widget',
  ];

  if (subfeatures.isEmpty) {
    // ✅ Jika tidak ada subfeature → buat satu struktur + injector + template
    _createFeatureStructure(context, featureBasePath, dirs);
    _createTemplateFiles(context, featureBasePath, feature);
    _createInjector(context, featureBasePath, feature, null);
  } else {
    // ✅ Jika ada beberapa subfeature → buat struktur & injector per subfeature + template
    for (final sub in subfeatures) {
      final subPath = p.join(featureBasePath, sub.snakeCase);
      _createFeatureStructure(context, subPath, dirs);
      _createTemplateFiles(context, subPath, feature, sub);
      _createInjector(context, subPath, feature, sub);
    }

    // ✅ Buat injector utama di root feature yang mengimpor semua subfeature
    _createRootInjector(context, featureBasePath, feature, subfeatures);
  }

  context.logger.success('✨ Feature "$feature" generated successfully!');
}

/// Buat struktur folder
void _createFeatureStructure(
    HookContext context, String basePath, List<String> dirs) {
  for (final dir in dirs) {
    final path = p.join(basePath, dir);
    Directory(path).createSync(recursive: true);
    context.logger.info('📂 Created $path');
  }
}

/// Buat file template default di tiap folder
void _createTemplateFiles(HookContext context, String basePath, String feature,
    [String? subfeature]) {
  final sub = subfeature?.snakeCase ?? 'example';

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
    'presentation/page': ['${sub}_page.dart'],
    'presentation/widget': ['${sub}_widget.dart'],
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

/// Buat injector per feature/subfeature
void _createInjector(HookContext context, String basePath, String feature,
    [String? subfeature]) {
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

/// Buat root injector untuk mengimpor semua subfeature
void _createRootInjector(
  HookContext context,
  String basePath,
  String feature,
  List<String> subfeatures,
) {
  final fileName = '${feature.snakeCase}_injector.dart';
  final injectorFile = File(p.join(basePath, fileName));

  // Buat import untuk semua subfeature injector
  final imports = subfeatures.map((sub) {
    final subPath = p.join('.', sub.snakeCase,
        '${sub.snakeCase}_injector.dart');
    return "import '$subPath';";
  }).join('\n');

  // Buat pemanggilan semua subfeature injector dengan sl
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
