//
//  PBModel.swift
//  Lark
//
//  Created by Hayden on 2022/9/2.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkHTTP

// swiftlint:disable all

fileprivate let _protobuf_package = "entities"

public struct ServerPB_Entities_EffectiveInterval {
  // LarkHTTP.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the LarkHTTP library for
  // methods supported on all messages.

  public var startTime: Int64 {
    get {return _startTime ?? 0}
    set {_startTime = newValue}
  }
  /// Returns true if `startTime` has been explicitly set.
  public var hasStartTime: Bool {return self._startTime != nil}
  /// Clears the value of `startTime`. Subsequent reads from it will return its default value.
  public mutating func clearStartTime() {self._startTime = nil}

  public var endTime: Int64 {
    get {return _endTime ?? 0}
    set {_endTime = newValue}
  }
  /// Returns true if `endTime` has been explicitly set.
  public var hasEndTime: Bool {return self._endTime != nil}
  /// Clears the value of `endTime`. Subsequent reads from it will return its default value.
  public mutating func clearEndTime() {self._endTime = nil}

  /// 已经特化成vc无结束时间的情况（vc状态下，状态的结束时间展示为"持续至会议结束"）
  public var isShowEndTime: Bool {
    get {return _isShowEndTime ?? true}
    set {_isShowEndTime = newValue}
  }
  /// Returns true if `isShowEndTime` has been explicitly set.
  public var hasIsShowEndTime: Bool {return self._isShowEndTime != nil}
  /// Clears the value of `isShowEndTime`. Subsequent reads from it will return its default value.
  public mutating func clearIsShowEndTime() {self._isShowEndTime = nil}

  /// 无固定结束时间的情况，原始需求是同步ios的系统状态
  public var isOpenWithoutEndTime: Bool {
    get {return _isOpenWithoutEndTime ?? false}
    set {_isOpenWithoutEndTime = newValue}
  }
  /// Returns true if `isOpenWithoutEndTime` has been explicitly set.
  public var hasIsOpenWithoutEndTime: Bool {return self._isOpenWithoutEndTime != nil}
  /// Clears the value of `isOpenWithoutEndTime`. Subsequent reads from it will return its default value.
  public mutating func clearIsOpenWithoutEndTime() {self._isOpenWithoutEndTime = nil}

  public var unknownFields = LarkHTTP.UnknownStorage()

  public init() {}

  fileprivate var _startTime: Int64? = nil
  fileprivate var _endTime: Int64? = nil
  fileprivate var _isShowEndTime: Bool? = nil
  fileprivate var _isOpenWithoutEndTime: Bool? = nil
}


