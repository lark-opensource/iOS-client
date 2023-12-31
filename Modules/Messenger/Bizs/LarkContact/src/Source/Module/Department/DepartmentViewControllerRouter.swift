//
//  DepartmentViewControllerRouter.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/10/15.
//

import Foundation
import LarkModel
import LarkMessengerInterface

protocol DepartmentViewControllerRouter: AnyObject {
    func didSelectWithChatter(_ vc: DepartmentViewController, chatter: Chatter)
    func pushDepartmentViewController(_ vc: DepartmentViewController, department: Department, departmentPath: [Department], departmentsAdministratorStatus: DepartmentsAdministratorStatus)
    func pushMemberInvitePage(_ vc: DepartmentViewController)
}
