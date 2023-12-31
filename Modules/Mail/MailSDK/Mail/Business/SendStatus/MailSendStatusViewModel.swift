//
//  MailSendStatusViewModel.swift
//  MailSDK
//
//  Created by tanghaojin on 2021/8/17.
//

import Foundation
import RxSwift
import ServerPB

class MailSendStatusViewModel: NSObject {
    let messageId: String
    let threadId: String
    let labelId: String
    var dataSource: [SendStatusDetail]? {
        didSet {
            if let handler = self.bindDataSourceToVC {
                handler()
            }
        }
    }
    var bindDataSourceToVC: (() -> Void)?
    var bindHeaderText: ((_ progress: String) -> Void)?
    private var disposeBag = DisposeBag()

    init(messageId: String,
         threadId: String,
         labelId: String) {
        self.messageId = messageId
        self.threadId = threadId
        self.labelId = labelId
    }

    func refreshDetailMessages(errorHandler: (() -> Void)? = nil) {
        MailDataServiceFactory.commonDataService?.getMessageSendStatus(messageId: self.messageId).subscribe { [weak self] (resp) in
            guard let `self` = self else { return }
            self.dataSource = resp.details
            self.genHeaderTextAndBind()
        } onError: { (error) in
            MailLogger.error("MailSendStatusViewModel refresh err=\(error)")
            if let handler = errorHandler {
                handler()
            }
        }.disposed(by: disposeBag)
    }
    func genHeaderTextAndBind() {
        let total: Int = self.dataSource?.count ?? 0
        let success: Int = self.dataSource?.filter({ (detail) in
            detail.detailStatus == .delivered
        }).count ?? 0
        if let handler = self.bindHeaderText {
            handler("\(success)/\(total)")
        }
    }
}
