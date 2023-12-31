//
//  FloatActionType.swift
//  SKCommon
//
//  Created by zoujie on 2021/1/4.
//  


import Foundation
import SKResource
import UniverseDesignIcon

public enum FloatActionType: String {
    case publish = "PUBLISH_ANNOUNCEMENT"
    case history = "HISTORY_RECORD"
    case disAssociate = "DISASSOCIATE_DOC" //解除关联文档
}

extension FloatActionType {
    
    public var item: FloatActionItem {
        switch self {
        case .publish:
            return FloatActionItem(icon: BundleResources.SKResource.Common.Icon.icon_announce_outlined,
                                   type: .publish)
        case .history:
            return FloatActionItem(icon: BundleResources.SKResource.Common.Global.icon_global_history_nor,
                                   type: .history)
        case .disAssociate:
            return FloatActionItem(icon: UDIcon.unboundGroupOutlined,
                                   type: .disAssociate)
        }
    }
    
}
