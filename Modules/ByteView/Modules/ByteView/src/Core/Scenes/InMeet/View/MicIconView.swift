//
//  MicIconView.swift
//  ByteView
//
//  Created by lutingting on 2022/3/30.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import UniverseDesignIcon

enum MicIconState: Equatable {
    case denied
    case off(MicCornerType = .empty)
    case on(MicCornerType = .empty)
    case disabled(MicCornerType = .empty)
    case hidden
    case disconnected
    case disconnectedToolbar

    var isMuted: Bool {
        switch self {
        case .on(.empty): return false
        default: return true
        }
    }
}

class MicIconView: UIView {
    private var iconSize: CGFloat

    private var normalColor: UIColor = Display.pad ? .ud.iconN2 : .ud.iconN1.withAlphaComponent(0.8)
    private var activeColor: UIColor
    private var disableColor: UIColor

    var currentState: MicIconState = .hidden

    lazy var micDeniedView: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UDIcon.getIconByKey(.micOffFilled, iconColor: UIColor.ud.iconDisabled, size: CGSize(width: iconSize, height: iconSize))
        return imgView
    }()

    lazy var micMutedView: ImageWithCornerView = {
        let iconSize = iconSize
        let imgView = ImageWithCornerView {
            switch $0 {
            case .empty:
                return UDIcon.getIconByKey(.micOffFilled, iconColor: UIColor.ud.functionDangerFillDefault, size: CGSize(width: iconSize, height: iconSize))
            case .room:
                return BundleResources.ByteView.JoinRoom.room_mic_off
                }
            }
        return imgView
    }()

    /// toolbar无音频图标
    lazy var disconnectedToolbarView: UIImageView = {
        let imgView = UIImageView()
        let image = UDIcon.getIconByKey(.disconnectAudioFilled, iconColor: normalColor, size: CGSize(width: iconSize, height: iconSize))
        imgView.image = image
        return imgView
    }()

    lazy var disconnectedView: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UDIcon.getIconByKey(.disconnectAudioFilled, iconColor: .ud.iconN3, size: CGSize(width: iconSize, height: iconSize))
        return imgView
    }()

    lazy var micOnView = MicVolumeWithCornerView(iconSize: iconSize, normalColor: normalColor, activeColor: activeColor)

    lazy var micDisabledView: ImageWithCornerView = {
        let iconSize = iconSize
        let imgView = ImageWithCornerView {
            switch $0 {
            case .empty:
                return UDIcon.getIconByKey(.micOffFilled, iconColor: UIColor.ud.iconDisabled, size: CGSize(width: iconSize, height: iconSize))
            case .room:
                return BundleResources.ByteView.JoinRoom.room_mic_off
            }
        }
        return imgView
    }()

    init(iconSize: CGFloat,
         normalColor: UIColor? = nil,
         activeColor: UIColor = UIColor.ud.functionSuccessContentDefault,
         disableColor: UIColor = UIColor.ud.iconDisabled) {
        self.iconSize = iconSize
        if let color = normalColor { self.normalColor = color }
        self.activeColor = activeColor
        self.disableColor = disableColor
        super.init(frame: .zero)
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImageEnabled(_ enable: Bool) {
//        micDeniedView 本来就是灰色不用改
        micMutedView.image = UDIcon.getIconByKey(.micOffFilled, iconColor: enable ? UIColor.ud.functionDangerContentDefault : disableColor, size: CGSize(width: iconSize, height: iconSize))
        micOnView.setImageEnabled(enable)
    }

    func setWaveEnabled(_ enable: Bool) {
        micOnView.enableWave = enable
    }

    func setMicState(_ state: MicIconState,
                     file: String = #fileID,
                     line: Int = #line,
                     function: String = #function) {
        Util.runInMainThread {
            Logger.ui.info("MicIconView setMicState to \(state) from \(self.currentState), file = \(file), line = \(line), function = \(function)")
            self.currentState = state
            switch state {
            case .denied:
                self.setSubviewIfNeeded(self.micDeniedView)
            case .off(let type):
                self.setSubviewIfNeeded(self.micMutedView)
                self.micMutedView.type = type
            case .on(let type):
                self.setSubviewIfNeeded(self.micOnView)
                self.micOnView.type = type
            case .disabled(let type):
                self.setSubviewIfNeeded(self.micDisabledView)
                self.micMutedView.type = type
            case .hidden:
                self.subviews.forEach { $0.removeFromSuperview() }
            case .disconnected:
                self.setSubviewIfNeeded(self.disconnectedView)
            case .disconnectedToolbar:
                self.setSubviewIfNeeded(self.disconnectedToolbarView)
            }
        }
    }

    private func setSubviewIfNeeded(_ view: UIView) {
        if view.superview != nil {
            Logger.ui.info("MicIconView setSubviewIfNeeded view superview is not nil")
            return
        }
        subviews.forEach { $0.removeFromSuperview() }
        addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
