//   
//   LiveSettingPrivilegeScope.swift
//   ByteViewNetwork
// 
//  Created by hubo on 2023/2/10.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//   


import Foundation
import ServerPB

/// ServerPB_Videochat_LiveSettingElement
public struct LiveSettingElement: Equatable {

    public var isSelected: Bool

    public var isDisabled: Bool

    public var disableHoverKey: String

    init(pb: ServerPB_Videochat_LiveSettingElement) {
        isSelected = pb.isSelected
        isDisabled = pb.isDisabled
        disableHoverKey = pb.disableHoverKey
    }
}

/// ServerPB_Videochat_LiveSettingPrivilegeScope
public struct LiveSettingPrivilegeScope: Equatable {

    public var scopeTenant: LiveSettingElement

    public var scopePublic: LiveSettingElement

    public var scopeCustom: LiveSettingElement

    init(pb: ServerPB_Videochat_LiveSettingPrivilegeScope) {
        scopeTenant = LiveSettingElement(pb: pb.scopeTenant)
        scopePublic = LiveSettingElement(pb: pb.scopePublic)
        scopeCustom = LiveSettingElement(pb: pb.scopeCustom)
    }
}
