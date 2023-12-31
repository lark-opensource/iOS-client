//
//  StreamDebugView.swift
//  ByteViewRtcBridge
//
//  Created by kiri on 2023/5/25.
//

import Foundation
import ByteViewCommon

final class StreamDebugView: UIView {
    let textLabel = UILabel()
    private var displayFps = false
    private var displayCodec = false
    private var fps: Int?
    private var videoCodec: RtcVideoCodecType?
    private var fpsTimer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        self.backgroundColor = .clear
        self.translatesAutoresizingMaskIntoConstraints = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(textLabel)
        textLabel.textColor = .white
        textLabel.font = UIFont.systemFont(ofSize: Display.phone ? 10 : 15)
        textLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 6).isActive = true
        textLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -6).isActive = true
        textLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 6).isActive = true
        textLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -6).isActive = true
        self.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private weak var renderView: StreamRenderView?
    func bindToRenderView(_ renderView: StreamRenderView) {
        self.renderView = renderView
        renderView.addListener(self)
        updateVisibility()
    }

    func showFps(_ shouldShow: Bool) {
        guard self.displayFps != shouldShow else { return }
        self.displayFps = shouldShow
        self.updateVisibility()
    }

    func showCodec(_ shouldShow: Bool) {
        guard self.displayCodec != shouldShow else { return }
        self.displayCodec = shouldShow
        self.updateVisibility()
    }

    private func updateText() {
        guard !self.isHidden else { return }
        var debugInfos: [String] = []
        if displayCodec, self.videoCodec == .byteVC1 {
            debugInfos.append("B")
        }
        if displayFps, let fps = self.fps, let size = self.renderView?.videoFrameSize {
            debugInfos.append("\(Int(size.width))x\(Int(size.height))@\(fps)")
        }
        textLabel.text = debugInfos.joined(separator: " ")
    }

    private func updateVideoCodec(_ codec: RtcVideoCodecType) {
        if self.videoCodec != codec {
            self.videoCodec = codec
            self.updateText()
        }
    }

    private func updateFps() {
        if let fps = self.renderView?.readFPS(), fps != self.fps {
            self.fps = fps
            updateText()
        }
    }

    private var isFpsVisible = false
    private var isCodecVisible = false
    private func updateVisibility() {
        if let renderView = self.renderView, renderView.isRendering, renderView.streamKey != nil,
           self.displayFps || self.displayCodec {
            self.isHidden = false
        } else {
            self.isHidden = true
        }

        let isCodecVisible = !self.isHidden && self.displayCodec
        if self.isCodecVisible != isCodecVisible {
            self.isCodecVisible = isCodecVisible
            if isCodecVisible {
                RtcInternalListeners.addStreamStatsListener(self)
            } else {
                RtcInternalListeners.removeStreamStatsListener(self)
            }
        }

        let isFpsVisible = !self.isHidden && self.displayFps
        if self.isFpsVisible != isFpsVisible {
            self.isFpsVisible = isFpsVisible
            if isFpsVisible {
                if self.fpsTimer == nil {
                    self.fps = 0
                    self.fpsTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] t in
                        guard let self = self else {
                            t.invalidate()
                            return
                        }
                        self.updateFps()
                    })
                }
            } else {
                self.fpsTimer?.invalidate()
                self.fpsTimer = nil
            }

        }

        if !self.isHidden {
            updateText()
        }
    }
}

extension StreamDebugView: StreamRenderViewListener {
    func streamRenderViewDidChangeVideoFrameSize(_ renderView: StreamRenderView, size: CGSize?) {
        if displayFps {
            self.updateText()
        }
    }

    func streamRenderViewDidChangeRendering(_ renderView: StreamRenderView, isRendering: Bool) {
        self.updateVisibility()
    }

    func streamRenderViewDidChangeStreamKey(_ renderView: StreamRenderView, streamKey: RtcStreamKey?) {
        self.updateVisibility()
    }
}

extension StreamDebugView: RtcStreamStatsListener {
    func onRemoteStreamStats(_ streamStats: RtcRemoteStreamStats) {
        Util.runInMainThread { [weak self] in
            guard let self = self, let streamKey = self.renderView?.streamKey,
                    streamKey.isScreen == streamStats.isScreen, streamKey.uid == streamStats.uid else {
                return
            }
            self.updateVideoCodec(streamStats.videoStats.codecType)
        }
    }

    func onLocalStreamStats(_ streamStats: RtcLocalStreamStats) {
        Util.runInMainThread { [weak self] in
            guard let self = self, let streamKey = self.renderView?.streamKey, !streamStats.isScreen, streamKey.isLocal else {
                return
            }
            self.updateVideoCodec(streamStats.videoStats.codecType)
        }
    }
}
