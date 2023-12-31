//
//  MyAIToolsSelectedViewController.swift
//  LarkIMMention
//
//  Created by ByteDance on 2023/5/24.
//  MyAITools 已选列表

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignColor
import UniverseDesignIcon
import LarkMessengerInterface
import LKCommonsLogging
import LarkModel
import UniverseDesignEmpty
import UniverseDesignToast
import LarkContainer
import LarkCore

final class MyAIToolsSelectedViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate, UserResolverWrapper {

    static let logger = Logger.log(MyAIToolsSelectedViewController.self, category: "Module.LarkAI.MyAITool")

    var userResolver: LarkContainer.UserResolver
    private var chat: Chat
    private var myAIPageService: MyAIPageService?
    public var toolItems: [MyAIToolInfo] = []
    public var toolIds: [String] = []
    public var aiChatModeId: Int64
    public var extra: [AnyHashable: Any]
    public var startNewTopicHandler: (() -> Void)?
    weak var fromVc: UIViewController?
    private var paneloffsetY: CGFloat = UIScreen.main.bounds.height

    private let disposeBag = DisposeBag()

    private lazy var viewModel: MyAIToolsSelectedViewModel = {
        let viewModel = toolIds.isEmpty ?
        MyAIToolsSelectedViewModel(toolItems: self.toolItems, aiChatModeId: self.aiChatModeId, userResolver: self.userResolver, myAIPageService: self.myAIPageService) :
        MyAIToolsSelectedViewModel(toolIds: toolIds, aiChatModeId: self.aiChatModeId, userResolver: self.userResolver, myAIPageService: self.myAIPageService)
        return viewModel
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = 68
        tableView.register(MyAIToolsSelectTableViewCell.self, forCellReuseIdentifier: "MyAIToolsSelectTableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.ud.bgBase
        return tableView
    }()

    private lazy var emptyDataView: UDEmptyView = {
        let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkAI.Lark_Legacy_PullEmptyResult)
        let emptyDataView = UDEmptyView(config: UDEmptyConfig(description: desc, type: .noApplication))
        emptyDataView.useCenterConstraints = true
        emptyDataView.isHidden = true
        return emptyDataView
    }()

    private lazy var footerView: MyAIToolselectedFooterView = MyAIToolselectedFooterView()

    init(toolItems: [MyAIToolInfo],
         userResolver: UserResolver,
         chat: Chat,
         aiChatModeId: Int64 = 0,
         myAIPageService: MyAIPageService? = nil,
         extra: [AnyHashable: Any] = [:]) {
        self.toolItems = toolItems
        self.userResolver = userResolver
        self.chat = chat
        self.aiChatModeId = aiChatModeId
        self.myAIPageService = myAIPageService
        self.extra = extra
        super.init(nibName: nil, bundle: nil)
    }

    init(toolIds: [String],
         userResolver: UserResolver,
         chat: Chat,
         aiChatModeId: Int64 = 0,
         myAIPageService: MyAIPageService? = nil,
         extra: [AnyHashable: Any] = [:]) {
        self.toolIds = toolIds
        self.userResolver = userResolver
        self.chat = chat
        self.aiChatModeId = aiChatModeId
        self.myAIPageService = myAIPageService
        self.extra = extra
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isNavigationBarHidden = true
        setupViews()
        bindAction()
        loadData()
        addExposureIMTracker()
    }

    private func addExposureIMTracker() {
        guard let myAIPageService = self.myAIPageService else {
            Self.logger.info("my ai add IMTracker, service is none")
            return
        }
        IMTracker.Chat.Main.Click.clickExtension(
            self.chat,
            params: viewModel.teaEventParams(extra: self.extra),
            myAIPageService.chatFromWhere)
        IMTracker.Chat.Main.viewExtension(
            self.chat,
            params: viewModel.teaEventParams(extra: self.extra),
            myAIPageService.chatFromWhere)
    }

    private func setupViews() {
        self.view.addSubview(tableView)
        self.view.addSubview(emptyDataView)
        tableView.tableFooterView = footerView
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(Cons.topMargin)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(Cons.leftMargin)
            make.right.equalToSuperview().inset(Cons.leftMargin).priority(.high)
        }
        emptyDataView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func loadData() {
        viewModel.loadToolsInfo()
    }

