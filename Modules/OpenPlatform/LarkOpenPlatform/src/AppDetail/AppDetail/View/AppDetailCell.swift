//
//  AppDetailCell.swift
//  LarkAppCenter
//
//  Created by yuanping on 2019/4/16.
//

import LarkUIKit
import UniverseDesignSwitch
import UniverseDesignIcon
import LKCommonsLogging
import RoundedHUD
import LarkContainer
import RxSwift
import ServerPB	
import RustPB	
import LarkRustClient
import LarkAccountInterface
import OPFoundation
import LarkFoundation
import SwiftyJSON

enum AppDetailCellType: String {
    
    case AppReview /// 评分

    case Instruction // 描述

    case Developer // 开发者
    
    case AuthorizationSetting // 权限设置：是否允许群主和添加者从群聊中移除机器人
    
    case ReceiveMessageSetting //是否接受消息推送(目前只有单聊入口BotProfile页有这个设置项)
    
    case FeedBack // 反馈

    case HistoryMessage // 查看历史消息

    case InvitedBy // 添加人
    
    case HelpDoc  // 帮助文档
    
    case ScopeInfo
}

class AppDetailCell: UITableViewCell {
    static let logger = Logger.log(AppDetailCell.self, category: appDetailLogCategory)
    private var resolver: UserResolver?
    private let disposeBag = DisposeBag()
    private lazy var title: UILabel = {
        let title = UILabel(frame: .zero)
        title.textColor = UIColor.ud.textTitle
        title.font = UIFont.systemFont(ofSize: 16.0)
        title.textAlignment = .left
        return title
    }()
    private lazy var descLabel: UILabel = {
        let description = UILabel(frame: .zero)
        description.numberOfLines = 2
        description.textColor = UIColor.ud.textPlaceholder
        description.font = UIFont.systemFont(ofSize: 14.0)
        description.lineBreakMode = .byTruncatingTail
        return description
    }()
    private lazy var isvImage: UIImageView = {
        let isv = UIImageView(frame: .zero)
        isv.image = BundleResources.LarkOpenPlatform.AppDetail.isv_developer
        isv.clipsToBounds = true
        return isv
    }()
    private static var service: ECONetworkService {
        return Injected<ECONetworkService>().wrappedValue
    }
    
