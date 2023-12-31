//
//  SendAttachedFilePreviewCell.swift
//  LarkFile
//
//  Created by ChalrieSu on 2018/9/20.
//

import UIKit
import Foundation
import LarkUIKit

final class SendAttachedFilePreviewCell: UITableViewCell {
    var fileId: String?

    private let closeButton = UIButton()
    private let sendAttachedFileContentView = SendAttachedFileContentView()
    private var bottomSeperator: UIView?

    private var closeButtonClickedBlock: ((SendAttachedFilePreviewCell) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectedBackgroundView = BaseCellSelectView()

        contentView.addSubview(sendAttachedFileContentView)
        sendAttachedFileContentView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-40)
        }

        closeButton.setImage(Resources.member_select_cancel, for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonDidClicked), for: .touchUpInside)
        contentView.addSubview(closeButton)
        closeButton.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        closeButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
        selectionStyle = .none
        bottomSeperator = lu.addBottomBorder(leading: 68)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(fileId: String,
                    name: String,
                    size: Int64,
                    duration: TimeInterval?,
                    isVideo: Bool,
                    isLastRow: Bool,
                    closeButtonClickedBlock: @escaping ((SendAttachedFilePreviewCell) -> Void)) {
        self.fileId = fileId
        sendAttachedFileContentView.setContent(name: name, size: size, duration: duration, isVideo: isVideo)
        bottomSeperator?.isHidden = isLastRow
        self.closeButtonClickedBlock = closeButtonClickedBlock
    }

    @objc
    private func closeButtonDidClicked() {
        closeButtonClickedBlock?(self)
    }

    func setImage(_ image: UIImage?) {
        sendAttachedFileContentView.setImage(image)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setImage(nil)
    }
}
