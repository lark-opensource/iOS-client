//
//  AITool.swift
//  LarkModel
//
//  Created by ByteDance on 2023/5/26.
//

import UIKit
import Foundation
import RustPB
import ServerPB
import LarkLocalizations

public struct MyAIToolInfo {
    public var toolId: String
    public var toolName: String
    public var toolAvatar: String
    public var toolDesc: String
    public var toolInfo: String? //Basic_V1_RichText
    public var isSelected: Bool
    public var enabled: Bool
    
    public init(toolId: String,
                toolName: String,
                toolAvatar: String,
                toolDesc: String,
                toolInfo: String? = nil,
                isSelected: Bool = false,
                enabled: Bool = true) {
        self.toolId = toolId
        self.toolName = toolName
        self.toolAvatar = toolAvatar
        self.toolDesc = toolDesc
        self.toolInfo = toolInfo
        self.isSelected = isSelected
        self.enabled = enabled
    }

    public mutating func transform(toolInfo: MyAIToolInfo) {
        self.toolId = toolInfo.toolId
        self.toolName = toolInfo.toolName
        self.toolAvatar = toolInfo.toolAvatar
        self.toolDesc = toolInfo.toolDesc
        self.toolInfo = toolInfo.toolInfo
        self.isSelected = toolInfo.isSelected
        self.enabled = toolInfo.enabled
    }

    public mutating func transformServerToolInfo() -> ServerPB.ServerPB_Office_ai_ToolInfo {
        var serverToolInfo = ServerPB_Office_ai_ToolInfo()
        serverToolInfo.id = self.toolId
        serverToolInfo.name = self.toolName
        serverToolInfo.icon = self.toolAvatar
        serverToolInfo.desc = self.toolDesc
        return serverToolInfo
    }

    public static func transform(pb: RustPB.Im_V1_MyAIExtensionBasicInfo) -> MyAIToolInfo {
        return MyAIToolInfo(
            toolId: pb.id,
            toolName: pb.name,
            toolAvatar: pb.icon,
            toolDesc: pb.desc,
            toolInfo: pb.desc
        )
    }

    public static func transform(serverPb: ServerPB.ServerPB_Office_ai_ToolInfo) -> MyAIToolInfo {
        let language = LanguageManager.currentLanguage.localeIdentifier.lowercased()
        let localeDesc = serverPb.locale2Desc[language] ?? serverPb.desc
        let localeDetail = serverPb.locale2Detail[language] ?? serverPb.detail
        // 搜索name 有高亮逻辑，服务端已经处理了多语言
        return MyAIToolInfo(
            toolId: serverPb.id,
            toolName: serverPb.name,
            toolAvatar: serverPb.icon,
            toolDesc: localeDesc,
            toolInfo: localeDetail
        )
    }
}

extension RustPB.Basic_V1_RichTextElement.MyAIToolProperty {
    public var localToolName: String {
        let enUSKey = "en_US"
        let language = LanguageManager.currentLanguage.localeIdentifier
        guard let localName = i18NName[language] else {
            return i18NName[enUSKey] ?? ""
        }
        return localName
    }
}

public struct MyAIToolConfig {
    public var maxSelectNum: Int
    public var isFirstUseTool: Bool

    public init(maxSelectNum: Int,
                isFirstUseTool: Bool) {
        self.maxSelectNum = maxSelectNum
        self.isFirstUseTool = isFirstUseTool
    }
}

public typealias MyAIOnboardInfo = ServerPB.ServerPB_Office_ai_PullOnboardInfoResponse
public typealias MyAISceneInfo = ServerPB.ServerPB_Office_ai_PullOnboardInfoResponse

