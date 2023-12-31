//
//  AudioOutputPicker.swift
//  ByteView
//
//  Created by kiri on 2022/12/6.
//

import Foundation
import LarkMedia
import ByteViewTracker
import AVKit

enum AudioOutputPickerScene: String, CustomStringConvertible {
    case lobby
    case prelobby
    case preview
    case onTheCall
    case callOut
    case callIn
    case phoneCall

    var description: String { rawValue }
}

enum AudioOutputPickerItem: String, CustomStringConvertible {
    case speaker
    case receiver
    case mute
    case unmute
    case picker
    case cancel

    var description: String { rawValue }
}

protocol AudioOutputPickerDelegate: AnyObject {
    func audioOutputPicker(_ picker: AudioOutputPicker, didSelect item: AudioOutputPickerItem)
    func audioOutputPickerWillAppear(_ picker: AudioOutputPicker)
    func audioOutputPickerWillDisappear(_ picker: AudioOutputPicker)
    func audioOutputPickerDidAppear(_ picker: AudioOutputPicker)
    func audioOutputPickerDidDisappear(_ picker: AudioOutputPicker)
}
extension AudioOutputPickerDelegate {
    func audioOutputPickerWillAppear(_ picker: AudioOutputPicker) {}
    func audioOutputPickerWillDisappear(_ picker: AudioOutputPicker) {}
    func audioOutputPickerDidAppear(_ picker: AudioOutputPicker) {}
    func audioOutputPickerDidDisappear(_ picker: AudioOutputPicker) {}
}

final class AudioOutputPicker {
    weak var delegate: AudioOutputPickerDelegate?

