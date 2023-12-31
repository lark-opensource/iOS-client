//
//  MailTagDataManager.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/8/31.
//

import Foundation
import RxSwift
import RxRelay
import ThreadSafeDataStructure

class MailTagDataManager {
    static var shared = MailTagDataManager()
    private let disposeBag = DisposeBag()
    private(set) var tagDic = SafeDictionary<String, MailClientLabel>() + .readWriteLock

    func updateTags(_ tags: [MailClientLabel]) {
        for tag in tags {
            self.tagDic.value.updateValue(tag, forKey: tag.id)
        }
    }

    func getTag(_ tagId: String) -> MailClientLabel? {
        return tagDic.value[tagId]
    }

    func getTagModels(_ tagIds: [String]) -> [MailClientLabel] {
        var models: [MailClientLabel] = []
        for tagId in tagIds {
            if let tagModel = tagDic.value[tagId] {
                models.append(tagModel)
            } else {
                MailLogger.info("[mail_applink_delete] Failed to getTagModels by labelId \(tagId)")
            }
        }
        return models
    }

    func getFolderModel(_ folderIDs: [String]) -> MailClientLabel? {
        let allTagIDs = tagDic.value.keys
        if FeatureManager.open(.searchTrashSpam, openInMailClient: true),
            let firstMatchFolderID = folderIDs.first(where: { [Mail_LabelId_Trash, Mail_LabelId_Spam].contains($0) }) {
            return tagDic.value[firstMatchFolderID]
        } else if folderIDs.contains(Mail_LabelId_Archived) {
            return tagDic.value[Mail_LabelId_Archived]
        } else if folderIDs.contains(Mail_LabelId_Sent) {
            return tagDic.value[Mail_LabelId_Sent]
        } else if folderIDs.contains(Mail_LabelId_Inbox) ||
                    folderIDs.contains(Mail_LabelId_Important) || folderIDs.contains(Mail_LabelId_Other) {
            if Store.settingData.getCachedCurrentSetting()?.smartInboxMode ?? false && !Store.settingData.mailClient {
                if folderIDs.contains(Mail_LabelId_Important) {
                    return tagDic.value[Mail_LabelId_Important]
                } else {
                    return tagDic.value[Mail_LabelId_Other]
                }
            } else {
                return tagDic.value[Mail_LabelId_Inbox]
            }
        } else if folderIDs.contains(Mail_LabelId_Inbox) {
            return tagDic.value[Mail_LabelId_Inbox]
        } else {
            if let customFolderID = folderIDs.first {
                return tagDic.value[customFolderID]
            } else {
                return nil
            }
        }
    }

    func updateCacheByLabelPropertyChange(_ change: MailLabelPropertyChange) {
        if change.isDelete {
            self.tagDic.value.removeValue(forKey: change.label.id)
        } else {
            self.tagDic.value.updateValue(change.label, forKey: change.label.id)
        }
    }

    func clear() {
        self.tagDic.value.removeAll()
    }

    init() {
        addObserver()
    }

    func addObserver() {
        PushDispatcher
            .shared
            .mailChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                switch push {
                case .updateLabelsChange(let change):
                    self?.mailLabelChange(change.labels)
                case .labelPropertyChange(let change):
                    self?.labelPropertyChange(change)
                default:
                    break
                }
        }).disposed(by: disposeBag)
    }

    private func mailLabelChange(_ labels: [MailClientLabel]) {
        //self.tags = labels.map({ MailFilterLabelCellModel(pbModel: $0) })
        //self.tags = labels
        MailLogger.info("[mail_tag_opt] mailLabelChange: \(labels.count)")
        updateTags(labels.sorted(by: { $0.userOrderedIndex < $1.userOrderedIndex }))
    }

    func labelPropertyChange(_ change: MailLabelPropertyChange) {
        MailTagDataManager.shared.updateCacheByLabelPropertyChange(change)
    }
}
