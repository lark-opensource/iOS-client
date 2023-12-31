//
//  MsgThreadDetailPreviewContainerViewController.swift
//  LarkThread
//
//  Created by ByteDance on 2023/1/6.
//

import Foundation
import LarkUIKit
import LarkModel
import UniverseDesignToast
import EENavigator
import LarkMessageCore
import LKCommonsLogging
import LarkSDKInterface
import LarkSplitViewController
import LarkFeatureGating
import LarkSuspendable
import LarkContainer
import UIKit

final class MsgThreadDetailPreviewContainerViewController: BaseUIViewController {

    init(
        viewModel: MsgThreadDetailPreviewContainerViewModel,
        intermediateStateControl: InitialDataAndViewControl<ReplyInThreadDetailBlockData, Void>,
        getDetailController: @escaping ReplyInThreadGetDetailController
    ) {
        self.viewModel = viewModel
        self.intermediateStateControl = intermediateStateControl
        self.getDetailController = getDetailController
        super.init(nibName: nil, bundle: nil)
        self.startIntermediateStateControl()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        self.supportSecondaryOnly = true
        self.supportSecondaryPanGesture = true
        self.keyCommandToFullScreen = true
        super.viewDidLoad()
        self.isNavigationBarHidden = true
        self.intermediateStateControl.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLeftNavigationItems()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateLeftNavigationItems()
    }

    // MARK: 全屏按钮
    override func splitSplitModeChange(splitMode: SplitViewController.SplitMode) {
        self.updateLeftNavigationItems()
    }

    private func updateLeftNavigationItems() {
        guard Display.pad else {
            return
        }
        self.fullScreenIcon.removeFromSuperview()
        guard let statusView = self.statusView, let btn = statusView.backBtn else {
            return
        }
        let controller = self
        /// 在 iPad 分屏场景中
        if let split = self.larkSplitViewController {
            if let navigation = controller.navigationController,
               navigation.realViewControllers.first != controller {
                btn.isHidden = false
            } else {
                btn.isHidden = true
            }
            if !split.isCollapsed, btn.isHidden {
                statusView.addSubview(fullScreenIcon)
                fullScreenIcon.snp.remakeConstraints { make in
                    make.left.right.top.bottom.equalTo(btn)
                }
                fullScreenIcon.updateIcon()
            }
        } else {
        /// 在 iPad 非左右分屏场景
            if let navigation = self.navigationController {
                btn.isHidden = false
            }
        }
    }

    private static let logger = Logger.log(MsgThreadDetailPreviewContainerViewController.self, category: "LarkThread")
    private let viewModel: MsgThreadDetailPreviewContainerViewModel
    private let getDetailController: ReplyInThreadGetDetailController
    private let intermediateStateControl: InitialDataAndViewControl<ReplyInThreadDetailBlockData, Void>
    private var loadingView: ReplyThreadIntermediateView?
    private var errorView: ReplyThreadErrorView?
    private lazy var fullScreenIcon: SecondaryOnlyButton = SecondaryOnlyButton(vc: self)

    private var statusView: ThreadAbnormalStatusView? {
        return self.errorView ?? self.loadingView
    }

    private func startIntermediateStateControl() {
        self.intermediateStateControl.start { [weak self] (result) in
            switch result {
            case .success(let status):
                Self.logger.info("ProcessStatus is \(status)")
                switch status {
                case .blockDataFetched(data: let data):
                    self?.viewModel.ready(threadMessage: data.0, chat: data.1)
                case .inNormalStatus:
                    guard let chat = self?.viewModel.chat,
                        let threadMessage = self?.viewModel.threadMessage else {
                            Self.logger.error("block data is empty error \(self?.viewModel.threadID ?? "")")
                            return
                    }

                    if threadMessage.isNoTraceDeleted {
                        Self.logger.error("threadMessage isNoTraceDeleted")
                        self?.showLoadingView()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.setupEmptyView(text: BundleI18n.LarkThread.Lark_IM_ForwardPreviewTopicRecalled_Empty)
                        }
                        Self.logger.error("topic had deleted \(self?.viewModel.threadID ?? "")")
                        return
                    }
                    self?.setupUI(with: threadMessage, chat: chat)
                    self?.hideLoadingView()
                case .inInstantStatus:
                    self?.showLoadingView()
                }
            case .failure(let error):
                if let error = error.underlyingError as? APIError {
                    switch error.type {
                    case .noPullMessagePermission(_):
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.setupEmptyView(text: BundleI18n.LarkThread.Lark_IM_ForwardPreviewGroupDisbanded_Empty)
                        }
                    default:
                        self?.showErrorView()
                    }
                } else {
                    self?.showErrorView()
                }
                Self.logger.error("fetch thread error \(self?.viewModel.threadID ?? "")", error: error)
            }
        }
    }

    private func getEmptyView(text: String) -> UIView {
        let view = UIView()
        let textLabel = UILabel()
        view.addSubview(textLabel)
        textLabel.textColor = UIColor.ud.textPlaceholder
        textLabel.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        textLabel.text = text
        textLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        return view
    }

    private func setupEmptyView(text: String) {
        let emptyView = self.getEmptyView(text: text)
        self.isNavigationBarHidden = false
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.hideLoadingView()
        self.view.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func showErrorView() {
        DispatchQueue.main.async {
            self.loadingView?.removeFromSuperview()
            let errorView = ReplyThreadErrorView( backButtonClickedBlock: { [weak self] in
                guard let `self` = self else {
                    return
                }
                self.dismiss(animated: true)
            })
            self.view.addSubview(errorView)
            errorView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            self.errorView = errorView
            self.updateLeftNavigationItems()
        }
    }

    private func setupUI(with threadMessage: ThreadMessage, chat: Chat) {
        guard let detailVC = try? self.getDetailController(self, threadMessage, chat) else { return }
        self.addChild(detailVC)
        self.view.addSubview(detailVC.view)
        detailVC.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Helper
    private func hideLoadingView() {
        self.loadingView?.stopLoading()
        self.loadingView?.removeFromSuperview()
        self.loadingView = nil
    }

    private func showLoadingView() {
        /// 如果error较早返回，就不需要展示loading了
        if self.errorView != nil {
            return
        }
        if self.loadingView != nil {
            return
        }
        let loadingView = ReplyThreadIntermediateView(backButtonClickedBlock: { [weak self] in
               guard let `self` = self else {
                   assertionFailure("miss From VC")
                   return
               }
               self.viewModel.navigator.pop(from: self)
        })
        self.view.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        loadingView.startLoading()
        self.loadingView = loadingView
        updateLeftNavigationItems()
    }
}
