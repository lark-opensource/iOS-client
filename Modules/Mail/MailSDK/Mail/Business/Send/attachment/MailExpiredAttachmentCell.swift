//
//  MailExpiredAttachmentCell.swift
//  MailSDK
//
//  Created by tanghaojin on 2022/3/15.
//

import UIKit
import RustPB

class MailExpiredAttachmentCell: UITableViewCell {
    static let identifier = "MailExpiredAttachmentCell"
    static let cellHeight: CGFloat = 68
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private lazy var fileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var sizeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private let sep: UIView = {
        let sep = UIView()
        sep.backgroundColor = UIColor.ud.lineDividerDefault
        return sep
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.layer.zPosition = 0
        contentView.backgroundColor = UIColor.ud.bgFloat
        contentView.addSubview(fileImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(sizeLabel)
        contentView.addSubview(sep)
        contentView.addSubview(statusLabel)
        
        fileImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(fileImageView.snp.right).offset(12)
            make.top.equalTo(12)
            make.right.equalTo(-16)
            make.height.equalTo(22)
        }
        sizeLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.left)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.height.equalTo(18)
        }
        sep.snp.makeConstraints { (make) in
            make.height.equalTo(12)
            make.width.equalTo(1)
            make.left.equalTo(sizeLabel.snp.right).offset(8)
            make.centerY.equalTo(sizeLabel.snp.centerY)
        }
        statusLabel.snp.makeConstraints { (make) in
            make.left.equalTo(sep.snp.right).offset(8)
            make.top.equalTo(sizeLabel.snp.top)
            make.height.equalTo(18)
        }
    }

    enum ExpiredAttachmentType {
        case expired // 过期
        case bannedAsOwner // 封禁-发件人
        case bannedAsCustomer // 封禁-收件人
        case harmful // 有害
        case deleted // 已删除
    }
    func updateCell(att: Email_Client_V1_Attachment, type: ExpiredAttachmentType) {
        titleLabel.text = att.fileName
        fileImageView.image = UIImage.fileLadderIcon(with: att.fileName,
                                                     size: CGSize(width: 40, height: 40))
        switch type {
        case .expired:
            sizeLabel.text = FileSizeHelper.memoryFormat(UInt64(att.fileSize))
            statusLabel.text = BundleI18n.MailSDK.Mail_Attachments_Expired
        case .bannedAsOwner:
            sizeLabel.text = BundleI18n.MailSDK.Mail_UserAgreementViolated_Text
            sizeLabel.textColor = UIColor.ud.functionDangerContentDefault
            sep.isHidden = true
            statusLabel.isHidden = true
        case .bannedAsCustomer:
            sizeLabel.text = FileSizeHelper.memoryFormat(UInt64(att.fileSize))
            statusLabel.text = BundleI18n.MailSDK.Mail_Expired_Text
        case .harmful:
            sizeLabel.text = BundleI18n.MailSDK.Mail_Attachment_ScanAttachmentsBlockedUploadReason
            sizeLabel.textColor = UIColor.ud.functionDangerContentDefault
            sep.isHidden = true
            statusLabel.isHidden = true
        case .deleted:
            sizeLabel.text = BundleI18n.MailSDK.Mail_Shared_LargeAttachmentAlreadyDeleted_Text
            sizeLabel.textColor = UIColor.ud.functionDangerContentDefault
            sep.isHidden = true
            statusLabel.isHidden = true
        }
    }
}