extension ServerPB_Entities_EffectiveInterval: LarkHTTP.Message, LarkHTTP._MessageImplementationBase, LarkHTTP._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".EffectiveInterval"
  public static let _protobuf_nameMap: LarkHTTP._NameMap = [
    1: .standard(proto: "start_time"),
    2: .standard(proto: "end_time"),
    3: .standard(proto: "is_show_end_time"),
    4: .standard(proto: "is_open_without_end_time"),
  ]

  public mutating func decodeMessage<D: LarkHTTP.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularInt64Field(value: &self._startTime)
      case 2: try decoder.decodeSingularInt64Field(value: &self._endTime)
      case 3: try decoder.decodeSingularBoolField(value: &self._isShowEndTime)
      case 4: try decoder.decodeSingularBoolField(value: &self._isOpenWithoutEndTime)
      default: break
      }
    }
  }

  public func traverse<V: LarkHTTP.Visitor>(visitor: inout V) throws {
    if let v = self._startTime {
      try visitor.visitSingularInt64Field(value: v, fieldNumber: 1)
    }
    if let v = self._endTime {
      try visitor.visitSingularInt64Field(value: v, fieldNumber: 2)
    }
    if let v = self._isShowEndTime {
      try visitor.visitSingularBoolField(value: v, fieldNumber: 3)
    }
    if let v = self._isOpenWithoutEndTime {
      try visitor.visitSingularBoolField(value: v, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: ServerPB_Entities_EffectiveInterval, rhs: ServerPB_Entities_EffectiveInterval) -> Bool {
    if lhs._startTime != rhs._startTime { return false }
    if lhs._endTime != rhs._endTime { return false }
    if lhs._isShowEndTime != rhs._isShowEndTime { return false }
    if lhs._isOpenWithoutEndTime != rhs._isOpenWithoutEndTime { return false }
    if lhs.unknownFields != rhs.unknownFields { return false }
    return true
  }
}

public struct ServerPB_Entities_TimeFormat {
  // LarkHTTP.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the LarkHTTP library for
  // methods supported on all messages.

  /// 时间单位
  public var timeUnit: ServerPB_Entities_TimeUnit {
    get { return _timeUnit ?? .second }
    set { _timeUnit = newValue }
  }
  /// Returns true if `timeUnit` has been explicitly set.
  public var hasTimeUnit: Bool { return self._timeUnit != nil }
  /// Clears the value of `timeUnit`. Subsequent reads from it will return its default value.
  public mutating func clearTimeUnit() { self._timeUnit = nil }

  public var startEndLayout: ServerPB_Entities_TimeFormat.StartEndLayout {
    get { return _startEndLayout ?? .hide }
    set { _startEndLayout = newValue }
  }
  /// Returns true if `startEndLayout` has been explicitly set.
  public var hasStartEndLayout: Bool { return self._startEndLayout != nil }
  /// Clears the value of `startEndLayout`. Subsequent reads from it will return its default value.
  public mutating func clearStartEndLayout() { self._startEndLayout = nil }

  /// 是否对其它用户展示时间，个人看自己profile始终展示时间，对其它用户展示由设置决定
  public var isShowToOthers: Bool {
    get { return _isShowToOthers ?? false }
    set { _isShowToOthers = newValue }
  }
  /// Returns true if `isShowToOthers` has been explicitly set.
  public var hasIsShowToOthers: Bool { return self._isShowToOthers != nil }
  /// Clears the value of `isShowToOthers`. Subsequent reads from it will return its default value.
  public mutating func clearIsShowToOthers() { self._isShowToOthers = nil }

  public var unknownFields = LarkHTTP.UnknownStorage()

  public enum StartEndLayout: LarkHTTP.Enum {
    public typealias RawValue = Int

    /// 不展示
    case hide // = 0

    /// 常规起始都显示
    case normal // = 1

    /// 只显示开始时间
    case startOnly // = 2

    /// 只显示结束时间
    case endOnly // = 3

    public init() {
      self = .hide
    }

    public init?(rawValue: Int) {
      switch rawValue {
      case 0: self = .hide
      case 1: self = .normal
      case 2: self = .startOnly
      case 3: self = .endOnly
      default: return nil
      }
    }

    public var rawValue: Int {
      switch self {
      case .hide: return 0
      case .normal: return 1
      case .startOnly: return 2
      case .endOnly: return 3
      }
    }

  }

  public init() {}

  fileprivate var _timeUnit: ServerPB_Entities_TimeUnit?
  fileprivate var _startEndLayout: ServerPB_Entities_TimeFormat.StartEndLayout?
  fileprivate var _isShowToOthers: Bool?
}

#if swift(>=4.2)

extension ServerPB_Entities_TimeFormat.StartEndLayout: CaseIterable {
  // Support synthesized by the compiler.
}

#endif  // swift(>=4.2)

extension ServerPB_Entities_TimeFormat: LarkHTTP.Message, LarkHTTP._MessageImplementationBase, LarkHTTP._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".TimeFormat"
  public static let _protobuf_nameMap: LarkHTTP._NameMap = [
    1: .standard(proto: "time_unit"),
    2: .standard(proto: "start_end_layout"),
    3: .standard(proto: "is_show_to_others")
  ]

  public mutating func decodeMessage<D: LarkHTTP.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularEnumField(value: &self._timeUnit)
      case 2: try decoder.decodeSingularEnumField(value: &self._startEndLayout)
      case 3: try decoder.decodeSingularBoolField(value: &self._isShowToOthers)
      default: break
      }
    }
  }

  public func traverse<V: LarkHTTP.Visitor>(visitor: inout V) throws {
    if let v = self._timeUnit {
      try visitor.visitSingularEnumField(value: v, fieldNumber: 1)
    }
    if let v = self._startEndLayout {
      try visitor.visitSingularEnumField(value: v, fieldNumber: 2)
    }
    if let v = self._isShowToOthers {
      try visitor.visitSingularBoolField(value: v, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: ServerPB_Entities_TimeFormat, rhs: ServerPB_Entities_TimeFormat) -> Bool {
    if lhs._timeUnit != rhs._timeUnit { return false }
    if lhs._startEndLayout != rhs._startEndLayout { return false }
    if lhs._isShowToOthers != rhs._isShowToOthers { return false }
    if lhs.unknownFields != rhs.unknownFields { return false }
    return true
  }
}

extension ServerPB_Entities_TimeFormat.StartEndLayout: LarkHTTP._ProtoNameProviding {
  public static let _protobuf_nameMap: LarkHTTP._NameMap = [
    0: .same(proto: "HIDE"),
    1: .same(proto: "NORMAL"),
    2: .same(proto: "START_ONLY"),
    3: .same(proto: "END_ONLY")
  ]
}

public enum ServerPB_Entities_TagColor: LarkHTTP.Enum {
  public typealias RawValue = Int

  /// BLUE兜底
  case blue // = 0
  case gray // = 1
  case indigo // = 2
  case wathet // = 3
  case green // = 4
  case turquoise // = 5
  case yellow // = 6
  case lime // = 7
  case red // = 8
  case orange // = 9
  case purple // = 10
  case violet // = 11
  case carmine // = 12

  public init() {
    self = .blue
  }

  public init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .blue
    case 1: self = .gray
    case 2: self = .indigo
    case 3: self = .wathet
    case 4: self = .green
    case 5: self = .turquoise
    case 6: self = .yellow
    case 7: self = .lime
    case 8: self = .red
    case 9: self = .orange
    case 10: self = .purple
    case 11: self = .violet
    case 12: self = .carmine
    default: return nil
    }
  }

  public var rawValue: Int {
    switch self {
    case .blue: return 0
    case .gray: return 1
    case .indigo: return 2
    case .wathet: return 3
    case .green: return 4
    case .turquoise: return 5
    case .yellow: return 6
    case .lime: return 7
    case .red: return 8
    case .orange: return 9
    case .purple: return 10
    case .violet: return 11
    case .carmine: return 12
    }
  }

}

