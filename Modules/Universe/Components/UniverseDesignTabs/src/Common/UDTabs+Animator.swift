//
//  UDTabsAnimator.swift
//  UniverseDesignTabs
//
//  Created by 姚启灏 on 2020/12/8.
//

import Foundation
import UIKit

class UDDisplayLinkProxy {
    weak var target: UDTabsAnimator?

    init(_ target: UDTabsAnimator) {
        self.target = target
    }

    @objc
    func processDisplayLink(sender: CADisplayLink) {
        target?.processDisplayLink(sender: sender)
    }
}

open class UDTabsAnimator {
    public var duration: TimeInterval = 0.25
    public var progressClosure: ((CGFloat) -> Void)?
    public var completedClosure: (() -> Void)?
    private var displayLink: CADisplayLink!
    private var firstTimestamp: CFTimeInterval?

    deinit {
        progressClosure = nil
        completedClosure = nil
    }

    /// init UDTabsAnimator
    public init() {
        displayLink = CADisplayLink(target: UDDisplayLinkProxy(self),
                                    selector: #selector(processDisplayLink(sender:)))
    }

    /// Start Animator
    public func start() {
        displayLink.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
    }

    /// Stop Animator
    public func stop() {
        progressClosure?(1)
        displayLink.invalidate()
        completedClosure?()
    }

    @objc
    func processDisplayLink(sender: CADisplayLink) {
        let firstTimestamp: CFTimeInterval = self.firstTimestamp ?? sender.timestamp

        if self.firstTimestamp == nil {
            self.firstTimestamp = sender.timestamp
        }

        let percent = (sender.timestamp - firstTimestamp) / duration

        if percent >= 1 {
            progressClosure?(1)
            displayLink.invalidate()
            completedClosure?()
        } else {
            progressClosure?(CGFloat(percent))
        }
    }
}
