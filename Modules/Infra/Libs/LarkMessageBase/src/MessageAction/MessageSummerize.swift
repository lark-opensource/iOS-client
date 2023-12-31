//
//  MessageSummerize.swift
//  LarkMessageBase
//
//  Created by qihongye on 2020/12/9.
//

import UIKit
import Foundation
import class LarkModel.Message
import LKLoadable

/// MetaModel summerize generator.
open class MetaModelSummerizeFactory {
    /// attr: InlinePreview
    /// clickURL: 点击url，使用默认href时可不传
    public typealias URLPreviewProvider = (_ elementID: String, _ customAttributes: [NSAttributedString.Key: Any]) -> (attr: NSAttributedString?, clickURL: String?)?

    open func canHandle(_ message: Message) -> Bool {
        assertionFailure("Must be overrided.")
        return false
    }

    required public init() {}

    /// getSummerize
    /// - Parameter model: Instance of CellMetaModel
    /// - Returns: Optional NSAttributedString
    open func getSummerize(message: Message,
                           chatterName: String,
                           fontColor: UIColor,
                           urlPreviewProvider: URLPreviewProvider? = nil) -> NSAttributedString? {
        return nil
    }
}

public final class MetaModelSummerizeRegistry {
    static var factoryTypes: [MetaModelSummerizeFactory.Type] = []

    let factories: [MetaModelSummerizeFactory]
    let defaultFactory: MetaModelSummerizeFactory

    public init(default: MetaModelSummerizeFactory) {
        SwiftLoadable.startOnlyOnce(key: "LarkMessageBase_MessageSummerize_regist")
        self.factories = Self.factoryTypes.map({ $0.init() })
        self.defaultFactory = `default`
    }

    public func getSummerize(message: Message,
                             chatterName: String,
                             fontColor: UIColor,
                             urlPreviewProvider: MetaModelSummerizeFactory.URLPreviewProvider? = nil) -> NSAttributedString? {
        var result: NSAttributedString?
        for factory in factories where factory.canHandle(message) {
            result = factory.getSummerize(
                message: message,
                chatterName: chatterName,
                fontColor: fontColor,
                urlPreviewProvider: urlPreviewProvider
            )
            break
        }
        if let result = result {
            return result
        }
        return defaultFactory.getSummerize(
            message: message,
            chatterName: chatterName,
            fontColor: fontColor,
            urlPreviewProvider: urlPreviewProvider
        )
    }

    /// Registry register
    /// - Parameter factory: Meta type of MetaModelSumemrizeFactory
    public static func regist(_ factory: MetaModelSummerizeFactory.Type) {
        factoryTypes.append(factory)
    }
}
