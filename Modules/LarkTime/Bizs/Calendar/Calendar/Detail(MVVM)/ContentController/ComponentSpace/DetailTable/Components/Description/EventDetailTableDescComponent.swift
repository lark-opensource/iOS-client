//
//  EventDetailTableDescComponent.swift
//  Calendar
//
//  Created by Rico on 2021/4/7.
//

import UIKit
import LarkContainer
import EENavigator
import LarkUIKit
import RxSwift
import CalendarFoundation

final class EventDetailTableDescComponent: UserContainerComponent {

    @ScopedInjectedLazy
    var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy
    var docsDispatherSerivce: DocsDispatherSerivce?

    let viewModel: EventDetailTableDescViewModel
    let disposeBag = DisposeBag()
    let throttler = Throttler(delay: 0.5)

    init(viewModel: EventDetailTableDescViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let descView = self.descView else {
            EventDetail.logError("Cannot load descView because no dependency in user container!")
            return
        }

        view.addSubview(descView)
        descView.snp.edgesEqualToSuperView()

        bindViewModel()
        bindView()
    }

    override func viewDidLayoutSubviews() {
        descView?.updateMaxWidth(view.frame.width)
    }

    private func bindViewModel() {
        viewModel.rxViewData
            .subscribeForUI(onNext: { [weak self] viewData in
            guard let self = self,
                  let viewData = viewData else { return }
            self.descView?.updateContent(viewData)
        }).disposed(by: disposeBag)
    }

    private func bindView() {

        descView?.openUrl = { [weak self] url, docInfo in
            guard let self = self,
                  let viewController = self.viewController else { return }
            // html类型的超链接和bridge中的openurl会一起发送，避免跳转两次的情况，加了拦截兜底
            self.throttler.call {
                self.userResolver.navigator.push(url, context: ["from": "calendar"], from: viewController)
            }
            let encryptToken = (docInfo?["token"] as? String).map(DocUtils.encryptDocInfo)
            CalendarTracerV2.EventDetail.traceClick {
                $0.click("click_doc")
                $0.event_type = self.viewModel.rxModel.value.isWebinar ? "webinar" : "normal"
                if let encryptToken = encryptToken { $0.token = encryptToken }
                $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.viewModel.rxModel.value.instance, event: self.viewModel.rxModel.value.event))
            }
        }
        descView?.openSelectTranslateHandler = {[weak self] selectString in
            guard let self = self,
                  let viewController = self.viewController else { return }
            self.descView?.endEditing(true)
            self.calendarDependency?.jumpToSelectTranslateController(selectString: selectString, fromVC: viewController)
        }
    }

    private lazy var descView: DetailDescCell? = {
        guard let docsViewHolder = docsDispatherSerivce?.sell() else { return nil }
        let descView = DetailDescCell(docsViewHolder: docsViewHolder)
        return descView
    }()
}