    private let logger = Logger.audio
    private weak var actionSheet: AudioOutputActionSheet?
    private weak var routePicker: SystemRoutePickerView?
    private var callActionSheet: AudioOutputCallActionSheet?
    private var clickPickerViewCount = 0
    private lazy var clickPickerViewMaxCount = {
        if #available(iOS 12.3, *) {
            return 5
        } else {
            // iOS 12.3 以下系统会缺失end事件回调
            // 因此每次都强制启动picker
            return 0
        }
    }()
    private var isPickerViewVisible: Bool { routePicker?.isPresentingRoutes == true }
    @RwAtomic private(set) var scene: AudioOutputPickerScene = .preview

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeRoute(_:)),
                                               name: LarkAudioSession.lkRouteChangeNotification, object: nil)
    }

    /// - parameter offset: 向下偏移几像素
    func show(scene: AudioOutputPickerScene, from: UIViewController, currentOutput: AudioOutput, isMuted: Bool, canMute: Bool = true, anchorView: UIView? = nil, config: AudioOutputActionSheet.Config) {
        logger.info("will showPicker from \(scene)")
        if scene != self.scene {
            self.scene = scene
            self.dismissAll()
        }
        DispatchQueue.global().async { [weak self, weak from, weak anchorView] in
            let isHeadsetConnected = LarkAudioSession.shared.isHeadsetConnected
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let from = from else {
                    self.logger.error("showPicker from \(scene) failed, from is nil")
                    return
                }
                self.logger.info("showPicker from \(scene), isHeadSetConnected: \(isHeadsetConnected), currentOutput: \(currentOutput), isMuted: \(isMuted)")
                self.startChangeRoute()
                if scene.isMuteEnabled {
                    self.showActionSheet(scene: scene, isHeadsetConnected: isHeadsetConnected, from: from,
                                         currentOutput: currentOutput, isMuted: isMuted,
                                         anchorView: anchorView, config: config)
                } else if isHeadsetConnected || Display.pad {
                    self.showSystemPicker(scene: scene, from: from)
                } else if Display.phone, scene == .callOut || scene == .callIn {
                    if let view = anchorView {
                        self.showCallActionSheet(scene: scene, currentOutput: currentOutput, from: from, anchorView: view)
                    } else {
                        self.logger.error("showPicker from \(scene) failed, anchorView is nil")
                    }
                } else {
                    LarkAudioSession.shared.enableSpeakerIfNeeded(currentOutput != .speaker)
                    DevTracker.post(.userAction(.clickAudioRoute).category(.audio).params([.extend_value: "default", .page: "\(from)"]))
                    return
                }
            }
        }
    }

    func dismissActionSheet() {
        self.logger.info("dismissActionSheet")
        Util.runInMainThread { [weak self] in
            self?.actionSheet?.dismiss()
            self?.actionSheet = nil
            self?.callActionSheet?.dismiss()
            self?.callActionSheet = nil
        }
    }

    private func dismissAll() {
        self.logger.info("dismissAll")
        Util.runInMainThread { [weak self] in
            self?.routePicker?.removeFromSuperview()
            self?.routePicker = nil
            self?.clickPickerViewCount = 0
            self?.actionSheet?.dismiss()
            self?.actionSheet = nil
            self?.callActionSheet?.dismiss()
            self?.callActionSheet = nil
        }
    }

    private func showActionSheet(scene: AudioOutputPickerScene, isHeadsetConnected: Bool, from: UIViewController,
                                 currentOutput: AudioOutput, isMuted: Bool, anchorView: UIView?, config: AudioOutputActionSheet.Config) {
        self.logger.info("will show AudioOutputActionSheet")
        DevTracker.post(.userAction(.clickAudioRoute).category(.audio).params([.extend_value: "sheet", .page: "\(from)"]))
        let actionSheet = AudioOutputActionSheet(scene: scene, isHeadsetConnected: isHeadsetConnected, output: currentOutput, isMuted: isMuted)
        actionSheet.delegate = self
        actionSheet.show(from: from, anchorView: anchorView, config: config)
        self.actionSheet = actionSheet
    }

    private func showSystemPicker(scene: AudioOutputPickerScene, from: UIViewController) {
        DevTracker.post(.userAction(.clickAudioRoute).category(.audio).params([.extend_value: "board", .page: "\(from)"]))
        self.logger.info("will show AudioOutputRoutePicker, isPickerViewVisible = \(isPickerViewVisible)")
        // 处理有几率呼不出的问题
        if isPickerViewVisible {
            DevTracker.post(.audio(.picker_view_bad_access).category(.audio))
            clickPickerViewCount += 1
            if clickPickerViewCount > clickPickerViewMaxCount {
                Logger.audio.warn("route picker controller click before end, retry")
                clickPickerViewCount = 0
            } else {
                Logger.audio.warn("AudioOutputRoutePicker is visible, ignored")
                return
            }
        }
        routePicker?.removeFromSuperview()
        let picker = SystemRoutePickerView()
        picker.scene = scene
        picker.endPresentingHandler = { [weak self] p in
            guard let self = self, self.routePicker == p else { return }
            self.clickPickerViewCount = 0
            self.endChangeRoute(isFromPickerView: true)
        }
        picker.show(from: from)
        self.routePicker = picker
    }

    private func showCallActionSheet(scene: AudioOutputPickerScene, currentOutput: AudioOutput,
                                     from: UIViewController, anchorView: UIView) {
        let actionSheet = AudioOutputCallActionSheet(scene: scene, output: currentOutput)
        actionSheet.delegate = self
        actionSheet.show(from: from, anchorView: anchorView)
        self.callActionSheet = actionSheet
    }

    @objc private func didChangeRoute(_ notificaton: Notification) {
        changeRouteEndTime = CACurrentMediaTime()
        if !isPickerViewVisible {
            endChangeRoute(isFromPickerView: false)
        }
        if let r0 = notificaton.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
           let reason = AVAudioSession.RouteChangeReason(rawValue: r0), reason == .newDeviceAvailable {
            dismissActionSheet()
        }
    }

    private var beforeChangeRoute: AudioOutput?
    private var changeRouteEndTime: CFTimeInterval = 0
    private func startChangeRoute() {
        self.beforeChangeRoute = LarkAudioSession.shared.currentOutput
        self.changeRouteEndTime = 0
        AppreciableTracker.shared.start(.vc_change_audio_route_time)
    }

    private func endChangeRoute(isFromPickerView: Bool) {
        if let oldValue = self.beforeChangeRoute, changeRouteEndTime > 0 {
            let output = LarkAudioSession.shared.currentOutput
            AppreciableTracker.shared.end(.vc_change_audio_route_time, params: [
                "from_source": oldValue.trackText,
                "after_source": output.trackText,
                "is_from_route_picker_view": isFromPickerView
            ], endTime: changeRouteEndTime)
        }
        self.beforeChangeRoute = nil
    }
}

