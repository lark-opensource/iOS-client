//
//  DocsRedDotView.swift
//  SKCommon
//
//  Created by huayufan on 2021/5/19.
//  


import UIKit
import SKFoundation
import SKUIKit
import UniverseDesignColor

// 负责生产和圆形有关的图片
class CircleComponent {
    
    
    /// 返回特定直径长度的红点图片， 图片作为懒加载属性存储在类变量中
    /// - Parameter diameter: 红点直径
    static func redDotImage(diameter: CGFloat) -> UIImage? {
        let key = "red_dot_\(diameter)"
        if let value = objc_getAssociatedObject(self, key) as? UIImage {
            return value
        }
        let image = DocsRedDotView(frame: CGRect(x: 0, y: 0, width: diameter, height: diameter)).docs.converToImage()
        objc_setAssociatedObject(self, key, image, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return image
    }
    
    
    /// 生成圆形镂空的图片，用作显示圆形头像
    /// - Parameters:
    ///   - diameter: 圆直径
    ///   - borderColor: 头像所在父视图的背景色
    static func holeImage(diameter: CGFloat, borderColor: UIColor = UIColor.ud.bgBody) -> UIImage? {
        let key = "hole_\(diameter)"
        if let value = objc_getAssociatedObject(self, key) as? UIImage {
            return value
        }
        let view = UIView(frame: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        view.backgroundColor = borderColor
        let bezierPath = UIBezierPath(rect: view.bounds)
        bezierPath.append(UIBezierPath(roundedRect: view.bounds, cornerRadius: view.bounds.width / 2.0).reversing())
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = bezierPath.cgPath
        view.layer.mask = shapeLayer
        let image = view.docs.converToImage()
        objc_setAssociatedObject(self, key, image, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return image
    }
    
}


class DocsRedDotView: UIView {
   
    private struct Layout {
        /// 白色边框
        static let padding: CGFloat = 1
    }
    
    private var redLayer = CALayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
        setupLayout()
    }
    
    private func setupInit() {
        redLayer.construct {
            $0.backgroundColor = UIColor.ud.colorfulRed.cgColor
            $0.masksToBounds = true
        }
        layer.addSublayer(redLayer)
        
        layer.ud.setBackgroundColor(UDColor.staticWhite)
        clipsToBounds = true
    }
    
    private func setupLayout() {
        redLayer.cornerRadius = (bounds.size.width - Layout.padding) / 2.0
        redLayer.frame = self.bounds.inset(by: .init(edges: Layout.padding))
        
        layer.cornerRadius = bounds.size.width / 2.0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



extension  DocsExtension where BaseType: UIView {
    func converToImage() -> UIImage? {
        var renderSize = base.bounds.size
        if renderSize.width == 0 { renderSize.width = 1 }
        if renderSize.height == 0 { renderSize.height = 1 }
        UIGraphicsBeginImageContextWithOptions(renderSize, false, SKDisplay.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        base.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
