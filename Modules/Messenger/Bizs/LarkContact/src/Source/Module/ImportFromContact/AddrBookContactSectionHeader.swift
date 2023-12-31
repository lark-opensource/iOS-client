//
//  AddrBookContactSectionHeader.swift
//  LarkContact
//
//  Created by mochangxing on 2020/7/14.
//

import UIKit
import Foundation
final class AddrBookContactSectionHeader: UITableViewHeaderFooterView {
    static let fontSize: CGFloat = 14

    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textColor = UIColor.ud.N900
        label.font = UIFont.systemFont(ofSize: AddrBookContactSectionHeader.fontSize)
        return label
    }()

    private lazy var subTitleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textColor = UIColor.ud.N900
        label.font = UIFont.systemFont(ofSize: AddrBookContactSectionHeader.fontSize)
        return label
    }()

    private lazy var topView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.bgBase
        return view
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgBody
        layoutPageSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutPageSubviews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(topView)
        contentView.addSubview(subTitleLabel)
        topView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(Layout.topViewHeight)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-Layout.titleLetfOffset)
            make.left.equalToSuperview().offset(Layout.titleLetfOffset)
            make.top.equalTo(topView.snp.bottom).offset(Layout.titleTopOffset)
        }

        subTitleLabel.snp.makeConstraints { (make) in
            make.right.equalTo(titleLabel)
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom)
        }
    }

    func setTitle(title: String) {
        titleLabel.text = title
    }

    func setSubTitle(subTitle: String) {
        subTitleLabel.text = subTitle
    }
}

extension AddrBookContactSectionHeader {
    enum Layout {
        static let titleLetfOffset: CGFloat = 16
        static let topViewHeight: CGFloat = 8
        static let titleTopOffset: CGFloat = 15.5
    }
}
