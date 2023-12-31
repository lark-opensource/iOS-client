//
//  BlockComponentUtils.swift
//  OPBlock
//
//  Created by lixiaorui on 2022/3/28.
//

import Foundation
import OPSDK
import LarkSetting
import LarkOPInterface

// web render 配置，用于做blockType级别的回滚
// 策略详见https://bytedance.feishu.cn/docx/doxcn6aEuboLWFkXvmSJv4Yo1Yd?from=space_home_recent&pre_pathname=%2Fdrive%2Fhome%2F
public struct BlockWebComponentConfig: SettingDefaultDecodable{
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "block_web_component")
    public static let defaultValue = BlockWebComponentConfig(
        blockHostBlackList: [],
        enableWebRender: false,
        webRenderHostBlackList: [],
        webRenderBlockBlackList: []
    )

    // 是否禁止对应宿主使用block
    public let blockHostBlackList: [String]

    // 是否命中web render灰度
    public let enableWebRender: Bool

	// 是否禁止对应宿主使用web render
	public let webRenderHostBlackList: [String]

    // 是否禁止对应block使用web render
    public let webRenderBlockBlackList: [String]

}

// block API配置，用于做block Api的统一控制
// 策略详见https://bytedance.feishu.cn/docx/doxcn6aEuboLWFkXvmSJv4Yo1Yd?from=space_home_recent&pre_pathname=%2Fdrive%2Fhome%2F
public struct BlockAPIConfig: SettingDefaultDecodable{
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "block_api_config")
    public static let defaultValue = BlockAPIConfig(
        commonApis: [],
        hostPublicApis: [:],
        blockTypePublicApis: [:],
        blockSpecificApis: [:]
    )

    // 通用API, 开放给所有 block的API
    public let commonApis: [String]

    // 宿主通用API, 开放给特定宿主 block的API
    public let hostPublicApis: [String: [String]]

    // 形态通用API, 开放给特定形态 block的API
    public let blockTypePublicApis: [String: [String]]

    // 特定 block 自己的api列表
    public let blockSpecificApis: [String: [String]]

}

// 提供一些配置获取等工具方法
public final class BlockComponentUtils {
    public let blockWebComponentConfig: BlockWebComponentConfig
    public let apiConfig: BlockAPIConfig

    public init(blockWebComponentConfig: BlockWebComponentConfig, apiConfig: BlockAPIConfig) {
        self.blockWebComponentConfig = blockWebComponentConfig
        self.apiConfig = apiConfig
    }

    public func blockAvailable(for host: String) -> Bool {
        return !blockWebComponentConfig.blockHostBlackList.contains(host)
    }
}


