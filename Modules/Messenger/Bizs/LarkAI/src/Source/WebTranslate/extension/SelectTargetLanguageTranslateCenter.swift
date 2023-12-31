//
//  SelectTargetLanguageTranslateAlert.swift
//  LarkApp
//
//  Created by 李勇 on 2019/8/20.
//

import UIKit
import Foundation
import LarkModel
import LarkMessengerInterface
import LarkAlertController
import EENavigator
import LarkActionSheet
import LarkSDKInterface
import LarkUIKit
import LarkFeatureGating
import LarkLocalizations
import LKCommonsLogging
import UniverseDesignIcon
import LarkContainer
import LarkStorage
import Homeric
import LKCommonsTracker
import LarkSearchCore

public enum TranslateContext {
    case message(context: MessageTranslateParameter)
    case image(context: ImageTranslateParameter)
    case web(context: WebTranslateProcessInfo)
    case moments(context: MomentsTranslateParameter)
    case text(context: String)
}
public protocol SelectTargetLanguageTranslateCenterDelegate: AnyObject {
    /// 语种选择回调
    func finishSelect(translateContext: TranslateContext, targetLanguage: String)
}

private enum UI {
    static let headerViewHeight: CGFloat = 59
    static let cellHeight: CGFloat = 52
    static let maxCellCountForExpend: Int = 14
    static let dismissThresholdOffset: CGFloat = 120
    static let dismissButtonWidth: CGFloat = 24
    static let dismissButtonHeight: CGFloat = 24
    static let dismissButtonRight: CGFloat = 16
    static let displayFullScreenThreshold = 7
}

/// 选择一个目标语言进行翻译，同一时间只会有一个alert弹出
/// 用户态改造以来webTranslate改造
final public class SelectTargetLanguageTranslateCenter: NSObject, UITableViewDataSource, UITableViewDelegate, UserResolverWrapper {
    static let logger = Logger.log(SelectTargetLanguageTranslateCenter.self,
                                   category: "LarkChat.SelectTargetLanguageTranslateCenter")
    private weak var delegate: SelectTargetLanguageTranslateCenterDelegate?
//    private weak var dismissDelegate: SelectTargetLanguageDismissDelegate?
    private var translateLanguageSetting: TranslateLanguageSetting
    /// 当前是否有其他的alert存在
    private var haveOtherAlert: Bool = false

    @ScopedInjectedLazy private var userSettings: UserGeneralSettings?

    /// 当前用户能选择的语言
    private var languages: [String] = []
    /// 用于展示语种的语言列表,
    private var displayLanguages: [String] = []
    /// 当前用户选中的语言
    private var selectLanguage: String = ""
    /// 当前选中语言label，用于后续改变内容
    private weak var languageLabel: UILabel?
    /// 缓存当前的翻译参数上下文
    private var currentTranslateContext: TranslateContext?
    /// 当前弹出的语种选择抽屉
    private weak var currentDrawer: SelectiveDrawerController?
    private weak var currentFrom: NavigatorFrom?
    private var usePushMode: Bool = false
    public let userResolver: UserResolver
    public init(userResolver: UserResolver,
                selectTargetLanguageTranslateCenterdelegate: SelectTargetLanguageTranslateCenterDelegate,
                translateLanguageSetting: TranslateLanguageSetting) {
        self.userResolver = userResolver
        self.delegate = selectTargetLanguageTranslateCenterdelegate
        self.translateLanguageSetting = translateLanguageSetting
    }