    ///  -------------- authorization setting config start --------------
    /// 参考用的权限设置cell高度
    static let referencedAuthorizationSettingCellHeight: CGFloat = 78.5
    static let helpLabelFont = UIFont.systemFont(ofSize: 14.0)
    static let helpLabelSettingSwitchMarginHorizontal: CGFloat = 12.0
    static let cellElementMarinHorizontal: CGFloat = 16.0
    static let settingSwitchSize = CGSize(width: 48, height: 28)
    /// 鉴于权限设置提示文本可能跨多行，故需要动态计算高度
    static func settingCellFitHeight(cellWidth: CGFloat, text: String) -> CGFloat {
        let labelWidth: CGFloat = cellWidth - Self.cellElementMarinHorizontal * 2 - Self.helpLabelSettingSwitchMarginHorizontal - Self.settingSwitchSize.width
        let constraintRect = CGSize(width: labelWidth, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [
                NSAttributedString.Key.font: Self.helpLabelFont
            ],
            context: nil
        )
        var labelHeight: CGFloat = ceil(boundingBox.height)
        let referencedOneLineHeight: CGFloat = 20
        labelHeight = max(labelHeight, referencedOneLineHeight)
        let viewHeight = Self.referencedAuthorizationSettingCellHeight - (referencedOneLineHeight - labelHeight)
        return viewHeight
    }
    /// 权限设置提示文本
    private lazy var helpLabel: UILabel = {
        let description = UILabel(frame: .zero)
        description.numberOfLines = 0
        description.textColor = UIColor.ud.textPlaceholder
        description.font = Self.helpLabelFont
        description.lineBreakMode = .byTruncatingTail
        return description
    }()
    /// 权限设置开关
    private lazy var settingSwitch: UDSwitch = {
        let udSwitch = UDSwitch(config: UDSwitchUIConfig.defaultConfig, behaviourType: .waitCallback)
        udSwitch.valueWillChanged = { [weak self] isOn in
            self?.settingSwitchChanged(isOn: isOn)
        }
        return udSwitch
    }()
    ///  -------------- authorization setting config end---------------
    private lazy var moreImg: UIImageView = {
        let more = UIImageView(frame: .zero)
        more.image = UDIcon.rightOutlined.ud.withTintColor(UIColor.ud.iconN3)
        more.clipsToBounds = true
        return more
    }()
    private lazy var splitLine: UIView = {
        let splitView = UIView(frame: .zero)
        splitView.backgroundColor = UIColor.ud.lineDividerDefault
        return splitView
    }()
    private lazy var deniedLabel: UILabel = {
        let denied = UILabel(frame: .zero)
        denied.text = BundleI18n.AppDetail.AppDetail_Card_Not_Visible
        denied.textColor = UIColor.ud.textPlaceholder
        denied.font = UIFont.systemFont(ofSize: 12.0)
        return denied
    }()
    private lazy var openTagWrapper: UIView = {
        let tagWrapper = UIView(frame: .zero)
        tagWrapper.backgroundColor = .clear
        return tagWrapper
    }()
    private lazy var openTagImg: UIImageView = {
        let openTagImg = UIImageView(frame: .zero)
        openTagImg.clipsToBounds = true
        return openTagImg
    }()
    private lazy var openTagLabel: UILabel = {
        let openTagLabel = UILabel(frame: .zero)
        openTagLabel.font = UIFont.systemFont(ofSize: 16.0)
        openTagLabel.textColor = UIColor.ud.primaryContentDefault
        return openTagLabel
    }()
    private lazy var appReviewView: AppDetailReviewInfoView = {
        let view = AppDetailReviewInfoView(frame: .zero)
        return view
    }()
    private lazy var contentContainer: UIView = {
        UIView()
    }()
    var model: AppDetailViewModel?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initSubViews()
    }
    /// 当前cell-type
    private var cellType: AppDetailCellType?
    /// 是否是isv开发者
    private var isIsvDevelop: Bool = false
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func initSubViews() {
        backgroundColor = UIColor.ud.bgBody
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor.ud.fillHover
        // iOS13+，不要设置contentView.backgroundColor
        contentView.addSubview(splitLine)
        splitLine.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
        contentView.addSubview(contentContainer)
        if #available(iOS 13.0, *) {
            let hover = UIHoverGestureRecognizer(target: self, action: #selector(hovering))
            contentContainer.addGestureRecognizer(hover)
        }
        contentContainer.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(splitLine.snp.top)
        }
        contentContainer.addSubview(title)
        title.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(17.5)
            make.leading.equalToSuperview().offset(16)
        }
        title.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        contentContainer.addSubview(descLabel)
        descLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(18.5)
            make.trailing.equalToSuperview().offset(-16)
        }
        descLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contentContainer.addSubview(isvImage)
        isvImage.snp.makeConstraints { (make) in
            make.width.height.equalTo(0)
            make.centerY.equalTo(descLabel)
            make.leading.greaterThanOrEqualToSuperview().offset(152)
            make.trailing.equalTo(descLabel.snp.leading)
        }
        isvImage.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        // 权限设置界面布局：
        // | title        ---
        // | description  ---  switch(vertical center in superview)
        contentContainer.addSubview(helpLabel)
        contentContainer.addSubview(settingSwitch)
        helpLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(Self.cellElementMarinHorizontal)
            make.right.equalTo(settingSwitch.snp.left).offset(-Self.helpLabelSettingSwitchMarginHorizontal)
            make.top.equalTo(title.snp.bottom).offset(4)
        }
        settingSwitch.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(Self.settingSwitchSize)
            make.right.equalToSuperview().inset(Self.cellElementMarinHorizontal)
        }
        contentContainer.addSubview(moreImg)
        moreImg.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
        contentContainer.addSubview(deniedLabel)
        deniedLabel.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }
        contentContainer.addSubview(openTagWrapper)
        openTagWrapper.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        openTagWrapper.addSubview(openTagImg)
        openTagImg.snp.makeConstraints { (make) in
            make.width.height.equalTo(20)
            make.leading.centerY.equalToSuperview()
        }
        openTagWrapper.addSubview(openTagLabel)
        openTagLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(openTagImg.snp.trailing).offset(6)
            make.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        contentContainer.addSubview(appReviewView)
        appReviewView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }
    private func resetViews() {
        descLabel.isHidden = true
        title.isHidden = true
        helpLabel.isHidden = true
        settingSwitch.isHidden = true
        moreImg.isHidden = true
        splitLine.isHidden = true
        deniedLabel.isHidden = true
        isvImage.isHidden = true
        openTagWrapper.isHidden = true
        appReviewView.isHidden = true
    }
    func updateCellType(model: AppDetailViewModel, type: AppDetailCellType, resolver: UserResolver) {
        self.resolver = resolver
        self.model = model
        // 重置
        splitLine.backgroundColor = UIColor.ud.lineDividerDefault
        splitLine.snp.remakeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
        descLabel.textColor = UIColor.ud.textPlaceholder
        descLabel.textAlignment = .left
        descLabel.numberOfLines = 2
        isvImage.snp.remakeConstraints { (make) in
            make.width.height.equalTo(0)
            make.centerY.equalTo(descLabel)
            if model.isSingleDeveloperInfo() {
                make.leading.greaterThanOrEqualToSuperview().offset(152)
            } else {
                make.leading.equalToSuperview().offset(152)
            }
            make.trailing.equalTo(descLabel.snp.leading)
        }
        openTagLabel.textColor = UIColor.ud.primaryContentDefault
        resetViews()
        self.cellType = type
        isIsvDevelop = model.appDetailInfo?.isISV() ?? false
        selectionStyle = isCellOpratable() ? .default : .none
        switch type {
        case .AppReview:
            appReviewView.isHidden = false
            appReviewView.updateViews(appReviewInfo: model.appDetailInfo?.appReviewInfo)
            splitLine.isHidden = false
        case .Instruction:
            title.isHidden = false
            title.text = BundleI18n.AppDetail.AppDetail_Card_HowtoStartBot
            descLabel.isHidden = false
            descLabel.text = model.appDetailInfo?.getLocalDirection()
            descLabel.textAlignment = model.isSingleDirection() ? .right : .left
            splitLine.isHidden = false
        case .Developer:
            title.isHidden = false
            title.text = BundleI18n.AppDetail.AppDetail_Card_Developer
            descLabel.isHidden = false
            descLabel.text = model.appDetailInfo?.getLocalDeveloperInfo()
            descLabel.textAlignment = model.isSingleDeveloperInfo() ? .right : .left
            if !(model.appDetailInfo?.developerId ?? "").isEmpty, !(model.appDetailInfo?.isISV() ?? false) {
                descLabel.textColor = UIColor.ud.primaryContentDefault
            }
            if model.isSingleDeveloperInfo() {
                descLabel.numberOfLines = 1
            }
            isvImage.isHidden = !(isIsvDevelop)
            if model.appDetailInfo?.isISV() ?? false {
                isvImage.snp.remakeConstraints { (make) in
                    make.width.height.equalTo(14)
                    if model.isSingleDeveloperInfo() {
                        make.centerY.equalTo(descLabel)
                        make.leading.greaterThanOrEqualToSuperview().offset(152)
                    } else {
                        make.top.equalTo(descLabel).offset(1)
                        make.leading.equalToSuperview().offset(152)
                    }
                    make.trailing.equalTo(descLabel.snp.leading).offset(-4)
                }
            }
            splitLine.isHidden = false
        case .AuthorizationSetting:
            title.isHidden = false
            title.text = BundleI18n.GroupBot.Lark_GroupBot_SettingsTtl
            helpLabel.isHidden = false
            helpLabel.text = BundleI18n.GroupBot.Lark_GroupBot_CustomAppPermissionCheckbox
            settingSwitch.isHidden = false
            // 针对添加到群聊的场景，切换开关不需要触发后端请求
            let behaviourType: UniverseDesignSwitch.SwitchBehaviourType
            if model.showAddBotToGroup() {
                behaviourType = .normal
            } else {
                behaviourType = .waitCallback
            }
            if settingSwitch.behaviourType != behaviourType {
                settingSwitch.behaviourType = behaviourType
            }
            let isOn = model.statusOfAuthorziationSetting()
            changeSettingSwitchStatus(isOn: isOn)
            splitLine.isHidden = false
        case .ReceiveMessageSetting:
            title.isHidden = false
            title.text = BundleI18n.GroupBot.Lark_BotMsg_ReceiveMsgOption
            helpLabel.isHidden = false
            helpLabel.text = BundleI18n.GroupBot.Lark_BotMsg_ReceiveMsgHoverText
            settingSwitch.isHidden = false
            settingSwitch.behaviourType = .waitCallback
            let isOn = model.ReceiveMessageSetting()
            changeSettingSwitchStatus(isOn: isOn)
            splitLine.isHidden = false
        case .FeedBack:
            title.isHidden = false
            title.text = BundleI18n.AppDetail.AppDetail_Card_Feedback
            moreImg.isHidden = false
            splitLine.isHidden = false
        case .HistoryMessage:
            openTagWrapper.isHidden = false
            openTagImg.image = BundleResources.LarkOpenPlatform.AppDetail.message_bot_tag
            openTagLabel.text = BundleI18n.LarkOpenPlatform.OpenPlatform_AppCenter_ViewHistoryNews
        case .InvitedBy:
            title.isHidden = false
            title.text = BundleI18n.GroupBot.Lark_GroupBot_CreatorTitle
            descLabel.isHidden = false
            descLabel.text = model.appDetailInfo?.getLocalBotInviterName()
            descLabel.textAlignment = .right
            if let botInviterID = model.appDetailInfo?.botInviterID, !botInviterID.isEmpty {
                descLabel.textColor = UIColor.ud.primaryContentDefault
            } else {
                descLabel.textColor = UIColor.ud.textPlaceholder
            }
            splitLine.isHidden = false
        case .HelpDoc:
            title.isHidden = false
            title.text = BundleI18n.LarkOpenPlatform.Lark_AppCenter_HelpDocTtl
            descLabel.isHidden = false
            descLabel.text = BundleI18n.LarkOpenPlatform.Lark_AppCenter_HelpDocLink
            descLabel.textAlignment = .right
            descLabel.textColor = UIColor.ud.textLinkNormal
            splitLine.isHidden = false
            
        case .ScopeInfo:
            title.isHidden = false
            title.text = BundleI18n.GroupBot.Lark_Bot_BotPermissionsTtl
            descLabel.isHidden = false
            descLabel.text = BundleI18n.LarkOpenPlatform.Lark_AppCenter_HelpDocLink
            descLabel.textAlignment = .right
            descLabel.textColor = UIColor.ud.textLinkNormal
            splitLine.isHidden = false
        }
    }
    /// hover事件
    @available(iOS 13.0, *)
    @objc
    func hovering(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            if isCellOpratable() {  // 支持点击的cell，展示hover态
                contentContainer.backgroundColor = UIColor.ud.fillHover
            } else {
                contentContainer.backgroundColor = .clear
            }
        case .ended:
            contentContainer.backgroundColor = .clear
        default:
            contentContainer.backgroundColor = .clear
        }
    }
    /// 判断当前类型是否支持操作（与tableView的点击事件相对应，容易忽略）
    private func isCellOpratable() -> Bool {
        guard let type = self.cellType else {
            return false
        }
        //  开发者是ISV（企业开发者）时，不可点击，则无hover态
        if type == .Developer, isIsvDevelop {
            return false
        }
        let operatableCell: [AppDetailCellType] = [.FeedBack,
                                                   .AppReview,
                                                   .Developer,
                                                   .HistoryMessage,
                                                   .HelpDoc,
                                                   .InvitedBy,
                                                   .ScopeInfo]
        return operatableCell.contains(type)
    }
}

