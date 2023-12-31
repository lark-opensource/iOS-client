//
//  ShareScreenVideoView.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/11/5.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewSetting
import ByteViewRtcBridge
import UniverseDesignIcon

class ShareScreenVideoView: UIView {

    private static let logger = Logger.ui

    // 共享标注 {
    lazy var sketchVideoWrapperView: SketchScreenWrapperView = SketchScreenWrapperView()
    var videoViewLastScale: CGFloat = 1.0
    // }

    private lazy var contentView: UIView = {
        let view = UIView()
        view.addSubview(self.shareScreenHintView)

        shareScreenHintView.snp.makeConstraints { (maker) in
            maker.centerX.centerY.equalToSuperview()
        }
        return view
    }()

    private lazy var shareScreenHintView = createShareScreenHintView()
    weak var singleTapGestureRecognizer: UITapGestureRecognizer? {
        didSet {
            if let zoom = self.videoView as? ZoomView, let doubleTap = zoom.doubleTapGestureRecognizer {
                singleTapGestureRecognizer?.require(toFail: doubleTap)
            }
        }
    }

    weak var zoomDelegate: ZoomViewZoomscaleObserver?

    var blockSelfDoubleTapAction: (() -> Bool)?

    let showHighDefinitionIndicator: Bool
    let autoHideToolbarConfig: AutoHideToolbarConfig
    private let miniWindowUnsubscribeDelay: TimeInterval?
    init(meeting: InMeetMeeting, showHighDefinitionIndicator: Bool = true) {
        if meeting.setting.miniWindowShareDisabled && meeting.setting.miniwindowShareConfig.shareUnsubscribeDelaySeconds > 0 {
            self.miniWindowUnsubscribeDelay = TimeInterval(meeting.setting.miniwindowShareConfig.shareUnsubscribeDelaySeconds)
        } else {
            self.miniWindowUnsubscribeDelay = nil
        }
        self.showHighDefinitionIndicator = showHighDefinitionIndicator
        self.autoHideToolbarConfig = meeting.setting.autoHideToolbarConfig
        super.init(frame: .zero)
        self.setupSubviews(meeting: meeting)
        self.backgroundColor = UIColor.ud.vcTokenMeetingBgVideoOff
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createShareScreenHintView() -> UIView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.backgroundColor = .clear

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.image = UDIcon.getIconByKey(.shareScreenFilled, iconColor: .ud.iconN3, size: CGSize(width: 40, height: 40))

        let label = UILabel()
        label.textAlignment = .natural
        label.lineBreakMode = .byTruncatingTail
        label.baselineAdjustment = .alignBaselines
        label.text = I18n.View_VM_Loading
        label.contentMode = .left
        label.backgroundColor = .clear
        label.font = .systemFont(ofSize: 14.0, weight: .medium)
        label.textColor = UIColor.ud.textPlaceholder

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        return stackView
    }

    var streamRenderView: StreamRenderView {
        sketchVideoWrapperView.videoView
    }

    private(set) var videoView: UIView? {
        didSet {
            guard videoView !== oldValue else {
                return
            }
            if oldValue?.isDescendant(of: self) == true {
                oldValue?.removeFromSuperview()
            }

            if let videoView = videoView {
                videoView.frame = contentView.bounds
                videoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                contentView.addSubview(videoView)
                videoView.backgroundColor = UIColor.clear
            }
        }
    }

    func setStreamKey(_ streamKey: RtcStreamKey?, isSipOrRoom: Bool) {
        streamRenderView.setStreamKey(streamKey, isSipOrRoom: isSipOrRoom)
    }

    private func setupSubviews(meeting: InMeetMeeting) {
        addSubview(contentView)
        contentView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        let setting = meeting.setting
        streamRenderView.bindMeetingSetting(setting)
        if self.showHighDefinitionIndicator, setting.canShowRtcDefinition {
            streamRenderView.addDefinitionViewIfNeeded()
        }
        shareScreenHintView.isHidden = streamRenderView.isRendering
        self.updateVideoFrameSize(streamRenderView.videoFrameSize)
        streamRenderView.addListener(self)
        let cfgs = setting.multiResolutionConfig
        if Display.pad {
            let cfg = cfgs.pad.subscribe
            streamRenderView.multiResSubscribeConfig = MultiResSubscribeConfig(normal: cfg.gridShareScreen.toRtc(),
                                                                               priority: .high)
        } else {
            let cfg = cfgs.phone.subscribe
            streamRenderView.multiResSubscribeConfig = MultiResSubscribeConfig(normal: cfg.gridShareScreen.toRtc(),
                                                                               priority: .high)
        }
        meeting.router.addListener(self)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        Logger.container.info("didMoveToWindow \(self.window)")
    }
}

extension ShareScreenVideoView: RouterListener {
    func didChangeWindowFloatingBeforeAnimation(_ isFloating: Bool, window: FloatingWindow?) {
        if isFloating {
            self.streamRenderView.unsubscribeDelay = self.miniWindowUnsubscribeDelay
        } else {
            self.streamRenderView.unsubscribeDelay = nil
        }
    }
}

extension ShareScreenVideoView: StreamRenderViewListener {
    func streamRenderViewDidChangeRendering(_ renderView: StreamRenderView, isRendering: Bool) {
        shareScreenHintView.isHidden = isRendering
    }

    func streamRenderViewDidChangeVideoFrameSize(_ renderView: StreamRenderView, size: CGSize?) {
        self.updateVideoFrameSize(size)
    }

    private func updateVideoFrameSize(_ size: CGSize?) {
        Logger.renderView.info("ShareScreen size \(size)")
        if let size = size, size.width > 1.0 && size.height > 1.0 {
            let viewSize = CGSize(width: size.width / self.vc.displayScale,
                                  height: size.height / self.vc.displayScale)
            if let zoomView = self.videoView as? ZoomView,
               zoomView.contentSize.height >= 1,
               abs(zoomView.contentSize.width / zoomView.contentSize.height - size.width / size.height) < 0.1 {
                zoomView.updateContentSize(viewSize)
                return
            }

            self.sketchVideoWrapperView.removeFromSuperview()
            let zoomView = ZoomView(contentView: self.sketchVideoWrapperView, contentSize: viewSize)
            zoomView.autoHideToolbarConfig = self.autoHideToolbarConfig
            if let zoomDelegate = self.zoomDelegate {
                zoomView.addListener(zoomDelegate)
            }
            self.videoView = zoomView
            self.sketchVideoWrapperView.zoomScale = zoomView.zoomScaleRelay
            if let tap = self.singleTapGestureRecognizer, let doubleTap = zoomView.doubleTapGestureRecognizer {
                tap.require(toFail: doubleTap)
            }
            zoomView.blockSelfDoubleTapAction = self.blockSelfDoubleTapAction
            self.layoutIfNeeded()
        } else {
            self.videoView = self.sketchVideoWrapperView
            self.layoutIfNeeded()
        }
    }
}
