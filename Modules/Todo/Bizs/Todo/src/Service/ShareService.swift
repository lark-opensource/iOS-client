//
//  ShareService.swift
//  Todo
//
//  Created by 张威 on 2021/1/22.
//

import RxSwift
import TodoInterface

/// 分享结果
enum ShareToLarkResult {
    typealias BlockAlert = (message: String, preferToast: Bool)
    /// 成功
    ///   - messageIds: 分享成功后，对应的 messageIds
    ///   - blockAlert: 局部失败的 alert 信息
    case success(messageIds: [String], blockAlert: BlockAlert?)
    /// 失败（message 描述失败信息）
    case failure(message: String)
}

protocol ShareService: AnyObject {

    func shareToLark(
        withTodoId todoGuid: String,
        items: [SelectSharingItemBody.SharingItem],
        type: Rust.TodoShareType,
        message: String?,
        completion: ((ShareToLarkResult) -> Void)?
    )

}
