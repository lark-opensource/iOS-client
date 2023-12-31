//
//  MailSearchResultFactory.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/8.
//

import UIKit
import RustPB

protocol MailSearchTableViewCellProtocol: UITableViewCell {
    var vm: MailSearchCellViewModel? { get }

    func set(viewModel: MailSearchCellViewModel,
             searchText: String?)

    static func cellHeight(viewModel: MailSearchCellViewModel) -> CGFloat
}

protocol MailSearchCellViewModel {
    var threadId: String { get }
    var messageId: String { get set }
    var from: String { get }
    var msgSummary: String { get set }
    var subject: String { get }
    var createTimestamp: Int64 { get }
    var lastMessageTimestamp: Int64 { get }
    var highlightString: [String] { get }
    var highlightSubject: [String] { get }
    var isRead: Bool { get set }
    var hasDraft: Bool { get set }
    var hasAttachment: Bool { get }
    var msgNum: Int { get set }
    var messageIds: [String] { get }
    var labels: [MailClientLabel] { get set }
    var fullLabels: [String] { get set }
    var actions: [ActionType] { get }
    var isFlagged: Bool { get set }
    var isExternal: Bool { get set }
    var senderAddresses: [String] { get set }
    var folders: [String] { get set }
    var headFroms: [String] { get set }
    var unauthorizedHeadFroms: [String] { get set }
    var addressList: [Email_Client_V1_Address] { get set }
}

extension MailSearchCellViewModel {
    func labelItems() -> String {
        var labelAndFolderIDs: Set<String> = []
        for tag in labels {
            if tag.tagType == .label {
                labelAndFolderIDs.insert("LABEL")
            } else {
                labelAndFolderIDs.insert("FOLDER")
            }
        }
        var fullLabelIDs = fullLabels.filter({ systemLabels.contains($0) || MailFilterLabelCellModel.restrictedLabels.contains($0) })
        var labelItemString = "["
        for (index, label) in (fullLabelIDs + Array(labelAndFolderIDs)).enumerated() {
            var sep = ""
            if index != 0 {
                sep = ", "
            }
            labelItemString = labelItemString + sep + label
        }
        return labelItemString + "]"
    }
}

// 用来管理搜索内的卡片类型
class MailSearchResultFactory {
    typealias MailSearchResultConfigItem = (String, MailSearchTableViewCellProtocol.Type)

    let mailSearchResultId = "mailSearchResultId"

    func createResultItems() -> [MailSearchResultConfigItem] {
        return [(mailSearchResultId, MailSearchResultCell.self)]
    }

    func cellIdentify(searchBack: MailSearchCallBack) -> String {
        return mailSearchResultId
    }

    func cellType(from: MailSearchCallBack) -> MailSearchTableViewCellProtocol.Type {
        return MailSearchResultCell.self
    }

    func createCellModel(from: MailSearchCallBack) -> MailSearchCellViewModel? {
        // TODO: 这里要重新设计?
        var vm = from.viewModel
        var filteredLabels = MailTagDataManager.shared.getTagModels(vm.fullLabels).filter({ $0.modelType == .label })
        filteredLabels = filteredLabels.map({ label in
            var newLabel = label
            let config = MailLabelTransformer.transformLabelColor(backgroundColor: label.bgColor)
            newLabel.fontColor = config.fontToHex(alwaysLight: false)
            newLabel.bgColor = config.bgToHex(alwaysLight: false)
            newLabel.colorType = config.colorType
            return newLabel
        })
        vm.labels = filteredLabels
        return vm
    }
}
