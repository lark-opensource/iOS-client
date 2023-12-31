//
//  SKSwitch.swift
//  SKUIKit
//
//  Created by yinyuan on 2023/2/7.
//

import Foundation
import UIKit

public class SKSwitch: UISwitch {
    
    /// 配置该回调后，点击时默认不切换状态，响应点击事件后再自主切换状态，用于一些网络请求成功后再切换状态的场景
    public var clickCallback: ((_ switchView: UISwitch) -> ())?
    
    private var lastPoint: CGPoint?
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let clickCallback = clickCallback {
            if self.point(inside: point, with: event), point != lastPoint {
                self.lastPoint = point
                clickCallback(self)
            }
            return nil
        } else {
            return super.hitTest(point, with: event)
        }
    }
}
