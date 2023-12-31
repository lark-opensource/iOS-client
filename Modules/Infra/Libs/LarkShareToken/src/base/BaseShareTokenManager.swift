//
//  BaseShareTokenManager.swift
//  LarkShareToken
//
//  Created by 赵冬 on 2020/4/14.
//
#if !LarkShareToken_Internal
import Foundation

public typealias ShareTokenHandler = ((_ map: [String: String]) -> Void)

public struct ObservePasteboardManager {
    public struct Notification {
        public static let startToObservePasteboard: NSNotification.Name = NSNotification.Name("lark.shareToken.startToObservePasteboard")
    }
    public static let throttle: DispatchTimeInterval = .microseconds(1000)
}

final public class ShareTokenManager {
    public static var shared = ShareTokenManager()

    init() {
    }

    public func cachePasteboardContent(string: String? = nil) {

    }

    public func registerHandler(source: String, handler: @escaping ShareTokenHandler) {

    }

    public func parsePasteboardToCheckWhetherOpenTokenAlert() {

    }
}
#endif
