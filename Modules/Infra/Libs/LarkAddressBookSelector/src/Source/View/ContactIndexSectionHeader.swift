//
//  ContactIndexSectionHeader.swift
//  LarkAddressBookSelector
//
//  Created by zhenning on 2020/4/27.
//

import Foundation
import UIKit
import SnapKit

final class ContactIndexSectionHeader: UITableViewHeaderFooterView {

    private var wrapperView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBase
        return view
    }()

    private var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        layoutPageSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(title: String) {
        titleLabel.text = title
    }

    private func layoutPageSubviews() {
        addSubview(wrapperView)
        wrapperView.addSubview(titleLabel)
        wrapperView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
    }
}
