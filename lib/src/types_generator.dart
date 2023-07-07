import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:schema_dart/src/util.dart';

import 'data_class_builder.dart';
import 'types.dart';

/// Generates Dart type definitions (aka data classes) from [Table]s
class TypesGenerator {
  final Directory outputDirectory;

  final List<Table> tables;
  final TypesGeneratorConfig config;

  late final formatter = DartFormatter(pageWidth: 120);

  TypesGenerator({
    required this.outputDirectory,
    required this.tables,
    this.config = const TypesGeneratorConfig(),
  });

  Future<void> addDartSourceToTables() async {
    for (final table in tables) {
      final builder = DataClassBuilder(config: config, table: table);
      final source = builder.build();
      table.source = formatter.format(source);
    }
  }

  String generateSchema() {
    var output = '';

    output += 'enum DatabaseTables {';
    for (final table in tables) {
      output +=
          '${table.tableName.convertSnakeCaseToCamelCase()}("${table.tableName}"),';
    }
    print(output);
    output += '''
    ;
      const DatabaseTables(this.name);
      final String name;
    ''';
    output += '}';

    output +=
        'typedef SchemaColumn = ({String name, Type dartType, String dataType, bool nullable});';
    output += 'typedef Schema = Map<DatabaseTables, List<SchemaColumn>>;';

    output += 'final Schema schema = {';
    for (final table in tables) {
      final sortColumnId = table.columns
          .where((element) => element.columnName.startsWith('id'))
          .toList()
        ..sort((a, b) {
          return a.columnName.compareTo(b.columnName);
        });
      final sortColumnNotId = table.columns
          .where((element) => !element.columnName.startsWith('id'))
          .toList()
        ..sort((a, b) {
          return a.columnName.compareTo(b.columnName);
        });
      final sortedColumns = sortColumnId + sortColumnNotId;
      output +=
          'DatabaseTables.${table.tableName.convertSnakeCaseToCamelCase()}: [';
      for (final column in sortedColumns) {
        output += '(';
        output += 'name: "${column.columnName}",';
        output += 'dartType: ${column.dartType.replaceAll('?', '')},';
        output += 'dataType: "${column.dataType}",';
        output += 'nullable: ${column.isNullable},';
        output += '),';
      }
      output += '],';
    }
    output += '};';
    output = formatter.format(output);
    return output;
  }
}

class TypesGeneratorConfig {
  final bool generateCopyWith;
  final bool generateSerialization;
  final bool generateEquality;
  final bool generateToString;

  const TypesGeneratorConfig({
    this.generateCopyWith = true,
    this.generateSerialization = true,
    this.generateEquality = true,
    this.generateToString = true,
  });
}

class ClassOnlyConfig extends TypesGeneratorConfig {
  const ClassOnlyConfig()
      : super(
          generateCopyWith: false,
          generateEquality: false,
          generateSerialization: false,
          generateToString: false,
        );
}