    private func bindAction() {
        footerView.startNewTopicHandler = { [weak self] in
            guard let self = self else { return }
            self.startNewTopicAction()
        }

        if self.traitCollection.horizontalSizeClass != .regular {
            let tableViewGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(pan:)))
            tableViewGesture.delegate = self
            tableView.addGestureRecognizer(tableViewGesture)
            let viewGesture = UIPanGestureRecognizer(target: self, action: #selector(handleContentViewPan(pan:)))
            self.view.addGestureRecognizer(viewGesture)
        }

        viewModel.status.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (status) in
            guard let self = self else { return }
            switch status {
            case .loading:
                self.loadingPlaceholderView.isHidden = false
            case .loadComplete:
                self.loadingPlaceholderView.isHidden = true
                self.tableView.reloadData()
            case .empty:
                self.loadingPlaceholderView.isHidden = true
                let emptyConfig = self.getUDEmptyConfig(.empty)
                self.emptyDataView.update(config: emptyConfig)
                self.addDataEmptyViewIfNeed()
            case .error(let error):
                self.loadingPlaceholderView.isHidden = true
                UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: self.view, error: error)
                let errorConfig = self.getUDEmptyConfig(.error(error))
                self.emptyDataView.update(config: errorConfig)
                self.addDataEmptyViewIfNeed()
            }
        }).disposed(by: disposeBag)
    }

    private func didClickDetailInfo(_ item: MyAIToolInfo?) {
        guard let item = item else { return }
        let toolDetailBody = MyAIToolsDetailBody(toolItem: item,
                                                 isSingleSelect: false,
                                                 chat: self.chat,
                                                 myAIPageService: self.myAIPageService)
        userResolver.navigator.push(body: toolDetailBody, from: self)
    }

    private func startNewTopicAction() {
        if let startNewTopicHandler = self.startNewTopicHandler {
            startNewTopicHandler()
        } else {
            NotificationCenter.default.post(
                name: MyAIToolsSelectedViewController.Notification.StartNewTopic,
                object: self,
                userInfo: ["aiChatModeId": self.aiChatModeId]
            )
        }
        self.fromVc?.dismiss(animated: true)
    }

    /// 失败重试
    func emptyRetryClickHandler() {
        loadData()
    }

    func getUDEmptyConfig(_ status: MyAIToolsSelectedStatus) -> UDEmptyConfig {
        if case .error(_) = status {
            let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError)
            let errorConfig = UDEmptyConfig(description: desc, type: .error)
            emptyDataView.clickHandler = { [weak self] in
                guard let self = self else { return }
                self.emptyRetryClickHandler()
            }
            return errorConfig
        } else {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.maximumLineHeight = 22
            paragraphStyle.minimumLineHeight = 22
            paragraphStyle.lineSpacing = 2
            paragraphStyle.alignment = .center
            let attributes = [NSAttributedString.Key.font: UIFont.ud.body2,
                              NSAttributedString.Key.paragraphStyle: paragraphStyle,
                              NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder]
            let content = NSMutableAttributedString(string: BundleI18n.LarkAI.MyAI_IM_CantChangePluginsInTopicsTemplate_Text(BundleI18n.LarkAI.MyAI_IM_CantChangePluginsInTopicsStartNew_Button),
                                                    attributes: attributes)
            let range = content.mutableString.range(of: BundleI18n.LarkAI.MyAI_IM_CantChangePluginsInTopicsStartNew_Button,
                                                    options: .caseInsensitive)
            content.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ud.primaryContentDefault, range: range)
            let emptyConfig = UDEmptyConfig(title: nil,
                                            description: .init(descriptionText: content,
                                                               operableRange: range),
                                            type: .noApplication,
                                            labelHandler: { [weak self] in
                self?.startNewTopicAction()
            })
            emptyDataView.clickHandler = nil
            return emptyConfig
        }
    }

    @objc
    func handlePan(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            paneloffsetY = tableView.contentOffset.y
        case .changed:
            let changeY = pan.translation(in: self.tableView).y - paneloffsetY
            if changeY > 0, tableView.contentOffset.y == 0 {
                changePanelHeight(changeY: changeY, state: pan.state)
            }
        case .ended:
            let changeY = pan.translation(in: self.tableView).y - paneloffsetY
            changePanelHeight(changeY: changeY, state: pan.state)
            // 重制为默认值
            paneloffsetY = UIScreen.main.bounds.height
        default:
            break
        }
    }

    @objc
    func handleContentViewPan(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .changed:
            let changeY = pan.translation(in: self.view).y
            if changeY > 0 {
                changePanelHeight(changeY: changeY, state: pan.state)
            }
        case .ended:
            let changeY = pan.translation(in: self.view).y
            changePanelHeight(changeY: changeY, state: pan.state)
        default:
            break
        }
    }

    func changePanelHeight(changeY: CGFloat, state: UIGestureRecognizer.State) {
        switch state {
        case .changed:
            self.fromVc?.view.transform = CGAffineTransform(translationX: 0, y: changeY)
        case .ended:
            if changeY / (self.view.bounds.height / 2) > 0.3 {
                self.fromVc?.dismiss(animated: true)
            } else {
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                    self.fromVc?.view.transform = CGAffineTransform(translationX: 0, y: 0)
                }
            }
        default:
            break
        }
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.tools.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MyAIToolsSelectTableViewCell") as? MyAIToolsSelectTableViewCell,
              self.viewModel.tools.count > indexPath.row else {
            return UITableViewCell()
        }
        cell.backgroundColor = UIColor.ud.bgBody
        let toolItem = self.viewModel.tools[indexPath.row]
        cell.toolItem = toolItem
        cell.didClickInfoHandler = { [weak self] (item) in
            self?.didClickDetailInfo(item)
        }
        // 设置第一个和最后一个 Cell 的圆角
        cell.layer.cornerRadius = 8
        cell.clipsToBounds = true
        if viewModel.tools.count == 1 {
            cell.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner
            ]
        } else if indexPath.row == 0 {
            cell.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner
            ]
        } else if indexPath.row == viewModel.tools.count - 1 {
            cell.layer.maskedCorners = [
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner
            ]
        } else {
            cell.layer.maskedCorners = []
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil,
        self.viewModel.tools.count > indexPath.row else { return }
        tableView.deselectRow(at: indexPath, animated: false)
        let toolItem = self.viewModel.tools[indexPath.row]
        didClickDetailInfo(toolItem)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let footerView = tableView.tableFooterView else {
            return
        }
        let width = tableView.bounds.size.width
        let size = footerView.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height))
        if footerView.frame.size.height != size.height {
            footerView.frame.size.height = size.height
            tableView.tableFooterView = footerView
        }
    }

    // MARK: - UIScrollViewDelegate
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffsetY = self.tableView.contentOffset.y
        let panelOffsetY = tableView.panGestureRecognizer.translation(in: self.tableView).y
        if contentOffsetY <= 0 {
            self.tableView.contentOffset.y = 0
        }
        if panelOffsetY > self.paneloffsetY, contentOffsetY >= 0 {
            self.tableView.contentOffset.y = 0
        }
    }

    // MARK: - UIGestureRecognizerDelegate
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    private func addDataEmptyViewIfNeed() {
        if self.viewModel.tools.isEmpty {
            emptyDataView.isHidden = false
            self.tableView.isHidden = true
        } else {
            emptyDataView.isHidden = true
            self.tableView.isHidden = false
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        print("MyAIToolsSelectedViewController - deinit")
    }
}

extension MyAIToolsSelectedViewController: MyAIToolsPanelInterface {
    public func show(from vc: UIViewController?) {
        self.fromVc = vc
    }
}

extension MyAIToolsSelectedViewController {
    enum Cons {
        static var topMargin: CGFloat { 28 }
        static var leftMargin: CGFloat { 16 }
    }
}

extension MyAIToolsSelectedViewController {
    // 向外暴露生命周期
    public struct Notification {
        public static let StartNewTopic: NSNotification.Name = NSNotification.Name("lark.myAITool.selected.startNewTopic")
    }
}
