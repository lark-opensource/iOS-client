//
//  FeatureGatingKey.swift
//  LarkContact
//
//  Created by 李勇 on 2020/6/23.
//

import Foundation
import LarkFeatureGating
import LarkSetting

extension FeatureGatingKey {
    // 是否放开选择部门权限限制
    static let disableSelectDepartmentPermission = "im.chat.depart_group_permission"
    static let enableMoreDepartmentsInOrganization = "lark.client.contact.organization.moredepartments"
}

extension FeatureGatingManager.Key {
    static let enableAddFromMobileContact: Self = "contact.addcontact.phonebook"
    static let enableDepartmentHeadCountRules: Self = "suite.admin.organization.departmentheadcountrules"
    static let enableEnterSearchDetail: Self = "suite.admin.organization.enter_search_detail"
}
