//
//  ChatOpenPinCardService.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/5/17.
//

import Foundation
import LarkModel

public protocol ChatOpenPinCardService: AnyObject {
    func update(doUpdate: @escaping (ChatPinPayload) -> ChatPinPayload?, completion: ((Bool) -> Void)?)
    func calculateSizeAndUpateView(shouldUpdate: @escaping (Int64, ChatPinPayload?) -> Bool)
    func refresh()
    var contentAvailableMaxWidth: CGFloat { get }
    var headerAvailableMaxWidth: CGFloat { get }
    var targetViewController: UIViewController { get }
}

public final class DefaultChatOpenPinCardServiceImp: ChatOpenPinCardService {
    public func update(doUpdate: @escaping (ChatPinPayload) -> ChatPinPayload?, completion: ((Bool) -> Void)?) {}
    public func calculateSizeAndUpateView(shouldUpdate: @escaping (Int64, ChatPinPayload?) -> Bool) {}
    public func refresh() {}
    public var contentAvailableMaxWidth: CGFloat { return .zero }
    public var headerAvailableMaxWidth: CGFloat { return .zero }
    public var targetViewController: UIViewController { return UIViewController() }
    public init() {}
}

public protocol ChatOpenPinSummaryService: AnyObject {
    func update(doUpdate: @escaping (ChatPinPayload) -> ChatPinPayload?, completion: ((Bool) -> Void)?)
}

public final class DefaultChatOpenPinSummaryServiceImp: ChatOpenPinSummaryService {
    public func update(doUpdate: @escaping (ChatPinPayload) -> ChatPinPayload?, completion: ((Bool) -> Void)?) {}
    public init() {}
}
