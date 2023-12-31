//
//  refusereply.pb.swift
//  LarkNotificationContentExtensionSDK
//
//  Created by shin on 2023/3/17.
//

// refusereply.pb.swift 是从 ServerPB 中 videochat.pb.swift 文件中摘取的拒绝回复相关的
// ServerPB_Videochat_RefuseReplyRequest
// ServerPB_Videochat_RefuseReplyResponse

import Foundation
import LarkHTTP

fileprivate let _protobuf_package = "videochat"

public struct ServerPB_Videochat_RefuseReplyRequest {
  // LarkHTTP.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the LarkHTTP library for
  // methods supported on all messages.

  public var meetingID: String {
    get {return _meetingID ?? String()}
    set {_meetingID = newValue}
  }
  /// Returns true if `meetingID` has been explicitly set.
  public var hasMeetingID: Bool {return self._meetingID != nil}
  /// Clears the value of `meetingID`. Subsequent reads from it will return its default value.
  public mutating func clearMeetingID() {self._meetingID = nil}

  public var refuseReply: String {
    get {return _refuseReply ?? String()}
    set {_refuseReply = newValue}
  }
  /// Returns true if `refuseReply` has been explicitly set.
  public var hasRefuseReply: Bool {return self._refuseReply != nil}
  /// Clears the value of `refuseReply`. Subsequent reads from it will return its default value.
  public mutating func clearRefuseReply() {self._refuseReply = nil}

  public var isSingleMeeting: Bool {
    get {return _isSingleMeeting ?? false}
    set {_isSingleMeeting = newValue}
  }
  /// Returns true if `isSingleMeeting` has been explicitly set.
  public var hasIsSingleMeeting: Bool {return self._isSingleMeeting != nil}
  /// Clears the value of `isSingleMeeting`. Subsequent reads from it will return its default value.
  public mutating func clearIsSingleMeeting() {self._isSingleMeeting = nil}

  public var inviterUserID: String {
    get {return _inviterUserID ?? String()}
    set {_inviterUserID = newValue}
  }
  /// Returns true if `inviterUserID` has been explicitly set.
  public var hasInviterUserID: Bool {return self._inviterUserID != nil}
  /// Clears the value of `inviterUserID`. Subsequent reads from it will return its default value.
  public mutating func clearInviterUserID() {self._inviterUserID = nil}

  public var unknownFields = LarkHTTP.UnknownStorage()

  public init() {}

  fileprivate var _meetingID: String? = nil
  fileprivate var _refuseReply: String? = nil
  fileprivate var _isSingleMeeting: Bool? = nil
  fileprivate var _inviterUserID: String? = nil
}

public struct ServerPB_Videochat_RefuseReplyResponse {
  // LarkHTTP.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the LarkHTTP library for
  // methods supported on all messages.

  public var groupStatus: ServerPB_Videochat_RefuseReplyResponse.RefuseReplyGroupStatus {
    get {return _groupStatus ?? .groupSuccess}
    set {_groupStatus = newValue}
  }
  /// Returns true if `groupStatus` has been explicitly set.
  public var hasGroupStatus: Bool {return self._groupStatus != nil}
  /// Clears the value of `groupStatus`. Subsequent reads from it will return its default value.
  public mutating func clearGroupStatus() {self._groupStatus = nil}

  public var singleStatus: ServerPB_Videochat_RefuseReplyResponse.RefuseReplySingleStatus {
    get {return _singleStatus ?? .singleSuccess}
    set {_singleStatus = newValue}
  }
  /// Returns true if `singleStatus` has been explicitly set.
  public var hasSingleStatus: Bool {return self._singleStatus != nil}
  /// Clears the value of `singleStatus`. Subsequent reads from it will return its default value.
  public mutating func clearSingleStatus() {self._singleStatus = nil}

  public var unknownFields = LarkHTTP.UnknownStorage()

  public enum RefuseReplyGroupStatus: LarkHTTP.Enum {
    public typealias RawValue = Int
    case groupSuccess // = 0
    case baseGroupFail // = 1

    ///会议结束
    case meetingEnd // = 2

    ///被邀请人离开
    case inviteIdle // = 3

    public init() {
      self = .groupSuccess
    }

    public init?(rawValue: Int) {
      switch rawValue {
      case 0: self = .groupSuccess
      case 1: self = .baseGroupFail
      case 2: self = .meetingEnd
      case 3: self = .inviteIdle
      default: return nil
      }
    }

    public var rawValue: Int {
      switch self {
      case .groupSuccess: return 0
      case .baseGroupFail: return 1
      case .meetingEnd: return 2
      case .inviteIdle: return 3
      }
    }

  }

  public enum RefuseReplySingleStatus: LarkHTTP.Enum {
    public typealias RawValue = Int
    case singleSuccess // = 1
    case baseSingleFail // = 2

