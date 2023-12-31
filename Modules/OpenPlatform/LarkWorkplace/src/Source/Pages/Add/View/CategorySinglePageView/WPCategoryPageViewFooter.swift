//
//  WPCategoryPageViewFooter.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/6/25.
//

import UIKit

let footerViewHeight: CGFloat = 76.0

final class WPCategoryPageViewFooter: UIView {
    /// 提示图标
    private lazy var tipIcon: UIImageView = {
       let view = UIImageView()
        view.image = Resources.workplace_nomore
        return view
    }()
    /// 提示文案
    private lazy var tipText: UILabel = {
        let text = UILabel()
        // font 使用 ud token 初始化
        // swiftlint:disable init_font_with_token
        text.font = UIFont.systemFont(ofSize: 14.0)
        // swiftlint:enable init_font_with_token
        text.textColor = UIColor.ud.textTitle
        text.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_DisplayMsg
        text.numberOfLines = 0
        return text
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setConstraint()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupViews() {
        backgroundColor = UIColor.ud.bgBody
        addSubview(tipIcon)
        addSubview(tipText)
    }
    private func setConstraint() {
        tipText.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().offset(14)
            make.left.equalTo(tipIcon.snp.right).offset(8)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
        tipIcon.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.top.equalTo(tipText.snp.top)
            make.right.equalTo(tipText.snp.left).offset(-8)
            make.left.greaterThanOrEqualToSuperview().offset(16)
        }
    }
}
