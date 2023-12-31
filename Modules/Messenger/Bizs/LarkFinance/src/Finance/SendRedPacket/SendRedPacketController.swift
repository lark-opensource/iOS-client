//
//  SendRedPacketController.swift
//  Pods
//
//  Created by lichen on 2018/10/29.
//

import UIKit
import Foundation
import Homeric
import LarkModel
import LarkUIKit
import SnapKit
import LKCommonsLogging
import LKCommonsTracker
import RxSwift
import EENavigator
import UniverseDesignToast
import LarkSDKInterface
import LarkMessengerInterface
import LarkKeyboardKit
import LarkCore
import RustPB
import RxRelay
import LarkContainer
import LarkSetting

final class SendRedPacketController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    static let logger = Logger.log(SendRedPacketController.self, category: "finance.send.redPacket")

    let disposeBag: DisposeBag = DisposeBag()
    var userResolver: LarkContainer.UserResolver
    private let isByteDancer: Bool
    private let chat: Chat
    private let redPacketAPI: RedPacketAPI
    private let payManager: PayManagerService
    private var result: RedPacketCheckResult
    private let tableView = UITableView()
    private var cells: [SendRedPacketBaseCell] = []
    private let checker: SendRedPackerChecker = {
        let checker = SendRedPackerChecker()
        checker.rules = SendRedPackerChecker.defaultRules
        return checker
    }()
    static let cellReuseIdentifier = "CellReuseIdentifier"
    private var cover: HongbaoCover? {
        result.content.cover
    }
    // 是否展示选人的cell
    private let isShowSelectCell: Bool
    // 当前选择的人
    private var selectedChatter: [Chatter] = [] {
        didSet {
            self.result.selectedChatters = selectedChatter
        }
    }
    // 是否展示红包数量的cell
    private let isShowCountCell: Bool
    private var pushRedPacketCoverChange: Observable<PushRedPacketCoverChange>
    // 用来同步各个页面的红包信息的信号
    private let redPacketPageModelRelay: BehaviorRelay<RedPacketPageModel?>
    // 发红包页面的类型: 拼手气、等额、专属
    private let pageType: SendRedpacketPageType

    public init(isByteDancer: Bool,
                pageType: SendRedpacketPageType,
                chat: Chat,
                redPacketAPI: RedPacketAPI,
                redPacketPageModelRelay: BehaviorRelay<RedPacketPageModel?>,
                pushRedPacketCoverChange: Observable<PushRedPacketCoverChange>,
                payManager: PayManagerService,
                userResolver: UserResolver) {
        self.isByteDancer = isByteDancer
        self.isShowSelectCell = (pageType == .exclusive)
        self.isShowCountCell = (pageType != .exclusive) && (chat.type == .group)
        self.chat = chat
        self.pageType = pageType
        self.payManager = payManager
        self.userResolver = userResolver
        self.redPacketPageModelRelay = redPacketPageModelRelay
        self.pushRedPacketCoverChange = pushRedPacketCoverChange
        self.redPacketAPI = redPacketAPI
        var channel = RustPB.Basic_V1_Channel()
        channel.id = chat.id
        channel.type = .chat
        let type: RustPB.Basic_V1_HongbaoContent.TypeEnum
        if chat.type == .p2P {
            type = .p2P
        } else {
            switch pageType {
            case .random:
                type = .groupRandom
            case .equal:
                type = .groupFix
            case .exclusive:
                type = .exclusive
            }
        }
        let context = SendRedPacketContext(groupNum: Int(chat.userCount))
        let content = SendRedPacketContent(type: type, channel: channel, context: context)
        result = RedPacketCheckResult(content: content, errors: [], chatId: chat.id)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let firstResponder = KeyboardKit.shared.firstResponder, firstResponder.isFirstResponder {
            firstResponder.resignFirstResponder()
        }
        // 页面消失的时候将红包元信息传递给其他页面
        let metaModel = SendRedPacketMetaModel(totalAmount: result.content.totalAmount,
                                               totalNum: result.content.totalNum,
                                               singleAmount: result.content.singleAmount,
                                               subject: result.content.subject,
                                               cover: result.content.cover)
        let model = RedPacketPageModel(redPacketMetaModel: metaModel,
                                       pageType: pageType)
        redPacketPageModelRelay.accept(model)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 同步上一个页面的数据
        self.result.content.updateData(redPacketPageModel: self.redPacketPageModelRelay.value,
                                       selectedCount: self.selectedChatter.count,
                                       currentType: self.pageType)
        self.updateRedPacketCheckResult()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        initView()
        bindEvent()
        if chat.type == .p2P {
            configNavigation()
        }
        FinanceTracker.imHongbaoSendViewTrack(pageType: pageType)
        payManager.payUpgrade(businessScene: .sendRedPacket)
    }

    private func configNavigation() {
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
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(SendRedPacketBaseCell.self, forCellReuseIdentifier: SendRedPacketController.cellReuseIdentifier)

        self.setupTableViewCell()
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

    private func bindEvent() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        if Display.pad {
            preferredContentSize = CGSize(
                width: 375, height: 620 - (navigationController?.navigationBar.bounds.height ?? 0)
            )
        }

        pushRedPacketCoverChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                self?.result.content.cover = push.cover
                self?.tableView.reloadData()
            }).disposed(by: self.disposeBag)
    }

    func setupTableViewCell() {
        var cells: [SendRedPacketBaseCell] = []

        let amount = SendRedPacketAmountCell(frame: CGRect.zero)
        cells.append(amount)
        if let cell = getSendRedPacketSelectPersonCell() {
            cells.append(cell)
        }
        cells.append(getSendRedPacketMoneyCell())
        if let cell = getSendRedPacketNumberCell() {
            cells.append(cell)
        }
        cells.append(getSendRedPacketSubjectCell())
        // 添加红包主题cell
        if let themeCell = getThemeCell() {
            cells.append(themeCell)
        }
        cells.append(getSendRedPacketButtonCell())

        self.cells = cells
    }

    private func getSendRedPacketSelectPersonCell() -> SendRedPacketBaseCell? {
        guard isShowSelectCell else { return nil }
        let cell = SendRedPacketSelectPersonCell()
        cell.tapHandler = { [weak self] in
            guard let self = self else { return }
            var body = SearchGroupChatterPickerBody(title: BundleI18n.LarkFinance.Lark_DesignateRedPacket_SelectRecipient_PageTitle,
                                                    chatId: self.chat.id,
                                                    forceMultiSelect: true,
                                                    selectedChatterIds: self.selectedChatter.map { $0.id })
            body.confirm = { [weak self] (vc, chatters) in
                guard let `self` = self else { return }
                DispatchQueue.main.async {
                    self.selectedChatter = chatters
                    self.result.content.totalNum = chatters.isEmpty ? nil : Int32(chatters.count)
                    let sum = (self.result.content.singleAmount ?? 0) * Int64(self.result.content.totalNum ?? 1)
                    self.result.content.totalAmount = sum
                    self.result.content.moneyStr = "\(Double(sum) / 100)"
                    self.updateRedPacketCheckResult()
                }
                vc.dismiss(animated: true, completion: nil)
            }
            self.userResolver.navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: self,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })

        }
        return cell
    }

    private func getThemeCell() -> SendRedPacketThemeCell? {
        guard let featureGatingService = try? userResolver.resolve(assert: FeatureGatingService.self),
                featureGatingService.staticFeatureGatingValue(with: "lark.hongbao.skin") else {
            return nil
        }
        let cell = SendRedPacketThemeCell()
        cell.tapHandler = { [weak self] in
            guard let `self` = self else { return }
            FinanceTracker.imHongbaoSendClickTrack(click: "hongbao_theme", target: "none")
            self.userResolver.navigator.push(body: RedPacketCoverBody(selectedCoverId: (self.cover?.hasID ?? false) ? self.cover?.id : nil), from: self)
        }
        return cell
    }

    private func getSendRedPacketMoneyCell() -> SendRedPacketBaseCell {
        let money = SendRedPacketMoneyCell(frame: CGRect.zero)
        money.moneyChangeBlock = { [weak self] text in
            guard let `self` = self else { return }
            if let text = text, let money = Double(text) {
                let cent = Int64(round(money * 100))
                if self.result.content.type == .p2P {
                    self.result.content.singleAmount = nil
                    self.result.content.totalAmount = cent
                } else if self.result.content.type == .groupFix {
                    self.result.content.singleAmount = cent
                    let sum = (self.result.content.singleAmount ?? 0) * Int64(self.result.content.totalNum ?? 1)
                    self.result.content.totalAmount = sum
                    self.result.content.moneyStr = "\(Double(sum) / 100)"
                } else if self.result.content.type == .groupRandom {
                    self.result.content.singleAmount = nil
                    self.result.content.totalAmount = cent
                } else if self.result.content.type == .exclusive {
                    self.result.content.singleAmount = cent
                    let sum = (self.result.content.singleAmount ?? 0) * Int64(self.result.content.totalNum ?? 1)
                    self.result.content.totalAmount = sum
                    self.result.content.moneyStr = "\(Double(sum) / 100)"
                }
            } else {
                self.result.content.singleAmount = nil
                self.result.content.totalAmount = nil
            }
            self.result.content.moneyStr = text
            self.updateRedPacketCheckResult()
        }
        return money
    }

    private func getSendRedPacketNumberCell() -> SendRedPacketBaseCell? {
        guard isShowCountCell else { return nil }
        let number = SendRedPacketNumberCell(frame: CGRect.zero)
        number.numberChangeBlock = { [weak self] text in
            guard let `self` = self else { return }
            if let text = text, let number = Int32(text) {
                self.result.content.totalNum = number
            } else {
                self.result.content.totalNum = nil
            }
            if self.result.content.type == .groupFix || self.result.content.type == .exclusive {
                let sum = (self.result.content.singleAmount ?? 0) * Int64(self.result.content.totalNum ?? 1)
                self.result.content.totalAmount = sum
                self.result.content.moneyStr = "\(Double(sum) / 100)"
            }
            self.result.content.numberStr = text
            self.updateRedPacketCheckResult()
        }
        number.chatNumber = Int(chat.userCount)
        return number
    }

    private func getSendRedPacketSubjectCell() -> SendRedPacketBaseCell {
        let placeholder = getDefaultSubject(pageType: self.pageType)
        let subject = SendRedPacketSubjectCell(frame: CGRect.zero)
        subject.setCellContent(placeholder: placeholder, textFieldText: self.result.content.subject)
        subject.subjectChangeBlock = { [weak self] text in
            self?.result.content.subject = text
            self?.updateRedPacketCheckResult()
        }
        return subject
    }

    func getSendRedPacketButtonCell() -> SendRedPacketBaseCell {
        let send = SendRedPacketButtonCell(frame: CGRect.zero)
        send.sendRedPacketBlock = { [weak self] in
            Tracker.post(TeaEvent(Homeric.HONGBAO_SENDNOW))
            FinanceTracker.imHongbaoSendClickTrack(click: "hongbao_send",
                                                   target: "none",
                                                   coverId: "\(self?.cover?.id)",
                                                   pageType: self?.pageType,
                                                   themeType: "\(self?.cover?.coverType)")

            SendRedPacketController.logger.info("点击发送红包")
            guard let `self` = self else {
                return
            }
            self.view.endEditing(true)
            if self.checkSendRedPacketEnable() {
                let content = self.result.content
                let totalNum: Int32
                let totalAmount: Int64
                let subject = content.subject.isEmpty ? self.getDefaultSubject(pageType: self.pageType) : content.subject
                let type = content.type
                let channel = content.channel
                let redPacketContentType: String
                let receiveUserIds = self.selectedChatter.isEmpty ? nil : self.selectedChatter.map({ Int64($0.id) ?? 0 })

                switch type {
                case .p2P:
                    totalNum = 1
                    totalAmount = content.totalAmount ?? 0
                    redPacketContentType = "single"
                case .groupFix:
                    totalNum = content.totalNum ?? 1
                    totalAmount = content.totalAmount ?? 0
                    redPacketContentType = "group_identical"
                case .groupRandom:
                    totalNum = content.totalNum ?? 1
                    totalAmount = content.totalAmount ?? 0
                    redPacketContentType = "group_normal"
                case .exclusive:
                    totalNum = content.totalNum ?? 1
                    totalAmount = content.totalAmount ?? 0
                    redPacketContentType = "exclusive"
                case .unknown, .commercial:
                    totalNum = 0
                    totalAmount = 0
                    redPacketContentType = ""
                case .b2CRandom, .b2CFix:
                    totalNum = 0
                    totalAmount = 0
                    redPacketContentType = ""
                @unknown default:
                    assert(false, "new value")
                    totalNum = 0
                    totalAmount = 0
                    redPacketContentType = ""
                }
                Tracker.post(TeaEvent(Homeric.MESSAGE_SENT, params: ["message_type": redPacketContentType]))

                let sendRedPacketBlock: () -> Void = { [weak self] in
                    guard let self = self else { return }
                    let financeSdkVersion = self.payManager.getCJSDKConfig()
                    self.sendRedPacket(totalAmount: totalAmount,
                                       coverId: (self.cover?.hasID ?? false) ? self.cover?.id : nil,
                                       totalNum: totalNum,
                                       subject: subject,
                                       receiveUserIds: receiveUserIds,
                                       type: type,
                                       channel: channel,
                                       isByteDancer: self.isByteDancer,
                                       financeSdkVersion: financeSdkVersion)
                }
                sendRedPacketBlock()
            }
        }

        send.sendRedPacketEnable = { [weak self] in
            guard let `self` = self else {
                return false
            }
            return self.checkSendRedPacketEnable()
        }
        return send
    }

    private func getDefaultSubject(pageType: SendRedpacketPageType) -> String {
        let placeholder: String
        switch pageType {
        case .exclusive:
            placeholder = BundleI18n.LarkFinance.Lark_DesignateRedPacket_DefaultMessage_Text
        case .equal, .random:
            placeholder = BundleI18n.LarkFinance.Lark_Legacy_BestWishes
        }
        return placeholder
    }

    func sendRedPacket(totalAmount: Int64,
                       coverId: Int64?,
                       totalNum: Int32,
                       subject: String,
                       receiveUserIds: [Int64]?,
                       type: RustPB.Basic_V1_HongbaoContent.TypeEnum,
                       channel: RustPB.Basic_V1_Channel,
                       isByteDancer: Bool,
                       financeSdkVersion: String) {
        guard let window = self.view.window else {
            assertionFailure()
            return
        }
        let hud = UDToast.showLoading(on: window, disableUserInteraction: true)
        let timeStamp = CACurrentMediaTime()
        RedPacketReciableTrack.sendRedPacketLoadTimeStart()
        self.redPacketAPI
            .sendRedPacket(totalAmount: totalAmount,
                           coverId: (self.cover?.hasID ?? false) ? self.cover?.id : nil,
                           totalNum: totalNum,
                           subject: subject,
                           receiveUserIds: receiveUserIds,
                           type: type,
                           channel: channel,
                           isByteDancer: self.isByteDancer,
                           financeSdkVersion: financeSdkVersion)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (result) in
                let networkCost = CACurrentMediaTime() - timeStamp
                RedPacketReciableTrack.updateSendRedPacketEndNetworkCost(networkCost)
                RedPacketReciableTrack.sendRedPacketLoadTimeEnd(key: RedPacketReciableTrack.getSendRedPacketKey())
                SendRedPacketController.logger.info("发送红包成功 id \(result.id)")
                let payCallback = PayManagerCallBack(
                    callDeskCallback: { [weak self] (success) in
                        SendRedPacketController.logger.info("唤起收银台 result \(success)")
                        if !success, let view = self?.view {
                            hud.showFailure(with: BundleI18n.LarkFinance.Lark_Legacy_PayDeskFailed, on: view)
                        } else {
                            hud.remove()
                        }
                    }, payCallback: { [weak self] (error) in
                    if let error = error {
                        SendRedPacketController.logger.error("支付失败 \(error)")
                        if let view = self?.view {
                            hud.showFailure(
                                with: BundleI18n.LarkFinance.Lark_Legacy_PayFailed,
                                on: view,
                                error: error
                            )
                        } else {
                            hud.remove()
                        }
                    } else {
                        hud.remove()
                        SendRedPacketController.logger.info("支付成功")
                        self?.dismiss(animated: true, completion: nil)
                    }
                    }, cacncelBlock: {
                        hud.remove()
                        SendRedPacketController.logger.info("支付取消")
                    })
                guard let `self` = self else { return }
                let paymentMethod: PaymentMethod
                switch result.payURLType {
                case .unknown:
                    paymentMethod = .unknown
                case .caijingPay:
                    paymentMethod = .caijingPay
                case .bytePay:
                    paymentMethod = .bytePay
                @unknown default:
                    paymentMethod = .unknown
                }
                Self.logger.info("call cjpay paymentMethod:\(paymentMethod) payURLType:\(result.payURLType)")
                self.payManager.pay(paramsString: result.paramsString, referVc: self, payCallback: payCallback, paymentMethod: paymentMethod)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                self.processSendRedPacketError(error, hud: hud)
            }).disposed(by: self.disposeBag)
    }

    private func processSendRedPacketError(_ error: Error,
                                           hud: UDToast) {
        hud.remove()
        SendRedPacketController.logger.error("发送红包失败", error: error)
        guard let apiError = error.underlyingError as? APIError else {
            RedPacketReciableTrack.sendRedPacketLoadNetworkError(errorCode: 0, errorMessage: "", isCJPay: false)
            if let view = self.view {
                hud.showFailure(
                    with: BundleI18n.LarkFinance.Lark_Legacy_SendRedPacketFailed,
                    on: view,
                    error: error
                )
            }
            return
        }
        RedPacketReciableTrack.sendRedPacketLoadNetworkError(errorCode: Int(apiError.errorCode), errorMessage: apiError.errorDescription ?? "", isCJPay: false)
        switch apiError.type {
            // 不是好友引导用户去加好友
        case .collaborationAuthFailedNoRights:
            let chatId = self.chat.id
            let chatterId = self.chat.chatter?.id ?? ""
            let displayName = self.chat.chatter?.displayName ?? ""
            var source = Source()
            source.sourceType = .chat
            source.sourceID = chatId
            let addContactBody = AddContactApplicationAlertBody(userId: chatterId,
                                                                chatId: chatId,
                                                                source: source,
                                                                displayName: displayName,
                                                                businessType: .hongBaoConfirm)
            userResolver.navigator.present(body: addContactBody, from: self)
        case .externalCoordinateCtl, .targetExternalCoordinateCtl:
            if let view = self.view {
                hud.showFailure(
                    with: BundleI18n.LarkFinance.Lark_Contacts_CantCompleteOperationNoExternalCommunicationPermission,
                    on: view,
                    error: apiError
                )
            }
        case .cjPayAccountNeedUpgrade(message: let message):
            //财经账号需要升级
            Self.logger.info("cjpay account need upgrade message:\(message)")
            self.payManager.payUpgrade(businessScene: .sendRedPacket)
        default:
            if let view = self.view {
                hud.showFailure(
                    with: BundleI18n.LarkFinance.Lark_Legacy_SendRedPacketFailed,
                    on: view,
                    error: apiError
                )
            }
        }
    }

    func updateRedPacketCheckResult() {
        self.result = self.checker.check(content: self.result.content, chatId: chat.id, selectedChatters: selectedChatter)
        self.cells.forEach { (cell) in
            cell.result = self.result
        }
    }

    func checkSendRedPacketEnable() -> Bool {
        let result = self.result
        let sendEnable = result.errors.isEmpty &&
            ((result.content.type == .p2P && result.content.totalAmount != nil) ||
                (result.content.type == .groupRandom && result.content.totalAmount != nil && result.content.totalNum != nil) ||
                (result.content.type == .groupFix && result.content.singleAmount != nil && result.content.totalNum != nil) ||
             (result.content.type == .exclusive && result.content.singleAmount != nil && result.content.totalNum != nil))
        return sendEnable
    }

    @objc
    func keyboardWillAppear(_ notification: NSNotification) {
        if let keyboardBounds = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if let firstResponse = self.view.lu.firstResponder(),
                let superView = firstResponse.superview,
                let window = firstResponse.window {
                let frame = superView.convert(firstResponse.frame, to: window)
                let keyboardHeight = keyboardBounds.height
                let showWindowHeight = UIScreen.main.bounds.height - keyboardHeight
                let offset: CGFloat = 10

                if frame.bottom + offset > showWindowHeight {
                    var contentOffset = self.tableView.contentOffset
                    contentOffset.y += frame.bottom + offset - showWindowHeight
                    self.tableView.setContentOffset(contentOffset, animated: true)
                }
            }
        }
    }
    // MARK: - UITableViewDelegate, UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    // swiftlint:disable did_select_row_protection
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // swiftlint:enable did_select_row_protection

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = cells[indexPath.row]
        cell.result = self.result
        return cell
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging {
            self.view.endEditing(true)
        }
    }
}

struct RedPacketPageModel {
    var redPacketMetaModel: SendRedPacketMetaModel
    var pageType: SendRedpacketPageType
}
