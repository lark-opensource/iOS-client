//
//  InMeetOrientationToolView.swift
//  ByteView
//
//  Created by kiri on 2020/11/23.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import AVFoundation
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignShadow
import ByteViewSetting

protocol InMeetOrientationToolViewDelegate: AnyObject {
    func orientationToolbarDidClickMic()
    func orientationToolbarPositionChanged()
    func orientationToolbarPanGestureWillEnd()
}

class InMeetOrientationToolView: UIView {
    private struct EdgeMask: OptionSet {
        var rawValue: Int
        static let top = EdgeMask(rawValue: 1 << 0)
        static let left = EdgeMask(rawValue: 1 << 1)
        static let bottom = EdgeMask(rawValue: 1 << 2)
        static let right = EdgeMask(rawValue: 1 << 3)
        static let none: EdgeMask = []

        func adjust(center: CGPoint, rect: CGRect) -> CGPoint {
            switch self {
            case [.top, .left]:
                return CGPoint(x: rect.minX, y: rect.minY)
            case [.top, .right]:
                return CGPoint(x: rect.maxX, y: rect.minY)
            case [.bottom, .left]:
                return CGPoint(x: rect.minX, y: rect.maxY)
            case [.bottom, .right]:
                return CGPoint(x: rect.maxX, y: rect.maxY)
            case .left:
                return CGPoint(x: rect.minX, y: center.y)
            case .right:
                return CGPoint(x: rect.maxX, y: center.y)
            default:
                return center
            }
        }

        static func from(center: CGPoint, rect: CGRect) -> EdgeMask {
            var result: EdgeMask = []
            if abs(center.x - rect.minX) < 1 {
                result.insert(.left)
            } else if abs(center.x - rect.maxX) < 1 {
                result.insert(.right)
            }
            if abs(center.y - rect.maxY) < 1 {
                result.insert(.bottom)
            } else if abs(center.y - rect.minY) < 1 {
                result.insert(.top)
            }
            return result
        }
    }

    private var centerBeforeDragging: CGPoint?
    private var forbiddenRegions: [CGRect] = []