    public func showSelectDrawer(translateContext: TranslateContext,
                                 from: NavigatorFrom,
                                 disableLanguage: String = "",
                                 backButtonStatus: SelectLanguageHeaderView.BackButtonStatus = .none,
                                 usePush: Bool = false,
                                 dismissCompletion: (() -> Void)? = nil) {
        if haveOtherAlert { return }

        usePushMode = usePush
        haveOtherAlert = true

        languages = []
        displayLanguages = []

        currentTranslateContext = translateContext
        let translateSetting = translateLanguageSetting

        var languageKeys: [String] = []
        switch translateContext {
        case .image:
            languageKeys = translateSetting.imageLanguageKeys
        case .message(let context):
            // 如果当前的消息为纯图片消息或者是仅单图富文本消息，则选用图片翻译的目标语种列表
            if isSingleImageMessage(message: context.message) {
                languageKeys = translateSetting.imageLanguageKeys
            } else {
                languageKeys = translateSetting.languageKeys
            }
        case .web, .text, .moments:
            languageKeys = translateLanguageSetting.languageKeys
        }
        languageKeys
            .filter { $0 != disableLanguage }
            .forEach { (language) in
            var displayLanguageName = ""
            if AIFeatureGating.translateSettingV2.isUserEnabled(userResolver: userResolver) {
                let trgLanguageMap = translateSetting.trgLanguagesConfig.first(where: { $0.key == language })
                let i18nLanguageName = trgLanguageMap?.value.i18NLanguage[LanguageManager.currentLanguage.localeIdentifier.lowercased()] ??
                    (trgLanguageMap?.value.i18NLanguage[trgLanguageMap?.value.defaultLocale ?? Lang.en_US.rawValue.lowercased()] ?? "")
                displayLanguageName = i18nLanguageName
            } else {
                guard let i18nLanguageName = translateSetting.supportedLanguages[language] else {
                    return
                }
                displayLanguageName = i18nLanguageName
            }

            if !displayLanguageName.isEmpty {
                self.languages.append(language)
                self.displayLanguages.append(displayLanguageName)
            }
            }

        if displayLanguages.isEmpty {
            SelectTargetLanguageTranslateCenter.logger.error("displayLanguages is empty",
                                                             additionalData: ["languageKeys": "\(translateSetting.languageKeys)",
                                                                              "imageLanguageKeys": "\(translateSetting.imageLanguageKeys)"])
            return
        }
        var config: DrawerConfig
        let headerView: SelectLanguageHeaderView
        if Display.pad {
            if usePushMode {
                let maxContentHeight = from.fromViewController?.view.frame.height ?? 0
                let headerConfig = SelectLanguageHeaderView.Config(backButtonStatus: .back)
                headerView = SelectLanguageHeaderView(config: headerConfig)
                let footerView = UIView(frame: CGRect(x: 0, y: 0, width: from.fromViewController?.view.frame.width ?? 0, height: 20))
                config = DrawerConfig(backgroundColor: UIColor.ud.bgMask,
                                      cornerRadius: 12,
                                      thresholdOffset: UI.dismissThresholdOffset,
                                      maxContentHeight: maxContentHeight,
                                      cellType: LanguageSelectiveCell.self,
                                      tableViewDataSource: self,
                                      tableViewDelegate: self,
                                      headerView: headerView,
                                      footerView: footerView,
                                      headerViewHeight: UI.headerViewHeight,
                                      footerViewHeight: 20)
            } else {
                let headerConfig = SelectLanguageHeaderView.Config(backButtonStatus: backButtonStatus)
                headerView = SelectLanguageHeaderView(config: headerConfig)
                config = DrawerConfig(backgroundColor: UIColor.ud.bgMask,
                                      cornerRadius: 12,
                                      thresholdOffset: UI.dismissThresholdOffset,
                                      maxContentHeight: CGFloat(UI.displayFullScreenThreshold) * UI.cellHeight + UI.headerViewHeight,
                                      cellType: LanguageSelectiveCell.self,
                                      tableViewDataSource: self,
                                      tableViewDelegate: self,
                                      headerView: headerView,
                                      headerViewHeight: UI.headerViewHeight)
            }
        } else {
            let headerConfig = SelectLanguageHeaderView.Config(backButtonStatus: backButtonStatus)
            headerView = SelectLanguageHeaderView(config: headerConfig)
            if displayLanguages.count <= UI.displayFullScreenThreshold {
                config = DrawerConfig(backgroundColor: UIColor.ud.bgMask,
                                          cornerRadius: 12,
                                          thresholdOffset: UI.dismissThresholdOffset,
                                          maxContentHeight: CGFloat(displayLanguages.count) * UI.cellHeight + UI.headerViewHeight,
                                          cellType: LanguageSelectiveCell.self,
                                          tableViewDataSource: self,
                                          tableViewDelegate: self,
                                          headerView: headerView,
                                          headerViewHeight: UI.headerViewHeight)
            } else {
                config = DrawerConfig(backgroundColor: UIColor.ud.bgMask,
                                      cornerRadius: 12,
                                      thresholdOffset: UI.dismissThresholdOffset,
                                      maxContentHeight: UIScreen.main.bounds.height - 60,
                                      cellType: LanguageSelectiveCell.self,
                                      tableViewDataSource: self,
                                      tableViewDelegate: self,
                                      headerView: headerView,
                                      headerViewHeight: UI.headerViewHeight)
            }
        }

        let drawer = SelectiveDrawerController(config: config, cancelBlock: { [weak self] in
            guard let self = self else { return }
            self.haveOtherAlert = false
            self.currentTranslateContext = nil
            dismissCompletion?()
        })
        currentDrawer = drawer
        currentFrom = from
        if Display.pad {
            if usePushMode {
                headerView.didTapBackButton = { [weak drawer, weak self] in
                    guard let self = self, let drawer = drawer else { return }
                    self.navigator.pop(from: from)
                    self.haveOtherAlert = false
                    self.currentTranslateContext = nil
                }
                navigator.push(drawer, from: from)
            } else {
                drawer.view.layer.cornerRadius = 12
                headerView.didTapBackButton = { [weak drawer, weak self] in
                    guard let self = self, let drawer = drawer else { return }
                    drawer.dismiss(animated: true)
                    self.haveOtherAlert = false
                    self.currentTranslateContext = nil
                    dismissCompletion?()
                }
                navigator.present(
                    drawer, from: from,
                    prepare: {
                        $0.modalPresentationStyle = .formSheet
                    },
                    animated: true) { [weak self] in
                        self?.haveOtherAlert = false
                }
            }
        } else {
            headerView.didTapBackButton = { [weak drawer, weak self] in
                guard let self = self, let drawer = drawer else { return }
                drawer.dismiss(animated: true)
                self.haveOtherAlert = false
                self.currentTranslateContext = nil
                dismissCompletion?()
            }
            if displayLanguages.count <= UI.displayFullScreenThreshold {
                navigator.present(drawer, from: from) { [weak self] in
                    self?.haveOtherAlert = false
                    dismissCompletion?()
                }
            } else {
                navigator.present(
                    drawer, from: from) { [weak self] in
                        self?.haveOtherAlert = false
                        dismissCompletion?()
                }
            }
        }
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayLanguages.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let language = languages[indexPath.row]
        let displayLanguage = displayLanguages[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(LanguageSelectiveCell.self)) as? LanguageSelectiveCell {
            cell.set(language: displayLanguage, isHighlight: selectLanguage == language)
            return cell
        }
        return UITableViewCell()
    }

