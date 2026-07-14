import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

void run(HookContext context) {
  // Ambil input dari user
  final targetPath = (context.vars['target_path'] as String? ?? 'lib/features')
      .trim()
      .replaceAll('\\', '/')
      .replaceAll(RegExp(r'/+'), '/')
      .replaceAll(RegExp(r'^/|/$'), '');
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
  final featureBasePath = p.join(targetPath, normalizedFeaturePath);

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
        File(filePath).writeAsStringSync(_getFileContent(folder, file, sub));
        context.logger.info('📄 Created template file: $filePath');
      }
    }
  });
}

/// Helper untuk generate boilerplate code untuk masing-masing file
String _getFileContent(String folder, String file, String sub) {
  final name = sub.pascalCase;
  if (folder == 'data/repositories') {
    return '''
import '../../domain/repositories/${sub}_repository.dart';

class ${name}RepositoryImpl implements ${name}Repository {
  // TODO: Add constructor and inject remote/local datasources
}
''';
  } else if (folder == 'data/mappers') {
    return '''
class ${name}Mapper {
  // TODO: Implement mapper (e.g. model to entity)
}
''';
  } else if (folder == 'data/datasources') {
    return '''
class ${name}RemoteDataSource {
  // TODO: Implement remote data source methods
}
''';
  } else if (folder == 'domain/entities') {
    return '''
class ${name}Entity {
  const ${name}Entity();
}
''';
  } else if (folder == 'domain/usecases') {
    return '''
import '../repositories/${sub}_repository.dart';

class ${name}UseCase {
  final ${name}Repository repository;

  const ${name}UseCase(this.repository);

  // TODO: Implement execution logic
  // Future<void> call() async {}
}
''';
  } else if (folder == 'domain/repositories') {
    return '''
abstract class ${name}Repository {
  // TODO: Add repository methods
}
''';
  } else if (folder == 'presentation/bloc') {
    if (file.endsWith('_bloc.dart')) {
      return '''
// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_bloc/flutter_bloc.dart';
import '${sub}_event.dart';
import '${sub}_state.dart';

class ${name}Bloc extends Bloc<${name}Event, ${name}State> {
  ${name}Bloc() : super(const ${name}Initial()) {
    // TODO: Register event handlers
  }
}
''';
    } else if (file.endsWith('_event.dart')) {
      return '''
abstract class ${name}Event {
  const ${name}Event();
}
''';
    } else if (file.endsWith('_state.dart')) {
      return '''
abstract class ${name}State {
  const ${name}State();
}

class ${name}Initial extends ${name}State {
  const ${name}Initial();
}
''';
    }
  } else if (folder == 'presentation/pages') {
    return '''
// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';

class ${name}Page extends StatelessWidget {
  const ${name}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('${name}Page'),
      ),
    );
  }
}
''';
  } else if (folder == 'presentation/widgets') {
    return '''
// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';

class ${name}Widget extends StatelessWidget {
  const ${name}Widget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
''';
  }
  return '// TODO: Implement $file';
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

  // Kumpulkan semua subfeatures: yang baru digenerate + yang sudah ada di disk
  final allSubfeatures = <String>{};
  allSubfeatures.addAll(subfeatures.map((s) => s.snakeCase));

  final dir = Directory(basePath);
  if (dir.existsSync()) {
    for (final entity in dir.listSync()) {
      if (entity is Directory) {
        final name = p.basename(entity.path);
        final subInjector = File(p.join(entity.path, '${name.snakeCase}_injector.dart'));
        if (subInjector.existsSync()) {
          allSubfeatures.add(name.snakeCase);
        }
      }
    }
  }

  final sortedSubs = allSubfeatures.toList()..sort();

  final imports = sortedSubs.map((sub) {
    final subPath =
        p.join('.', sub, '${sub}_injector.dart').replaceAll('\\', '/');
    return "import '$subPath';";
  }).join('\n');

  final calls = sortedSubs.map((sub) {
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
