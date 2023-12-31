//
//  SetupLarkMessageCardTask.swift
//  LarkMessageCard
//
//  Created by ByteDance on 2022/11/28.
//

import Foundation
import BootManager
import LarkLynxKit
import Lynx
import LarkModel
import LarkContainer
import LarkSetting
import UniverseDesignColor
import UniversalCardBase

class SetupLarkMessageCardTask: FlowBootTask, Identifiable {
    @Provider private var messageCardEnvService: MessageCardEnvService
    static var identify = "SetupLarkMessageCardTask"
    let tag = "MessageCard"

    private let extensionUDColorToken: [String: UIColor] = [
        "R100": UDColor.R100,
        "O100": UDColor.O100,
        "Y100": UDColor.Y100,
        "L100": UDColor.L100,
        "G100": UDColor.G100,
        "T100": UDColor.T100,
        "W100": UDColor.W100,
        "B100": UDColor.B100,
        "C100": UDColor.C100,
        "P100": UDColor.P100,
        "N200": UDColor.N200,
        "B500": UDColor.B500,
        "N00": UDColor.N00,
        "icon-disable": UDColor.iconDisabled
    ]
    
    // 是否允许图片组件使用shadowNode
    public let lynxImageUseShadowNodeEnable: Bool = {
        // 同样的 FG 在 MessageCardAssembly 中也存在
        @FeatureGatingValue(key: "messagecard.lynximageshadownode.enable")
        var featureGating: Bool
        return featureGating
    }()
    
    override var scope: Set<BizScope> { return [.openplatform] }

    override func execute(_ context: BootContext) {
        guard MessageCardRenderControl.lynxCardRenderEnable else { return }
        registerUDColorExtension()
    }

    // 注册当前UDcolor通过token获取不到的color
    private func registerUDColorExtension() {
        var registerTokens:[UDColor.Name: UIColor] = [:]
        for (token, color) in extensionUDColorToken {
            if UDColor.getValueByBizToken(token: token) == nil {
                registerTokens[UDColor.Name(token)] = color
            }
        }
        UDColor.registerBizTokens(registerTokens)
    }
}