extension AudioOutputPicker: AudioOutputActionSheetDelegate {
    func audioOutputActionSheet(_ actionSheet: UIViewController, didSelect item: AudioOutputPickerItem) {
        self.delegate?.audioOutputPicker(self, didSelect: item)
        if item == .picker, let from = actionSheet.presentingViewController {
            showSystemPicker(scene: scene, from: from)
        }
    }

    func audioOutputActionSheetWillAppear(_ actionSheet: UIViewController) {
        delegate?.audioOutputPickerWillAppear(self)
    }

    func audioOutputActionSheetWillDisappear(_ actionSheet: UIViewController) {
        delegate?.audioOutputPickerWillDisappear(self)
    }

    func audioOutputActionSheetDidAppear(_ actionSheet: UIViewController) {
        delegate?.audioOutputPickerDidAppear(self)
    }

    func audioOutputActionSheetDidDisappear(_ actionSheet: UIViewController) {
        delegate?.audioOutputPickerDidDisappear(self)
    }
}

extension AudioOutputPicker: AudioOutputCallActionSheetDelegate {
    func audioOutputCallActionSheet(_ actionSheet: AudioOutputCallActionSheet, didSelect item: AudioOutputPickerItem) {
        self.delegate?.audioOutputPicker(self, didSelect: item)
    }

    func audioOutputCallActionSheetDidPresent(_ actionSheet: AudioOutputCallActionSheet) {
        self.delegate?.audioOutputPickerWillAppear(self)
    }

    func audioOutputCallActionSheetDidDismiss(_ actionSheet: AudioOutputCallActionSheet) {
        self.delegate?.audioOutputPickerWillDisappear(self)
    }
}

/// 系统选择框
private class SystemRoutePickerView: AVRoutePickerView, AVRoutePickerViewDelegate {
    @RwAtomic private(set) var isPresentingRoutes: Bool = false
    var scene: AudioOutputPickerScene = .preview
    var endPresentingHandler: ((SystemRoutePickerView) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate = self
        self.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(from: UIViewController) {
        from.view.addSubview(self)
        for obj in self.subviews {
            if let btn = obj as? UIButton {
                btn.sendActions(for: .touchUpInside)
                break
            }
        }
    }

    func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        isPresentingRoutes = true
        Logger.audio.info("AVRoutePickerView will begin presenting routes when \(scene)")
    }

    func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        isPresentingRoutes = false
        routePickerView.removeFromSuperview()
        Logger.audio.info("AVRoutePickerView did end presenting routes when \(scene)")
        self.endPresentingHandler?(self)
    }
}

extension AudioOutputPickerScene {
    var trackText: String {
        switch self {
        case .lobby:
            return "waiting_room"
        case .prelobby:
            return "pre_waiting_room"
        case .preview:
            return "pre_view"
        case .onTheCall:
            return "meeting_onthecall"
        default:
            return ""
        }
    }

    var isMuteEnabled: Bool {
        switch self {
        case .callOut, .phoneCall, .callIn:
            return false
        default:
            return true
        }
    }
}

extension AudioOutputPickerItem {
    var trackText: String {
        switch self {
        case .speaker:
            return "loudspeaker"
        case .picker:
            return "switch_audio_connection_device"
        default:
            return rawValue
        }
    }
}
