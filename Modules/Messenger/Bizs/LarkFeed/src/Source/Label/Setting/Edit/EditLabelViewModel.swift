//
//  EditLabelViewModel.swift
//  LarkFeed
//
//  Created by aslan on 2022/4/18.
//

import Foundation
import LarkSDKInterface
import RxSwift
import LarkContainer
import LKCommonsLogging

public final class EditLabelViewModel: SettingLabelViewModel {
    var textFieldText: String

    var errorTip: String = BundleI18n.LarkFeed.Lark_Feed_Label_FailedToEditLabel_Toast

    var needShowResultToast: Bool = false

    var title: String = BundleI18n.LarkFeed.Lark_Core_EditLabel_Button

    var rightItemTitle: String = BundleI18n.LarkFeed.Lark_Feed_Label_EditLabel_Save_Button

    private(set) var disposeBag = DisposeBag()

    weak var targetVC: SettingLabelViewController?
    var labelId: Int64
    var labelName: String

    private static let logger = Logger.log(
        EditLabelViewModel.self,
        category: "LarkFeed.EditLabelViewModel")

    let feedAPI: FeedAPI

    private let editSubject: PublishSubject<(String?, Error?)> = PublishSubject<(String?, Error?)>()
    var resultObservable: Observable<(String?, Error?)> {
        return editSubject.asObservable()
    }

    func rightItemClick(label: String) {
        self.editLabel(label: label)
        FeedTeaTrack.editLabelConfirmClick(labelId: self.labelId, isChanged: label != self.labelName)
    }

    func viewDidLoad() {
        FeedTeaTrack.editLabelView(labelId: self.labelId)
    }

    /// 取消点击
    func leftItemClick() {
        FeedTeaTrack.editLabelCancelClick(labelId: self.labelId)
    }

    public init(resolver: UserResolver, labelId: Int64, labelName: String) throws {
        self.feedAPI = try resolver.resolve(assert: FeedAPI.self)
        self.labelId = labelId
        self.labelName = labelName
        self.textFieldText = labelName
    }

    private func editLabel(label: String) {
        Self.logger.info("edit label request: \(label), label id:\(labelId)")
        feedAPI.updateLabelInfo(id: labelId, name: label)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_: UpdateLabelResponse) in
                guard let `self` = self else { return }
                /// 编辑结果不需要弹提示，且sdk返回里亦无字段
                self.editSubject.onNext((nil, nil))
                Self.logger.info("edit label success: \(label)")
            }, onError: { [weak self] error in
                guard let `self` = self else { return }
                self.editSubject.onNext((nil, error))
                Self.logger.info("edit label error: \(error.localizedDescription)")
            }).disposed(by: disposeBag)
    }
}
