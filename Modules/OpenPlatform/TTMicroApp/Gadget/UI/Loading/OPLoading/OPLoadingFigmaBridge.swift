//
//  OPLoadingFigmaBridge.swift
//  TTMicroApp
//
//  Created by xingjinhao on 2021/9/7.
//

import Foundation

// 桥接FigmaKit中setSmoothCorner方法以供OC使用
public final class OPLoadingFigmaBridge: NSObject{
    @objc static public func setSmoothCorner(inputView: UIView, radius: CGFloat){
        inputView.layer.ux.setSmoothCorner(radius: radius)
    }
}
