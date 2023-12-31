//
//  SendRedPacketContainerController.swift
//  LarkFinance
//
//  Created by JackZhao on 2021/11/23.
//

import UIKit
import Foundation
import Homeric
import LarkModel
import LarkUIKit
import SnapKit
import LKCommonsLogging
import LKCommonsTracker
import UniverseDesignTabs
import RxSwift
import EENavigator
import UniverseDesignToast
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeatureGating
import LarkCore
import RxRelay
import RustPB
import LarkContainer
import LarkSetting

// 发不同类型红包的容器
 final class SendRedPacketContainerController: BaseUIViewController, UDTabsListContainerViewDataSource, UDTabsViewDelegate, UserResolverWrapper {
    static let logger = Logger.log(SendRedPacketContainerController.self, category: "finance.send.redPacket")

    let disposeBag: DisposeBag = DisposeBag()
    var userResolver: LarkContainer.UserResolver

    private let segmentedView: UDTabsTitleView = {
        let tabs = UDTabsTitleView()
        let config = tabs.getConfig()
        config.itemSpacing = 0
        config.layoutStyle = .average
        config.itemMaxWidth = 200
        config.titleSelectedColor = redPacketRed
        tabs.setConfig(config: config)
        /// 配置指示器
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2
        indicator.indicatorCornerRadius = 0
        indicator.indicatorColor = redPacketRed
        tabs.indicators = [indicator]
        tabs.backgroundColor = UIColor.clear
        return tabs
    }()

    private lazy var listContainerView = UDTabsListContainerView(dataSource: self)
    private var lastVCWidth: CGFloat = 0
    // 拼手气红包 控制器
    private lazy var randomSendRedpacketController = self.generateSendRedpacketController(type: .random)
    // 等额红包 控制器
    private lazy var equalSendRedpacketController = self.generateSendRedpacketController(type: .equal)
    // 专属红包 控制器
    private lazy var exclusiveSendRedpacketController = self.generateSendRedpacketController(type: .exclusive)
    // 用来同步各个页面的红包信息的信号: model: num and sum, type: 页面类型
     private let redPacketPageModelRelay = BehaviorRelay<RedPacketPageModel?>(value: nil)

    private lazy var redpacketDesignatedFG: Bool = {
         guard let featureGatingService = try? userResolver.resolve(assert: FeatureGatingService.self) else { return false }
         return featureGatingService.staticFeatureGatingValue(with: "lark.redpacket.designated")
    }()
    private lazy var pageTypes: [SendRedpacketPageType] = {
        if redpacketDesignatedFG {
            return [.random, .equal, .exclusive]
        } else {
            return [.random, .equal]
        }
    }()
    private let isByteDancer: Bool
    private let chat: Chat
    private let redPacketAPI: RedPacketAPI
    private let payManager: PayManagerService
    private var pushRedPacketCoverChange: Observable<PushRedPacketCoverChange>

    public init(isByteDancer: Bool,
                chat: Chat,
                redPacketAPI: RedPacketAPI,
                pushRedPacketCoverChange: Observable<PushRedPacketCoverChange>,
                payManager: PayManagerService,
                userResolver: UserResolver) {
        self.isByteDancer = isByteDancer
        self.chat = chat
        self.pushRedPacketCoverChange = pushRedPacketCoverChange
        self.payManager = payManager
        self.userResolver = userResolver
        self.redPacketAPI = redPacketAPI

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        initNavigation()
        initView()
    }

    private func initNavigation() {
        self.title = BundleI18n.LarkFinance.Lark_Legacy_SendHongbao

        let barItem = LKBarButtonItem(image: Resources.hongbao_close)
        barItem.button.addTarget(self, action: #selector(clickDismissBtn), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = barItem

        let historyItem = LKBarButtonItem(title: BundleI18n.LarkFinance.Lark_Legacy_History)
        historyItem.button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        historyItem.button.contentHorizontalAlignment = .right
        historyItem.addTarget(self, action: #selector(historyButtonDidClick), for: .touchUpInside)
        navigationItem.rightBarButtonItem = historyItem
    }

    private func initView() {
        if redpacketDesignatedFG {
            segmentedView.titles = [BundleI18n.LarkFinance.Lark_RedPacket_SendPageRandomAmount_Tab,
                                    BundleI18n.LarkFinance.Lark_RedPacket_SendPageIdenticalAmount_Tab,
                                    BundleI18n.LarkFinance.Lark_DesignateRedPacket_DesignatedRedPacket_Tab]
        } else {
            segmentedView.titles = [BundleI18n.LarkFinance.Lark_RedPacket_SendPageRandomAmount_Tab,
                                    BundleI18n.LarkFinance.Lark_RedPacket_SendPageIdenticalAmount_Tab]
        }
        segmentedView.backgroundColor = UIColor.ud.bgBody
        view.addSubview(segmentedView)
        segmentedView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(40)
        }
        segmentedView.delegate = self

        segmentedView.listContainer = listContainerView
        view.addSubview(listContainerView)
        listContainerView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(segmentedView.snp.bottom)
        }
        lastVCWidth = self.navigationController?.view.bounds.size.width ?? self.view.bounds.size.width
    }

    @objc
    func clickDismissBtn() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    private func historyButtonDidClick() {
        let body = RedPacketHistoryBody()
        userResolver.navigator.push(body: body, from: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let viewWidth = self.navigationController?.view.bounds.size.width ?? self.view.bounds.size.width
        if lastVCWidth != viewWidth {
            lastVCWidth = viewWidth
            segmentedView.reloadData()
        }
    }

    func generateSendRedpacketController(type: SendRedpacketPageType) -> UDTabsListContainerViewDelegate {
        let vc = SendRedPacketController(isByteDancer: isByteDancer,
                                         pageType: type,
                                         chat: chat,
                                         redPacketAPI: redPacketAPI,
                                         redPacketPageModelRelay: redPacketPageModelRelay,
                                         pushRedPacketCoverChange: pushRedPacketCoverChange,
                                         payManager: payManager,
                                         userResolver: userResolver)
        return vc
    }

    func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int {
        return pageTypes.count
    }

    func listContainerView(_ listContainerView: UDTabsListContainerView, initListAt index: Int) -> UDTabsListContainerViewDelegate {
        let type = pageTypes[index]
        return viewController(with: type)
    }

    func viewController(with type: SendRedpacketPageType) -> UDTabsListContainerViewDelegate {
        switch type {
        case .random:        return randomSendRedpacketController
        case .equal:         return equalSendRedpacketController
        case .exclusive:     return exclusiveSendRedpacketController
        }
    }
}

// 发红包页面的类型
enum SendRedpacketPageType {
    // 拼手气
    case random
    // 等额/普通
    case equal
    // 专属
    case exclusive
}

// MARK: - UDTabsListContainerViewDelegate
extension SendRedPacketController: UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        return self.view
    }
}
