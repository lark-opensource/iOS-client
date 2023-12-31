//
//  Dependency.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/8/18.
//

import Foundation
import TTMicroApp
import UniversalCard
import LarkStorage
import LarkContainer

class UniversalCardModuleDependency: UniversalCardModuleDependencyProtocol {
    private var semaphore = DispatchSemaphore(value: 1)
    public var _template: SDKTemplate?
    var templateVersion: String? { _template?.version }
    private let resolver: UserResolver

    public init(resolver: UserResolver) throws {
        self.resolver = resolver
    }

    public func loadTemplate() -> SDKTemplate? {
        semaphore.wait(); defer { semaphore.signal() }
        guard _template == nil ||
                BDPVersionManagerV2.compareVersion(BDPVersionManagerV2.localLibVersionString(.sdkMsgCard), with: _template?.version) == 1 else {
            return _template
        }
        var extraTiming: [AnyHashable: Any] = [:]
        extraTiming["prepare_template_start"] = Int64(Date().timeIntervalSince1970 * 1000)
        var jsPath = BDPVersionManagerV2.latestVersionMsgCardSDKPath()

        //debug和内测包都强制使用新解压的templateJS
        #if ALPHA || DEBUG
        let messageCardDebugIsOn = EMADebugUtil.sharedInstance()?.debugConfig(forID: kEMADebugConfigMessageCardDebugTool)?.boolValue ?? false
        if messageCardDebugIsOn {
            try? LSFileSystem.main.removeItem(atPath: jsPath)
            jsPath = BDPVersionManagerV2.latestVersionMsgCardSDKPath()
        }
        #endif

        let jsPathAbs = AbsPath(BDPVersionManagerV2.latestVersionMsgCardSDKPath())
        let version = BDPVersionManagerV2.localLibVersionString(.sdkMsgCard)

        guard let data = try? Data.read(from: jsPathAbs) else {
            assertionFailure("MessageCardContainer load template data fail")
            return nil
        }
        extraTiming["prepare_template_end"] = Int64(Date().timeIntervalSince1970 * 1000)
        _template = (data, version, extraTiming)
        return _template
    }

    func latestVersionCard(with path: String) -> AbsPath? {
        return AbsPath(BDPVersionManagerV2.latestVersionCard(withPath: path))
    }
}
