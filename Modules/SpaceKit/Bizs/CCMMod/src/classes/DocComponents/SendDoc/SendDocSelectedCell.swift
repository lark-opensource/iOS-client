//
//  SendDocSelectedCell.swift
//  Lark
//
//  Created by lichen on 2018/7/20.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import SnapKit
import LarkUIKit
import LarkModel

#if MessengerMod
import LarkCore
#endif

import UniverseDesignColor
import UniverseDesignIcon

class SendDocSelectedCell: UITableViewCell {

    var clickDeleteBlock: ((SendDocModel) -> Void)?
    var doc: SendDocModel?

    private let docIcon = UIImageView()
    private var titleLabel: UILabel = UILabel()
    private let detailLabel: UILabel = UILabel()
    private let deleteBtn: UIButton = UIButton()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UDColor.bgBody
        self.contentView.addSubview(self.docIcon)
        self.docIcon.snp.makeConstraints { (make) in
            make.width.height.equalTo(48)
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }
        self.docIcon.layer.masksToBounds = true
        self.docIcon.layer.cornerRadius = 24

        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.font = UIFont.systemFont(ofSize: 17)
        self.titleLabel.textColor = UDColor.textTitle
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.docIcon.snp.right).offset(12)
            make.right.lessThanOrEqualTo(-44)
            make.top.equalToSuperview().offset(15)
        }
        self.contentView.addSubview(self.detailLabel)
        self.detailLabel.font = UIFont.systemFont(ofSize: 14)
        self.detailLabel.textColor = UDColor.textPlaceholder
        self.detailLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.docIcon.snp.right).offset(12)
            make.right.lessThanOrEqualTo(-44)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(7)
        }

        self.contentView.addSubview(self.deleteBtn)
        self.deleteBtn.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.centerY.equalToSuperview()
            make.centerX.equalTo(self.contentView.snp.right).offset(-22)
        }
        deleteBtn.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        deleteBtn.setImage(UDIcon.closeOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
        deleteBtn.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setDoc(_ doc: SendDocModel) {
        self.doc = doc
        self.titleLabel.text = doc.title.isEmpty ? BundleI18n.CCMMod.Lark_Legacy_DefaultName : doc.title
        self.detailLabel.text = "\(BundleI18n.CCMMod.Lark_Legacy_SendDocDocOwner)\(BundleI18n.CCMMod.Lark_Legacy_Colon)\(doc.ownerName)"
        #if MessengerMod
        if doc.docType == .wiki {
            self.docIcon.image = LarkCoreUtils.wikiIcon(docType: doc.wikiSubType, fileName: doc.title)
        } else {
            self.docIcon.image = LarkCoreUtils.docIcon(docType: doc.docType, fileName: doc.title)
        }
        #endif
    }

    @objc
    fileprivate func deleteButtonTapped() {
        if let doc = self.doc {
            self.clickDeleteBlock?(doc)
        }
    }
}
