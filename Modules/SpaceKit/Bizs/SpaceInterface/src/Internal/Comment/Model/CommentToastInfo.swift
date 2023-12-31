//
//  CommentToastInfo.swift
//  SKCommon
//
//  Created by huayufan on 2022/2/23.
//  


import UIKit

public struct CommentToastInfo: Codable {
    public var commentUUID: String?
    public var commentId: String?
    var code: Int
    var replyUUID: String?
    public var message: String? // 前端指定的toast文案
    
    public enum CodingKeys: String, CodingKey {
        case commentUUID
        case commentId
        case code
        case replyUUID
        case message
    }
    
    public enum Action: String {
        case showDetail
        case retry
    }
    
    public enum Result {
        case success
        /// 内容不符合规范
        case contentReviewFail
        /// 无评论权限
        case permissionFail
        /// 网络错误
        case networkFail
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        commentUUID = try? container.decode(String.self, forKey: .commentUUID)
        commentId = try? container.decode(String.self, forKey: .commentId)
        replyUUID = try? container.decode(String.self, forKey: .replyUUID)
        if let intCode = try? container.decode(Int.self, forKey: .code) {
            code = intCode
        } else if let strCode = try? container.decode(String.self, forKey: .code),
                  let toIntcode = Int(strCode) {
            code = toIntcode
        } else {
            code = -1
        }
    }
    
    public var result: Result {
        if code == 0 {
            return .success
        } else if code == 10009 || code == 10013 {
            return .contentReviewFail
        } else if code == 4 {
            return .permissionFail
        } else {
            return .networkFail
        }
    }
}

extension CommentToastInfo.Result {
    public var action: CommentToastInfo.Action {
        switch self {
        case .success, .contentReviewFail:
            return .showDetail
        case .permissionFail, .networkFail:
            return .retry
        }
    }
}

public protocol CommentToastViewType: AnyObject {
   func remove()
}

public protocol AddCommentToastView: AnyObject {
    func show(on: UIView, params: [String: Any], delay: CGFloat, onClick: @escaping (CommentToastInfo) -> Void)
    func showLoading(on: UIView) -> CommentToastViewType
}
