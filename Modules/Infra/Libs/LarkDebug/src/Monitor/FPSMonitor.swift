//
//  FPSMonitor.swift
//  Lark
//
//  Created by Yuguo on 2018/1/7.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//
import Foundation
#if !LARK_NO_DEBUG
import UIKit

@objc public protocol FPSMonitorDelegate: AnyObject {
    @objc
    optional func fps(fps: FPSMonitor, currentFPS: Double)
}

public final class FPSMonitor: NSObject {
    public var isEnable: Bool = true

    public var updateInterval: Double = 1.0

    public weak var delegate: FPSMonitorDelegate?

    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
            selector: #selector(FPSMonitor.applicationWillResignActiveNotification),
            name: UIApplication.willResignActiveNotification,
            object: nil)

        NotificationCenter.default.addObserver(self,
            selector: #selector(FPSMonitor.applicationDidBecomeActiveNotification),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
    }

    public func open() {
        guard self.isEnable == true else {
            return
        }
        self.displayLink.isPaused = false
        UIApplication.shared.keyWindow?.addSubview(displayLabel)
    }

    public func close() {
        guard self.isEnable == true else {
            return
        }

        self.displayLink.isPaused = true
        self.displayLink.invalidate()
        displayLabel.removeFromSuperview()
    }

    @objc
    private func applicationWillResignActiveNotification() {
        guard self.isEnable == true else {
            return
        }

        self.displayLink.isPaused = true
    }

    @objc
    private func applicationDidBecomeActiveNotification() {
        guard self.isEnable == true else {
            return
        }
        self.displayLink.isPaused = false
    }

    @objc
    private func displayLinkHandler() {
        self.count += self.displayLink.preferredFramesPerSecond
        let interval = self.displayLink.timestamp - self.lastTime

        guard interval >= self.updateInterval else {
            return
        }

        self.lastTime = self.displayLink.timestamp
        let fps = Double(self.count) / interval
        self.count = 0

        self.outPutFPS(currentFPS: round(fps))
        self.delegate?.fps?(fps: self, currentFPS: round(fps))
    }

    private lazy var displayLink: CADisplayLink = { [unowned self] in
        let new = CADisplayLink(target: self, selector: #selector(FPSMonitor.displayLinkHandler))
        new.isPaused = true
        new.add(to: RunLoop.main, forMode: .common)
        return new
    }()

    private var count: Int = 0

    private var lastTime: CFTimeInterval = 0.0

    private lazy var displayLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 12)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.textAlignment = .center
        if UIApplication.shared.statusBarFrame.height == 44 {
            label.frame = CGRect(x: UIScreen.main.bounds.size.width - 100, y: 44, width: 50, height: 15)
        } else {
            label.frame = CGRect(x: UIScreen.main.bounds.size.width - 100, y: 0, width: 50, height: 15)
        }
        return label
    }()
}

extension FPSMonitor {
    func outPutFPS(currentFPS: Double) {
        displayLabel.text = "\(currentFPS) fps"
    }
}
#endif
