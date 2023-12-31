//
//  PadToolBarMicView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/5.
//

import Foundation

class PadToolBarMicView: PadToolBarTitledView {
    static let unauthorizedIconSize = CGSize(width: 14, height: 14)
    lazy var micIconView = MicIconView(iconSize: Self.iconSize.width)
    let unauthorizedView = UIImageView()

    deinit {
        item.meeting.syncChecker.unregisterMicrophone(self)
    }

    override func setupSubviews() {
        super.setupSubviews()

        button.addSubview(micIconView)

        unauthorizedView.image = BundleResources.ByteView.ToolBar.disable_icon.vc.resized(to: Self.unauthorizedIconSize)
        unauthorizedView.contentMode = .scaleAspectFill
        button.addSubview(unauthorizedView)
        (item as? ToolBarMicItem)?.micDelegate = self
        item.meeting.syncChecker.registerMicrophone(self)
    }

    override func bind(item: ToolBarItem) {
        super.bind(item: item)
        guard let item = item as? ToolBarMicItem else { return }
        updateMicView(item)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        iconView.isHidden = true
        micIconView.frame = iconView.frame
        unauthorizedView.frame = CGRect(origin: CGPoint(x: iconView.frame.minX + 10,
                                                        y: iconView.frame.minY + 6),
                                        size: Self.unauthorizedIconSize)
    }

    private func updateMicView(_ item: ToolBarMicItem) {
        let micState: MicIconState
        switch item.micState {
        case .on: micState = .on()
        case .off: micState = .off()
        case .denied: micState = .denied
        case .sysCalling: micState = .disabled()
        case .forbidden: micState = .disabled()
        case .disconnect: micState = .disconnectedToolbar
        case let .room(bindState):
            micState = bindState.roomState
        case let .callMe(callMeState, isRingring):
            micState = callMeState == .denied && isRingring ? .disabled() : callMeState.toMicIconState
        }
        micIconView.setMicState(micState)
        micIconView.setImageEnabled(item.isEnabled)
        unauthorizedView.isHidden = item.micState.isHiddenMicAlertIcon
        micIconView.setWaveEnabled(item.enableVolumeWave)
    }
}

extension PadToolBarMicView: ToolBarMicItemDelegate {
    func volumeDidChange(_ volume: Int) {
        micIconView.micOnView.updateVolume(volume)
    }
}

extension PadToolBarMicView: MicrophoneStateRepresentable {
    var isMicMuted: Bool? {
        micIconView.currentState.isMuted
    }

    var micIdentifier: String {
        "ToolBarMic"
    }
}
