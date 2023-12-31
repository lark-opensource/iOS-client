//
//  Tenant.swift
//  Calendar
//
//  Created by zhouyuan on 2019/5/8.
//

import Foundation
import CalendarFoundation
// 需求 https://bytedance.feishu.cn/space/doc/doccnB5h06VqMDwuA9eAOg#
public struct Tenant {
    public static let noTenantId = "-1"
    public static let customerTenantId = "0"
    private let currentTenantId: String
    public init(currentTenantId: String) {
        self.currentTenantId = currentTenantId
    }

    /// 是否是C端用户
    public func isCustomerTenant() -> Bool {
        return isCustomerTenant(tenantId: currentTenantId)
    }

    private func isCustomerTenant(tenantId: String) -> Bool {
        return tenantId == Tenant.customerTenantId
    }

    public func tenantCase(tenantId: String,
                    isCrossTenant: Bool,
                    isCustomer: () -> Void,
                    isExternal: (Bool) -> Void) {
        // C端用户不牵涉到跨不跨租户, 没有跨租户的概念
        if isCustomerTenant() {
            isCustomer()
            return
        }
        // 非法租户按b端非跨租户处理
        if tenantId == Tenant.noTenantId {
            isExternal(false)
            return
        }

        if isCrossTenant {
            isExternal(true)
            return
        }
        // 群的tenantId为空, 群的external SDK判断
        guard !tenantId.isEmpty,
            tenantId != Tenant.noTenantId else {
                isExternal(false)
                return
        }
        isExternal(currentTenantId != tenantId)
    }
}

extension Tenant {

    /// 是否是外部租户
    public func isExternalTenant(isCrossTenant: Bool) -> Bool {
        return isExternalTenant(tenantId: "", isCrossTenant: isCrossTenant)
    }

    public func isExternalTenant(tenantId: String, isCrossTenant: Bool) -> Bool {
        var isExternalTenant = false
        tenantCase(tenantId: tenantId, isCrossTenant: isCrossTenant, isCustomer: {
            isExternalTenant = false
        }, isExternal: { isExternal in
            isExternalTenant = isExternal
        })
        return isExternalTenant
    }

    /// 是否是当前租户
    public func isCurrentTenant(isCrossTenant: Bool) -> Bool {
        return isCurrentTenant(tenantId: "", isCrossTenant: isCrossTenant)
    }

    public func isCurrentTenant(tenantId: String, isCrossTenant: Bool) -> Bool {
        var isCurrentTenant = false
        tenantCase(tenantId: tenantId, isCrossTenant: isCrossTenant, isCustomer: {
            isCurrentTenant = false
        }, isExternal: { isExternal in
            isCurrentTenant = !isExternal
        })
        return isCurrentTenant
    }
}
