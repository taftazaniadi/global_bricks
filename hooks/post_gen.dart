import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

String _toSnakeCase(String value) {
  final normalized = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  return normalized.isEmpty ? 'feature' : normalized.toLowerCase();
}

String _toPascalCase(String value) {
  final parts = value.split(RegExp(r'[^a-zA-Z0-9]+')).where((segment) => segment.isNotEmpty).map((segment) => segment[0].toUpperCase() + segment.substring(1).toLowerCase()).toList();
  return parts.isEmpty ? 'Feature' : parts.join();
}

String normalizeFeaturePath(String rawFeature) {
  return rawFeature.trim().replaceAll('\\', '/').split('/').map((segment) => segment.trim()).where((segment) => segment.isNotEmpty).map((segment) => _toSnakeCase(segment.replaceAll(RegExp(r'\s+'), '_'))).join('/');
}

String normalizeFeatureName(String rawFeature) => p.basename(normalizeFeaturePath(rawFeature));

List<String> normalizeSubfeatures(String rawSubfeatures) {
  return rawSubfeatures.split(',').map((segment) => segment.trim()).where((segment) => segment.isNotEmpty).map((segment) => _toSnakeCase(segment.replaceAll(RegExp(r'\s+'), '_'))).toList();
}

List<String> buildDefaultFeatureDirs() => [
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

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == 'yes' || normalized == 'y';
  }
  return false;
}

void run(HookContext context) {
  final useDefaultTarget = _asBool(context.vars['default_target']);
  final requestedTargetPath = useDefaultTarget
      ? 'lib/features'
      : (context.vars['custom_target_path'] as String? ?? 'lib/features');
  final targetPath = requestedTargetPath.trim().replaceAll('\\', '/').replaceAll(RegExp(r'/+'), '/').replaceAll(RegExp(r'^/|/$'), '');

  final rawFeature = context.vars['feature_name'] as String? ?? '';
  final hasSubfeatures = _asBool(context.vars['has_subfeatures']);
  final rawSubfeatures = hasSubfeatures ? (context.vars['subfeature_name'] as String?)?.trim() ?? '' : '';

  if (rawFeature.trim().isEmpty) {
    context.logger.err('❌ Feature name tidak boleh kosong!');
    exit(1);
  }

  final normalizedFeaturePath = normalizeFeaturePath(rawFeature);
  final featureName = normalizeFeatureName(rawFeature);
  final subfeatures = normalizeSubfeatures(rawSubfeatures);
  final featureBasePath = p.join(targetPath, normalizedFeaturePath);
  final dirs = buildDefaultFeatureDirs();

  if (subfeatures.isEmpty) {
    _createFeatureStructure(context, featureBasePath, dirs);
    _createTemplateFiles(context, featureBasePath, featureName);
    _createInjector(context, featureBasePath, featureName);
  } else {
    for (final sub in subfeatures) {
      final subPath = p.join(featureBasePath, _toSnakeCase(sub));
      _createFeatureStructure(context, subPath, dirs);
      _createTemplateFiles(context, subPath, featureName, sub);
      _createInjector(context, subPath, featureName, sub);
    }
    _createRootInjector(context, featureBasePath, featureName, subfeatures);
  }

  context.logger.success('✨ Feature "$normalizedFeaturePath" generated successfully!');
}

void _createFeatureStructure(HookContext context, String basePath, List<String> dirs) {
  for (final dir in dirs) {
    final path = p.join(basePath, dir);
    Directory(path).createSync(recursive: true);
    context.logger.info('📂 Created $path');
  }
}

void _createTemplateFiles(HookContext context, String basePath, String feature, [String? subfeature]) {
  final sub = _toSnakeCase(subfeature ?? feature);
  final templates = {
    'data/repositories': ['${sub}_repository_impl.dart'],
    'data/mappers': ['${sub}_mapper.dart'],
    'data/datasources': ['${sub}_remote_datasource.dart'],
    'domain/entities': ['${sub}_entity.dart'],
    'domain/usecases': ['${sub}_usecase.dart'],
    'domain/repositories': ['${sub}_repository.dart'],
    'presentation/bloc': ['${sub}_bloc.dart', '${sub}_event.dart', '${sub}_state.dart'],
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

String _getFileContent(String folder, String file, String sub) {
  final name = _toPascalCase(sub);
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
    } else {
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
      body: Center(child: Text('${name}Page')),
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
  Widget build(BuildContext context) => const SizedBox();
}
''';
  }
  return '// TODO: Implement $file';
}

void _createInjector(HookContext context, String basePath, String feature, [String? subfeature]) {
  final fileName = subfeature == null ? '${_toSnakeCase(feature)}_injector.dart' : '${_toSnakeCase(subfeature)}_injector.dart';
  final injectorFile = File(p.join(basePath, fileName));
  if (!injectorFile.existsSync()) {
    final funcName = subfeature == null ? 'inject${_toPascalCase(feature)}' : 'inject${_toPascalCase(subfeature)}';
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

void _createRootInjector(HookContext context, String basePath, String feature, List<String> subfeatures) {
  final injectorFile = File(p.join(basePath, '${_toSnakeCase(feature)}_injector.dart'));
  final allSubfeatures = <String>{...subfeatures.map(_toSnakeCase)};
  final dir = Directory(basePath);
  if (dir.existsSync()) {
    for (final entity in dir.listSync()) {
      if (entity is Directory) {
        final name = p.basename(entity.path);
        if (File(p.join(entity.path, '${_toSnakeCase(name)}_injector.dart')).existsSync()) {
          allSubfeatures.add(_toSnakeCase(name));
        }
      }
    }
  }

  final sortedSubs = allSubfeatures.toList()..sort();
  final imports = sortedSubs.map((sub) => "import './$sub/${sub}_injector.dart';").join('\n');
  final calls = sortedSubs.map((sub) => '  inject${_toPascalCase(sub)}(sl);').join('\n');
  injectorFile.writeAsStringSync('''
// ignore_for_file: depend_on_referenced_packages
import 'package:get_it/get_it.dart';
$imports

void inject${_toPascalCase(feature)}(GetIt sl) {
$calls
}
''');
  context.logger.success('🧩 Created root injector file: ${injectorFile.path}');
}
