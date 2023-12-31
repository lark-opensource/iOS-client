//
//  DocsFPSMonitor.swift
//  SKFoundation
//
//  Created by huayufan on 2023/2/21.
//  


import Foundation
import UIKit

public class DocsFPSMonitor {
    
    public enum Mode {
        case normal // 累计1s计算一次平均FPS
        case accumulate // 统计开始和结束后之间的平均FPS
    }
    
    class DisplayLinkKeeper {
        weak var link: CADisplayLink?
        var updateFPSCallback: ((CADisplayLink) -> Void)?
        init(callback: @escaping ((CADisplayLink) -> Void)) {
            self.updateFPSCallback = callback
            let link = CADisplayLink(target: self, selector: #selector(updateFPS))
            link.add(to: .main, forMode: .common)
            self.link = link
        }
        
        @objc func updateFPS(displayLink: CADisplayLink) {
            updateFPSCallback?(displayLink)
        }
    }
    
    private(set) var displayLink: DisplayLinkKeeper?

    private var pause = true
    /// 上一次CADisplayLink返回的时间戳
    private var lastUpdateTime: CFTimeInterval = 0
    /// 上一次resumeCADisplayLink返回的时间戳
    private var resumeTime: CFTimeInterval = 0
    /// 最近一次CADisplayLink返回的时间戳
    private var lastTimestamp: CFTimeInterval = 0

    private var frameCount: Int = 0

    private var lastFPS: Double = 0

    
    var mode: Mode

    public init(mode: Mode) {
        self.mode = mode
        reset()
    }
    
    private func reset() {
        pause = true
        frameCount = 0
        resumeTime = 0
        lastUpdateTime = 0
        lastTimestamp = 0
        lastFPS = 0
    }

   private func updateFPS(link: CADisplayLink) {
        spaceAssertMainThread()
        if resumeTime == 0 {
            resumeTime = link.timestamp
        }

        if lastUpdateTime == 0 {
            lastUpdateTime = link.timestamp
            frameCount = 0
            return
        }
        frameCount += 1
        if mode == .normal {
            let interval = link.timestamp - lastUpdateTime
            lastUpdateTime = link.timestamp
            if interval < 1 {
                return
            }
            lastFPS = Double(frameCount) / interval
            frameCount = 0
        } else {
            self.lastTimestamp = link.timestamp
        }
    }
    
    deinit {
        displayLink?.link?.remove(from: .main, forMode: .common)
        displayLink?.link?.invalidate()
        displayLink?.link?.isPaused = true
        displayLink = nil
    }
}


// MARK: - public

extension DocsFPSMonitor {

    public var isMonitoring: Bool {
        return !pause
    }

    @discardableResult
    public func stop() -> Double {
        spaceAssertMainThread()
        displayLink?.link?.isPaused = true
        defer { reset() }
        if mode == .accumulate, lastTimestamp > 0 {
            let interval = lastTimestamp - resumeTime
            return Double(frameCount) / interval
        } else {
            return 0
        }
    }

    public func resume() {
        spaceAssertMainThread()
        pause = false
        if displayLink == nil {
            let keeper = DisplayLinkKeeper(callback: { [weak self] link in
                guard let self = self else { return }
                guard self.pause == false else { return }
                self.updateFPS(link: link)
            })
            displayLink = keeper
        }
        displayLink?.link?.isPaused = false
    }
}
