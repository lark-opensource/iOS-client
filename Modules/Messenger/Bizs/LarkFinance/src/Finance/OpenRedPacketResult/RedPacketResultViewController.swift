//
//  RedPacketResultViewController.swift
//  LarkFinance
//
//  Created by SuPeng on 3/29/19.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkExtensions
import LarkUIKit
import LarkModel
import EENavigator
import LKCommonsLogging
import LarkSDKInterface
import LarkAccountInterface
import LarkMessengerInterface
import LarkContainer

extension RedPacketResultViewController: RedPacketNaviBarDelegate {
    func naviBarDidClickBackOrCloseButton(_ naviBar: RedPacketNaviBar) {
        headerViewDidClickBackOrCloseButton(headerView)
    }

    func naviBarDidClickHistoryButton(_ naviBar: RedPacketNaviBar) {
        headerViewBarDidClickHistoryButton(headerView)
    }
}

final class RedPacketResultViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, RedPacketHeaderViewDelegate, UserResolverWrapper {
    static let logger = Logger.log(RedPacketResultViewController.self, category: "RedPacket")

    var userResolver: LarkContainer.UserResolver
    // ui
    private let bgView = RedPacketResultView()
    private let headerView = RedPacketHeaderView()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private lazy var naviBar = RedPacketNaviBar(cover: redPacketInfo.cover,
                                                isShowAvatr: canGrabExclusiveHongbao,
                                                currentUserId: userResolver.userID,
                                                currentAvatarKey: passportUserService.user.avatarKey)

