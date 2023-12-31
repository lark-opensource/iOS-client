//
//  DetailPreviewContainerController.swift
//  LarkThread
//
//  Created by ByteDance on 2023/1/3.
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
import LarkSuspendable
import LarkContainer
import LarkMessengerInterface
import UIKit

final class DetailPreviewContainerController: BaseUIViewController {
    var pushInfo: ThreadDetailPushInfo?
    var sourceID: String = UUID().uuidString

    init(
        viewModel: DetailPreviewContainerViewModel,
        intermediateStateControl: InitialDataAndViewControl<DetailBlockData, Void>,
        getDetailController: @escaping GetDetailController
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
        self.fullScreenSceneBlock = { "channel" }
        super.viewDidLoad()
        self.addCloseItem()
        self.isNavigationBarHidden = true
        self.intermediateStateControl.viewDidLoad()
    }

    private static let logger = Logger.log(DetailPreviewContainerController.self, category: "LarkThread")
    private let viewModel: DetailPreviewContainerViewModel
    private let getDetailController: GetDetailController
    private let intermediateStateControl: InitialDataAndViewControl<DetailBlockData, Void>
    private var loadingView: DetailIntermediateView?

    private func startIntermediateStateControl() {
        self.intermediateStateControl.start { [weak self] (result) in
            switch result {
            case .success(let status):
                DetailPreviewContainerController.logger.info("ProcessStatus is \(status)")
                switch status {
                case .blockDataFetched(data: let data):
                    self?.viewModel.ready(threadMessage: data.0, chat: data.1, topicGroup: data.2)
                case .inNormalStatus:
                    guard let chat = self?.viewModel.chat,
                        let threadMessage = self?.viewModel.threadMessage,
                        let topicGroup = self?.viewModel.topicGroup else {
                            DetailPreviewContainerController.logger.error("block data is empty error \(self?.viewModel.threadID ?? "")")
                            return
                    }

                    if threadMessage.isNoTraceDeleted || !threadMessage.isVisible || threadMessage.position <= chat.firstMessagePostion {
                        self?.showLoadingView()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.setupEmptyView(text: BundleI18n.LarkThread.Lark_IM_ForwardPreviewTopicRecalled_Empty)
                        }
                        DetailPreviewContainerController.logger.error("topic had deleted \(self?.viewModel.threadID ?? "")")
                        return
                    }
                    self?.setupUI(with: threadMessage, chat: chat, topicGroup: topicGroup)
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
                    default: break
                    }
                }
                DetailPreviewContainerController.logger.error("fetch thread error \(self?.viewModel.threadID ?? "")", error: error)
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

    private func setupUI(with threadMessage: ThreadMessage, chat: Chat, topicGroup: TopicGroup) {
        guard let detailVC = try? self.getDetailController(self, threadMessage, chat, topicGroup) else { return }
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
    }

    private func showLoadingView() {
        let loadingView = DetailIntermediateView(showKeyboard: true, backButtonClickedBlock: { [weak self] in
            guard let `self` = self else {
                assertionFailure("lack From VC")
                return
            }
            self.dismiss(animated: true)
        })
        self.view.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        loadingView.startLoading()
        self.loadingView = loadingView
    }
}
