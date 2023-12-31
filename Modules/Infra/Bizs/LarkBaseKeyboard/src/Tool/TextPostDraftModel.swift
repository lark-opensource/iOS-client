//
//  TextPostDraftModel.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/5/3.
//

import UIKit
import LarkExtensions
import RustPB
import EditTextView

public protocol Persistable {
    static var `default`: Self { get }

    init(unarchive: [String: Any])
    func archive() -> [String: Any]

    func stringify() -> String
}

public extension Persistable {
    func stringify() -> String {
        return JSONStringWithObject(object: self.archive())
    }

    static func parse(_ json: String? = nil) -> Self {
        guard let json = json, let data = json.data(using: .utf8) else {
            return .default
        }
        do {
            return try Self(unarchive: JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:])
        } catch {
            assertionFailure("\(Self.self)parse fail")
        }
        return .default
    }
}

public struct TextDraftModel: Persistable {
    public static let `default` = TextDraftModel()
    public var content: String = ""
    public var userInfoDic: [String: String] = [:]
    public private(set) var unarchiveSuccess = false
    public init(content: String = "",
                userInfoDic: [String: String] = [:]) {
        self.content = content
        self.userInfoDic = userInfoDic
    }
    /// 如果后续需要增加一个新的属性，不要
    public init(unarchive: [String: Any]) {
        guard let content = unarchive["richTextContent"] as? String,
              let userInfoDic = unarchive["userInfoDic"] as? [String: String] else {
                  self.unarchiveSuccess = false
            return
        }
        self.content = content
        self.userInfoDic = userInfoDic
        self.unarchiveSuccess = true
    }

    public func archive() -> [String: Any] {
        return [
            "richTextContent": self.content,
            "userInfoDic": userInfoDic
        ]
    }

    /// 如果没有内容 需要返回"",否则feed会展示有问题
    public func stringify() -> String {
        if self.content.isEmpty {
            return ""
        }
        return JSONStringWithObject(object: self.archive())
    }

    /// feed页面展示草稿使用
    public static func getContentPreviewFromDraft(_ draft: String) -> String? {
        if draft.isEmpty {
            return nil
        }
        let model = TextDraftModel.parse(draft)
        if model.unarchiveSuccess {
            return RichTextTransformKit.transformDraftToText(content: model.content)
        }
        return RichTextTransformKit.transformDraftToText(content: draft)
    }
}

public struct PostDraftModel: Persistable {
    public static let `default` = PostDraftModel()

    public var title: String = ""
    public var content: String = ""
    public var uploaderDraft: String = ""
    public var chatId: String = ""
    public var userInfoDic: [String: String] = [:]
    public var lingoElements: [SingleLingoElement] = []
    // processProvider不参与archive，Post撤回重编时URL附带额外的Inline信息，无法通过richText携带
    public var processProvider: ElementProcessProvider = [:]

    public init(title: String = "",
                content: String = "",
                uploaderDraft: String = "",
                chatId: String = "",
                userInfoDic: [String: String] = [:],
                lingoElements: [SingleLingoElement] = []) {
        self.title = title
        self.content = content
        self.uploaderDraft = uploaderDraft
        self.chatId = chatId
        self.userInfoDic = userInfoDic
        self.lingoElements = lingoElements
    }

    public init(unarchive: [String: Any]) {
        guard let title = unarchive["title"] as? String,
              let content = unarchive["content"] as? String,
              let uploaderDraft = unarchive["uploaderDraft"] as? String
        else {
            return
        }

        self.title = title
        self.content = content
        self.uploaderDraft = uploaderDraft

        //兼容旧版本
        if let chatId = unarchive["chatId"] as? String {
            self.chatId = chatId
        }
        //旧版本可能不存在
        if let userInfoDic = unarchive["userInfoDic"] as? [String: String] {
            self.userInfoDic = userInfoDic
        }
        // 词条相关的信息
        if let lingoElements = unarchive["lingoElements"] as? [[String: Any]] {
            self.lingoElements = lingoElements.map{ SingleLingoElement.init(unarchive: $0) }

        }

    }

    public func archive() -> [String: Any] {
        return [
            "title": self.title,
            "content": self.content,
            "uploaderDraft": self.uploaderDraft,
            "chatId": self.chatId,
            "userInfoDic": userInfoDic,
            "lingoElements": self.lingoElements.map{ $0.archive() }
        ]
    }
}

extension PostDraftModel: Equatable {
    public static func == (lhs: PostDraftModel, rhs: PostDraftModel) -> Bool {
        return lhs.title == rhs.title &&
        lhs.content == rhs.content &&
        lhs.uploaderDraft == rhs.uploaderDraft &&
        lhs.chatId == rhs.chatId &&
        lhs.lingoElements == rhs.lingoElements
    }
}
