//
//  File.swift
//  Calendar
//
//  Created by zc on 2018/7/20.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation
import UIKit
import LarkCompatible

extension UIView {
    @discardableResult public func addTopSepratorLine() -> UIView {
        assertLog(Thread.isMainThread)
        let seprator = UIView()
        seprator.backgroundColor = UIColor.ud.N300
        addSubview(seprator)
        seprator.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        return seprator
    }

    @discardableResult public func addBottomSepratorLine() -> UIView {
        assertLog(Thread.isMainThread)
        let seprator = UIView()
        seprator.backgroundColor = UIColor.ud.N300
        addSubview(seprator)
        seprator.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        return seprator
    }

    public func layout(equalTo superView: UIView) {
        superView.addSubview(self)
        self.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    public func viewController() -> UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController                
            }
        }
        return nil
    }
}

extension UIView: CalendarExtensionCompatible {}

extension CalendarExtension where BaseType: UIView {
    public func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: base.bounds,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        base.layer.mask = mask
    }
}
