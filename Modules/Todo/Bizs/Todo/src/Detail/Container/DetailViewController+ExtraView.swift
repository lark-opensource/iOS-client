//
//  DetailViewController+ExtraView.swift
//  Todo
//
//  Created by wangwanxin on 2021/12/27.
//

import UniverseDesignEmpty
import LarkUIKit
import RxCocoa
import RxSwift
import UniverseDesignFont

/// Detail - View State

extension DetailViewController {

    // MARK: - View State

    func bindViewState() {
        viewModel.rxViewState
            .subscribe(onNext: { [weak self] viewState in
                self?.doUpdateViewState(viewState)
                // 耗时加载埋点
                if case .succeed = viewState,
                    let task = self?.loadDetailTrackerTask {
                    task.complete()
                    self?.loadDetailTrackerTask = nil
                }
            })
            .disposed(by: disposeBag)
    }

    private func doUpdateViewState(_ viewState: DetailViewModel.ViewState) {
        switch viewState {
        case .loading(let showLoading):
            guard showLoading else { return }
            setupLoadingView()
            loadingView?.isHidden = false
            view.bringSubviewToFront(loadingView ?? UIView())
        case .succeed:
            loadingView?.removeFromSuperview()
            failedView?.removeFromSuperview()
        case .failed(let failure):
            setupFailedView(with: failure)
            failedView?.isHidden = false
            view.bringSubviewToFront(failedView ?? UIView())
        case .idle:
            break
        }
    }

    private func setupLoadingView() {
        guard loadingView == nil else { return }
        let loadingView = LoadingPlaceholderView()
        loadingView.isHidden = true
        loadingView.backgroundColor = UIColor.ud.bgBody
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }
        self.loadingView = loadingView
    }

    private func setupFailedView(with failure: ViewStateFailure) {
        failedView?.removeFromSuperview()
        var (tip, type): (String?, UDEmptyType?)
        var clickHandler: (() -> Void)?
        switch failure {
        case .noAuth:
            tip = I18N.Todo_ShareTasks_NoPermissionsToViewTask_EmptyState
            type = .noAccess
        case .deleted:
            tip = I18N.Todo_Task_BotMsgTaskDeleted
            type = .loadingFailure
        case .needsRetry:
            tip = I18N.Lark_Legacy_LoadFailedRetryTip
            type = .loadingFailure
            clickHandler = { [weak self] in self?.viewModel.retryFromFail() }
        case .none: break
        }
        guard let tip = tip, let type = type else {
            return
        }
        let desc = UDEmptyConfig.Description(
            descriptionText: AttrText(
                string: tip,
                attributes: [
                    .font: UDFont.systemFont(ofSize: 14, weight: .regular),
                    .foregroundColor: UIColor.ud.textCaption
                ]
            )
        )
        let newFailedView = UDEmptyView(config: UDEmptyConfig(description: desc, type: type))
        newFailedView.clickHandler = clickHandler
        newFailedView.backgroundColor = UIColor.ud.bgBody
        newFailedView.useCenterConstraints = true
        newFailedView.isHidden = true
        view.addSubview(newFailedView)
        newFailedView.snp.makeConstraints { $0.edges.equalToSuperview() }
        self.failedView = newFailedView
    }

}

/// Detail - Create View

extension DetailViewController {

    // MARK: - Create View

    func initBottomCreateView() -> DetailBottomCreateView {
        guard !Display.pad, case .create = context.scene else {
            assertionFailure()
            return DetailBottomCreateView(
                hasSendToChatCheckbox: false,
                isSendToChatCheckboxSelected: false
            )
        }

        return DetailBottomCreateView(
            hasSendToChatCheckbox: context.scene.isShowSendToChat,
            isSendToChatCheckboxSelected: todoService?.getSendToChatIsSeleted() ?? true
        )
    }

    func setupBottomCreate() {
        guard viewModel.hasBottomCrateView() else { return }
        let height = viewModel.createViewHeight
        view.addSubview(bottomCreateView)
        bottomCreateView.frame = CGRect(
            x: 0,
            y: view.frame.height - view.safeAreaInsets.bottom - height,
            width: view.frame.width,
            height: view.safeAreaInsets.bottom + height
        )
        bottomCreateView.onClick = { [weak self] in
            self?.handleCreateItemClick()
        }
        bottomCreateView.sendToChatView.onToggleCheckbox = { [weak self] isSelected in
            self?.todoService?.setSendToChatIsSeleted(isSeleted: isSelected)
        }
        viewModel.rxBottomCreate.bind(to: bottomCreateView).disposed(by: disposeBag)
        context.rxKeyboardHeight.observeOn(MainScheduler.asyncInstance)
            .skip(1)
            .subscribe(onNext: { [weak self] bottomInset in
                self?.handleBottomCreateFrame(bottomInset)
            }).disposed(by: disposeBag)
    }

    private func handleBottomCreateFrame(_ bottomInset: CGFloat) {
        guard let options = context.keyboard.options, (options.isShow != isCreateShown || bottomInset != lastBottomInset) else {
            return
        }
        lastBottomInset = bottomInset
        isCreateShown = options.isShow
        let height = viewModel.createViewHeight
        // 使用frame是为了做动画，snpKit会使得整个view都有动画
        let animations = { [weak self] in
            guard let self = self else { return }
            if options.isShow {
                self.bottomCreateView.frame = CGRect(
                    x: 0,
                    y: self.view.frame.height - bottomInset,
                    width: self.view.frame.width,
                    height: 44
                )
            } else {
                self.bottomCreateView.frame = CGRect(
                    x: 0,
                    y: self.view.frame.height - self.view.safeAreaInsets.bottom - height,
                    width: self.view.frame.width,
                    height: self.view.safeAreaInsets.bottom + height
                )
            }
        }
        UIView.animate(
            withDuration: options.animationDuration,
            delay: 0,
            options: [.beginFromCurrentState, .layoutSubviews],
            animations: {
                UIView.setAnimationCurve(options.animationCurve)
                animations()
            },
            completion: nil)
    }

}