extension AppDetailCell {
    @objc
    func settingSwitchChanged(isOn: Bool) {
        Self.logger.info("settingSwitchChanged to \(isOn)")
        // 针对添加到群聊的场景，等添加操作触发后，再一起设置权限开关
        if self.cellType == .AuthorizationSetting {
            if let model = model, model.showAddBotToGroup() {
                Self.logger.info("AppDetailCell showAddBotToGroup")
                model.checkMenderForGroupBotToAddScene = isOn
                // 此场景不需要请求后端，状态立即生效
                return
            }
            guard let model = model, let appDetailInfo = model.appDetailInfo else {
                Self.logger.error("settingSwitchChanged: model or appDetailInfo is empty")
                return
            }
            let isWebhook = appDetailInfo.isWebHook ?? false
            let botID = appDetailInfo.botId
            let chatID = model.chatID
            let onError: (Error) -> Void = { [weak self] error in
                /// 规避UDSwitch当处于loading时无法重置isOn
                self?.settingSwitch.stopAnimating()
                // 当请求后端更改状态报错后需要把状态改回去
                self?.changeSettingSwitchStatus(isOn: !isOn)
                Self.logger.error("settingSwitchChanged failed with error(\(error)")
                if let window = self?.window {
                    RoundedHUD.showFailure(with: BundleI18n.LarkOpenPlatform.OpenPlatform_AppActions_NetworkErrToast, on: window)
                } else {
                    Self.logger.error("settingSwitchChanged failed not show toast because window is nil")
                }
            }
            let onSuccess: (APIResponse) -> Void = { [weak self] apiResponse in
                if apiResponse.code == 0 {
                    self?.changeSettingSwitchStatus(isOn: isOn)
                } else {
                    self?.settingSwitch.stopAnimating()
                    self?.changeSettingSwitchStatus(isOn: !isOn)
                    Self.logger.error("settingSwitchChanged failed with code:\(apiResponse.code ?? -1)")
                    let msg = apiResponse.json["mag"].string
                    let toast = msg ?? BundleI18n.LarkOpenPlatform.OpenPlatform_AppActions_NetworkErrToast
                    if let window = self?.window {
                        RoundedHUD.showFailure(with: toast, on: window)
                    } else {
                        Self.logger.error("settingSwitchChanged failed not show toast because window is nil")
                    }
                }
            }
            
            if OPNetworkUtil.basicUseECONetworkEnabled() {
                guard let (url, header, params, context) = updateBotInfoReqComponents(isWebhook: isWebhook, botID: botID, checkMender: isOn, chatID: chatID) else {
                    Self.logger.error("AppDetailCell: update bot info webhook \(isWebhook) req components failed")
                    return
                }
                let completionHandler: (ECOInfra.ECONetworkResponse<[String: Any]>?, ECOInfra.ECONetworkError?) -> Void = { [weak self] response, error in
                    if let error = error {
                        onError(error)
                        return
                    }
                    guard let resolver = self?.resolver else {
                        let error = "AppDetailCell: update bot info webhook \(isWebhook) failed because resolver is nil"
                        let nsError = NSError(domain: error, code: -1, userInfo: nil)
                        onError(nsError)
                        return
                    }
                    let logID = OPNetworkUtil.reportLog(Self.logger, response: response)
                    guard let response = response,
                          let result = response.result else {
                        let error = "AppDetailCell: update bot info webhook \(isWebhook) failed because response or result is nil"
                        let nsError = NSError(domain: error, code: -1, userInfo: nil)
                        onError(nsError)
                        return
                    }
                    let json = JSON(result)
                    let obj = APIResponse(json: json, api: OpenPlatformAPI(path: .empty, resolver: resolver))
                    obj.lobLogID = logID
                    onSuccess(obj)
                }
                let task = Self.service.post(url: url, header: header, params: params, context: context, requestCompletionHandler: completionHandler)
                if let task = task {
                    Self.service.resume(task: task)
                } else {
                    Self.logger.error("AppDetailCell: update bot info webhook \(isWebhook) url econetwork task failed")
                }
                return
            }
            
            guard let httpClient = try? resolver?.resolve(assert: OpenPlatformHttpClient.self) else {
                Self.logger.error("AppDetailCell: OpenPlatformHttpClient impl is nil")
                return
            }
            guard let api = updateBotInfoAPI(isWebhook: isWebhook, botID: botID, chatID: chatID, checkMender: isOn) else {
                Self.logger.error("AppDetailCell: api is nil")
                return
            }
            httpClient.request(api: api).subscribe(onNext: { apiResponse in
                onSuccess(apiResponse)
            }, onError: { (error) in
                onError(error)
            }).disposed(by: self.disposeBag)
        } else if self.cellType == .ReceiveMessageSetting {
            var request = RustPB.Contact_V1_UpdateChatterRequest()
            request.chatterID = model?.appDetailInfo?.botId ?? ""
            var botMutedInfo = Basic_V1_Chatter.BotMutedInfo()
            botMutedInfo.mutedScenes  = ["p2p_chat": !isOn]
            request.mutedInfo = botMutedInfo
            guard let client = try? resolver?.resolve(assert: RustService.self) else {
                Self.logger.error("AppDetailCell: RustService impl is nil")
                return
            }
            client.sendAsyncRequest(request).observeOn(MainScheduler.instance)
                .subscribe(
                    onNext: {[weak self] (response: Contact_V1_UpdateChatterResponse) in
                        Self.logger.info("update receive message success,isOn:\(!isOn), message:\(response.message)")
                        self?.changeSettingSwitchStatus(isOn: isOn)
                    },
                    onError: {[weak self] error in
                        self?.changeSettingSwitchStatus(isOn: !isOn)
                        Self.logger.error("update receive message fail,isOn:\(!isOn),error:\(error)")
                        if let window = self?.window {
                            RoundedHUD.showFailure(with: BundleI18n.LarkOpenPlatform.OpenPlatform_AppActions_NetworkErrToast, on: window)
                        }
                    }
            ).disposed(by: disposeBag)
            
        }
    }

