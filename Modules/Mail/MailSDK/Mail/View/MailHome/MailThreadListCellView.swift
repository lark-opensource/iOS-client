//
//  MailThreadListCellView.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/9/23.
//

import Foundation

// MARK: - 空状态
class MailHomeEmptyCell: UITableViewCell {
    enum EmptyCellStatus {
        case canRetry
        case noNet
        case empty
        case none
        case emptyAttachment // 空附件
    }

    var centerYOffset: CGFloat = 0.0 {
        didSet {
            container.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.centerY.equalToSuperview().offset(-centerYOffset)
            }
        }
    }

    var isUnreadEmpty: Bool = false {
        didSet {
            self.actionButton.isHidden = canRetry || !isUnreadEmpty
        }
    }
    var isStrangerEmpty: Bool = false {
        didSet {
            guard status == .empty else {
                titleLabel.isHidden = false
                emptyIcon.isHidden = false
                return
            }
            titleLabel.isHidden = isStrangerEmpty
            emptyIcon.isHidden = isStrangerEmpty
            if isStrangerEmpty {
                actionButton.isHidden = true
                emptyIcon.snp.makeConstraints { (make) in
                    make.top.centerX.equalToSuperview()
                    make.width.height.equalTo(100)
                }
            } else {
                emptyIcon.snp.remakeConstraints { (make) in
                    make.centerX.equalToSuperview()
                    make.centerY.equalToSuperview().offset(-50)
                    make.width.height.equalTo(100)
                }
            }
        }
    }
    var canRetry: Bool = false {
        didSet {
            emptyIcon.image = canRetry ? Resources.feed_error_icon : Resources.feed_empty_data_icon
            titleLabel.text = BundleI18n.MailSDK.Mail_Common_NetworkError // "网络错误 请点击重试"
            titleLabel.sizeToFit()
            self.actionButton.isHidden = true
        }
    }
    var status: EmptyCellStatus = .empty {
        didSet {
            switch status {
            case .canRetry:
                emptyIcon.image = Resources.feed_error_icon
                titleLabel.text = BundleI18n.MailSDK.Mail_Common_NetworkError
            case .noNet:
                emptyIcon.image = Resources.feed_error_icon
                titleLabel.text = BundleI18n.MailSDK.Mail_ThreadList_NoNetwork
            case .empty:
                emptyIcon.image = Resources.feed_empty_data_icon
            case .none:
                emptyIcon.image = Resources.feed_empty_data_icon
            case .emptyAttachment:
                emptyIcon.image = Resources.feed_empty_file_icon
                titleLabel.text = BundleI18n.MailSDK.Mail_Shared_LargeAttachment_NoLargeFile_EmptyTitle
                titleLabel.font = UIFont.systemFont(ofSize: 14)
                actionButton.isHidden = true
            }
            titleLabel.sizeToFit()
        }
    }
    var type = "" {
        didSet {
            guard !isUnreadEmpty else {
                titleLabel.text = BundleI18n.MailSDK.Mail_ThreadList_ReadAllTip(type)
                return
            }
            titleLabel.text = BundleI18n.MailSDK.Mail_List_Empty(type)
            titleLabel.sizeToFit()
        }
    }
    fileprivate lazy var container = UIView()
    fileprivate lazy var titleLabel = self.makeTitleLabel()
    fileprivate lazy var emptyIcon = self.makeEmptyIcon()
    fileprivate lazy var actionButton = self.makeActionButton()

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    func setup() {
        // container
        addSubview(container)
        container.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview().offset(-centerYOffset)
        }
        [titleLabel, emptyIcon, actionButton].forEach {
            container.addSubview($0)
        }

        self.backgroundColor = UIColor.clear
        emptyIcon.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-50)
            make.width.height.equalTo(100)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(emptyIcon.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.centerX.equalToSuperview()
        }
        titleLabel.sizeToFit()
        actionButton.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        selectedBackgroundView = UIView()
    }

    // MARK: - Make
    private func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textPlaceholder
        label.text = BundleI18n.MailSDK.Mail_List_Empty(type)
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        return label
    }

    private func makeEmptyIcon() -> UIImageView {
        let imageview = UIImageView()
        imageview.image = Resources.feed_empty_data_icon
        return imageview
    }

    private func makeActionButton() -> UILabel {
        let label = UILabel()
        label.text = BundleI18n.MailSDK.Mail_Label_ClearFilter
        label.textColor = UIColor.ud.primaryContentDefault
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }
}
