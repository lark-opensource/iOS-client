//
//  IMAtUserAnalysisService.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/7/21.
//

import UIKit
import LarkModel
import LarkSDKInterface
import RxSwift
import LarkContainer
import LKCommonsLogging
import LarkBaseKeyboard
import EditTextView

/// TODO: 李洛斌
/// 1. 局部复制的问题 @前面的位置 卡着文字会有问题 [wait, 以及@在最后, 代码先下了]
/// 2 anchor的局部复制的问题[wait]

public protocol IMAtUserAnalysisService: AnyObject {

    func updateAttrAtUserInfoBeforePasteIfNeed(_ attr: NSAttributedString,
                                                      textView: LarkEditTextView,
                                                      isSameChat: Bool) -> NSAttributedString

    func updateAttrAtInfoAfterPaste(_ attr: NSAttributedString,
                                                chat: Chat,
                                                textView: LarkEditTextView,
                                                isSameChat: Bool,
                                                finish: (() -> Void)?)
}

public struct ChatUserAnalysisInfo {
    let isMember: Bool
    let chatter: Chatter
    let nickName: String
}

public class IMAtUserAnalysisServiceIMP: IMAtUserAnalysisService {

    static let logger = Logger.log(IMAtUserAnalysisServiceIMP.self, category: "IMAtUserAnalysisServiceIMP")

    public let userResolver: UserResolver

    private let copyKey = NSAttributedString.Key("copy_at_key")

    private var atAnalysisFg: Bool {
        self.userResolver.fg.staticFeatureGatingValue(with: "messenger.input.copy_@")
    }

    private let disposeBag = DisposeBag()

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    public func updateAttrAtUserInfoBeforePasteIfNeed(_ attr: NSAttributedString,
                                                      textView: LarkEditTextView,
                                                      isSameChat: Bool) -> NSAttributedString {
        if !isSameChat {
            return self.replaceAtInfoBeforePasteIfNeed(attr, textView: textView)
        } else {
            return self.removeAllAtAll(attr, textView: textView)
        }
    }

    public func removeAllAtAll(_ attr: NSAttributedString, textView: LarkEditTextView) -> NSAttributedString {
        guard atAnalysisFg else { return attr }
        let muattr = NSMutableAttributedString(attributedString: attr)
        let color = textView.defaultTypingAttributes[.foregroundColor] ?? UIColor.ud.N600
        attr.enumerateAttribute(AtTransformer.UserIdAttributedKey, in: NSRange(location: 0, length: attr.length)) { value, range, _ in
            if let value = value as? AtChatterInfo {
                /// at的话 将来不做替换
                if value.id == "all" {
                    muattr.addAttributes([self.copyKey: value,
                        .foregroundColor: color], range: range)
                    muattr.removeAttribute(AtTransformer.UserIdAttributedKey, range: range)
                }
            }
        }
        return muattr
    }

    public func replaceAtInfoBeforePasteIfNeed(_ attr: NSAttributedString, textView: LarkEditTextView) -> NSAttributedString {
        guard atAnalysisFg else { return attr }
        let muattr = NSMutableAttributedString(attributedString: attr)
        let color = textView.defaultTypingAttributes[.foregroundColor] ?? UIColor.ud.N600
        attr.enumerateAttribute(AtTransformer.UserIdAttributedKey, in: NSRange(location: 0, length: attr.length)) { value, range, _ in
            if let value = value as? AtChatterInfo {
                muattr.removeAttribute(AtTransformer.UserIdAttributedKey, range: range)
                /// at的话 将来不做替换
                if value.id != "all" {
                    muattr.addAttributes([self.copyKey: value,
                        .foregroundColor: color], range: range)
                } else {
                    muattr.addAttributes([.foregroundColor: color], range: range)
                }
            }
        }
        return muattr
    }

