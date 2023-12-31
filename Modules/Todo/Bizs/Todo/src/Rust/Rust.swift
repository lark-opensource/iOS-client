//
//  Rust.swift
//  TodoInterface
//
//  Created by 张威 on 2020/11/11.
//

import LarkRustClient

enum Rust { }

extension Rust {

    static let defaultErrorDisplayMessage = I18N.Todo_common_SthWentWrongTryLater

    static func displayMessage(from err: Error, default: String = I18N.Todo_common_SthWentWrongTryLater) -> String {
        guard let rcErr = err as? RCError,
              case .businessFailure(let errInfo) = rcErr else {
            return `default`
        }
        guard !errInfo.displayMessage.isEmpty else {
            return `default`
        }
        return errInfo.displayMessage
    }

}
