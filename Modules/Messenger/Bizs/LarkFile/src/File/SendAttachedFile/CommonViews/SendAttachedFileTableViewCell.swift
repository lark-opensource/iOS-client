//
//  SendAttachedFileTableViewCell.swift
//  Lark
//
//  Created by CharlieSu on 2017/12/16.
//  Copyright © 2017 Bytedance.Inc. All rights reserved.
//
//  用于SendAttachedFileViewController以及SendAttachedFilePreviewViewController中的cell，header展示
import Foundation
import UIKit
import LarkUIKit
import SnapKit
import UniverseDesignCheckBox

final class SendAttachedFileTableViewCell: UITableViewCell {
    var fileId: String?

    private let checkbox = UDCheckBox(boxType: .multiple)
    private let sendAttachedFileContentView = SendAttachedFileContentView()
    private var bottomSeperator: UIView?
    private var iconButtonClickedBlock: ((SendAttachedFileTableViewCell) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(checkbox)
        checkbox.isUserInteractionEnabled = false
        checkbox.snp.makeConstraints({ make in
            make.size.equalTo(CGSize(width: 18, height: 18))
            make.centerY.equalToSuperview()
            make.left.equalTo(16)
        })
        if let recognizers = checkbox.gestureRecognizers {
            for gestureRecognizer in recognizers {
                checkbox.removeGestureRecognizer(gestureRecognizer)
            }
        }

        sendAttachedFileContentView.iconButtonClickedBlock = { [weak self] (_) in
            guard let `self` = self else { return }
            self.iconButtonClickedBlock?(self)
        }
        contentView.addSubview(sendAttachedFileContentView)
        sendAttachedFileContentView.snp.makeConstraints { (make) in
            make.left.equalTo(checkbox.snp.right).offset(12)
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-15)
        }
        bottomSeperator = lu.addBottomBorder(leading: 98)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(fileId: String,
                    name: String,
                    size: Int64,
                    duration: TimeInterval?,
                    isVideo: Bool,
                    isSelected: Bool,
                    isLastRow: Bool,
                    iconButtonDidClick: @escaping (SendAttachedFileTableViewCell) -> Void) {
        self.fileId = fileId
        checkbox.isSelected = isSelected
        bottomSeperator?.isHidden = isLastRow
        self.iconButtonClickedBlock = iconButtonDidClick
        sendAttachedFileContentView.setContent(name: name, size: size, duration: duration, isVideo: isVideo)
    }

    func setSelected(_ selected: Bool) {
        checkbox.isSelected = selected
    }

    func setImage(_ image: UIImage?) {
        sendAttachedFileContentView.setImage(image)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setImage(nil)
    }
}
