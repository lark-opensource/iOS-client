//
//  DocFilterNaviBar.swift
//  LarkSearch
//
//  Created by SuPeng on 5/5/19.
//

import UIKit
import Foundation
import LarkUIKit

public protocol DocFilterNaviBarDelegate: AnyObject {
    func naviBarDidClickCloseButton(_ naviBar: DocFilterNaviBar)
}

public final class DocFilterNaviBar: UIView {
    public weak var delegate: DocFilterNaviBarDelegate?

    public let closeButton = UIButton()
    public let titleLabel = UILabel()

    public init() {
        super.init(frame: .zero)

        backgroundColor = UIColor.ud.bgBody

        closeButton.setImage(LarkUIKit.Resources.navigation_close_light.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = UIColor.ud.iconN1
        closeButton.addTarget(self, action: #selector(closeButtonDidClick), for: .touchUpInside)
        addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(16)
        }

        titleLabel.text = BundleI18n.LarkSearchFilter.Lark_Search_DocTypeFilter
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func closeButtonDidClick() {
        delegate?.naviBarDidClickCloseButton(self)
    }
}
