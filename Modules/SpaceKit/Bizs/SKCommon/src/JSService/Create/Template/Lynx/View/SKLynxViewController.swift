//
//  SKLynxViewController.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/11/8.
//

import Foundation
import BDXBridgeKit
import BDXServiceCenter
import SKFoundation

public struct SKLynxConfig {
    public var cardPath: String
    public var initialProperties: [String: Any]?
    public var shareContextID: String?

    public init(cardPath: String, initialProperties: [String: Any]? = nil, shareContextID: String? = nil) {
        self.cardPath = cardPath
        self.initialProperties = initialProperties
        self.shareContextID = shareContextID
    }
}

public final class SKLynxViewController: LynxBaseViewController {
    private let cardPath: String

    public init(config: SKLynxConfig) {
        cardPath = config.cardPath
        super.init(nibName: nil, bundle: nil)
        shareContextID = config.shareContextID
        self.initialProperties = config.initialProperties ?? [:]
        templateRelativePath = config.cardPath
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
