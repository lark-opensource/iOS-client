//
//  GroupGuideAddTabProvider.swift
//  LarkMessengerInterface
//
//  Created by zhaojiachen on 2022/12/16.
//

import UIKit
import Foundation
import LarkContainer

public protocol GroupGuideAddTabProvider {
    func createView(docToken: String, docType: String, templateId: String, chatId: String, fromVC: UIViewController?) -> UIView
}
