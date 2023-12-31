//
//  CreateShortcutStages.swift
//  SKCommon
//
//  Created by majie.7 on 2023/1/4.
//

import Foundation
import SKFoundation
import SKResource

public enum CreateShortcutStages {
    typealias R = BundleI18n.SKResource
    case hasEntity
    case hasShortcut
    case normal
    
    public var contentString: String {
        switch self {
        case .hasEntity:
            return R.LarkCCM_Workspace_AddShortcut_Repitition1_Description
        case .hasShortcut:
            return R.LarkCCM_Workspace_AddShortcut_Repitition2_Description
        case .normal:
            spaceAssertionFailure("create shorcut should not show confirm dialog in normal stages")
            return ""
        }
    }
}
