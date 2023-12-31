//
//  LynxViewPagerItem.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/9.
//  


import Foundation
import Lynx
import UIKit
import SnapKit

//class LynxViewPagerItemView: UIView {
//    
//}

class LynxViewPagerItem: LynxUI<UIView> {
    private(set) var tag = ""
    static let name = "ud-viewpager-item"
    override var name: String {
        return Self.name
    }
    
    override func createView() -> UIView {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }
    
    @objc
    public static func propSetterLookUp() -> [[String]] {
        return [
            ["tag", NSStringFromSelector(#selector(setTag))]
        ]
    }
    @objc
    func setTag(_ value: String, requestReset: Bool) {
        tag = value
    }
}
