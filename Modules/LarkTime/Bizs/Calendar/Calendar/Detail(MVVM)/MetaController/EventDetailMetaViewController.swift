//
//  EventDetailMetaViewController.swift
//  Calendar
//
//  Created by Rico on 2021/3/15.
//

import Foundation
import UIKit
import LarkUIKit
import LarkContainer
import CalendarFoundation
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignIcon
import RxSwift
import SnapKit

final class EventDetailMetaViewController: CalendarController {

    private let viewModel: EventDetailMetaViewModel
    private let bag = DisposeBag()
    private var titleLabel = {
        let label = UILabel()
        label.font = UIFont.ud.title3(.fixed)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        label.text = I18n.Calendar_Detail_EventDetail
        return label
    }()

    init(viewModel: EventDetailMetaViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        viewModel.startTrackLoadUI()
        ReciableTracer.shared.recStartEventDetail()
        viewModel.trackEventDetailLoadTime()
        super.viewDidLoad()
        isNavigationBarHidden = true

        layoutSelf()
        layoutNavigation()

        bindViewModel()
        bindView()
    }

    override public func viewWillTransition(to size: CGSize,
                                            with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.view.layoutSubviews()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.modalPresentationControl.readyToControlIfNeeded()
    }

    private func layoutSelf() {
        view.backgroundColor = UDColor.bgBase
        self.modalPresentationControl.dismissEnable = Display.pad
    }

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        .default
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let backButton = UIButton.cd.button(type: .custom)
    private var presentStyle: PresentStyle = .present
    private var loadingView: LoadingView?

}

// MARK: - Bind
extension EventDetailMetaViewController {
    private func bindViewModel() {

        viewModel.rxReplayMetaDataStatus
            .subscribeForUI(onNext: { [weak self] status in
                guard let self = self else { return }

                EventDetail.logInfo("meta data status changed: \(status.description)")

                // 错误情况、看不到日程
                if let (image, tips, canRetry) = status.errorInfo {
                    // 这里分两种情况
                    // 1. 首次加载即为错误，直接显示错误页面
                    // 2. 先加载本地日程显示，后请求服务端有错误情况，需要先清空已展示的内容
                    self.children.forEach {
                        $0.willMove(toParent: nil)
                        $0.view.removeFromSuperview()
                        $0.removeFromParent()
                    }
                    self.showFailedView(title: tips, image: image, canRetry: canRetry)
                    EventDetail.logWarn("show error view")
                    return
                }

                // 加载状态
                if status.shouldShowLoadingView {
                    self.showLoadingView()
                    EventDetail.logInfo("show loading view")
                    return
                }

                // 成功加载日程内容
                if case .metaDataLoaded = status {
                    self.hideLoadingView()
                    self.loadContentVC()
                    ReciableTracer.shared.recEndEventDetail()
                    EventDetail.logInfo("load content vc")
                    return
                }

            }).disposed(by: bag)

        viewModel.rxToastStatus.bind(to: rx.toast).disposed(by: bag)
    }

    private func bindView() {
        backButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.backButtonPressed()
            }).disposed(by: bag)
    }
}

// MARK: - Action
extension EventDetailMetaViewController {
    private func backButtonPressed() {
        switch presentStyle {
        case .push: navigationController?.popViewController(animated: true)
        case .present: (navigationController ?? self).dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - Private
extension EventDetailMetaViewController {

    private func showLoadingView() {
        loadingView?.remove()
        let newLoadingView = LoadingView(displayedView: view)
        view.sendSubviewToBack(newLoadingView)
        loadingView = newLoadingView
        loadingView?.showLoading()
    }

    private func showFailedView(title: String, image: UIImage?, canRetry: Bool) {
        titleLabel.isHidden = false
        let retryAction = { [weak self] in
            guard let self = self else { return }
            self.viewModel.action(.retryLoadEvent)
        }
        loadingView?.showFailed(title: title,
                                image: image ?? UIImage(),
                                withRetry: canRetry ? retryAction : nil)
    }

    private func hideLoadingView() {
        loadingView?.hideSelf()
        titleLabel.isHidden = true
    }

}

// MARK: - ContentVC
extension EventDetailMetaViewController {
    private func loadContentVC() {
        guard let contentViewModel = viewModel.buildContentViewModel() else {
            return
        }
        let contentViewController = EventDetailViewController(viewModel: contentViewModel)

        addChild(contentViewController)
        view.addSubview(contentViewController.view)
        contentViewController.view.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        contentViewController.didMove(toParent: self)
    }

}

// MARK: - Layout Navigation
extension EventDetailMetaViewController {

    enum PresentStyle {
        case present
        case push
    }

    private func layoutNavigation() {
        if let controllers = navigationController?.viewControllers,
           controllers.contains(self) && (controllers.count > 1) {
            presentStyle = .push
        }
        layoutBackButton()
        layoutTitleLabel()
        titleLabel.isHidden = true
    }

    private func layoutTitleLabel() {
        view.addSubview(titleLabel)

        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(32)
            make.centerY.equalTo(view.snp.top).offset(statusBarHeight + 22)
        }
    }

    private func layoutBackButton() {
        let image: UIImage
        if presentStyle == .present {
            image = UDIcon.getIconByKeyNoLimitSize(.closeSmallOutlined).scaleNaviSize().renderColor(with: .n1)
        } else {
            image = UDIcon.getIconByKeyNoLimitSize(.leftOutlined).scaleNaviSize().renderColor(with: .n1)
        }
        view.addSubview(backButton)
        backButton.setImage(image, for: .normal)
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        backButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(24).priority(.high)
            make.left.equalToSuperview().offset(16)
            make.centerY.equalTo(view.snp.top).offset(statusBarHeight + 22)
        }
    }

}

enum EventDetailMetaAction {
    case retryLoadEvent
}