    public init() {
      self = .singleSuccess
    }

    public init?(rawValue: Int) {
      switch rawValue {
      case 1: self = .singleSuccess
      case 2: self = .baseSingleFail
      default: return nil
      }
    }

    public var rawValue: Int {
      switch self {
      case .singleSuccess: return 1
      case .baseSingleFail: return 2
      }
    }

  }

  public init() {}

  fileprivate var _groupStatus: ServerPB_Videochat_RefuseReplyResponse.RefuseReplyGroupStatus? = nil
  fileprivate var _singleStatus: ServerPB_Videochat_RefuseReplyResponse.RefuseReplySingleStatus? = nil
}

#if swift(>=4.2)

extension ServerPB_Videochat_RefuseReplyResponse.RefuseReplyGroupStatus: CaseIterable {
  // Support synthesized by the compiler.
}

extension ServerPB_Videochat_RefuseReplyResponse.RefuseReplySingleStatus: CaseIterable {
  // Support synthesized by the compiler.
}

#endif  // swift(>=4.2)

extension ServerPB_Videochat_RefuseReplyRequest: LarkHTTP.Message, LarkHTTP._MessageImplementationBase, LarkHTTP._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".RefuseReplyRequest"
  public static let _protobuf_nameMap: LarkHTTP._NameMap = [
    1: .standard(proto: "meeting_id"),
    2: .standard(proto: "refuse_reply"),
    3: .standard(proto: "is_single_meeting"),
    4: .standard(proto: "inviter_user_id"),
  ]

  public mutating func decodeMessage<D: LarkHTTP.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularStringField(value: &self._meetingID)
      case 2: try decoder.decodeSingularStringField(value: &self._refuseReply)
      case 3: try decoder.decodeSingularBoolField(value: &self._isSingleMeeting)
      case 4: try decoder.decodeSingularStringField(value: &self._inviterUserID)
      default: break
      }
    }
  }

  public func traverse<V: LarkHTTP.Visitor>(visitor: inout V) throws {
    if let v = self._meetingID {
      try visitor.visitSingularStringField(value: v, fieldNumber: 1)
    }
    if let v = self._refuseReply {
      try visitor.visitSingularStringField(value: v, fieldNumber: 2)
    }
    if let v = self._isSingleMeeting {
      try visitor.visitSingularBoolField(value: v, fieldNumber: 3)
    }
    if let v = self._inviterUserID {
      try visitor.visitSingularStringField(value: v, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: ServerPB_Videochat_RefuseReplyRequest, rhs: ServerPB_Videochat_RefuseReplyRequest) -> Bool {
    if lhs._meetingID != rhs._meetingID {return false}
    if lhs._refuseReply != rhs._refuseReply {return false}
    if lhs._isSingleMeeting != rhs._isSingleMeeting {return false}
    if lhs._inviterUserID != rhs._inviterUserID {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension ServerPB_Videochat_RefuseReplyResponse: LarkHTTP.Message, LarkHTTP._MessageImplementationBase, LarkHTTP._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".RefuseReplyResponse"
  public static let _protobuf_nameMap: LarkHTTP._NameMap = [
    1: .standard(proto: "group_status"),
    2: .standard(proto: "single_status"),
  ]

  public mutating func decodeMessage<D: LarkHTTP.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularEnumField(value: &self._groupStatus)
      case 2: try decoder.decodeSingularEnumField(value: &self._singleStatus)
      default: break
      }
    }
  }

  public func traverse<V: LarkHTTP.Visitor>(visitor: inout V) throws {
    if let v = self._groupStatus {
      try visitor.visitSingularEnumField(value: v, fieldNumber: 1)
    }
    if let v = self._singleStatus {
      try visitor.visitSingularEnumField(value: v, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: ServerPB_Videochat_RefuseReplyResponse, rhs: ServerPB_Videochat_RefuseReplyResponse) -> Bool {
    if lhs._groupStatus != rhs._groupStatus {return false}
    if lhs._singleStatus != rhs._singleStatus {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension ServerPB_Videochat_RefuseReplyResponse.RefuseReplyGroupStatus: LarkHTTP._ProtoNameProviding {
  public static let _protobuf_nameMap: LarkHTTP._NameMap = [
    0: .same(proto: "GROUP_SUCCESS"),
    1: .same(proto: "BASE_GROUP_FAIL"),
    2: .same(proto: "MEETING_END"),
    3: .same(proto: "INVITE_IDLE"),
  ]
}

extension ServerPB_Videochat_RefuseReplyResponse.RefuseReplySingleStatus: LarkHTTP._ProtoNameProviding {
  public static let _protobuf_nameMap: LarkHTTP._NameMap = [
    1: .same(proto: "SINGLE_SUCCESS"),
    2: .same(proto: "BASE_SINGLE_FAIL"),
  ]
}

