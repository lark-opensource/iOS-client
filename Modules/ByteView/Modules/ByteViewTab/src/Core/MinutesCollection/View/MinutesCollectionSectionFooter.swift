//
//  MinutesCollectionSectionFooter.swift
//  ByteViewTab
//
//  Created by 陈乐辉 on 2023/5/12.
//

import Foundation

final class MinutesCollectionSectionFooter: UITableViewHeaderFooterView {
    var bezierPath: UIBezierPath {
        let path = UIBezierPath(roundedRect: contentView.bounds, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 10, height: 10))
        return path
    }

    lazy var shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.ud.bgFloat.cgColor
        return layer
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        contentView.layer.addSublayer(shapeLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.path = bezierPath.cgPath
    }

    func setIsRegular(isRegular: Bool) {
        contentView.backgroundColor = isRegular ? .clear : UIColor.ud.bgFloat
    }
}
