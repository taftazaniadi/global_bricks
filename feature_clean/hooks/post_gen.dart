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
    // ✅ Jika tidak ada subfeature → buat satu struktur + injector di root feature
    _createFeatureStructure(context, featureBasePath, dirs);
    _createInjector(context, featureBasePath, feature, null);
  } else {
    // ✅ Jika ada beberapa subfeature → buat struktur & injector per subfeature
    for (final sub in subfeatures) {
      final subPath = p.join(featureBasePath, sub.snakeCase);
      _createFeatureStructure(context, subPath, dirs);
      _createInjector(context, subPath, feature, sub);
    }

    // ✅ Buat injector utama di root feature yang mengimpor semua subfeature
    _createRootInjector(context, featureBasePath, feature, subfeatures);
  }

  context.logger.success('✨ Feature "$feature" generated successfully!');
}

void _createFeatureStructure(
    HookContext context, String basePath, List<String> dirs) {
  for (final dir in dirs) {
    final path = p.join(basePath, dir);
    Directory(path).createSync(recursive: true);
    context.logger.info('📂 Created $path');
  }
}

void _createInjector(HookContext context, String basePath, String feature,
    [String? subfeature]) {
  final fileName = subfeature == null
      ? '${feature.snakeCase}_injector.dart'
      : '${feature.snakeCase}_${subfeature.snakeCase}_injector.dart';

  final injectorFile = File(p.join(basePath, fileName));

  if (!injectorFile.existsSync()) {
    final funcName = subfeature == null
        ? 'inject${feature.pascalCase}()'
        : 'inject${feature.pascalCase}${subfeature.pascalCase}()';

    injectorFile.writeAsStringSync('''
      // ignore_for_file: depend_on_referenced_packages
      import 'package:get_it/get_it.dart';
      
      final sl = GetIt.instance;
      
      void $funcName {
        // TODO: Register your dependencies here.
      }
    ''');

    context.logger.success('⚙️ Created injector file: ${injectorFile.path}');
  }
}

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
        '${feature.snakeCase}_${sub.snakeCase}_injector.dart');
    return "import '$subPath';";
  }).join('\n');

  // Buat pemanggilan semua subfeature injector
  final calls = subfeatures.map((sub) {
    return '  inject${feature.pascalCase}${sub.pascalCase}();';
  }).join('\n');

  final content = '''
    // ignore_for_file: depend_on_referenced_packages
    import 'package:get_it/get_it.dart';
    $imports

    final sl = GetIt.instance;

    void inject${feature.pascalCase}() {
    $calls
    }
  ''';

  injectorFile.writeAsStringSync(content);
  context.logger.success('🧩 Created root injector file: ${injectorFile.path}');
}
