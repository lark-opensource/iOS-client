//
//  FPSMonitor.swift
//  Docs
//
//  Created by 陈谦 on 2018/10/29.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import UIKit

public class FPSMonitor: NSObject {
    public var updateInterval: Double = 1.0

    private var count: Int = 0
    private var lastTime: CFTimeInterval = 0.0
    private lazy var displayLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N00
        label.font = UIFont.systemFont(ofSize: 12)
        label.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.6)
        label.textAlignment = .center
        label.frame = CGRect(x: UIScreen.main.bounds.size.width - 100, y: UIApplication.shared.statusBarFrame.height, width: 50, height: 15)
        return label
    }()

    private lazy var displayLink: CADisplayLink = { [unowned self] in
        let displayLink = CADisplayLink(target: self, selector: #selector(FPSMonitor.displayLinkHandler))
        displayLink.isPaused = true
        displayLink.add(to: RunLoop.main, forMode: .common)
        return displayLink
        }()

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

    @objc
    private func applicationWillResignActiveNotification() {
        self.displayLink.isPaused = true
    }

    @objc
    private func applicationDidBecomeActiveNotification() {
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
        self.showFPS(currentFPS: round(fps))
    }

    public func open() {
        self.displayLink.isPaused = false
        UIApplication.shared.keyWindow?.addSubview(displayLabel)
    }

    public func close() {
        self.displayLink.isPaused = true
        self.displayLink.invalidate()
        displayLabel.removeFromSuperview()
    }

    func showFPS(currentFPS: Double) {
        displayLabel.text = "\(currentFPS) fps"
    }
}