    // swiftlint:disable did_select_row_protection
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedLanguage = languages[indexPath.row]
        if selectedLanguage == selectLanguage {
            dismissCurrentDrawer()
            return
        }
        if let translateContext = currentTranslateContext {
            dismissCurrentDrawer()
            if selectedLanguage != userSettings?.translateLanguageSetting.targetLanguage {
                KVPublic.AI.lastSelectedTargetLanguage.setValue(selectedLanguage, forUser: userResolver.userID)
            }
            trackSelectedLanguage(selectedLanguage: selectedLanguage)
            delegate?.finishSelect(translateContext: translateContext, targetLanguage: selectedLanguage)
        }
    }

    private func trackSelectedLanguage(selectedLanguage: String) {
        if let translateContext = currentTranslateContext,
           case let .message(context) = translateContext {
            var trackInfo = [String: Any]()
            var chatTypeForTracking: String {
                if context.chat.chatMode == .threadV2 {
                    return "topic"
                } else if context.chat.type == .group {
                    return "group"
                } else {
                    return "single"
                }
            }
            trackInfo["chat_id"] = context.chat.id
            trackInfo["chat_type"] = chatTypeForTracking
            trackInfo["msg_id"] = context.message.id
            trackInfo["message_language"] = context.message.messageLanguage
            trackInfo["target_language"] = context.message.translateLanguage
            trackInfo["target"] = selectedLanguage
            trackInfo["click"] = "switch_lang"
            Tracker.post(TeaEvent(Homeric.ASL_CROSSLANG_TRANSLATION_IM_SUB_CLICK, params: trackInfo))
        }
    }

    // swiftlint:enable did_select_row_protection

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UI.cellHeight
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}

