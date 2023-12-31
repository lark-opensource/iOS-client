//
//  JXSegmentedAnimator.swift
//  JXSegmentedView
//
//  Created by jiaxin on 2019/1/21.
//  Copyright © 2019 jiaxin. All rights reserved.
//

import Foundation
import UIKit

open class JXSegmentedAnimator {
    public var duration: TimeInterval = 0.25
    public var progressClosure: ((CGFloat)->())?
    public var completedClosure: (()->())?
    private var displayLink: CADisplayLink!
    private var firstTimestamp: CFTimeInterval?

    deinit {
        progressClosure = nil
        completedClosure = nil
    }

    public init() {
        displayLink = CADisplayLink(target: self, selector: #selector(processDisplayLink(sender:)))
    }

    public func start() {
        displayLink.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
    }

    public func stop() {
        progressClosure?(1)
        displayLink.invalidate()
        completedClosure?()
    }

    @objc private func processDisplayLink(sender: CADisplayLink) {
        if firstTimestamp == nil {
            firstTimestamp = sender.timestamp
        }
        let percent = (sender.timestamp - firstTimestamp!)/duration
        if percent >= 1 {
            progressClosure?(1)
            displayLink.invalidate()
            completedClosure?()
        }else {
            progressClosure?(CGFloat(percent))
        }
    }
}
