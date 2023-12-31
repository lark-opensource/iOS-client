//
//  CreateLabelViewModel.swift
//  LarkFeed
//
//  Created by aslan on 2022/4/18.
//

import Foundation
import LarkSDKInterface
import LarkOpenFeed
import RxSwift
import LarkContainer
import LKCommonsLogging

public final class CreateLabelViewModel: SettingLabelViewModel {
    var textFieldText: String

    var needShowResultToast: Bool = true

    var title: String = BundleI18n.LarkFeed.Lark_Core_CreateLabel_Button_Mobile

    var errorTip: String = BundleI18n.LarkFeed.Lark_Feed_Label_CreateLabel_FailToast

    var rightItemTitle: String = BundleI18n.LarkFeed.Lark_Core_CreateLabel_Create_Button

    weak var targetVC: SettingLabelViewController?
    var entityId: Int64?
    var successCallback: ((Int64) -> Void)?
    private var sending = false

    private(set) var disposeBag = DisposeBag()

    private let feedAPI: FeedAPI
    private let guideService: FeedThreeColumnsGuideService

    private let createSubject: PublishSubject<(String?, Error?)> = PublishSubject<(String?, Error?)>()
    var resultObservable: Observable<(String?, Error?)> {
        return createSubject.asObservable()
    }

    func rightItemClick(label: String) {
        self.createLabel(label: label)
    }

    func viewDidLoad() {
        /// do nothing
    }

    func leftItemClick() {
        /// do nothing
    }

    public init(resolver: UserResolver, entityId: Int64?, successCallback: ((Int64) -> Void)?) throws {
        self.feedAPI = try resolver.resolve(assert: FeedAPI.self)
        self.guideService = try resolver.resolve(assert: FeedThreeColumnsGuideService.self)

        self.entityId = entityId
        self.successCallback = successCallback
        self.textFieldText = ""
    }

    private func createLabel(label: String) {
        guard !self.sending else {
            FeedContext.log.info("feedlog/label/createLabel. repeat request")
            return
        }
        self.sending = true
        FeedContext.log.info("feedlog/label/createLabel. entity id:\(self.entityId)")
        feedAPI.createLabel(labelName: label, feedId: self.entityId)
            .subscribe(onNext: { [weak self] (result: CreateLabelResponse) in
                guard let `self` = self else { return }
                self.createSubject.onNext((result.feedGroup.name, nil))
                self.successCallback?(result.feedGroup.id)
                FeedTeaTrack.creatLabelConfirmClick(labelId: result.feedGroup.id)
                FeedContext.log.info("feedlog/label/createLabel. success: \(result.feedGroup.name)")
                // 触发汉堡菜单引导条件 - 创建标签
                self.guideService.triggerThreeColumnsGuide(scene: .createTag)
                self.sending = false
            }, onError: { [weak self] error in
                guard let `self` = self else { return }
                self.createSubject.onNext((nil, error))
                FeedContext.log.info("feedlog/label/createLabel. error: \(error.localizedDescription)")
                self.sending = false
            }).disposed(by: disposeBag)
    }
}
