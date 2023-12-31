//
//  MailExpiredAttachmentViewController.swift
//  MailSDK
//
//  Created by tanghaojin on 2022/3/15.
//

import UIKit
import RustPB

class MailExpiredAttachmentViewController: MailBaseViewController, UITableViewDelegate, UITableViewDataSource{
    let tableHeaderViewHeight: CGFloat = 44
    lazy var headerViewText: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.ud.textCaption
        return label
    }()
    lazy var tableHeaderView: UIView = {
        let view = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: self.view.bounds.size.width,
                                        height: tableHeaderViewHeight))
        view.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(headerViewText)
        headerViewText.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalTo(view.snp.centerY)
        }
        let line = UIView()
        view.addSubview(line)
        line.backgroundColor = UIColor.ud.lineDividerDefault
        line.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
        return view
    }()
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(MailExpiredAttachmentCell.self, forCellReuseIdentifier: MailExpiredAttachmentCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = MailExpiredAttachmentCell.cellHeight
        tableView.backgroundColor = UIColor.ud.bgFloat
        tableView.estimatedRowHeight = 0.0
        tableView.estimatedSectionFooterHeight = 0.0
        tableView.estimatedSectionHeaderHeight = 0.0
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.bounces = false
        return tableView
    }()
    let attachmentList: [Email_Client_V1_Attachment]
    let bannedInfo: [String: FileBannedInfo]?
    
    private let accountContext: MailAccountContext
    
    init(attachments: [Email_Client_V1_Attachment], bannedInfo: [String: FileBannedInfo]?, accountContext: MailAccountContext) {
        self.attachmentList = attachments
        self.bannedInfo = bannedInfo
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.top.right.bottom.equalToSuperview()
        }
        self.title = BundleI18n.MailSDK.Mail_Attachments_ReplyOriginalEmailAttachmentsMobile
        self.headerViewText.text = BundleI18n.MailSDK.Mail_UnableToAddFollowingAttachment_Text(attachmentList.count)
        updateNavAppearanceIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloatBase
    }

    
    // MARK: - tableView delegate & dataSource
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableHeaderView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableHeaderViewHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: MailExpiredAttachmentCell.identifier, for: indexPath as IndexPath)
        cell.isUserInteractionEnabled = false
        if indexPath.row < self.attachmentList.count {
            if let attCell = cell as? MailExpiredAttachmentCell {
                let att = self.attachmentList[indexPath.row]
                let attachmentType = String(att.fileName.split(separator: ".").last ?? "")
                if att.type == .large && att.expireTime != 0 && att.expireTime / 1000 < Int64(Date().timeIntervalSince1970) {
                    // 已过期
                    attCell.updateCell(att: att, type: .expired)
                } else if bannedInfo?[att.fileToken]?.isBanned == true {
                    // 已封禁
                    if bannedInfo?[att.fileToken]?.isOwner == true {
                        attCell.updateCell(att: att, type: .bannedAsOwner)
                    } else {
                        attCell.updateCell(att: att, type: .bannedAsCustomer)
                    }
                } else if let type = DriveFileType(rawValue: attachmentType), type.isHarmful == true {
                    // 有害附件
                    attCell.updateCell(att: att, type: .harmful)
                } else if bannedInfo?[att.fileToken]?.status == .deleted {
                    // 已删除
                    attCell.updateCell(att: att, type: .deleted)
                } else {
                    // 兜底
                    attCell.updateCell(att: att, type: .expired)
                }
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attachmentList.count
    }
}
