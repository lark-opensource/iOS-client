//
//  WPGroupBackground.swift
//  templateDemo
//
//  Created by  bytedance on 2021/3/27.
//

import LarkUIKit
import UniverseDesignShadow
/// section背景装饰图的布局属性
final class BackgroundDecorationViewLayoutAttributes: UICollectionViewLayoutAttributes {

    // 背景色
    var model: GroupBackgroundComponent?

//    //所定义属性的类型需要遵从 NSCopying 协议
//    override func copy(with zone: NSZone? = nil) -> Any {
//        let copy = super.copy(with: zone) as! BackgroundDecorationViewLayoutAttributes
//        copy.backgroundColor = self.backgroundColor
//        return copy
//    }
//
//    //所定义属性的类型还要实现相等判断方法（isEqual）
//    override func isEqual(_ object: Any?) -> Bool {
//        guard let rhs = object as? BackgroundDecorationViewLayoutAttributes else {
//            return false
//        }
//
//        if !self.backgroundColor.isEqual(rhs.backgroundColor) {
//            return false
//        }
//        return super.isEqual(object)
//    }
}

final class WPGroupBackground: UICollectionReusableView {
    /// 背景图
    private lazy var backgroundView: UIImageView = {
        let view = UIImageView()
        view.layer.ud.setShadow(type: UDShadowType.s2Down)
        view.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        view.layer.borderWidth = WPUIConst.BorderW.px1
        return view
    }()

    // MARK: view initial
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.layer.shadowPath = CGPath(rect: bounds, transform: nil)
    }

    private func setupView() {
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    // 通过apply方法让自定义属性生效
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let attr = layoutAttributes as? BackgroundDecorationViewLayoutAttributes, let model = attr.model else {
            return
        }

        backgroundView.backgroundColor = UIColor.ud.bgFloat // model.backgroundStartColor
        backgroundView.layer.cornerRadius = model.backgroundRadius
    }
}
