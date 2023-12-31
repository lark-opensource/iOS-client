//
//  ProfileViewModel.swift
//  LarkProfile
//
//  Created by Yuri on 2022/8/16.
//

import Foundation
import UIKit
import RxSwift
import RustPB
import LarkContainer
import LarkMessengerInterface

public enum ProfileStatus {
    case error
    case empty
    case normal
    case noPermission
}

public struct ProfileState {
    struct Background {
        var key: String?
        var placeholder: UIImage?
    }
    
    public struct UserDescription: Equatable {
        var text: String
        var attrText: NSMutableAttributedString
        var urlRanges: [NSRange: URL]?
        var textRanges: [NSRange: String]?
        var length: Int = 0
    }
    
    var background = Background()
    var desc: UserDescription?
    var status = ProfileStatus.normal
    var isMe: Bool = false
    var isLocalData: Bool = false // 是否来自缓存数据
}

public final class ProfileViewModel: UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver
    
    typealias InlineTrackTime = (sourceText: String, startTime: CFTimeInterval, tracked: Bool, isFromPush: Bool)
    
    @ScopedInjectedLazy var inlineService: TextToInlineService?
    
    public var state = BehaviorSubject<ProfileState?>(value: nil)
    public var currentState: ProfileState? {
        didSet {
            guard let s = currentState else { return }
            state.onNext(s)
        }
    }
    public var desc = BehaviorSubject<ProfileState.UserDescription?>(value: nil)
    public var currentDesc: ProfileState.UserDescription? {
        didSet {
            guard let currentDesc = currentDesc else { return }
            desc.onNext(currentDesc)
        }
    }
    
    init(resolver: UserResolver) {
        self.userResolver = resolver
    }
    
    func updateError() {
        var state = self.currentState
        state?.status = .error
        self.currentState = state
    }
    
    func update(profile: ProfileInfoProtocol, isMe: Bool, isLocal: Bool, fromPush: Bool) {
        // 高优先级队列加载视图数据
        let userInfo = profile.userInfoProtocol
        var state = self.currentState ?? ProfileState()
        state.isMe = isMe
        if profile.canNotFind {
            state.status = .noPermission
        } else if profile.fieldOrders.isEmpty, !isLocal {
            state.status = .empty
        } else {
            state.status = .normal
        }
        state.isLocalData = isLocal
        
        self.generateUserDescription(userInfo: userInfo, isMe: isMe, fromPush: fromPush) { (desc, type) in
            state.desc = desc
            self.currentState = state
        }
    }
    
    // swiftlint:disable all
    func generateUserDescription(userInfo: UserInfoProtocol, isMe: Bool, fromPush: Bool, callback : @escaping ((ProfileState.UserDescription?, InlineSourceType?) -> Void)) {
        let textColor = userInfo.description_p.text.isEmpty && isMe ? ProfileStatusView.Cons.emptyTextColor : ProfileStatusView.Cons.textColor
        if !userInfo.description_p.text.isEmpty || isMe {
            var text = userInfo.description_p.text
            let length = self.getLength(forText: text)
            if isMe {
                if userInfo.description_p.text.isEmpty {
                    text = BundleI18n.LarkProfile.Lark_Profile_EnterYourSignature
                }
            }
            let inlineTime = self.generateTrackTime(sourceText: userInfo.description_p.text, fromPush: fromPush)
            if !userInfo.description_p.text.isEmpty, let inlineService = self.inlineService {
                inlineService.replaceWithInlineTrySDK(sourceID: userInfo.userID,
                                                      sourceText: userInfo.description_p.text,
                                                      type: .personalSig,
                                                      strategy: .forceServer,
                                                      textColor: textColor,
                                                      linkColor: ProfileStatusView.Cons.linkColor,
                                                      font: ProfileStatusView.Cons.textFont) { [weak self] (attr, urlRange, textRange, sourceType) in
                    guard let self = self else { return }
                    let desc = ProfileState.UserDescription(text: userInfo.description_p.text, attrText: attr, urlRanges: urlRange, textRanges: textRange, length: length)
                    self.trackInlineRender(inlineTrackTime: inlineTime, sourceID: userInfo.userID, sourceText: userInfo.description_p.text, sourceType: sourceType)
                    callback(desc, sourceType)
                }
            } else {
                let attr = NSMutableAttributedString(string: text, attributes: [.foregroundColor: textColor, .font: ProfileStatusView.Cons.textFont])
                let desc = ProfileState.UserDescription(text: userInfo.description_p.text, attrText: attr, length: length)
                callback(desc, nil)
            }
        } else {
            callback(nil, nil)
        }
    }

    func generateTrackTime(sourceText: String, fromPush: Bool) -> InlineTrackTime {
        // 更换签名需要重新记录开始时间
        return (sourceText, CACurrentMediaTime(), false, fromPush)
    }
    
    func trackInlineRender(inlineTrackTime: InlineTrackTime, sourceID: String, sourceText: String, sourceType: InlineSourceType) {
        // 需要判断sourceText，否则有异步时序问题
        let endTime = CACurrentMediaTime()
        mainOrAsync { [weak self] in
            self?.inlineService?.trackURLInlineRender(
                sourceID: sourceID,
                sourceText: sourceText,
                type: .personalSig,
                sourceType: sourceType,
                scene: "profile_sign",
                startTime: inlineTrackTime.startTime,
                endTime: endTime,
                isFromPush: inlineTrackTime.isFromPush
            )
        }
    }
    
    private func getLength(forText text: String) -> Int {
        return text.reduce(0) { res, char in
            // 单字节的 UTF-8（英文、半角符号）算 1 个字符，其余的（中文、Emoji等）算 2 个字符
            return res + min(char.utf8.count, 2)
        }
    }
}

func mainOrAsync(task: @escaping () -> Void) {
    if Thread.isMainThread {
        task()
    } else {
        DispatchQueue.main.async { task() }
    }
}
