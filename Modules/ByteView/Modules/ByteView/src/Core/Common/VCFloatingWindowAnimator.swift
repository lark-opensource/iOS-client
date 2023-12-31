//
//  VCFloatingWindowAnimator.swift
//  ByteView
//
//  Created by kiri on 2021/3/31.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import ByteViewSetting

final class VCFloatingWindowAnimator: DefaultFloatingWindowAnimator {
    private weak var setting: MeetingSettingManager?
    let dependency: WindowDependency

    init?(logger: Logger, dependency: WindowDependency, setting: MeetingSettingManager?) {
        guard dependency.isExternalWindowEnabled else { return nil }
        self.dependency = dependency
        self.setting = setting
        super.init(logger: logger)
    }

    var isExternalWindowEnabled: Bool {
        dependency.isExternalWindowEnabled
    }

    override func floatingSize(for window: FloatingWindow) -> CGSize {
        /// 当前可能不在会中，用MeetingSession.meetSubType
        let subType = setting?.meetingSubType
        let isShareScreenMeeting = subType == .screenShare
        let isPhoneCall = subType == .enterprisePhoneCall
        if isShareScreenMeeting || isPhoneCall {
            return CGSize(width: 90, height: 90)
        } else {
            return super.floatingSize(for: window)
        }
    }

    override func animationEndFrame(for window: FloatingWindow) -> CGRect {
        var newFrame = super.animationEndFrame(for: window)
        if isExternalWindowEnabled {
            if window.isFloating {
                let targetOrigin = dependency.getTargetOrigin(with: newFrame.size)
                newFrame.origin = targetOrigin
                self.logger.info("target origin: \(targetOrigin)")
            }
        }
        return newFrame
    }

    override func updateSupportedInterfaceOrientations() {
        super.updateSupportedInterfaceOrientations()
        dependency.updateSupportedInterfaceOrientations()
    }

    override func prepareAnimation(for window: FloatingWindow, to frame: CGRect) {
        if isExternalWindowEnabled, !window.isFloating {
            let targetFrame = dependency.getTargetFrame()
            self.logger.info("target frame: \(targetFrame)")
            guard let vc = dependency.removeViewController() else { return }
            if vc.parent != nil {
                self.logger.info("vc:\(vc) remove from parent:\(vc.parent)")
                vc.vc.removeFromParent()
            }
            self.logger.info("set window rootViewController: \(vc) from suspend")
            window.frame = targetFrame
            if #available(iOS 15, *) {
                vc.beginAppearanceTransition(false, animated: false)
                vc.endAppearanceTransition()
                window.rootViewController = vc
                vc.beginAppearanceTransition(true, animated: false)
                vc.endAppearanceTransition()
            } else {
                window.rootViewController = vc
            }
        }
    }

    override func animations(for window: FloatingWindow, animated: Bool, to frame: CGRect) {
        if isExternalWindowEnabled {
            window.frame = frame
            window.layoutIfNeeded()
        } else {
            super.animations(for: window, animated: animated, to: frame)
        }
    }

    override func completeAnimation(for window: FloatingWindow, animated: Bool, to frame: CGRect) {
        super.completeAnimation(for: window, animated: animated, to: frame)
        guard isExternalWindowEnabled else {
            return
        }
        if window.isFloating {
            if let vc = window.rootViewController {
                if vc is PresentationViewController {
                    self.logger.info("set window rootViewController to a new UIViewController")
                    window.rootViewController = AlwaysPortraitViewController()
                    dependency.addViewController(with: vc, size: frame.size)
                    //缩到最小后直接隐藏会看到背景，因为suspendWindow还没有上屏显示
                    // nolint-next-line: magic number
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak window] in
                        window?.isHidden = true
                    }
                } else {
                    let currentSize = dependency.getTargetFrame().size
                    if !currentSize.equalSizeTo(frame.size),
                       let currentVC = dependency.removeViewController() {
                        dependency.addViewController(with: currentVC, size: frame.size)
                        self.logger.info("reset suspend window vc with size:\(frame.size)")
                    }
                    self.logger.info("set window rootViewController to a new UIViewController failed with vc:\(vc)")
                }
            }
        } else {
            window.isHidden = false
        }
    }

    deinit {
        _ = dependency.removeViewController()
    }
}
