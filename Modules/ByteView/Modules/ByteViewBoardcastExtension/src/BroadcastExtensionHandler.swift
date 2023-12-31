//
//  BroadcastExtensionHandler.swift
//  ByteViewBoardcastExtension
//
//  Created by Prontera on 2021/3/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import ReplayKit
import ByteViewBoardcastExtension
import LarkLocalizations
import LarkExtensionServices

private let initOnce: Void = {
    // swiftlint:disable all
    LanguageManager.supportLanguages =
        (Bundle.main.infoDictionary!["SUPPORTED_LANGUAGES"] as! [String]).map { Lang(rawValue: $0) }
    // swiftlint:enable all
}()

class BroadcastExtensionHandler: RPBroadcastSampleHandler {
    private static let broadcastDelay = 1.0

    let client = ByteRtcScreenCapturerExt.shared
    let logger = LogFactory.createLogger(label: "vc.broadcast")
    var isAppRunning = false

    override init() {
        _ = initOnce
        super.init()
        signal(SIGPIPE, SIG_IGN)
        logger.info("[VC boardcastExtension] init BroadcastExtensionHandler")
    }

    // MARK: - RPBroadcastSampleHandler
    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        let groupID = Bundle.main.infoDictionary?["EXTENSION_GROUP"] as? String ?? ""
        logger.info("[VC boardcastExtension] broadcastStarted success")
        client.start(with: self, groupId: groupID)
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.broadcastDelay) { [weak self] in
            guard let self = self else {
                return
            }
            if !self.isAppRunning {
                self.stopExtension()
            }
        }
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case .video, .audioApp:
            client.processSampleBuffer(sampleBuffer, with: sampleBufferType)
        case .audioMic:
            break
        }
    }

    func stopExtension(function: String = #function) {
        logger.info("[VC boardcastExtension] stopExtension from: \(function)")
        client.stop()
        let error = makeError(reason: BundleI18n.ByteViewExtension.View_VM_NotInCallOrMeeting)
        finishBroadcastWithError(error)
    }
}

extension BroadcastExtensionHandler: ByteRtcScreenCapturerExtDelegate {

    static let errorDomain = "BroadcastExtension"
    static let errorCode = 1

    func onQuitFromApp() {
        stopExtension()
    }

    func onReceiveMessage(fromApp message: Data) {
        guard let reason = String(data: message, encoding: .utf8) else {
            logger.info("[VC boardcastExtension] onReceiveMessage fail")
            self.stopExtension()
            return
        }
        logger.info("[VC boardcastExtension] onReceiveMessage reaseon: \(reason)")
        self.client.stop()
        let error = self.makeError(reason: reason)
        self.finishBroadcastWithError(error)
    }

    func onSocketDisconnect() {
        stopExtension()
    }

    func onSocketConnect() {}

    func onNotifyAppRunning() {
        logger.info("[VC boardcastExtension] onNotifyAppRunning")
        self.isAppRunning = true
    }

    private func makeError(reason: String) -> Error {
        return NSError(domain: Self.errorDomain, code: Self.errorCode, userInfo: [NSLocalizedFailureReasonErrorKey: reason])
    }
}
