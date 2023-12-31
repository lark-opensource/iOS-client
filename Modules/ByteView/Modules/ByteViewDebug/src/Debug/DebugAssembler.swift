//
//  DebugAssembler.swift
//  ByteViewDebug
//
//  Created by lvdaqian on 2020/10/23.
//

import Foundation
import ByteView
import SwiftUI
import LarkAssembler
import Swinject
import LarkRustClient

public final class DebugAssembler {
    public static func setup(dependency: DebugDependency) {
        DebugConfig.shared.dependency = dependency
        ParticipantGridDebugToolResolver.setup {
            ParticipantGridDebugTool()
        }
        DebugConfigs.entries.append(DebugConfigs.CustomVCEntry(label: "多分辨率配置", vcBuilder: { SimulcastConfigurationSelectVC() }))
        if #available(iOS 14.0, *) {
            DebugConfigs.entries.append(DebugConfigs.CustomVCEntry(label: "推送录制回放", vcBuilder: { UIHostingController(rootView: ToastContainer { PushDebugRootView() }) }))
        }
    }
}


class PushProcessor: UserPushHandler {
    func process(push: RustPushPacket<Data>) throws {
        PushDebug.shared.pushRecorder.handleMessage(push)
    }
}

public final class ByteViewDebugAssembly: LarkAssemblyInterface {
    public init() {}

    public func registRustPushHandlerInUserSpace(container: Container) {
        // 参会人变化
        (Command.pushMeetingParticipantChange, PushProcessor.init(resolver:))
    }

}
