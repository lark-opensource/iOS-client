//
//  LiveWebViewModel.swift
//  ByteViewLive
//
//  Created by yangyao on 2021/6/7.
//

import Foundation

protocol LiveWebViewModelDelegate: AnyObject {
    func showFloatView(viewModel: LiveWebViewModel)
    func stopAndCleanLive(viewModel: LiveWebViewModel)
    func stopLiveForMeeting(viewModel: LiveWebViewModel)
}

class LiveWebViewModel {

    private let logger = Logger.live

    var playerType: PlayerType = .live
    
    public weak var delegate: LiveWebViewModelDelegate?

    var liveData = LarkLiveData()

    public init() {
    }

    deinit {
        logger.info("LiveWebViewModel live is deinit")
    }

    func renewURL(with url: URL) -> URL {
        if liveData.streamLink != nil && !liveData.streamLink!.isEmpty {
            logger.info("streamLink exist, add parameters to url")
            var newUrl = url.append(name: "autoplay", value: "true")
            newUrl = newUrl.append(name: "muted", value: "\(liveData.muted)")
            return newUrl.append(name: "danmaku", value: "\(liveData.danmaku)")
        }
        logger.info("streamLink is nil or empty, url no parameters")
        return url
    }

    func onWebLiveStateChanged(event: LarkLiveEvent, data: LarkLiveData) {
        logger.info("LiveWebViewModel onWebLiveStateChanged, action: \(event), liveData: \(data)")
        // 不直接赋值的原因是liveData需要保留自己的liveState属性
        liveData.liveHost = data.liveHost
        liveData.liveID = data.liveID
        liveData.streamLink = data.streamLink
        liveData.danmaku = data.danmaku
        liveData.muted = data.muted
        liveData.delay = data.delay
        liveData.content = data.content
        liveData.delay = data.delay
        liveData.content = data.content
        liveData.playerType = data.playerType
        liveData.floatViewOrientation = data.floatViewOrientation

        let playerType = PlayerType(rawValue: data.playerType ?? "")
        switch event {
        case .error:
            liveData = LarkLiveData()
        case .play:
            liveData.liveState = .play
        case .pause:
            liveData.liveState = .pause
        case .end:
            stopLiveForMeeting()
            liveData.liveState = .end
        case .liveCanplay: // 首帧
            break
        case .webviewLoaded:
            break
        case .nativeToastVisibleChange:
            if let content = data.content, let delay = data.delay {
                let interval = TimeInterval(delay / 1000)
                LiveToast.showTips(with: content, operationText: nil, delay: interval, operationCallBack: nil, dismissCallBack: nil)
            }
        case .changeWindowOrientation:
            logger.info("changeWindowOrientation event: \(liveData.floatViewOrientation)")
            if liveData.floatViewOrientation == "landscape" {
                // 横屏
                LarkLiveManager.shared.floatViewSize = CGSize(width: FloatViewLayout.floatWindowWidth, height: FloatViewLayout.floatWindowHeight)
            } else if liveData.floatViewOrientation == "portrait" {
                // 竖屏
                LarkLiveManager.shared.floatViewSize = CGSize(width: FloatViewLayout.floatWindowHeight, height: FloatViewLayout.floatWindowWidth)
            } else {
                // 默认，横屏
                LarkLiveManager.shared.floatViewSize = CGSize(width: FloatViewLayout.floatWindowWidth, height: FloatViewLayout.floatWindowHeight)
            }
        default:
            // skip
            print()
        }
    }

    func isLivingPlaying() -> Bool {
        switch liveData.liveState {
        case .play: return true
        default: return false
        }
    }
    /// 判断当前是否有直播
    func isLivingInPage() -> Bool {
        switch liveData.liveState {
        case .play, .pause: return true
        default: return false
        }
    }

    func checkPlayStatus() {
        logger.info("LiveWebViewModel checkPlayStatus, action: \(self.liveData.liveState)")
        switch self.liveData.liveState {
        case .play:
            logger.info("LiveWebViewModel live is play, tryShowFloatView")
            self.delegate?.showFloatView(viewModel: self)
        default:
            logger.info("LiveWebViewModel live is not play, stopAndCleanLive")
            self.stopAndCleanLive()
            self.delegate?.stopAndCleanLive(viewModel: self)
        }
    }

    // 关闭小窗，准备开启会议
    private func stopLiveForMeeting() {
        logger.info("LiveWebViewModel will start new meeting, try close liveFloatView")
        self.delegate?.stopLiveForMeeting(viewModel: self)
    }

    func stopAndCleanLive() {
        liveData = LarkLiveData()
    }
}