    public func updateAttrAtInfoAfterPaste(_ attr: NSAttributedString,
                                                chat: Chat,
                                                textView: LarkEditTextView,
                                                isSameChat: Bool,
                                                finish: (() -> Void)?) {
        guard atAnalysisFg else {
            finish?()
            return
        }
        guard !isSameChat else {
            let chatterInfo: [AtChatterInfo] = AtTransformer.getAllChatterInfoForAttributedString(attr)
            let chatterAPI = try? userResolver.resolve(assert: ChatterAPI.self)
            /// 这里使用isForceServer = false，等于trylocal
            /// 多数情况下走本地即可满足需求，因为从消息上复制 极端情况下服务端兜底
            /// chatterInfo中可能有重复的ID，所以实际需要请求的数量 是不重复的user id,这里利用set做个去重
            let requestUserIDs = Array(Set(chatterInfo.map { $0.id }))
            chatterAPI?.fetchChatChatters(ids: requestUserIDs,
                                          chatId: chat.id,
                                          isForceServer: false)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self, weak textView] (chatterMapInfo) in
                    guard let self = self, let textView = textView else {
                        finish?()
                        return
                    }
                    var result: [String: ChatUserAnalysisInfo] = [:]
                    chatterInfo.forEach { info in
                        if let chatter = chatterMapInfo[info.id] {
                            let nickName = chatter.displayName(chatId: chat.id,
                                                               chatType: chat.type,
                                                               scene: chat.oncallId.isEmpty ? .atOrUrgentPick : .oncall)
                            result[chatter.id] = ChatUserAnalysisInfo(isMember: !info.isOuter,
                                                                      chatter: chatter,
                                                                      nickName: nickName)
                        }
                    }
                    self.replaceUserInfoFor(textView, with: result, for: AtTransformer.UserIdAttributedKey)
                    Self.logger.info("IMAtUserAnalysisServiceIMP fetchChatChatters success chatID \(chat.id) - count: \(chatterInfo.count) - \(requestUserIDs.count)")
                    finish?()
                }, onError: { error in
                    finish?()
                    Self.logger.error("IMAtUserAnalysisServiceIMP fetchChatChatters error chatID \(chat.id)", error: error)
                    /// 本地失败 可能是数据清空等原因，尝试从服务端拉取一次
                }).disposed(by: self.disposeBag)
            return
        }

        var userIds: [String] = []
        attr.enumerateAttribute(self.copyKey, in: NSRange(location: 0, length: attr.length)) { value, _, _ in
            if let info = value as? AtChatterInfo, !info.isAnonymous {
                userIds.append(info.id)
            }
        }
        self.analysisForUserInfo(userIds, chat: chat) { [weak textView] reslut in
            guard let textView = textView else {
                finish?()
                return
            }
            if !reslut.isEmpty {
                self.replaceUserInfoFor(textView, with: reslut, for: self.copyKey)
            }
            finish?()
        }
    }

    private func analysisForUserInfo(_ userIds: [String], chat: Chat, finish: (([String: ChatUserAnalysisInfo]) -> Void)?) {
        /// 这里有个数量的限制
        guard !userIds.isEmpty else {
            finish?([:])
            return
        }
        var targetIds: [String] = []
        var userMap: [String: String] = [:]
        userIds.forEach { userId in
            if userMap.count < 100 {
                userMap[userId] = ""
            }
        }
        targetIds = Array(userMap.keys)
        let chatterAPI = try? userResolver.resolve(assert: ChatterAPI.self)
        let chatAPI = try? userResolver.resolve(assert: ChatAPI.self)
        guard let ob1 = chatterAPI?.fetchChatChatters(ids: targetIds, chatId: chat.id, isForceServer: false),
              let ob2 = chatAPI?.checkChattersInChat(chatterIds: targetIds, chatId: chat.id) else {
            finish?([:])
            return
        }

        Self.logger.info("IMAtUserAnalysisServiceIMP start request userIds count \(userIds.count) \(targetIds.count)-- \(chat.id)")
        Observable.zip(ob1, ob2)
            .timeout(.seconds(3), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (res1, res2) in
                Self.logger.info("IMAtUserAnalysisServiceIMP finish request -- \(chat.id)")
                var result: [String: ChatUserAnalysisInfo] = [:]
                for (chatterId, chatter) in res1 {
                    let nickName = chatter.displayName(chatId: chat.id,
                                                       chatType: chat.type,
                                                       scene: chat.oncallId.isEmpty ? .atOrUrgentPick : .oncall)
                    result[chatterId] = ChatUserAnalysisInfo(isMember: res2.contains(chatter.id),
                                                        chatter: chatter,
                                                        nickName: nickName)

                }
                finish?(result)
            }, onError: { (error) in
                finish?([:])
                Self.logger.error("analysisForUserInfo fail", error: error)
            }).disposed(by: self.disposeBag)
    }

    public func replaceUserInfoFor(_ textView: LarkEditTextView, with map: [String: ChatUserAnalysisInfo], for key: NSAttributedString.Key) {
        guard atAnalysisFg else { return }
        var ranges: [NSRange] = []
        var rangeMap: [NSRange: NSAttributedString] = [:]
        let muAttr = NSMutableAttributedString(attributedString: textView.attributedText)
        let defaultTypingAttributes = textView.defaultTypingAttributes
        muAttr.enumerateAttribute(key,
                                in: NSRange(location: 0, length: muAttr.length)) { value, range, _ in
            if let info = value as? AtChatterInfo, !info.isAnonymous, let userInfo = map[info.id] {
                info.name = userInfo.nickName
                info.actualName = userInfo.chatter.localizedName
                info.isOuter = !userInfo.isMember
                ranges.append(range)
                var attributes = muAttr.attributedSubstring(from: range).attributes(at: 0, effectiveRange: nil)
                let subText = NSMutableAttributedString(attributedString: AtTransformer.transformContentToString(info,
                                                                                               style: [:],
                                                                                               attributes: defaultTypingAttributes))
                attributes.removeValue(forKey: .foregroundColor)
                subText.addAttributes(attributes, range: NSRange(location: 0, length: subText.length))
                rangeMap[range] = subText
            }
        }
        ranges.reversed().forEach { range in
            if let value = rangeMap[range] {
                muAttr.replaceCharacters(in: range, with: value)
            }
        }
        textView.attributedText = muAttr
    }
}
