//
//  DocFilterButton.swift
//  LarkSearch
//
//  Created by SuPeng on 5/5/19.
//

import Foundation
import UIKit
import SnapKit
import LarkModel
import LarkSDKInterface

final class DocFilterButton: UIButton {
    var docFilterDidClickBlock: ((DocFormatType) -> Void)?

    private let filter: DocFormatType
    private let icon = UIImageView()
    private let title = UILabel()

    init(filter: DocFormatType) {
        self.filter = filter

        super.init(frame: .zero)

        let guide = UILayoutGuide()
        addLayoutGuide(guide)
        guide.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(1)
        }

        icon.image = filter.image.withRenderingMode(.alwaysTemplate)
        icon.tintColor = UIColor.ud.iconN1
        addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.top.equalTo(guide.snp.top)
            make.centerX.equalToSuperview()
        }

        title.textColor = UIColor.ud.textCaption
        title.font = UIFont.systemFont(ofSize: 14)
        title.text = filter.title
        addSubview(title)
        title.snp.makeConstraints { (make) in
            make.top.equalTo(icon.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(guide.snp.bottom)
        }

        addTarget(self, action: #selector(didClick), for: .touchUpInside)
    }

    override var isHighlighted: Bool {
        didSet {
            // NOTE: backgroundImage不知道为什么始终是亮色，换成backgroundColor的实现方式
            backgroundColor = isHighlighted ? UIColor.ud.bgFiller : nil
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didClick() {
        docFilterDidClickBlock?(filter)
    }
}
