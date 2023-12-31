//
//  PageRouteBridgeHandler.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/12.
//  


import Foundation
import BDXServiceCenter
import BDXBridgeKit
import UIKit

class PageCloseBridgeHandler: BridgeHandler {
    let methodName = "ccm.closePage"
    
    weak var currentPage: UIViewController?
    
    let handler: BDXLynxBridgeHandler
    
    init(page: UIViewController?) {
        currentPage = page
        handler = { [weak page] (_, _, params, callback) in
            guard let currentPage = page else {
                return
            }
            let animated = params?["animated"] as? Bool ?? true
            if let navigationController = currentPage.navigationController, navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: animated)
            } else if currentPage.presentingViewController != nil {
                currentPage.dismiss(animated: animated)
            } else {
                currentPage.navigationController?.popViewController(animated: animated)
            }
        }
    }
}
