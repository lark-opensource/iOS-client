//
//  MailMessageListController+Notice.swift
//  MailSDK
//
//  Created by ByteDance on 2023/11/14.
//

import Foundation

extension MailMessageListController: MailMessageListHeaderManagerDelegate {
    func closeHeaderView() {
        containerView.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(view.safeAreaInsets.top)
            make.left.right.bottom.equalToSuperview()
        }
        //更新位置
    }
}
