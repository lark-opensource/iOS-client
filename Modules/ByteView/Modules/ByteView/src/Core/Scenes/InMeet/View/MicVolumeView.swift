//
//  MicVolumeView.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/4/8.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewCommon
import ByteViewUI
import ByteViewSetting
import UniverseDesignIcon

final class MicVolumeWithCornerView: MicVolumeView {

    var type: MicCornerType {
        didSet {
            if oldValue != type {
                updateType()
            }
        }
    }

    private let corner: MicCorner
    init(iconSize: CGFloat, normalColor: UIColor, activeColor: UIColor = UIColor.ud.functionSuccessContentDefault, type: MicCornerType = .empty) {
        self.type = type
        self.corner = MicCorner(type: type)
        super.init(iconSize: iconSize, normalColor: normalColor, activeColor: activeColor)
        corner.attachToSuperView(self)
        updateType()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateType() {
        updateImage()
        corner.cornerType = type
    }

    private func updateImage() {
        switch type {
        case .empty:
            micIconView.image = UDIcon.getIconByKey(.micFilled, iconColor: normalColor, size: CGSize(width: iconSize, height: iconSize))
            activeImageView.image = BundleResources.ByteView.Meet.iconMicFilled02.ud.resized(to: CGSize(width: iconSize, height: iconSize)).ud.withTintColor(activeColor)
        case .room:
            micIconView.image = BundleResources.ByteView.JoinRoom.room_mic_on
            activeImageView.image = BundleResources.ByteView.JoinRoom.room_mic_half.withRenderingMode(.alwaysTemplate)
            activeImageView.tintColor = activeColor
        }
    }
}

class MicVolumeView: UIView {

    enum VolumeWaveStrategy {
        case level
        case linear
    }

    static var micVolumeConfig: MicVolumeConfig = .default
    static var animationConfig = AnimationConfigItem(key: .mic_volume, enabled: true, framerate: 15)

    private static let logger = Logger.ui
    private static let recycleAnimationKey = "MicRecycleAnimationKey"
    private var levels: [Int] = []
    private static var fps: CGFloat { animationConfig.framerate }
    private var isAnimating = false

    private func level(of volume: Int) -> Int {
        return levels.firstIndex { volume <= $0 } ?? 0
    }

    var enableWave: Bool = true

    private var currentVolume: Int = 0 {
        didSet {
            switch self.strategy {
            case .level:
                currentLevel = level(of: currentVolume)
            case .linear:
                startLinearWave()
            }
        }
    }

    var animationLowerBoundForCurrentLevel: CGFloat = 0
    var currentLevel = 0 {
        didSet {
            if oldValue != currentLevel {
                let currentMaxVolume = currentLevel < levels.count ? levels[currentLevel] : 0
                animationLowerBoundForCurrentLevel = CGFloat((currentMaxVolume - recycleStep)) / 255.0 * maskHeight
                startLevelWave()
            }
        }
    }

    fileprivate var normalColor: UIColor
    fileprivate var activeColor: UIColor

    private let maskHeight: CGFloat
    fileprivate let iconSize: CGFloat

    fileprivate lazy var micIconView = UIImageView(image: UDIcon.getIconByKey(.micFilled, iconColor: normalColor, size: CGSize(width: iconSize, height: iconSize)))

    fileprivate lazy var activeImageView = UIImageView(image: BundleResources.ByteView.Meet.iconMicFilled02.vc.resized(to: CGSize(width: iconSize, height: iconSize)).ud.withTintColor(activeColor))

    let volumeMaskView = UIView()

    // 过渡动画时长
    private static let transitionDuration = 0.1
    // 单个循环动画时长
    private static let recycleDuration = 0.3
    private var recycleStep = 0
    private var isReady = false

    // 使用带动画版，目前不带 fg
    private let strategy: MicVolumeView.VolumeWaveStrategy = .level

    lazy var cycleRange: CGFloat = CGFloat(self.recycleStep) / 255.0 * self.maskHeight

