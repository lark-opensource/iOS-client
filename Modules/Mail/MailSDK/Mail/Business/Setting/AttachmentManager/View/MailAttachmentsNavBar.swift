//
//  MailAttachmentsNavBar.swift
//  MailSDK
//
//  Created by ByteDance on 2023/4/20.
//

import Foundation
import LarkUIKit
import RxSwift
import UIKit

protocol MailAttachmentsNavBarDelegate: AnyObject {
    func managerDidTap() // 管理按钮点击
    func deleteTap() // 删除点击
}

/// 超大附件管理页面NavBar

class MailAttachmentsNavBar: UIView {
    static var navBarHeight: CGFloat {
        return MailTitleNaviBar.navBarHeight
    }
    
    let titleNavBar = MailTitleNaviBar(titleString: BundleI18n.MailSDK.Mail_Shared_LargeAttachmentStorage_ManageStorage_Title)
    
    weak var delegate: MailAttachmentsNavBarDelegate?
    
    init() {
        super.init(frame: .zero)
//        autoConfigNaviItem()
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var navBarHeight: CGFloat {
        return titleNavBar.naviBarHeight
    }
    
    private func setupViews() {
        isUserInteractionEnabled = true
        backgroundColor = UIColor.ud.bgBody
        addSubview(titleNavBar)
        titleNavBar.snp.makeConstraints { (make) in
            make.left.top.right.bottom.equalToSuperview()
        }
        titleNavBar.backgroundColor = UIColor.ud.bgBody
    }
}
