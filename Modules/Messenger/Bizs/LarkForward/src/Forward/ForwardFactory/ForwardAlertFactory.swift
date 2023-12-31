//
//  ForwardAlertFactory.swift
//  LarkForward
//
//  Created by 姚启灏 on 2019/2/21.
//

import Foundation
import LarkModel
import LarkUIKit
import Swinject
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface
import LKLoadable
import LarkContainer

/// 用来生成相应的ForwardAlertProvider
public final class ForwardAlertFactory {
    private static var forwardAlertFactoryType: [ForwardAlertProvider.Type] = []
    private static var forwardAlertConfigFactoryType: [ForwardAlertConfig.Type] = []
    private let userResolver: UserResolver

    public static func register(type: ForwardAlertProvider.Type) {
        if !ForwardAlertFactory.forwardAlertFactoryType.contains(where: { $0 == type }) {
            ForwardAlertFactory.forwardAlertFactoryType.append(type)
        }
    }
    public static func registerAlertConfig(alertConfigType: ForwardAlertConfig.Type) {
        if !ForwardAlertFactory.forwardAlertConfigFactoryType.contains(where: { $0 == alertConfigType }) {
            ForwardAlertFactory.forwardAlertConfigFactoryType.append(alertConfigType)
        }
    }

    public init(userResolver: UserResolver) { self.userResolver = userResolver }

    public func createWithContent(content: ForwardAlertContent) -> ForwardAlertProvider? {
        SwiftLoadable.startOnlyOnce(key: "LarkForward_LarkForwardMessageAssembly_regist")
        guard let providerType = ForwardAlertFactory
            .forwardAlertFactoryType
            .first(where: { (type) -> Bool in
                type.canHandle(content: content)
            }) else { return nil }

        return providerType.init(userResolver: self.userResolver, content: content)
    }

    public func createAlertConfigWithContent(content: ForwardAlertContent) -> ForwardAlertConfig? {
        SwiftLoadable.startOnlyOnce(key: "LarkForward_LarkForwardMessageAssembly_regist")
        guard let providerType = ForwardAlertFactory
            .forwardAlertConfigFactoryType
            .first(where: { (type) -> Bool in
                type.canHandle(content: content)
            }) else { return nil }

        return providerType.init(userResolver: self.userResolver, content: content)
    }
}
