//
//  WebViewProgress.swift
//  LarkUIKit
//
//  Created by liuwanlin on 2017/12/20.
//  Copyright © 2017年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit

public protocol WebViewProgressDelegate: AnyObject {
    func webViewProgress(_ webViewProgress: WebViewProgress, updateProgress progress: Float)
}

public final class WebViewProgress: NSObject {
    public weak var progressDelegate: WebViewProgressDelegate?
    public var progress: Float = 0.0

    fileprivate var loadingCount: Int?
    fileprivate var maxLoadCount: Int?
    fileprivate var currentUrl: URL?
    fileprivate var interactive: Bool?

    private let InitialProgressValue: Float = 0.1
    private let InteractiveProgressValue: Float = 0.5
    private let FinalProgressValue: Float = 0.9
    fileprivate let completePRCURLPath = "/webviewprogressproxy/complete"

    // MARK: Initializer
    public override init() {
        super.init()
        maxLoadCount = 0
        loadingCount = 0
        interactive = false
    }

    fileprivate func setProgress(_ progress: Float) {
        guard progress > self.progress || progress == 0 else {
            return
        }
        self.progress = progress
        progressDelegate?.webViewProgress(self, updateProgress: progress)
    }

    // MARK: Public Method
    public func reset() {
        maxLoadCount = 0
        loadingCount = 0
        interactive = false
        setProgress(0.0)
    }
}
