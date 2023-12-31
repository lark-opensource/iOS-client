//
//  GroupsViewControllerRouter.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/10/12.
//

import Foundation
import LarkModel
import LarkMessengerInterface

protocol GroupsViewControllerRouter: AnyObject {
    func didSelectBotWithGroup(_ vc: GroupsViewController, chat: Chat, fromWhere: ChatFromWhere)
}
