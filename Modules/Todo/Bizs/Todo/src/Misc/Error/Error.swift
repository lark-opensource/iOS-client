//
//  Error.swift
//  Todo
//
//  Created by 张威 on 2021/8/5.
//

import LarkRustClient
import RustPB

/// 描述用户可理解（`message`）的 Error
struct UserError: Error {
    static let defaultMessage = I18N.Todo_common_SthWentWrongTryLater
    struct EmptyError: Error { }

    var error: Error
    var message: String

    init(error: Error, message: String) {
        self.error = error
        self.message = message
    }

    init(message: String) {
        self.error = EmptyError()
        self.message = message
    }
}

extension UserError {
    enum BizCodeType: String {
        /// 执行者上限
        case assigneeLimit
        /// 关注者上限
        case followerLimit
        /// text 没通过审核
        case textNotAudit
        /// image 没通过审核
        case imageNotAudit
        /// 拉取评论时，该评论所属的 Todo 还没有同步到 server
        case todoOfCommentNotFound
    }

    // 错误码配置，忽略魔法数约束
    // nolint: magic number
    func bizCode() -> BizCodeType? {
        guard
            let rcErr = self.error as? RCError,
            case .businessFailure(let errInfo) = rcErr
        else {
            return nil
        }
        switch errInfo.errorCode {
        case Int32(RustPB.Basic_V1_Auth_ErrorCode.todoAssigneeNumberExceedsLimit.rawValue):
            return .assigneeLimit
        case Int32(RustPB.Basic_V1_Auth_ErrorCode.todoFollowerNumberExceedsLimit.rawValue):
            return .followerLimit
        case 40_016:
            return .textNotAudit
        case 40_017:
            return .imageNotAudit
        case 380_001:
            return .todoOfCommentNotFound
        default:
            return nil
        }
    }
    // enable-lint: magic number
}

extension Rust {

    static func makeUserError(from err: Error) -> UserError {
        guard
            let rcErr = err as? RCError,
            case .businessFailure(let errInfo) = rcErr,
            !errInfo.displayMessage.isEmpty
        else {
            return .init(error: err, message: UserError.defaultMessage)
        }
        return .init(error: err, message: errInfo.displayMessage)
    }

}