    // data
    var dismissBlock: ((UIViewController) -> Void)?
    private let tableViewTop = RedPacketNaviBar.redPacketStatusBarHeight() + 44
    private let redPacketInfo: RedPacketInfo
    private var receiveInfo: RedPacketReceiveInfo
    private var receiveDetails: [RedPacketReceiveDetail]
    private let redPacketAPI: RedPacketAPI
    private let grabNumber: Int
    private let totalGrabAmount: Int
    private let luckyUserID: String
    private var lastFrame: CGRect = .null
    private var isChangingOffset: Bool = false
    private let disposeBag = DisposeBag()
    // 是否能领取专属红包
    private lazy var canGrabExclusiveHongbao: Bool = {
        return redPacketInfo.type == .exclusive && redPacketInfo.hasPermissionToGrab
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    /// 红包领取详情是否隐藏
    private var isRedPacketResultDetailHidden: Bool {
        return redPacketInfo.type == .p2P ||
        redPacketInfo.type == .commercial || redPacketInfo.isB2C
    }

    private var isCustomCover: Bool {
        redPacketInfo.cover?.hasID == true
    }

    /// 是否来自我发送的红包
    private var isFromeMe: Bool {
        redPacketInfo.userID == userResolver.userID
    }

    private var redpacketType: RedPacketType = .p2P {
        didSet {
            let hideHistory = self.redpacketType == .commercial
            self.naviBar.historyButton.isHidden = hideHistory
        }
    }
    let passportUserService: PassportUserService
    let payManagerService: PayManagerService

    /// 钱包url
    var walletUrl: String?
    var preferMaxContentSize: CGSize {
        if Display.pad { return CGSize(width: 375, height: 620) }
        return self.view.frame.size
    }

    init(redPacketInfo: RedPacketInfo,
         receiveInfo: RedPacketReceiveInfo,
         redPacketAPI: RedPacketAPI,
         payManagerService: PayManagerService,
         userResolver: UserResolver) throws {
        self.redPacketInfo = redPacketInfo
        self.receiveInfo = receiveInfo
        self.redPacketAPI = redPacketAPI
        self.userResolver = userResolver
        self.passportUserService = try userResolver.resolve(assert: PassportUserService.self)
        self.payManagerService = payManagerService
        self.receiveDetails = receiveInfo.details

        self.grabNumber = receiveInfo.grabNumber ?? redPacketInfo.grabNumber
        self.totalGrabAmount = receiveInfo.totalGrabAmount ?? redPacketInfo.totalGrabAmount
        self.luckyUserID = receiveInfo.luckyUserID ?? redPacketInfo.luckyUserID

        if receiveInfo.grabNumber == nil || receiveInfo.totalGrabAmount == nil {
            RedPacketResultViewController.logger.error(
                "Get redPacketReceiveDetail error, missing grabNumber of totalGrabAmount when cursor is empty",
                additionalData: ["redPacketID": receiveInfo.redPacketID]
            )
        }
        super.init(nibName: nil, bundle: nil)
        self.getWalletUrl()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        isNavigationBarHidden = true
        view.backgroundColor = UIColor.ud.bgBody

        headerView.delegate = self
        let dismissType: RedPacketHeaderViewDismissType
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
            dismissType = .back
        } else {
            dismissType = .close
        }
        let description: String
        switch redPacketInfo.type {
        case .exclusive:
            description = canGrabExclusiveHongbao ? BundleI18n.LarkFinance.Lark_DesignateRedPacket_NameCongratsRedPacket_Text(passportUserService.user.name) :
            BundleI18n.LarkFinance.Lark_DesignatedRedPacket_SenderDesignatedRedPacket_Text(redPacketInfo.chatter?.localizedName ?? "")
        case .b2CRandom, .b2CFix:
            description = BundleI18n.LarkFinance.Lark_RedPacket_FromUser(redPacketInfo.hongbaoCoverCompanyName ?? "")
        @unknown default:
            description = BundleI18n.LarkFinance.Lark_RedPacket_FromUser(redPacketInfo.chatter?.localizedName ?? "")
        }
        headerView.setContent(currentChatterId: userResolver.userID,
                              preferMaxWidth: preferMaxContentSize.width,
                              isShowAvatar: !canGrabExclusiveHongbao,
                              description: description,
                              redPacketInfo: redPacketInfo,
                              dismissType: dismissType)
        self.redpacketType = redPacketInfo.type

        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.rowHeight = 64
        tableView.allowsSelection = false

        tableView.separatorStyle = .none
        tableView.lu.register(cellSelf: RedPacketResultCell.self)
        tableView.tableHeaderView = headerView

        if receiveInfo.hasMore {
            tableView.addBottomLoadMoreView { [weak self] in
                self?.loadMoreReceiveDetail()
            }
        }
        self.view.addSubview(naviBar)
        naviBar.delegate = self
        FinanceTracker.imHongbaoReceiveDetailView(hongbaoType: redPacketInfo.type,
                                                  hongbaoId: redPacketInfo.redPacketID,
                                                  isReciever: redPacketInfo.hasPermissionToGrab)
        if Display.pad {
            preferredContentSize = preferMaxContentSize
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard view.frame != lastFrame else { return }
        lastFrame = view.frame
        naviBar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: isCustomCover ? 200 : 124)

        // dynamic set table headerview height
        guard let headerView = tableView.tableHeaderView else {
            return
        }
        let size = headerView.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize,
            withHorizontalFittingPriority: .defaultLow,
            verticalFittingPriority: .defaultHigh
        )
        let height = size.height
        headerView.translatesAutoresizingMaskIntoConstraints = true
        if headerView.frame.height != height {
            headerView.frame.size.height = height
            tableView.layoutIfNeeded()
        }
        tableView.frame = CGRect(x: 0,
                                 y: naviBar.frame.maxY,
                                 width: view.bounds.width,
                                 height: view.bounds.height - naviBar.frame.maxY)
    }

    /// 加载更多
    private func loadMoreReceiveDetail() {
        redPacketAPI.getRedPacketReceiveDetail(redPacketID: redPacketInfo.redPacketID,
                                               type: self.redPacketInfo.type,
                                               cursor: receiveInfo.nextCursor,
                                               count: 20)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (receiveInfo) in
                guard let `self` = self else { return }
                self.receiveInfo = receiveInfo
                self.receiveDetails.append(contentsOf: receiveInfo.details)
                if receiveInfo.hasMore {
                    self.tableView.addBottomLoadMoreView { [weak self] in
                        self?.loadMoreReceiveDetail()
                    }
                } else {
                    self.tableView.removeBottomLoadMore()
                }
                self.tableView.reloadData()
            }, onError: { [weak self] (_) in
                self?.tableView.endBottomLoadMore()
            })
            .disposed(by: disposeBag)
    }

    func getWalletUrl() {
        self.payManagerService.getWalletScheme { [weak self] (walletUrl) in
            guard let self = self else { return }
            self.walletUrl = walletUrl
        }
    }
    // MARK: - RedPacketHeaderViewDelegate
    func headerViewDidClickBackOrCloseButton(_ headerView: RedPacketHeaderView) {
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
            self.navigationController?.popViewController(animated: true)
        } else {
            if let dismissBlock = dismissBlock {
                dismissBlock(self)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    func headerViewBarDidClickHistoryButton(_ headerView: RedPacketHeaderView) {
        let body = RedPacketHistoryBody()
        userResolver.navigator.push(body: body, from: self)
    }

    func headerViewBarDidClickDetailButton(_ headerView: RedPacketHeaderView) {
        userResolver.navigator.push(body: WalletBody(walletUrl: self.walletUrl), from: self)
    }
    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return isRedPacketResultDetailHidden ? 0 : 42
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if isRedPacketResultDetailHidden {
            return nil
        }
        let name = redPacketInfo.chatter?.name ?? ""
        let headerView = RedPacketResultSectionHeaderView(text: getHeaderViewText(), sender: redPacketInfo.type == .exclusive ? name : nil)
        return headerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isRedPacketResultDetailHidden ? 0 : receiveDetails.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = String(describing: RedPacketResultCell.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: id) as? RedPacketResultCell else {
            return UITableViewCell()
        }
        let detail = receiveDetails[indexPath.row]
        let model = RedPacketResultCellModel.transfromFrom(detail: detail,
                                                           isExclusive: redPacketInfo.type == .exclusive,
                                                           isLuckiest: redPacketInfo.isGrabbedFinish ? (luckyUserID == detail.chatter.id) : false)
        cell.setContent(model: model)
        return cell
    }

    private func getHeaderViewText() -> String {
        let info = redPacketInfo
        let text: String
        if info.type == .exclusive {
            text = BundleI18n.LarkFinance.Lark_DesignateRedPacket_NumRecipientsInTotalListedBelow_Text(grabNumber, info.totalNumber)
        } else {
            if isFromeMe {
                text = String(format: BundleI18n.LarkFinance.Lark_HongbaoResult_SenderSide_Text,
                                          grabNumber,
                                          info.totalNumber,
                                          Float(totalGrabAmount) / 100.0,
                                          Float(info.totalAmount) / 100.0)
            } else {
                text = String(format: BundleI18n.LarkFinance.Lark_Legacy_HongbaoResultOpenProgress,
                              grabNumber,
                              info.totalNumber)
            }
        }
        return text
    }
}
