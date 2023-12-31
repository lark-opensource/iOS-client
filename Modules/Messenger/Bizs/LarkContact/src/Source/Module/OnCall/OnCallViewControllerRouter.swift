//
//  OnCallViewControllerRouter.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/10/10.
//

import Foundation
import LarkModel

protocol OnCallViewControllerRouter: AnyObject {
    func onCallViewController(_ vc: OnCallViewController, chatModel: Chat)
}