    func overlapWithForbiddenRegions(_ center: CGPoint) -> Bool {
        let size = self.frame.size
        let newFrame = CGRect(origin: CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2), size: size)
        return forbiddenRegions.contains { $0.intersects(newFrame) }
    }

    weak var delegate: InMeetOrientationToolViewDelegate?
    let meeting: InMeetMeeting
    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 48, height: 48)))
        isHidden = true
        autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin]
        Self.setupButtonStyle(micButton)
        addSubview(micButton)
        micButton.isHidden = true
        micButton.addTarget(self, action: #selector(didClickMic), for: .touchUpInside)
        micButton.addSubview(micAlertImageView)
        micAlertImageView.isHidden = true
        micAlertImageView.snp.makeConstraints { make in
            make.size.equalTo(14)
            make.bottom.equalTo(-13)
            make.right.equalTo(-10)
        }

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(pan)
        meeting.syncChecker.registerMicrophone(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        meeting.syncChecker.unregisterMicrophone(self)
    }

    // nolint: duplicated_code
    func setMicState(by state: MicViewState) {
        micButton.isEnabled = true
        micAlertImageView.isHidden = state.isHiddenMicAlertIcon
        switch state {
        case .on:
            micButton.tintColor = UIColor.ud.N700
            micIconView.setMicState(.on())
        case .off:
            micButton.tintColor = UIColor.ud.functionDangerContentDefault
            micIconView.setMicState(.off())
        case .denied:
            micButton.tintColor = UIColor.ud.iconDisabled
            micIconView.setMicState(.denied)
        case .sysCalling, .forbidden:
            micButton.tintColor = UIColor.ud.iconDisabled
            micIconView.setMicState(.disabled())
        case .callMe(let callMeState, false):
            switch callMeState {
            case .denied:
                micButton.tintColor = UIColor.ud.iconDisabled
                micIconView.setMicState(.denied)
            case .on, .off:
                micButton.tintColor = callMeState == .on ? UIColor.ud.N700 : UIColor.ud.functionDangerContentDefault
                micIconView.setMicState(callMeState.toMicIconState)
            }
        case .disconnect:
            micButton.tintColor = UIColor.ud.iconDisabled
            micIconView.setMicState(.disconnectedToolbar)
        case .room(let bindState):
            micButton.tintColor = bindState.roomTintColor
            micIconView.setMicState(bindState.roomState)
        case .callMe(let callMeState, true):
            micButton.tintColor = UIColor.ud.iconDisabled
            micIconView.setMicState(callMeState.toMicIconState)
        }
    }

    static func buttonBackgroundImage(isDarkModel: Bool) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 48, height: 48)
        let render = UIGraphicsImageRenderer(bounds: rect)
        let image = render.image { _ in
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 20)
            path.addClip()
            path.lineWidth = 1
            if !isDarkModel {
                UIColor.ud.bgFloat.alwaysLight.withAlphaComponent(0.9).setFill()
            } else {
                UIColor.ud.bgFloat.alwaysDark.withAlphaComponent(0.9).setFill()
            }
            path.fill()
            if !isDarkModel {
                UIColor.ud.lineBorderCard.alwaysLight.setStroke()
            } else {
                UIColor.ud.lineBorderCard.alwaysDark.setStroke()
            }
            path.stroke()
        }
        return image
    }

    private var autoresizingMaskBeforePin: UIView.AutoresizingMask = []
    var isPinPosition: Bool = false {
        didSet {
            if isPinPosition {
                autoresizingMaskBeforePin = autoresizingMask
                autoresizingMask = []
            } else {
                autoresizingMask = autoresizingMaskBeforePin
            }
        }
    }

    @objc private func didClickMic() {
        delegate?.orientationToolbarDidClickMic()
    }

    lazy var micIconView: MicIconView = {
        let iconView = MicIconView(iconSize: 20)
        return iconView
    }()

    private lazy var micButton: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(origin: CGPoint(x: 0, y: 56), size: CGSize(width: 48, height: 48))
        button.tintColor = UIColor.ud.N700
        button.addSubview(micIconView)
        micIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.width.equalTo(24)
        }
        return button
    }()
    private let micAlertImageView = UIImageView(image: CommonResources.iconDeviceDisabled)

    static var btnDarkBgImg = buttonBackgroundImage(isDarkModel: true)
    static var btnLightBgImg = buttonBackgroundImage(isDarkModel: false)
    static func setupButtonStyle(_ button: UIButton) {
        button.setBackgroundImage(UIImage.dynamic(light: btnLightBgImg, dark: btnDarkBgImg), for: .normal)
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 48, height: 48), cornerRadius: 20)
        button.layer.shadowPath = path.cgPath
        button.layer.ud.setShadow(type: .s4Down)
    }

    private var isDragging = false
    private var edgeMask: EdgeMask = .none
    private var dragbleMargin = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
    private(set) var extraMargin: UIEdgeInsets = .zero
    func updateContext(dragbleMargin: UIEdgeInsets, isMicHidden: Bool, isFullScreen: Bool, isResetPosition: Bool,
                       initialMargin: UIEdgeInsets, forbiddenRegions: [CGRect]) {
        isDragging = false
        self.isMicHidden = isMicHidden
        self.forbiddenRegions = forbiddenRegions
        self.extraMargin = initialMargin
        micButton.frame.origin.y = 0
        updateMicBtnAlpha()
        let size = CGSize(width: 48, height: 48)
        if isPinPosition {
            self.frame.size = size
        } else {
            let origin = CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2)
            self.frame = CGRect(origin: origin, size: size)
        }
        self.dragbleMargin = dragbleMargin
        fixBoundary(isResetPosition: isResetPosition, isApplyEdgeMask: true, extraMargin: initialMargin)
    }

    // MARK: - 全屏闲置态逻辑

    private var isMicHidden: Bool = false {
        didSet {
            updateMicBtnAlpha()
        }
    }

    private func updateMicBtnAlpha() {
        micButton.isHidden = isMicHidden
    }


    private var delayedFixBoundary: DispatchWorkItem?
    func fixBoundary(isResetPosition: Bool = false, isUpdateEdgeMask: Bool = false,
                     isApplyEdgeMask: Bool = false, extraMargin: UIEdgeInsets = .zero) {
        delayedFixBoundary?.cancel()
        delayedFixBoundary = nil
        guard let sv = self.superview else {
            return
        }
        let size = self.frame.size
        var center = self.center
        let rect = sv.bounds.inset(by: dragbleMargin).inset(by: extraMargin)
            .insetBy(dx: size.width / 2, dy: size.height / 2)
        if rect.origin.x.isInfinite || rect.origin.y.isInfinite {
            // 有时候动画中的sv.bounds容纳不下margin+size， 导致center为inf，延迟一会儿布局
            let item = DispatchWorkItem { [weak self] in
                self?.fixBoundary(isResetPosition: isResetPosition, isUpdateEdgeMask: isUpdateEdgeMask,
                                  isApplyEdgeMask: isApplyEdgeMask)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: item)
            self.delayedFixBoundary = item
            return
        }

        if isResetPosition || rect.isEmpty {
            edgeMask = [.bottom, .right]
            center = CGPoint(x: rect.maxX, y: rect.maxY)
        } else {
            center.x = center.x > rect.midX ? rect.maxX : rect.minX
            center.y = max(rect.minY, min(center.y, rect.maxY))
            if isUpdateEdgeMask {
                edgeMask = .from(center: center, rect: rect)
            }
            if isApplyEdgeMask {
                center = edgeMask.adjust(center: center, rect: rect)
            }
        }

        let mask: UIView.AutoresizingMask
        switch center.y {
        case rect.maxY:
            mask = [.flexibleTopMargin]
        case rect.minY:
            mask = [.flexibleBottomMargin]
        default:
            mask = [.flexibleTopMargin, .flexibleBottomMargin]
        }
        if isPinPosition {
            autoresizingMaskBeforePin = mask
        } else {
            autoresizingMask = mask
        }

        if overlapWithForbiddenRegions(center) {
            // - Mic浮标与禁止区域有交集，尝试恢复到拖拽前的位置。
            // - 若没有拖拽，恢复到最右下角。
            //   - 出现这种情况的场景：先将Mic拖到同传图标的位置后再开启同传
            if let prevCenter = self.centerBeforeDragging {
                center = prevCenter
            } else {
                center = CGPoint(x: rect.maxX, y: rect.maxY)
            }
        }

        if center != self.center {
            self.center = center
        }
    }

    private var panOffsetX: CGFloat = 0
    private var panOffsetY: CGFloat = 0
    @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
        guard let sv = self.superview, gr.view == self, !isHidden, !isPinPosition else {
            isDragging = false
            return
        }

        switch gr.state {
        case .began:
            isDragging = true
            self.centerBeforeDragging = self.center
            let location = gr.location(in: sv)
            let origin = self.frame.origin
            panOffsetX = location.x - origin.x
            panOffsetY = location.y - origin.y
        case .changed:
            guard isDragging else {
                return
            }
            let location = gr.location(in: sv)
            self.frame.origin = CGPoint(x: location.x - panOffsetX, y: location.y - panOffsetY)
            self.delegate?.orientationToolbarPositionChanged()
        default:
            guard isDragging else {
                return
            }
            self.delegate?.orientationToolbarPanGestureWillEnd()
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.25, animations: {
                self.fixBoundary(isUpdateEdgeMask: true)
            }, completion: { _ in
                self.isDragging = false
                self.centerBeforeDragging = nil
            })
        }
    }
}

extension InMeetOrientationToolView: MicrophoneStateRepresentable {
    var isMicMuted: Bool? {
        guard !micIconView.isHidden else { return nil }
        return micIconView.currentState.isMuted
    }

    var micIdentifier: String {
        "OrientationToolViewMic"
    }
}
