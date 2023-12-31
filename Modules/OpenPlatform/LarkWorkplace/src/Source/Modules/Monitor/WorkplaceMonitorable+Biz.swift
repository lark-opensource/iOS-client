//
//  WorkplaceMonitorable+Biz.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/10.
//

import Foundation
import ECOInfra

/// 业务自定义结构的封装，作为语法糖方便使用。
///
/// 注意: 如果方法比较多，按照业务聚类拆解成不同的 Extension。
extension WorkplaceMonitorable {
    func setWorkplaceError(_ error: WorkplaceError) -> WorkplaceMonitorable {
        setValue(error.code, for: .error_code)
        setValue(error.httpCode, for: .http_code)
        if let errorMessage = error.errorMessage {
            setValue(errorMessage, for: .error_message)
        }
        if let serverCode = error.serverCode {
            setValue(serverCode, for: .server_error)
        }
        return self
    }

    /// 设置门户渲染类型
    func setPortalRenderType(_ renderType: WorkplaceMonitorPortalRenderType) -> WorkplaceMonitorable {
        return setValue(renderType.rawValue, for: .render_scene)
    }

    /// 设置门户类型
    func setPortalType(_ portalType: WPPortal.PortalType) -> WorkplaceMonitorable {
        return setValue(portalType.rawValue, for: .type)
    }

    /// 设置模版工作台失败来源
    func setTemplateFailFrom(_ failFrom: WPLoadTemplateError.WPLoadTemplateFailFrom) -> WorkplaceMonitorable {
        return setValue(failFrom.rawValue, for: .fail_from)
    }

    /// 设置错误页显示来源
    func setTemplateShowErrorFrom(_ from: WPLoadTemplateShowErrorViewFrom) -> WorkplaceMonitorable {
        return setValue(from.rawValue, for: .fail_from)
    }

    /// 设置门户变更
    func setPortalChange(
        originPortal: WPPortal, newPortal: WPPortal, changeType: WPPortalChangeType
    ) -> WorkplaceMonitorable {
        return setValue(changeType.rawValue, for: .change_type)
            .setValue(newPortal.type.rawValue, for: .new_portal_type)
            .setValue(originPortal.type.rawValue, for: .origin_portal_type)
            .setValue(newPortal.template?.id, for: .new_portal_id)
            .setValue(originPortal.template?.id, for: .origin_portal_id)
    }

    func setPortalTriggerFrom(_ from: WPPortalLoadFrom) -> WorkplaceMonitorable {
        return setValue(from.rawValue, for: .trigger_from)
    }
}
