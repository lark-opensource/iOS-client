//
//  ShareRouter.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/3/9.
//

import UIKit
import Foundation
import LarkMessengerInterface

protocol ShareRouter {
    func routeToForwardLarkInviteMsg(
        with msg: String,
        newTitle: String?,
        from: UIViewController,
        nextHandler: @escaping ForwardTextBody.SentHandler
    )
}
