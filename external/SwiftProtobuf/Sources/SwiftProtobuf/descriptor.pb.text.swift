// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: google/protobuf/descriptor.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

#if DEBUG || ALPHA
extension Google_Protobuf_FileDescriptorSet: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "file"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_FileDescriptorProto: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "name"),
    2: .same(proto: "package"),
    3: .same(proto: "dependency"),
    10: .standard(proto: "public_dependency"),
    11: .standard(proto: "weak_dependency"),
    4: .standard(proto: "message_type"),
    5: .standard(proto: "enum_type"),
    6: .same(proto: "service"),
    7: .same(proto: "extension"),
    8: .same(proto: "options"),
    9: .standard(proto: "source_code_info"),
    12: .same(proto: "syntax"),
    13: .same(proto: "edition"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_DescriptorProto: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "name"),
    2: .same(proto: "field"),
    6: .same(proto: "extension"),
    3: .standard(proto: "nested_type"),
    4: .standard(proto: "enum_type"),
    5: .standard(proto: "extension_range"),
    8: .standard(proto: "oneof_decl"),
    7: .same(proto: "options"),
    9: .standard(proto: "reserved_range"),
    10: .standard(proto: "reserved_name"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_DescriptorProto.ExtensionRange: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "start"),
    2: .same(proto: "end"),
    3: .same(proto: "options"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_DescriptorProto.ReservedRange: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "start"),
    2: .same(proto: "end"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_ExtensionRangeOptions: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    999: .standard(proto: "uninterpreted_option"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_FieldDescriptorProto: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "name"),
    3: .same(proto: "number"),
    4: .same(proto: "label"),
    5: .same(proto: "type"),
    6: .standard(proto: "type_name"),
    2: .same(proto: "extendee"),
    7: .standard(proto: "default_value"),
    9: .standard(proto: "oneof_index"),
    10: .standard(proto: "json_name"),
    8: .same(proto: "options"),
    17: .standard(proto: "proto3_optional"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_FieldDescriptorProto.TypeEnum: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "TYPE_DOUBLE"),
    2: .same(proto: "TYPE_FLOAT"),
    3: .same(proto: "TYPE_INT64"),
    4: .same(proto: "TYPE_UINT64"),
    5: .same(proto: "TYPE_INT32"),
    6: .same(proto: "TYPE_FIXED64"),
    7: .same(proto: "TYPE_FIXED32"),
    8: .same(proto: "TYPE_BOOL"),
    9: .same(proto: "TYPE_STRING"),
    10: .same(proto: "TYPE_GROUP"),
    11: .same(proto: "TYPE_MESSAGE"),
    12: .same(proto: "TYPE_BYTES"),
    13: .same(proto: "TYPE_UINT32"),
    14: .same(proto: "TYPE_ENUM"),
    15: .same(proto: "TYPE_SFIXED32"),
    16: .same(proto: "TYPE_SFIXED64"),
    17: .same(proto: "TYPE_SINT32"),
    18: .same(proto: "TYPE_SINT64"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_FieldDescriptorProto.Label: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "LABEL_OPTIONAL"),
    2: .same(proto: "LABEL_REQUIRED"),
    3: .same(proto: "LABEL_REPEATED"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_OneofDescriptorProto: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "name"),
    2: .same(proto: "options"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_EnumDescriptorProto: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "name"),
    2: .same(proto: "value"),
    3: .same(proto: "options"),
    4: .standard(proto: "reserved_range"),
    5: .standard(proto: "reserved_name"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_EnumDescriptorProto.EnumReservedRange: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "start"),
    2: .same(proto: "end"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_EnumValueDescriptorProto: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "name"),
    2: .same(proto: "number"),
    3: .same(proto: "options"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_ServiceDescriptorProto: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "name"),
    2: .same(proto: "method"),
    3: .same(proto: "options"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_MethodDescriptorProto: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "name"),
    2: .standard(proto: "input_type"),
    3: .standard(proto: "output_type"),
    4: .same(proto: "options"),
    5: .standard(proto: "client_streaming"),
    6: .standard(proto: "server_streaming"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_FileOptions: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "java_package"),
    8: .standard(proto: "java_outer_classname"),
    10: .standard(proto: "java_multiple_files"),
    20: .standard(proto: "java_generate_equals_and_hash"),
    27: .standard(proto: "java_string_check_utf8"),
    9: .standard(proto: "optimize_for"),
    11: .standard(proto: "go_package"),
    16: .standard(proto: "cc_generic_services"),
    17: .standard(proto: "java_generic_services"),
    18: .standard(proto: "py_generic_services"),
    42: .standard(proto: "php_generic_services"),
    23: .same(proto: "deprecated"),
    31: .standard(proto: "cc_enable_arenas"),
    36: .standard(proto: "objc_class_prefix"),
    37: .standard(proto: "csharp_namespace"),
    39: .standard(proto: "swift_prefix"),
    40: .standard(proto: "php_class_prefix"),
    41: .standard(proto: "php_namespace"),
    44: .standard(proto: "php_metadata_namespace"),
    45: .standard(proto: "ruby_package"),
    999: .standard(proto: "uninterpreted_option"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_FileOptions.OptimizeMode: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "SPEED"),
    2: .same(proto: "CODE_SIZE"),
    3: .same(proto: "LITE_RUNTIME"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_MessageOptions: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "message_set_wire_format"),
    2: .standard(proto: "no_standard_descriptor_accessor"),
    3: .same(proto: "deprecated"),
    7: .standard(proto: "map_entry"),
    999: .standard(proto: "uninterpreted_option"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_FieldOptions: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "ctype"),
    2: .same(proto: "packed"),
    6: .same(proto: "jstype"),
    5: .same(proto: "lazy"),
    15: .standard(proto: "unverified_lazy"),
    3: .same(proto: "deprecated"),
    10: .same(proto: "weak"),
    999: .standard(proto: "uninterpreted_option"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_FieldOptions.CType: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "STRING"),
    1: .same(proto: "CORD"),
    2: .same(proto: "STRING_PIECE"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_FieldOptions.JSType: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "JS_NORMAL"),
    1: .same(proto: "JS_STRING"),
    2: .same(proto: "JS_NUMBER"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_OneofOptions: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    999: .standard(proto: "uninterpreted_option"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_EnumOptions: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    2: .standard(proto: "allow_alias"),
    3: .same(proto: "deprecated"),
    999: .standard(proto: "uninterpreted_option"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_EnumValueOptions: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "deprecated"),
    999: .standard(proto: "uninterpreted_option"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_ServiceOptions: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    33: .same(proto: "deprecated"),
    999: .standard(proto: "uninterpreted_option"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_MethodOptions: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    33: .same(proto: "deprecated"),
    34: .standard(proto: "idempotency_level"),
    999: .standard(proto: "uninterpreted_option"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_MethodOptions.IdempotencyLevel: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "IDEMPOTENCY_UNKNOWN"),
    1: .same(proto: "NO_SIDE_EFFECTS"),
    2: .same(proto: "IDEMPOTENT"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_UninterpretedOption: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    2: .same(proto: "name"),
    3: .standard(proto: "identifier_value"),
    4: .standard(proto: "positive_int_value"),
    5: .standard(proto: "negative_int_value"),
    6: .standard(proto: "double_value"),
    7: .standard(proto: "string_value"),
    8: .standard(proto: "aggregate_value"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_UninterpretedOption.NamePart: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "name_part"),
    2: .standard(proto: "is_extension"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_SourceCodeInfo: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "location"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_SourceCodeInfo.Location: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "path"),
    2: .same(proto: "span"),
    3: .standard(proto: "leading_comments"),
    4: .standard(proto: "trailing_comments"),
    6: .standard(proto: "leading_detached_comments"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_GeneratedCodeInfo: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "annotation"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_GeneratedCodeInfo.Annotation: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "path"),
    2: .standard(proto: "source_file"),
    3: .same(proto: "begin"),
    4: .same(proto: "end"),
    5: .same(proto: "semantic"),
  ]
}
#endif

#if DEBUG || ALPHA
extension Google_Protobuf_GeneratedCodeInfo.Annotation.Semantic: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "NONE"),
    1: .same(proto: "SET"),
    2: .same(proto: "ALIAS"),
  ]
}
#endif
