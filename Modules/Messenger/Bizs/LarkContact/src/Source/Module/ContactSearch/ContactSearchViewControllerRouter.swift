//
//  ContactSearchViewControllerRouter.swift
//  LarkContact
//
//  Created by SuPeng on 5/13/19.
//

import Foundation
import UIKit
import LarkModel

protocol ContactSearchViewControllerRouter {
    func didSelectWithChatter(_ vc: ContactSearchViewController, chatterId: String, type: Chatter.TypeEnum)
    func didSelectWithChat(_ vc: ContactSearchViewController, chatId: String)
}
