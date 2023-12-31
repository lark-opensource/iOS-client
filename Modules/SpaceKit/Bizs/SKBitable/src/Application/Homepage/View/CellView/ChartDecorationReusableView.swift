//
//  ChartDecorationReusableView.swift
//  SKBitable
//
//  Created by qianhongqiang on 2023/11/28.
//

import UIKit

class HomePageChartDecorationCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {

    // 背景色
    var backgroundColor = UIColor.clear

    //所定义属性的类型需要遵从 NSCopying 协议
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone)
        if let copy = copy as? HomePageChartDecorationCollectionViewLayoutAttributes {
            copy.backgroundColor = backgroundColor
        }
        return copy
    }

    //所定义属性的类型还要实现相等判断方法（isEqual）
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? HomePageChartDecorationCollectionViewLayoutAttributes else {
            return false
        }

        if !self.backgroundColor.isEqual(rhs.backgroundColor) {
            return false
        }
        return super.isEqual(object)
    }
}

class ChartDecorationReusableView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let attr = layoutAttributes as? HomePageChartDecorationCollectionViewLayoutAttributes else {
            return
        }

        self.backgroundColor = attr.backgroundColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 设置圆角,只需要左下,右下
        let maskPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: frame.size), byRoundingCorners: [.bottomLeft,.bottomRight], cornerRadii: CGSize(width: BitableHomeChartHeaderLayoutConfig.maskCorner, height: BitableHomeChartHeaderLayoutConfig.maskCorner))
        let mask = CAShapeLayer()
        mask.path = maskPath.cgPath
        layer.mask = mask
    }
    
    static func decorationViewReuseIdentifier() -> String {
        return "ChartDecorationViewReuseIdentifier"
    }
}
