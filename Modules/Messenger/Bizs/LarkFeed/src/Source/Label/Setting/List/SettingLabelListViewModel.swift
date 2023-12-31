//
//  SettingListViewModel.swift
//  LarkFeed
//
//  Created by aslan on 2022/4/20.
//

import Foundation
import LarkSDKInterface
import EENavigator
import Swinject
import LarkModel
import LarkContainer
import RxSwift
import RustPB
import LKCommonsLogging

public final class SettingLabelListViewModel: UserResolverWrapper {
    public let userResolver: UserResolver
    var title: String = BundleI18n.LarkFeed.Lark_Core_LabelTab_Title

    var errorTip: String = BundleI18n.LarkFeed.Lark_Core_Label_ActionFailed_Toast

    var rightItemTitle: String = BundleI18n.LarkFeed.Lark_Core_AddLabels_ConfirmButton

    func rightItemClick() {
        self.updateSelectLabel()
    }

    static let logger = Logger.log(SettingLabelListViewModel.self, category: "SettingLabel")

    let pushLabels: Observable<PushLabel>
    private let labelListAPI: FeedAPI
    public let entityId: Int64
    public var selectLabels: Set<Int64> = []
    public var originalSelectLabels: Set<Int64> = []

    private let disposeBag = DisposeBag()
    private let datasourceSubject: BehaviorSubject<[FeedLabelPreview]> = BehaviorSubject<[FeedLabelPreview]>(value: [])

    private let selectSubject: PublishSubject<Bool> = PublishSubject<Bool>()
    var selectObservable: Observable<Bool> {
        return selectSubject.asObserver()
    }

    var datasource: [FeedLabelPreview] = [] {
        didSet {
            self.datasourceSubject.onNext(datasource)
        }
    }

    var datasourceObservable: Observable<[FeedLabelPreview]> {
        return datasourceSubject.asObservable()
    }

    private let updateSubject: PublishSubject<(Int, Error?)> = PublishSubject<(Int, Error?)>()
    var resultObservable: Observable<(Int, Error?)> {
        return updateSubject.asObservable()
    }

    init(resolver: UserResolver,
         labelListAPI: FeedAPI,
         entityId: Int64,
         labelIds: [Int64],
         pushLabels: Observable<PushLabel>) {
        self.userResolver = resolver
        self.labelListAPI = labelListAPI
        self.entityId = entityId
        self.pushLabels = pushLabels
        labelIds.forEach { id in
            self.selectLabels.insert(id)
        }
        /// 记录下原始选择，请求接口需要用到
        self.originalSelectLabels = self.selectLabels
    }

    func checkIsSelected(labelId: Int64) -> Bool {
        return self.selectLabels.contains(labelId)
    }

    func updateLabelSelect(labelId: Int64) {
        if checkIsSelected(labelId: labelId) {
            self.selectLabels.remove(labelId)
        } else {
            self.selectLabels.insert(labelId)
        }
        let hasChange = !self.selectLabels.elementsEqual(self.originalSelectLabels)
        self.selectSubject.onNext(hasChange)
    }

    func fetchLabelList() {
        Self.logger.info("SettingLabelList start fetch")
        labelListAPI.getAllLabels(
            pageCount: LabelConfig.loadMoreLabelCount,
            maxTimes: LabelConfig.loadMoreLabelMaxTimes)
        .subscribe(onNext: { [weak self] items in
            guard let self = self else { return }
            self.datasource = items
            Self.logger.info("label list fetch success!", additionalData: [
                "label list count": "\(self.datasource.count)"
            ])
        }, onError: { [weak self] error in
            guard let self = self else { return }
            self.datasourceSubject.onError(error)
            Self.logger.error("label list fetch failed!", error: error)
        }).disposed(by: disposeBag)
    }

    func updateSelectLabel() {
        Self.logger.info("SettingLabelList start update")
        var diffAdd = self.selectLabels.subtracting(self.originalSelectLabels).map { labelId in
            return labelId
        }
        var diffDel = self.originalSelectLabels.subtracting(self.selectLabels).map { labelId in
            return labelId
        }
        Self.logger.info("SettingLabelList update diff add:\(diffAdd)")
        Self.logger.info("SettingLabelList update diff del:\(diffDel)")
        self.labelListAPI.updateLabel(feedId: self.entityId, updateLabels: diffAdd, deleteLabels: diffDel)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let diffCount = self.originalSelectLabels.count - self.selectLabels.count
                self.updateSubject.onNext((diffCount, nil))
                var changeType = "same"
                if diffCount > 0 {
                    changeType = "remove"
                } else if diffCount < 0 {
                    changeType = "add"
                }
                FeedTeaTrack.selectLabelConfirmClick(changType: changeType)
            }, onError: { [weak self] error in
                self?.updateSubject.onNext((0, error))
                Self.logger.info("SettingLabelList update error:\(error.localizedDescription)")
            })
    }
}
