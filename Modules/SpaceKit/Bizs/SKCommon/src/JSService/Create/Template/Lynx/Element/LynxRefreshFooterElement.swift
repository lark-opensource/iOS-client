//
//  LynxRefreshFooterElement.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/11.
//  


import Foundation
import Lynx
import UIKit

class LynxRefreshFooterElement: LynxUI<UIView> {
    static let name = "ccm-refresh-footer"
    
    override var name: String {
        return Self.name
    }
    override func createView() -> UIView {
        return UIView()
    }
}
