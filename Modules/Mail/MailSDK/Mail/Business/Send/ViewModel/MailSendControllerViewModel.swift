//
//  MailSendControllerViewModel.swift
//  MailSDK
//
//  Created by majx on 2019/6/16.
//

import Foundation

struct MailSendViewModel {
    var sendToArray: [MailAddressCellViewModel] = []        // 收件地址数组
    var ccToArray: [MailAddressCellViewModel] = []          // 抄送地址数组
    var bccToArray: [MailAddressCellViewModel] = []         // 秘送地址数组
    var atContactsToArray: [MailAddressCellViewModel] = []  // at联系人地址数组
    var filteredArray: [MailAddressCellViewModel] = []    // 过滤后的收件地址数组
    var selectedArray: [MailAddressCellViewModel] = []    // 当前选中的收件地址
    var tempAtContacts = [String: Int]()
    var contextText: String = ""                          // 邮件内容

    // 生成一个带有全部Email地址的MailContent
    //
    mutating func createMailContentWithEmailAddress(_ needFilter: Bool = false) -> MailContent {
        return MailContent(from: MailAddress(name: "", address: "", larkID: "", tenantId: "", displayName: "", type: nil),
                           to: sendToArray.compactMap { needFilter ? emailAddressFilter($0): converCellViewModelToAddress($0) },
                           cc: ccToArray.compactMap { needFilter ? emailAddressFilter($0): converCellViewModelToAddress($0) },
                           bcc: bccToArray.compactMap { needFilter ? emailAddressFilter($0): converCellViewModelToAddress($0) },
                           atContacts: atContactsToArray.compactMap { needFilter ? emailAddressFilter($0): converCellViewModelToAddress($0) },
                           subject: "",
                           bodySummary: "",
                           bodyHtml: "",
                           subjectCover: nil,
                           attachments: [],
                           images: [],
                           priorityType: .normal,
                           needReadReceipt: false,
                           docsConfigs: [])
    }

    func emailAddressFilter(_ model: MailAddressCellViewModel) -> MailAddress? {
        if model.address.isLegalForEmail() || (!model.larkID.isEmpty && model.larkID != "0") { // 允许出现没有email但是有larkID的情况
            let address = MailAddress(name: model.name,
                                      address: model.address,
                                      larkID: model.larkID,
                                      tenantId: model.tenantId, displayName: model.displayName,
                                      type: model.type)
            return address
        }
        return nil
    }

    func converCellViewModelToAddress(_ model: MailAddressCellViewModel) -> MailAddress {
        let address = MailAddress(name: model.name,
                                  address: model.address,
                                  larkID: model.larkID,
                                  tenantId: model.tenantId, displayName: model.displayName,
                                  type: model.type)
        return address
    }
    mutating func updateAddresModels(model: MailAddressCellViewModel) {
        for (index, send) in sendToArray.enumerated() where send.address == model.address &&
        send.name != model.name {
            sendToArray[index] = model
        }
        for (index, cc) in ccToArray.enumerated() where cc.address == model.address &&
        cc.name != model.name {
            ccToArray[index] = model
        }
        for (index, bcc) in bccToArray.enumerated() where bcc.address == model.address &&
        bcc.name != model.name {
            bccToArray[index] = model
        }
    }
}
