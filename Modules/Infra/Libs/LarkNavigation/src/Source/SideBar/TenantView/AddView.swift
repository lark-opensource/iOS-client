//
//  AddView.swift
//  LarkNavigation
//
//  Created by Supeng on 2021/6/30.
//

import UIKit
import Foundation
import UniverseDesignColor
import SnapKit
import UniverseDesignIcon

final class AddView: UITableViewCell {
    static let resuseIdentifier = String(ObjectIdentifier(AddView.self).hashValue)

    let backgrounView = UIView()
    private let addIcon = UIImageView()
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = UDColor.bgBase

        let layoutGuide = UILayoutGuide()
        contentView.addLayoutGuide(layoutGuide)
        layoutGuide.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.center.equalToSuperview()
        }

        backgrounView.layer.cornerRadius = 8
        backgrounView.layer.masksToBounds = true
        backgrounView.backgroundColor = UDColor.bgFloat
        contentView.addSubview(backgrounView)
        backgrounView.snp.makeConstraints { (make) in
            make.top.centerX.equalTo(layoutGuide)
            make.size.equalTo(CGSize(width: 48, height: 48))
        }

        addIcon.image = BundleResources.LarkNavigation.tab_tenant_add
            .withInsets(insets: UIEdgeInsets(edges: 16))?.ud.withTintColor(UIColor.ud.iconN3)

        backgrounView.addSubview(addIcon)
        addIcon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 48, height: 48))
        }

        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = UIColor.ud.N900
        label.text = BundleI18n.LarkNavigation.Lark_Accounts_NavigationBarPlusButtonTitle
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.right.equalTo(-12)
            make.top.equalTo(backgrounView.snp.bottom).offset(8)
            make.bottom.centerX.equalTo(layoutGuide)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// TODO: 收敛进 UD
extension UIImage {

    /// 将图片四周填充空白，并渲染新的图片
    /// - Parameter insets: 空白边距
    func withInsets(insets: UIEdgeInsets) -> UIImage? {
        let width = self.size.width + insets.left + insets.right
        let height = self.size.height + insets.top + insets.bottom
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: width, height: height), false, self.scale)
        _ = UIGraphicsGetCurrentContext()
        let origin = CGPoint(x: insets.left, y: insets.top)
        self.draw(at: origin)
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithInsets
    }
}
