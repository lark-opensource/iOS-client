//
//  CCMUserScope.swift
//  SKFoundation
//
//  Created by ByteDance on 2023/4/21.
//

import Foundation
import LarkSetting
import LarkContainer

public struct CCMUserScope {
    
    private static let keyPrefix = "ccm.foundation.usercontainer"
    
    private static let enabledKey = keyPrefix + ".main_enabled"
    
    private static let compatibleKey = keyPrefix + ".main_compatible_mode"
    
    private static let bizKey = keyPrefix + ".enabled_bizs"
    
    private static func isEnabled(key: String) -> Bool {
        let array = CCMKeyValue.globalUserDefault.stringArray(forKey: bizKey) ?? []
        return array.contains(key)
    }
}

extension CCMUserScope {
    
    /// 替换.user, 兼容模式和.user一致
    public static let userScope = UserLifeScope { compatibleMode }

    /// 替换.graph, compatibleMode控制是否开启兼容模式。没有指定 scope 的默认都为 .graph
    public static let userGraph = UserGraphScope { compatibleMode }

    /// 替换.transient, compatibleMode控制是否开启兼容模式。
    public static let userTransient = UserTransientScope { compatibleMode }
}

extension CCMUserScope {
    
    public enum BizType: String {
        case spacekit
        case common
        case comment

        case drive
        case space
        case wiki
        case permission

        case browser
        case doc
        case sheet
        case mindnote
        case slide

        case bitable
    }
    
    public static func saveMainSwitchState(_ dict: [String: Any]) {
        let mainEnabled = (dict["main_enabled"] as? Bool) ?? false
        CCMKeyValue.globalUserDefault.set(mainEnabled, forKey: enabledKey)
        let mainCompatibleMode = (dict["main_compatible_mode"] as? Bool) ?? false
        CCMKeyValue.globalUserDefault.set(mainCompatibleMode, forKey: compatibleKey)
    }

    public static func saveEnabledBizs(_ bizs: [String]) {
        CCMKeyValue.globalUserDefault.setStringArray(bizs, forKey: bizKey)
    }
}

extension CCMUserScope {
    
    /// CCM用户态总开关
    private static let enableUserScope: Bool = { // 使用 static let 保证本次运行期间不再变化
        CCMKeyValue.globalUserDefault.bool(forKey: enabledKey)
    }()
    
    /// 是否开启兼容模式,  兼容模式的UserResolver，表现行为和Resolver一致，使用当前UserStorage，不会抛错.
    public static let compatibleMode: Bool = {
        let value: Bool? = CCMKeyValue.globalUserDefault.value(forKey: compatibleKey)
        return value ?? true // 兜底`兼容`
    }()
    
    /// 集成层开关，包括CCMMod、SpaceKit、SpaceInterface等
    public static let spacekitEnabled: Bool = {
        enableUserScope && isEnabled(key: BizType.spacekit.rawValue)
    }()
    
    /// 公共基建开关, 包括网络、User、ModuleService等
    public static let commonEnabled: Bool = {
        enableUserScope && isEnabled(key: BizType.common.rawValue)
    }()
    
    /// 评论开关
    public static let commentEnabled: Bool = {
        enableUserScope && isEnabled(key: BizType.comment.rawValue)
    }()
    
    /// drive开关
    public static let driveEnabled: Bool = {
        enableUserScope && isEnabled(key: BizType.drive.rawValue)
    }()
    
    /// space开关
    public static let spaceEnabled: Bool = {
        enableUserScope && isEnabled(key: BizType.space.rawValue)
    }()
    
    /// wiki开关
    public static let wikiEnabled: Bool = {
        enableUserScope && isEnabled(key: BizType.wiki.rawValue)
    }()
    
    /// permission开关
    public static let permissionEnabled: Bool = {
        enableUserScope && isEnabled(key: BizType.permission.rawValue)
    }()
    
    /// browser开关
    public static let browserEnabled: Bool = {
        enableUserScope && isEnabled(key: BizType.browser.rawValue)
    }()
    
    /// doc开关
    public static let docEnabled: Bool = {
        enableUserScope && isEnabled(key: BizType.doc.rawValue)
    }()
    
    /// sheet开关
    public static let sheetEnabled: Bool = {
        enableUserScope && isEnabled(key: BizType.sheet.rawValue)
    }()
    
    /// mindnote开关
    public static let mindnoteEnabled: Bool = {
        enableUserScope && isEnabled(key: BizType.mindnote.rawValue)
    }()
    
    /// slide开关
    public static let slideEnabled: Bool = {
        enableUserScope && isEnabled(key: BizType.slide.rawValue)
    }()
    
    /// bitable开关
    public static let bitableEnabled: Bool = {
        enableUserScope && isEnabled(key: BizType.bitable.rawValue)
    }()
}
