//
//  CollaborationDepartmentViewControllerRouter.swift
//  LarkContact
//
//  Created by tangyunfei.tyf on 2021/3/15.
//

import Foundation
import LarkModel
import LarkMessengerInterface
import EENavigator
import RustPB

protocol CollaborationDepartmentViewControllerRouter: AnyObject {
    func didSelectWithChatter(_ vc: CollaborationDepartmentViewController, chatter: Chatter)

    func pushCollaborationDepartmentViewController(_ vc: CollaborationDepartmentViewController,
                                                   tenantId: String?, department: Department,
                                                   departmentPath: [Department],
                                                   associationContactType: AssociationContactType?)

    func pushCollaborationTenantInviteSelectPage(_ vc: CollaborationDepartmentViewController, contactType: AssociationContactType)

    func pushCollaborationTenantInviteQRPage(contactType: AssociationContactType, _ vc: AssociationInviteSelectViewController)

    func pushAssociationInviteHelpURL(url: URL, from vc: NavigatorFrom)
}
