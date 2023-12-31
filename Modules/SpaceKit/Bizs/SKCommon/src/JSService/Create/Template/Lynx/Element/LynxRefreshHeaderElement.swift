//
//  LynxRefreshHeaderElement.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/11.
//  


import Foundation
import Lynx
import UIKit

class LynxRefreshHeaderElement: LynxUI<UIView> {
    static let name = "ccm-refresh-header"
    
    override var name: String {
        return Self.name
    }
    override func createView() -> UIView {
        return UIView()
    }
}