    init(iconSize: CGFloat, normalColor: UIColor, activeColor: UIColor = UIColor.ud.functionSuccessContentDefault) {
        self.maskHeight = iconSize
        self.iconSize = iconSize
        self.normalColor = normalColor
        self.activeColor = activeColor
        super.init(frame: .zero)
        setupSubviews()
        let config = Self.micVolumeConfig
        DispatchQueue.global().async { [weak self] in
            self?.setupLevels(config)
        }
    }

    deinit {
        Self.logger.info("Deinit MicVolumeView \(self)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        [micIconView, activeImageView].forEach {
            addSubview($0)
            $0.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        volumeMaskView.backgroundColor = UIColor.black
        activeImageView.mask = volumeMaskView
        volumeMaskView.frame = CGRect(x: 0, y: maskHeight, width: iconSize, height: iconSize)
    }

    private func setupLevels(_ config: MicVolumeConfig) {
        Self.logger.info("Get mic volume configuration, levels = \(config.levels), animatedVolume = \(config.animatedVolume)")
        let actualLevels = config.levels
        let actualStep = config.animatedVolume
        DispatchQueue.main.async { [weak self] in
            self?.levels = actualLevels
            self?.recycleStep = actualStep
            self?.isReady = true
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if self.strategy == .linear {
            let ratio = CGFloat(self.currentVolume) / 255.0
            volumeMaskView.frame = CGRect(x: 0, y: maskHeight * (1 - ratio), width: iconSize, height: iconSize)
        }
    }

    override var isHidden: Bool {
        didSet {
            if isHidden {
                clear()
            }
        }
    }

    func setImageEnabled(_ enable: Bool) {
        micIconView.image = UDIcon.getIconByKey(.micFilled, iconColor: enable ? normalColor : UIColor.ud.iconDisabled, size: CGSize(width: iconSize, height: iconSize))
    }

    func updateVolume(_ volume: Int) {
        currentVolume = volume
    }

    private func startLevelWave() {
        guard isReady && isVisible && Self.animationConfig.enabled else { return }
        guard currentLevel != 0, enableWave else {
            clear()
            return
        }
        isAnimating = true
        let animator = CustomFrameAnimator()
        animator.duration = Self.transitionDuration
        animator.preferredFramesPerSecond = Self.fps
        animator.completionHandler = {
            self.startRecycleUpAnimation()
        }
        animator.add(BVAnimationProperty(type: .y, fromValue: volumeMaskView.frame.minY, toValue: maskHeight - animationLowerBoundForCurrentLevel))
        animator.add(on: volumeMaskView, for: Self.recycleAnimationKey)
    }

    private func startRecycleUpAnimation() {
        guard isVisible else { return }
        let animator = CustomFrameAnimator()
        animator.duration = Self.recycleDuration
        animator.autoreverse = true
        animator.repeatCount = .greatestFiniteMagnitude
        animator.preferredFramesPerSecond = Self.fps
        animator.add(BVAnimationProperty(type: .y, fromValue: volumeMaskView.frame.minY, toValue: maskHeight - animationLowerBoundForCurrentLevel - cycleRange))
        animator.add(on: volumeMaskView, for: Self.recycleAnimationKey)
    }

    private func clear() {
        guard isAnimating else {
            volumeMaskView.frame.origin.y = maskHeight
            return
        }
        isAnimating = false
        let animator = CustomFrameAnimator()
        animator.duration = Self.transitionDuration
        animator.preferredFramesPerSecond = Self.fps
        animator.add(BVAnimationProperty(type: .y, fromValue: volumeMaskView.frame.minY, toValue: maskHeight))
        animator.add(on: volumeMaskView, for: Self.recycleAnimationKey)
    }

    private func startLinearWave() {
        if self.currentVolume < 0 {
            self.currentVolume = 0
        }
        if self.currentVolume > 255 {
            self.currentVolume = 255
        }

        DispatchQueue.main.async {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }

    }
}

private extension UIView {
    var isVisible: Bool {
        if window == nil || isHidden { return false }
        var current: UIView = self
        while let superview = current.superview {
            if superview.bounds.intersects(current.frame) == false { return false }
            if superview.isHidden { return false }
            current = superview
        }
        return true
    }
}
