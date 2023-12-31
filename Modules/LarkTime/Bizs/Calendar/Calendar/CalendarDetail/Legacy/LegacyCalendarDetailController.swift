//
//  CalendarDetailController.swift
//  Calendar
//
//  Created by zhuheng on 2021/5/28.
//

import UIKit
import UniverseDesignIcon
import Foundation
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkContainer
import EENavigator
import LarkTab
import UniverseDesignColor
import LarkTimeFormatUtils
import CTFoundation

final class LegacyCalendarDetailController: BaseUIViewController, UserResolverWrapper {
    @ScopedProvider var calendarHome: CalendarHome?

    let userResolver: UserResolver
    private let viewModel: LegacyCalendarDetailViewModel

    private lazy var loadingView = LoadingPlaceholderView()
    private lazy var loadingFailedView = LoadFaildRetryView()

    private lazy var detailView = LegacyCalendarDetailView()
    private lazy var noAccessView = NoAccessCalendarDetailView()

    private let disposeBag = DisposeBag()
    private let toast = UDToast()

    init(viewModel: LegacyCalendarDetailViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.Calendar.Calendar_Calendar_CalendarDetails

        view.backgroundColor = UIColor.ud.bgBody
        addBackItem()
        isNavigationBarHidden = false
        let closeBarButton: LKBarButtonItem

        closeBarButton = LKBarButtonItem(image: UDIcon.getIconByKeyNoLimitSize(.closeSmallOutlined).scaleNaviSize().renderColor(with: .n1))

        closeBarButton.button.addTarget(self,
                                        action: #selector(dismissSelf),
                                        for: .touchUpInside)
        navigationItem.leftBarButtonItem = closeBarButton

        let topLine = UIView()
        topLine.backgroundColor = UIColor.ud.lineDividerDefault
        view.addSubview(topLine)
        topLine.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        view.addSubview(loadingView)
        loadingView.isHidden = true
        loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.addSubview(loadingFailedView)
        loadingFailedView.isHidden = true
        loadingFailedView.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.addSubview(detailView)
        detailView.isHidden = true
        detailView.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.addSubview(noAccessView)
        noAccessView.isHidden = true
        noAccessView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.right.equalToSuperview().inset(16)
        }

        bindActions()
        bindViewData()

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadData()
    }

    private func bindActions() {
        loadingFailedView.retryAction = { [weak self] in
            self?.loadingView.isHidden = false
            self?.loadingFailedView.isHidden = true
            self?.viewModel.loadData()
        }

        detailView.buttonTapped = { [weak self] in
            guard let self = self,
                  let calendarID = self.viewModel.calendarID,
                  let calendarHome = self.calendarHome else { return }
            if self.viewModel.isSubscribed {
                self.navigationController?.dismiss(animated: true, completion: {
                    self.userResolver.navigator.switchTab(Tab.calendar.url, from: calendarHome, animated: true) {_ in
                        calendarHome.jumpToSlideView(calendarID: calendarID, source: nil)
                    }
                })
                CalendarTracer.shared.calDetailClick(calendarID: calendarID, clickType: "enter_cal_view")
            } else {
                CalendarTracer.shared.calDetailClick(calendarID: calendarID, clickType: "sub_cal")
                self.viewModel.doSubscribe()
            }
        }

    }

    private func bindViewData() {
        viewModel.rxDetailViewData.bind(to: detailView.rx.viewData).disposed(by: disposeBag)

        viewModel.rxStatus.bind { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .showDetail:
                self.loadingView.isHidden = true
                self.loadingFailedView.isHidden = true
                self.noAccessView.isHidden = true
                self.detailView.isHidden = false
            case .showLoading:
                self.loadingView.isHidden = false
                self.loadingFailedView.isHidden = true
                self.noAccessView.isHidden = true
                self.detailView.isHidden = true
            case .showRetry:
                self.loadingView.isHidden = true
                self.loadingFailedView.isHidden = false
                self.noAccessView.isHidden = true
                self.detailView.isHidden = true
            case .showNoAccess(let tip):
                self.loadingView.isHidden = true
                self.loadingFailedView.isHidden = true
                self.detailView.isHidden = true
                self.noAccessView.isHidden = false
                self.noAccessView.title.text = tip
            }
        }.disposed(by: disposeBag)

        viewModel.rxToast.bind { [weak self] toastType in
            guard let self = self else { return }
            switch toastType {
            case .error(let info):
                self.toast.remove()
                self.toast.showFailure(with: info, on: self.view)
            case .success(let info):
                self.toast.remove()
                self.toast.showSuccess(with: info, on: self.view)
            case .loading:
                self.toast.showLoading(with: I18n.Calendar_Common_LoadingCommon,
                                         on: self.view,
                                         disableUserInteraction: true)
            case .none:
                self.toast.remove()
            }
        }.disposed(by: disposeBag)
    }

    @objc
    private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
}