    func changeSettingSwitchStatus(isOn: Bool) {
        settingSwitch.setOn(isOn, animated: false)
    }
    
    private func updateBotInfoAPI(isWebhook: Bool, botID: String, chatID: String? = nil, checkMender: Bool) -> OpenPlatformAPI? {
        guard let resolver = resolver else {
            Self.logger.error("AppDetailCell: resolver is nil")
            return nil
        }
        if isWebhook {
            return OpenPlatformAPI.updateWebhookBotInfoAPI(botID: botID, checkMender: checkMender, resolver: resolver)
        } else {
            return OpenPlatformAPI.updateAppBotInfoAPI(botID: botID, chatID: chatID ?? "", checkMender: checkMender, resolver: resolver)
        }
    }
    
    private func updateBotInfoReqComponents(isWebhook: Bool, botID: String, checkMender: Bool, chatID: String? = nil) -> OPNetworkUtil.ECONetworkReqComponents? {
        guard let resolver = resolver else {
            Self.logger.error("AppDetailCell: resolver is nil")
            return nil
        }
        var url: String? = nil
        if isWebhook {
            url = OPNetworkUtil.getUpdateWebhookBotInfoURL()
        } else {
            url = OPNetworkUtil.getUpdateAppBotInfoURL()
        }
        guard let url = url else {
            Self.logger.error("AppDetailCell: get update bot info webhook \(isWebhook) url failed")
            return nil
        }
        var header: [String: String] = [APIHeaderKey.Content_Type.rawValue: "application/json"]
        if let userService = try? resolver.resolve(assert: PassportUserService.self) {
            let sessionID: String? = userService.user.sessionKey
            header[APIHeaderKey.X_Session_ID.rawValue] = sessionID
            // 对照原网络接口参数实现, 若session:nil, 则不为Header添加Cookie:value键值对
            if let value = sessionID {
                header[APIHeaderKey.Cookie.rawValue] = "\(APICookieKey.session.rawValue)=\(value)"
            }
        }
        var params: [String: Any] = [APIParamKey.bot_id.rawValue: botID,
                                     APIParamKey.check_mender.rawValue: checkMender,
                                     APIParamKey.larkVersion.rawValue: Utils.appVersion,
                                     APIParamKey.i18n.rawValue: OpenPlatformAPI.curLanguage(),
                                     APIParamKey.locale.rawValue: OpenPlatformAPI.curLanguage()]
        if !isWebhook {
            params[APIParamKey.chat_id.rawValue] = chatID
        }
        let context = OpenECONetworkContext(trace: OPTraceService.default().generateTrace(), source: .other)
        return OPNetworkUtil.ECONetworkReqComponents(url: url, header: header, params: params, context: context)
    }
}