#if swift(>=4.2)

extension ServerPB_Entities_TagColor: CaseIterable {
  // Support synthesized by the compiler.
}

#endif  // swift(>=4.2)

public enum ServerPB_Entities_TimeUnit: LarkHTTP.Enum {
  public typealias RawValue = Int
  case second // = 0
  case minute // = 1
  case hour // = 2
  case day // = 3
  case month // = 4
  case year // = 5

  public init() {
    self = .second
  }

  public init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .second
    case 1: self = .minute
    case 2: self = .hour
    case 3: self = .day
    case 4: self = .month
    case 5: self = .year
    default: return nil
    }
  }

  public var rawValue: Int {
    switch self {
    case .second: return 0
    case .minute: return 1
    case .hour: return 2
    case .day: return 3
    case .month: return 4
    case .year: return 5
    }
  }

}

#if swift(>=4.2)

extension ServerPB_Entities_TimeUnit: CaseIterable {
  // Support synthesized by the compiler.
}

#endif  // swift(>=4.2)

public struct ServerPB_Entities_TagInfo {
  // LarkHTTP.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the LarkHTTP library for
  // methods supported on all messages.

  public var isShowTag: Bool {
    get { return _isShowTag ?? false }
    set { _isShowTag = newValue }
  }
  /// Returns true if `isShowTag` has been explicitly set.
  public var hasIsShowTag: Bool { return self._isShowTag != nil }
  /// Clears the value of `isShowTag`. Subsequent reads from it will return its default value.
  public mutating func clearIsShowTag() { self._isShowTag = nil }

  public var tagColor: ServerPB_Entities_TagColor {
    get { return _tagColor ?? .blue }
    set { _tagColor = newValue }
  }
  /// Returns true if `tagColor` has been explicitly set.
  public var hasTagColor: Bool { return self._tagColor != nil }
  /// Clears the value of `tagColor`. Subsequent reads from it will return its default value.
  public mutating func clearTagColor() { self._tagColor = nil }

  public var unknownFields = LarkHTTP.UnknownStorage()

  public init() {}

  fileprivate var _isShowTag: Bool?
  fileprivate var _tagColor: ServerPB_Entities_TagColor?
}

extension ServerPB_Entities_TagInfo: LarkHTTP.Message, LarkHTTP._MessageImplementationBase, LarkHTTP._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".TagInfo"
  public static let _protobuf_nameMap: LarkHTTP._NameMap = [
    1: .standard(proto: "is_show_tag"),
    2: .standard(proto: "tag_color")
  ]

  public mutating func decodeMessage<D: LarkHTTP.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularBoolField(value: &self._isShowTag)
      case 2: try decoder.decodeSingularEnumField(value: &self._tagColor)
      default: break
      }
    }
  }

  public func traverse<V: LarkHTTP.Visitor>(visitor: inout V) throws {
    if let v = self._isShowTag {
      try visitor.visitSingularBoolField(value: v, fieldNumber: 1)
    }
    if let v = self._tagColor {
      try visitor.visitSingularEnumField(value: v, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: ServerPB_Entities_TagInfo, rhs: ServerPB_Entities_TagInfo) -> Bool {
    if lhs._isShowTag != rhs._isShowTag { return false }
    if lhs._tagColor != rhs._tagColor { return false }
    if lhs.unknownFields != rhs.unknownFields { return false }
    return true
  }
}

// swiftlint:enable all
