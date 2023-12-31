//
//  UniversalCardAPIContext.swift
//  UniversalCardBase
//
//  Created by ByteDance on 2023/8/9.
//

import Foundation
import Lynx
import LarkLynxKit
import LarkOpenAPIModel
import LarkOpenPluginManager
import UniversalCardInterface


public class UniversalCardAPIContext: OpenAPIContext {
    public let lynxContext: LynxContext
    public let cardContext: UniversalCardContext
    public init(
        dispatcher: OpenPluginManagerProtocol?,
        lynxContext: LynxContext,
        cardContext: UniversalCardContext
    ) {
        self.lynxContext = lynxContext
        self.cardContext = cardContext
        super.init(
            trace: cardContext.renderingTrace ?? cardContext.trace,
            dispatcher: dispatcher,
            additionalInfo: [:],
            isLazyInvoke: false,
            lazyInvokeElapsedDuration: nil
        )
    }
}
