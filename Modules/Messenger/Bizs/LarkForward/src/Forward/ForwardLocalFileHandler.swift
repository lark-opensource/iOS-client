//
//  ForwardLocalFileHandler.swift
//  LarkForward
//
//  Created by ByteDance on 2023/8/31.
//

import Foundation
import LarkContainer
import RxSwift
import LarkUIKit
import LarkCore
import Swinject
import LarkModel
import EENavigator
import UniverseDesignToast
import LarkFeatureGating
import LarkAlertController
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkOpenFeed
import LarkNavigator

public final class ForwardLocalFileHandler: UserTypedRouterHandler, ForwardAndShareHandler {
    public func handle(_ body: ForwardLocalFileBody, req: EENavigator.Request, res: Response) throws {
        guard FileManager.default.fileExists(atPath: body.localPath) else {
            ForwardLogger.shared.info(module: .forwardAlert, event: "ForwardLocalFileHandler: file not exist")
            return
        }
        guard let attr = try? FileManager.default.attributesOfItem(atPath: body.localPath),
              let fileSize = attr[FileAttributeKey.size] as? NSNumber else {
            ForwardLogger.shared.info(module: .forwardAlert, event: "ForwardLocalFileHandler: fail to get file Size")
            return
        }
        // swiftlint:disable line_length
        ForwardLogger.shared.info(module: .forwardAlert, event: "ForwardLocalFileHandler: fileSizeByte: \(fileSize.int64Value)Byte, fizeSizeKB: \(ByteCountFormatter.string(fromByteCount: fileSize.int64Value, countStyle: .binary))")
        // swiftlint:enable line_length
        var content = ForwardFileAlertContent(fileURL: body.localPath,
                                              fileName: URL(fileURLWithPath: body.localPath).lastPathComponent,
                                              fileSize: fileSize.int64Value)
        // 关闭“创建群组并转发入口”，降低安全风险
        // 不展示话题、机器人、外部人和群
        content.canCreateGroup = false
        content.includeThread = false
        content.includeBot = false
        content.includeOuter = false
        let provider = ForwardFileAlertProvider(userResolver: userResolver, content: content)
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider, router: router)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }
}
