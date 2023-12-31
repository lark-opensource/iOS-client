//
//  SideBarMenuSource.swift
//  LarkNavigation
//
//  Created by liuxianyu on 2022/9/14.
//

import UIKit
import Foundation
import UniverseDesignDrawer
import LarkTab
import LarkContainer

public typealias ContentPercentProvider = (UserResolver, UDDrawerTriggerType) throws -> CGFloat
public typealias SubCustomVCProvider = (UserResolver, UDDrawerTriggerType, UIViewController?) throws -> UIViewController?

public struct SideBarMenuSource {
    public let contentPercentProvider: ContentPercentProvider
    public let subCustomVCProvider: SubCustomVCProvider

    public init(contentPercentProvider: @escaping ContentPercentProvider,
                subCustomVCProvider: @escaping SubCustomVCProvider) {
        self.contentPercentProvider = contentPercentProvider
        self.subCustomVCProvider = subCustomVCProvider
    }
}

final public class SideBarMenuSourceFactory {
    private static var sourceMap: [Tab: SideBarMenuSource] = [:]

    public static func register(tab: Tab,
                                contentPercentProvider: @escaping ContentPercentProvider,
                                subCustomVCProvider: @escaping SubCustomVCProvider) {
        let source = SideBarMenuSource(contentPercentProvider: contentPercentProvider,
                                       subCustomVCProvider: subCustomVCProvider)
        SideBarMenuSourceFactory.sourceMap[tab] = source
    }

    public static func source(for tab: Tab) -> SideBarMenuSource? {
        if let source = SideBarMenuSourceFactory.sourceMap[tab] {
            return source
        }
        return nil
    }
}