private extension SelectTargetLanguageTranslateCenter {
    func dismissCurrentDrawer() {
        if Display.pad && usePushMode {
            guard let from = currentFrom else { return }
            navigator.pop(from: from, completion: {
                self.haveOtherAlert = false
                self.currentTranslateContext = nil
            })
        } else {
            currentDrawer?.dismiss(animated: true, completion: {
                self.haveOtherAlert = false
                self.currentTranslateContext = nil
            })
        }
    }
    func isSingleImageMessage(message: Message) -> Bool {
        switch message.type {
        case .image:
            return true
        case .post:
            // 意在判断单图post消息， 随着post的丰富，接口不可用
            /*
            if let richText = (message.content as? PostContent)?.richText {
                let elementIds = richText.elementIds
                let imageIds = richText.imageIds
                return elementIds.count == 1 && imageIds.count == 1
            }
             */
            return false
        @unknown default:
            return false
        }
    }
}

private final class LanguageSelectiveCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        layoutPageSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(language: String, isHighlight: Bool) {
        langNameLabel.text = language
        langNameLabel.textColor = isHighlight ? UIColor.ud.colorfulBlue : UIColor.ud.N900
    }

    func layoutPageSubviews() {
        contentView.backgroundColor = UIColor.ud.bgFloat
        contentView.addSubview(langNameLabel)
        langNameLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(24)
            make.centerY.equalToSuperview()
        }
    }

    private lazy var langNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N900
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
}
final public class SelectLanguageHeaderView: UIView {
    public enum BackButtonStatus {
        case none
        case cancel
        case back
    }
    struct Config {
        var backButtonStatus: BackButtonStatus = .none
    }
    var didTapBackButton: (() -> Void)?
    let config: Config
    private lazy var headerTitle: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .ud.textTitle
        label.text = BundleI18n.LarkAI.Lark_Shared_MessageTranslation_TranslateInto_Title
        return label
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.closeSmallOutlined.ud.withTintColor(.ud.iconN1), for: .normal)
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.leftOutlined.ud.withTintColor(.ud.iconN1), for: .normal)
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.lineDividerDefault.withAlphaComponent(0.15)
        return view
    }()

    init(config: Config) {
        self.config = config
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .ud.bgFloat
        addSubview(headerTitle)
        headerTitle.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        switch config.backButtonStatus {
        case .none: break
        case let .cancel:
            addSubview(cancelButton)
            cancelButton.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(18)
                make.centerY.equalToSuperview()
            }
        case let .back:
            addSubview(backButton)
            backButton.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(18)
                make.centerY.equalToSuperview()
            }
        }

        addSubview(divider)
        divider.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    @objc
    private func backButtonTapped() {
        didTapBackButton?()
        didTapBackButton = nil
    }
}
