//
//  WorkplaceTrackable+Biz.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/10.
//

import Foundation

/// 业务自定义结构的封装，作为语法糖方便使用。
///
/// 注意: 如果方法比较多，按照业务聚类拆解成不同的 Extension, 当前 Extension 适合各业务间服用的逻辑。
extension WorkplaceTrackable {
    /// 设置目标页面
    func setTargetView(_ target: WorkplaceTrackTargetValue) -> WorkplaceTrackable {
        return setValue(target.rawValue, for: .target)
    }

    /// 设置点击元素
    func setClickValue(_ clickValue: WorkplaceTrackClickValue) -> WorkplaceTrackable {
        return setValue(clickValue.rawValue, for: .click)
    }

    /// 设置曝光 UI
    func setExposeUIType(_ type: WorkplaceTrackExposeUIType) -> WorkplaceTrackable {
        return setValue(type.rawValue, for: .type)
    }

    /// 设置组件 menu 类型
    func setMenuType(_ menuType: WorkplaceTrackMenuType) -> WorkplaceTrackable {
        return setValue(menuType.rawValue, for: .menu_type)
    }

    /// 设置 host
    func setHost(_ host: WorkplaceTrackHostType) -> WorkplaceTrackable {
        return setValue(host.rawValue, for: .host)
    }

    /// 设置组件类型
    func setSubType(_ subType: WorkplaceTrackSubType) -> WorkplaceTrackable {
        return setValue(subType.rawValue, for: .sub_type)
    }

    /// 设置常用组件状态
    func setFavoriteStatus(_ status: WorkplaceTrackFavoriteStatus) -> WorkplaceTrackable {
        return setValue(status.rawValue, for: .status)
    }

    /// 设置常用组件拖拽类型
    func setFavoriteDragType(_ dragType: WorkplaceTrackFavoriteDragType) -> WorkplaceTrackable {
        return setValue(dragType.rawValue, for: .type)
    }

    /// 设置常用组件的删除类型
    func setFavoriteRemoveType(_ removeType: WorkplaceTrackFavoriteRemoveType) -> WorkplaceTrackable {
        return setValue(removeType.rawValue, for: .remove_type)
    }

    /// 设置运营弹窗操作类型
    func setOperationType(_ operationType: OperationalType) -> WorkplaceTrackable {
        return setValue(operationType.rawValue, for: .operation_id)
    }

    /// 设置门户更新类型
    func setUpdateType(_ updateType: WPPortalTemplate.UpdateInfo.UpdateType) -> WorkplaceTrackable {
        return setValue(updateType.rawValue, for: .update_type)
    }
}
