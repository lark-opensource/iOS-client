//
//  NavigationBarTitleViewFactory.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/11/14.
//

import UIKit
import Foundation
import RxSwift
import LarkCore
import LarkInteraction
import LarkFocus
import LarkModel
import LarkBizTag
import LarkTag
import LKContentFix
import LarkMessengerInterface
import EENavigator
import RustPB
import TangramService
import LarkSDKInterface
import SwiftProtobuf
import LarkLocalizations
import LKCommonsLogging
import LarkFeatureGating
import LarkOpenChat
import UniverseDesignIcon
import UniverseDesignStyle
import UniverseDesignTag
import LarkContainer

public protocol NavigationBarTitleViewDelegate: AnyObject {
    func getCurrentWindow() -> UIWindow?
    func titleClicked()
}

public enum ChatNavigationItemType: Equatable {
    case nameItem           // 会话标题
    case countItem          // 群人数
    case specialFocusItem   // 星标联系人
    case focusItem          // 个人状态
    case tagsItem           // tag标签
    case rightArrowItem     // 向右箭头
    case statusItem         // 状态信息
    case extraFieldsItem    // 管理员勾选的字段

    public static func == (lhs: ChatNavigationItemType, rhs: ChatNavigationItemType) -> Bool {
        switch (lhs, rhs) {
        case (.nameItem, .nameItem): return true
        case (.countItem, .countItem): return true
        case (.specialFocusItem, .specialFocusItem): return true
        case (.focusItem, .focusItem): return true
        case (.tagsItem, .tagsItem): return true
        case (.rightArrowItem, .rightArrowItem): return true
        case (.statusItem, .statusItem): return true
        case (.extraFieldsItem, .extraFieldsItem): return true
        default: return false
        }
    }
}

public struct NavigationBarTitleViewConfig {

    let showExtraFields: Bool
    let canTap: Bool
    let itemsOfTop: [ChatNavigationItemType]?
    let itemsOfbottom: [ChatNavigationItemType]?
    let darkStyle: Bool
    var barStyle: OpenChatNavigationBarStyle
    let tagsGenerator: ChatNavigationBarTagsGenerator
    let inlineService: MessageTextToInlineService?
    let chatterAPI: ChatterAPI?
    let fixedTitle: String?
    let style: ChatTitleViewStyle

    public init(showExtraFields: Bool,
                canTap: Bool,
                itemsOfTop: [ChatNavigationItemType]?,
                itemsOfbottom: [ChatNavigationItemType]?,
                darkStyle: Bool,
                barStyle: OpenChatNavigationBarStyle,
                tagsGenerator: ChatNavigationBarTagsGenerator,
                inlineService: MessageTextToInlineService?,
                chatterAPI: ChatterAPI?,
                fixedTitle: String? = nil,
                style: ChatTitleViewStyle = ChatTitleViewStyle.defalutStyle()) {
        self.showExtraFields = showExtraFields
        self.canTap = canTap
        self.itemsOfTop = itemsOfTop
        self.itemsOfbottom = itemsOfbottom
        self.darkStyle = darkStyle
        self.barStyle = barStyle
        self.tagsGenerator = tagsGenerator
        self.inlineService = inlineService
        self.chatterAPI = chatterAPI
        self.fixedTitle = fixedTitle
        self.style = style
    }

    static func defaultConfig(userResolver: UserResolver) -> NavigationBarTitleViewConfig {
        return NavigationBarTitleViewConfig(showExtraFields: false,
                                            canTap: false,
                                            itemsOfTop: nil,
                                            itemsOfbottom: nil,
                                            darkStyle: false,
                                            barStyle: .lightContent,
                                            tagsGenerator: ChatNavigationBarTagsGenerator(forceShowAllStaffTag: false,
                                                                                          isDarkStyle: false,
                                                                                          userResolver: userResolver),
                                            inlineService: nil,
                                            chatterAPI: nil)
    }
}
public final class NavigationBarTitleViewFactory: UserResolverWrapper {

    private static let logger = Logger.log(NavigationBarTitleViewFactory.self, category: "NavigationBarTitleViewFactory")
    weak var delegate: NavigationBarTitleViewDelegate?
    private let disposeBag = DisposeBag()

    fileprivate var titleView: ChatTitleView?
    private var config: NavigationBarTitleViewConfig
    private(set) var bottomOfCenterItems: [ChatNavigationItemType] = []

    private(set) lazy var itemsOfbottomSubject = ReplaySubject<[ChatNavigationItemType]>.create(bufferSize: 1)
    public var chat: Chat? {
        didSet {
            guard let old = oldValue, let new = self.chat else {
                return
            }
            if new.type == .p2P {
                if old.chatter?.displayName == new.chatter?.displayName &&
                    old.chatter?.description_p.text == new.chatter?.description_p.text &&
                    old.chatter?.isSpecialFocus == new.chatter?.isSpecialFocus &&
                    old.isOfflineOncall == new.isOfflineOncall {
                    return
                }
                self.updateTitle(chat: new)
            } else {
                if old.name == new.name &&
                    old.userCount == new.userCount &&
                    old.chatterCount == new.chatterCount &&
                    old.isUserCountVisible == new.isUserCountVisible &&
                    old.isOfflineOncall == new.isOfflineOncall &&
                    old.isFrozen == new.isFrozen &&
                    old.isDepartment == new.isDepartment &&
                    old.isPublic == new.isPublic {
                    return
                }
                self.updateTitle(chat: new)
            }
        }
    }
    public let userResolver: UserResolver
    public init(resolver: UserResolver) {
        self.config = NavigationBarTitleViewConfig.defaultConfig(userResolver: resolver)
        self.userResolver = resolver
    }

    public func createTitleView(config: NavigationBarTitleViewConfig,
                         delegate: NavigationBarTitleViewDelegate) -> UIView? {
        guard let chat = self.chat else {
            return nil
        }
        let tintColor = config.barStyle.elementTintColor()
        let titleView = ChatTitleView(tintColor: tintColor, style: config.style)
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(
                    effect: .highlight,
                    shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                        guard let view = interaction.view else {
                            return (.zero, 0)
                        }
                        return (CGSize(width: view.bounds.width + 24, height: view.bounds.height + 12), 16)
                    })
                )
            )
            titleView.addLKInteraction(pointer)
        }
        titleView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.delegate = delegate
        self.config = config
        self.setupTapCallBackFor(titleView: titleView)
        self.setupBottomCenterItems(customBottomCenterItems: config.itemsOfbottom)
        self.titleView = titleView
        self.updateTitle(chat: chat)
        return titleView
    }

    public func updateBarStyle(_ barStyle: OpenChatNavigationBarStyle) {
        self.config.barStyle = barStyle
        var infoTextColor: UIColor = UIColor.ud.textCaption
        if case .custom = barStyle {
            infoTextColor = barStyle.elementTintColor()
        }
        self.titleView?.updateTintColor(tintColor: barStyle.elementTintColor(), infoTextColor: infoTextColor)
    }

    private func setupTapCallBackFor(titleView: ChatTitleView) {
        guard self.config.canTap, let chat = self.chat, !chat.isTeamVisitorMode else {
            return
        }
        titleView.statusLabel.linkBlock = { [weak self] (url) in
            guard let self = self, let window = self.delegate?.getCurrentWindow() else {
                assertionFailure("miss From VC")
                return
            }
            self.navigator.push(url, context: ["from": "self_signature"], from: window)
            if let chatterStatus = self.chat?.chatter?.description_p.text, !chatterStatus.isEmpty,
               let chatterID = self.chat?.chatter?.id {
                self.config.inlineService?.trackURLParseClick(sourceID: chatterID,
                                                                 sourceText: chatterStatus,
                                                                 type: .personalSig,
                                                                 originURL: url.absoluteString,
                                                                 scene: "profile_sign")
            }
        }

        titleView.statusLabel.telBlock = { [weak self] (tel) in
            guard let window = self?.delegate?.getCurrentWindow() else {
                assertionFailure("miss From VC")
                return
            }
            self?.navigator.open(body: OpenTelBody(number: tel), from: window)
        }

        titleView.onTap = { [weak self] in
            guard let self = self,
            let chat = self.chat else { return }
            self.delegate?.titleClicked()
            //刷新一下数据
            self.updateP2pSubTitleItem(chat: chat)
        }
    }

    private func updateTitle(chat: Chat) {
        let topActive = chat.type == .p2P ? chat.chatter?.focusStatusList.topActive : nil
        var topOfCenterItems = self.config.itemsOfTop ?? self.defaultTopOfCenterItems()
        if chat.isTeamVisitorMode {
            topOfCenterItems.removeAll(where: { $0 == .rightArrowItem })
        }
        self.titleView?.setTitle(
            title: self.config.fixedTitle ?? chat.displayWithAnotherName,
            isSpecialFocus: chat.type == .p2P && chat.chatter?.isSpecialFocus == true,
            focusStatus: topActive,
            tagDataItems: self.config.tagsGenerator.getTagDataItems(chat),
            chatterCountConfig: ChatterCountInfoView.Config(
                isHidden: chat.type != .group || chat.isFrozen,
                userCount: Int(chat.userCount),
                isUserCountVisible: chat.isUserCountVisible,
                chatterCount: Int(chat.chatterCount)
            ),
            itemsOfTop: topOfCenterItems,
            itemsOfbottomObservable: self.itemsOfbottomSubject
        )
        updateP2pSubTitleItem(chat: chat)
    }

    //更新单聊中名字下面的内容。可能是个性签名或管理员配置的额外字段
    private func updateP2pSubTitleItem(chat: Chat) {
        if chat.type != .p2P {
            //不是单聊 则不做任何处理
            return
        }
        if self.config.showExtraFields {
            self.getChatWindowFields { [weak self] fields in
                guard let self = self else { return }
                if fields.isEmpty {
                    self.titleView?.setExtraFields(fields: [])
                    self.updateChatterStatus(chat: chat)
                } else {
                    self.titleView?.setExtraFields(fields: fields)
                }
            } fail: { [weak self] _ in
                guard let self = self else { return }
                self.updateChatterStatus(chat: chat)
            }
        } else {
            updateChatterStatus(chat: chat)
        }
    }

    private func updateChatterStatus(chat: Chat) {
        guard let titleView = self.titleView else { return }
        /// 这里密聊的文字还维持原有的颜色
        titleView.statusLabel.textColor = self.config.darkStyle ? UIColor.ud.N300.nonDynamic : UIColor.ud.N500
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: titleView.statusLabel.textColor,
            .font: titleView.statusLabel.font,
            MessageInlineViewModel.iconColorKey: UIColor.ud.colorfulBlue,
            MessageInlineViewModel.tagTypeKey: TagType.link
        ]
        if let chatterStatus = chat.chatter?.description_p.text, !chatterStatus.isEmpty,
           let chatterID = chat.chatter?.id,
           let inlineService = self.config.inlineService {
            let startTime = CACurrentMediaTime()
            inlineService.replaceWithInlineTryMemory(
                sourceID: chatterID,
                sourceText: chatterStatus,
                type: .personalSig,
                strategy: .tryLocal,
                attributes: attributes,
                completion: { [weak self] result, _, _, sourceType in
                    guard let self = self else { return }
                    self.titleView?.setChatterStatus(chatterStatus: result)
                    self.config.inlineService?.trackURLInlineRender(sourceID: chatterID,
                                                                       sourceText: chatterStatus,
                                                                       type: .personalSig,
                                                                       sourceType: sourceType,
                                                                       scene: "chat_navibar",
                                                                       startTime: startTime,
                                                                       endTime: CACurrentMediaTime())
                }
            )
        } else {
            let chatterStatus = chat.chatter?.description_p.text ?? ""
            let result = chatterStatus.isEmpty ? nil : ParseTextLinkResult(attriubuteText: NSMutableAttributedString(string: chatterStatus,
                                                                                                                     attributes: attributes),
                                                                           urlRangeMap: [:],
                                                                           textUrlRangeMap: [:])
            titleView.setChatterStatus(chatterStatus: result)
        }
    }

    private func getChatWindowFields(succeed: @escaping (([String]) -> Void), fail: ((Error) -> Void)?) {
        let chat = self.chat
        guard let chat = chat,
              chat.type == .p2P,
              let chatter = chat.chatter else {
                  Self.logger.error("getChatWindowFields should be used in p2P chat, but found chat.type is: \(chat?.type), chatId: \(chat?.id)")
                  return
              }
        self.config.chatterAPI?.getUserChatWindowFields(userId: [chatter.id], forceServer: false)
            .flatMap({ [weak self] res -> Observable<Contact_V2_GetUserChatWindowFieldsResponse> in
                guard let self = self else { return .empty() }
                let fields = res.chatWindowFields[chatter.id]?.fieldOrders ?? []
                let strings = self.transfromFieldsToStrings(fields)
                DispatchQueue.main.async {
                    succeed(strings)
                }
                guard let oldDataUserId = res.oldDataUserIds.first else { return .empty() }
                return self.config.chatterAPI?.getUserChatWindowFields(userId: [oldDataUserId], forceServer: true) ?? .empty()
            })
            .subscribe { [weak self] res in
                guard let self = self else { return }
                let fields = res.chatWindowFields[chatter.id]?.fieldOrders ?? []
                let strings = self.transfromFieldsToStrings(fields)
                DispatchQueue.main.async {
                    succeed(strings)
                }
            } onError: { error in
                Self.logger.error("getUserChatWindowFields fail, \(chat.id) error: \(error)")
                if let fail = fail {
                    DispatchQueue.main.async {
                        fail(error)
                    }
                }
            }.disposed(by: disposeBag)
    }

    private func transfromFieldsToStrings(_ fields: [Contact_V2_GetUserProfileResponse.Field]) -> [String] {
        var strings = [String]()
        for field in fields {
            var options = JSONDecodingOptions()
            options.ignoreUnknownFields = true
            var string = ""
            switch field.fieldType {
            case .text, .cAlias:
                if let text = try? Contact_V2_GetUserProfileResponse.Text(jsonString: field.jsonFieldVal, options: options) {
                    string = setI18NVal(text.text)
                     }
            case .link:
                if let link = try? Contact_V2_GetUserProfileResponse.Href(jsonString: field.jsonFieldVal, options: options) {
                    string = setI18NVal(link.title)
                }
            case .cDescription:
                if let description = try? Chatter.Description(jsonString: field.jsonFieldVal) {
                    string = description.text
                }
            case .sDepartment:
                if let departments = try? Contact_V2_GetUserProfileResponse.Department(jsonString: field.jsonFieldVal, options: options),
                let departmentPath = departments.departmentPaths.first {
                    var path: String = ""
                    for department in departmentPath.departmentNodes {
                        let id = department.departmentID
                        if !id.isEmpty {
                            path.append(setI18NVal(department.departmentName) + "-")
                        }
                    }
                    if !path.isEmpty {
                        path.removeLast()
                    }
                    string = path
                }
            @unknown default:
                break
            }
            if !string.isEmpty {
                strings.append(string)
            }
        }
        return strings
    }

    private func setI18NVal(_ i18Names: Contact_V2_GetUserProfileResponse.I18nVal) -> String {
        let i18NVal = i18Names.i18NVals
        let currentLocalizations = LanguageManager.currentLanguage.rawValue.lowercased()
        if let result = i18NVal[currentLocalizations],
            !result.isEmpty {
            return result
        } else {
            return i18Names.defaultVal
        }
    }

    private func defaultTopOfCenterItems() -> [ChatNavigationItemType] {
        var items: [ChatNavigationItemType] = []
        items.append(.nameItem)
        items.append(.countItem)
        items.append(.specialFocusItem)
        items.append(.focusItem)
        items.append(.tagsItem)
        items.append(.rightArrowItem)
        return items
    }

    private func defaultBottomOfCenterItems() -> [ChatNavigationItemType] {
        var items: [ChatNavigationItemType] = []
        items.append(.statusItem)
        if self.userResolver.fg.staticFeatureGatingValue(with: "pc.show.user.admin.info") {
            items.append(.extraFieldsItem)
        }
        return items
    }

    private func setupBottomCenterItems(customBottomCenterItems: [ChatNavigationItemType]?) {
        self.bottomOfCenterItems = customBottomCenterItems ?? defaultBottomOfCenterItems()
        self.itemsOfbottomSubject.onNext(bottomOfCenterItems)
    }

    public func updateChat(_ chat: Chat) {
        self.chat = chat
    }
}

public struct ChatTitleViewStyle {
    enum AlignmentStyle {
        case left
        case center
    }
    let alignmentStyle: AlignmentStyle
    let showTitleArrow: Bool

    public static func defalutStyle() -> ChatTitleViewStyle {
        ChatTitleViewStyle(alignmentStyle: .center, showTitleArrow: true)
    }
}

private final class ChatTitleView: UIView {
    private var disposeBag = DisposeBag()

    fileprivate var onTap: (() -> Void)?

    private let topStackView = UIStackView()
    private let subTopStackView = UIStackView()
    private let contentStackView = UIStackView()

    private var chatTintColor: UIColor?

    private lazy var nameAttributes: [NSAttributedString.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        // 设置attributedText默认不会显示省略号，需要自己主动设置
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .medium),
            .foregroundColor: UIColor.ud.textTitle.chatTintColor(self.chatTintColor),
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()
    private let nameLabel: UILabel = UILabel()
    private lazy var focusImageView = FocusTagView(preferredSingleIconSize: 18)
    private lazy var specialFocusImageView: UDTag = {
        let config = UDTag.Configuration(
            icon: UDIcon.collectFilled,
            text: nil,
            height: 18,
            backgroundColor: .clear,
            cornerRadius: UDStyle.smallRadius,
            horizontalMargin: 0,
            iconTextSpacing: 0,
            textAlignment: .center,
            textColor: nil,
            iconSize: CGSize(width: 18, height: 18),
            iconColor: UIColor.ud.colorfulYellow,
            font: UIFont.systemFont(ofSize: 0)
        )

        let tagView = UDTag(configuration: config)
        return tagView
    }()

    fileprivate private(set) lazy var chatterCountInfoView = ChatterCountInfoView()

    private lazy var tagView: TagWrapperView = {
        let tagWrapperView = self.tagBulider.build()
        // iPad端tag会引起标题右侧focusItem跳动,需要默认设为hidden
        tagWrapperView.isHidden = true
        return tagWrapperView
    }()
    private lazy var tagBulider: ChatTagViewBuilder = {
        ChatTagViewBuilder()
    }()
    private lazy var goChatSettingArrow: UIImageView = {
        let view = UIImageView()
        view.image = Resources.goChatSettingArrow.chatTintColor(self.chatTintColor)
        return view
    }()

    fileprivate private(set) lazy var statusLabel: ChatterStatusLabel = {
        let label = ChatterStatusLabel()
        label.textColor = UIColor.ud.N600
        label.font = UIFont.systemFont(ofSize: 10)
        label.isHidden = true
        return label
    }()

    private lazy var extraFieldsView: MultiFieldsView = {
        let view = MultiFieldsView()
        view.isHidden = true
        return view
    }()

    init(tintColor: UIColor?, style: ChatTitleViewStyle) {
        self.chatTintColor = tintColor

        super.init(frame: .zero)

        topStackView.axis = .horizontal
        topStackView.distribution = .fill
        topStackView.alignment = .center
        topStackView.spacing = 4

        subTopStackView.axis = .horizontal
        subTopStackView.distribution = .fill
        subTopStackView.alignment = .center
        subTopStackView.spacing = 4

        addSubview(contentStackView)
        contentStackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        contentStackView.axis = .vertical
        contentStackView.spacing = 2
        switch style.alignmentStyle {
        case .left:
            contentStackView.alignment = .leading
        case .center:
            contentStackView.alignment = .center
        }
        goChatSettingArrow.isHidden = !style.showTitleArrow
        contentStackView.distribution = .fill
        contentStackView.addArrangedSubview(topStackView)
        chatterCountInfoView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configTopItems(types: [ChatNavigationItemType]) {
        var addArrangedSubStack = false
        for item in types {
            switch item {
            case .nameItem:
                topStackView.addArrangedSubview(nameLabel)
            case .rightArrowItem:
                topStackView.addArrangedSubview(goChatSettingArrow)
            case .countItem:
                addArrangedSubStack = true
                subTopStackView.addArrangedSubview(chatterCountInfoView)
            case .tagsItem:
                topStackView.addArrangedSubview(tagView)
            case .focusItem:
                topStackView.addArrangedSubview(focusImageView)
            case .specialFocusItem:
                topStackView.addArrangedSubview(specialFocusImageView)
            default:
                break
            }
        }
        if addArrangedSubStack {
            contentStackView.addArrangedSubview(subTopStackView)
        }
    }

    func configBottomItems(types: [ChatNavigationItemType]) {
        for item in types {
            switch item {
            case .statusItem:
                contentStackView.addArrangedSubview(statusLabel)
            case .extraFieldsItem:
                contentStackView.addArrangedSubview(extraFieldsView)
            default:
                break
            }
        }
    }

    func updateTintColor(tintColor: UIColor, infoTextColor: UIColor) {
        self.chatTintColor = tintColor
        if let image = goChatSettingArrow.image {
            goChatSettingArrow.image = image.chatTintColor(self.chatTintColor)
        }
        self.nameAttributes[.foregroundColor] = UIColor.ud.textTitle.chatTintColor(self.chatTintColor)
        if let name = self.nameLabel.attributedText?.string {
            let attrStr = NSAttributedString(string: name, attributes: self.nameAttributes)
            nameLabel.attributedText = LKStringFix.shared.fix(attrStr)
        }
        chatterCountInfoView.updateTextColor(infoTextColor)
    }

    func setTitle(title: String,
                  isSpecialFocus: Bool,//星标联系人
                  focusStatus: Chatter.FocusStatus?,
                  tagDataItems: [TagDataItem],
                  chatterCountConfig: ChatterCountInfoView.Config,
                  count: Int? = nil,
                  itemsOfTop: [ChatNavigationItemType],
                  itemsOfbottomObservable: Observable<[ChatNavigationItemType]>) {
        disposeBag = DisposeBag()

        self.configTopItems(types: itemsOfTop)

        let attrStr = NSAttributedString(string: title, attributes: self.nameAttributes)
        nameLabel.attributedText = LKStringFix.shared.fix(attrStr)

        specialFocusImageView.isHidden = !isSpecialFocus

        if let focus = focusStatus {
            focusImageView.isHidden = false
            focusImageView.config(with: focus)
        } else {
            focusImageView.isHidden = true
        }
        chatterCountInfoView.set(chatterCountConfig)
        self.tagBulider.update(with: tagDataItems)
        self.tagView.isHidden = tagDataItems.isEmpty

        shouldHiddSubTopView()

        itemsOfbottomObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (itemsOfbottom) in
                self?.configBottomItems(types: itemsOfbottom)
            })
            .disposed(by: disposeBag)
    }

    func setChatterStatus(chatterStatus: ParseTextLinkResult?) {
        if extraFieldsView.isHidden,
           let chatterStatus = chatterStatus {
            statusLabel.isHidden = false
            // 由于不显示工作状态图标，所以‘descriptionType’使用默认值: .onDefault
            statusLabel.set(
                description: chatterStatus.attriubuteText,
                descriptionType: .onDefault,
                autoDetectLinks: true,
                urlRangeMap: chatterStatus.urlRangeMap,
                textUrlRangeMap: chatterStatus.textUrlRangeMap,
                showIcon: false
            )
        } else {
            statusLabel.isHidden = true
        }
    }

    func setExtraFields(fields: [String?]) {
        let fields = fields.compactMap { field in
            (field?.isEmpty ?? true) ? nil : field
        }
        if !fields.isEmpty {
            statusLabel.isHidden = true
            extraFieldsView.isHidden = false
            if fields.count == 1 {
                extraFieldsView.setupFields(field: fields.first ?? "")
            } else {
                extraFieldsView.setupFields(field1: fields.first ?? "", field2: fields.last ?? "")
            }
        } else {
            extraFieldsView.isHidden = true
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.onTap?()
    }

    private func shouldHiddSubTopView() {
        subTopStackView.isHidden = tagView.isHidden && chatterCountInfoView.isHidden ? true : false
    }
}

fileprivate extension UIImage {
    func chatTintColor(_ color: UIColor?) -> UIImage? {
        if let tintColor = color {
            return self.ud.withTintColor(tintColor, renderingMode: .alwaysOriginal)
        }

        return self
    }
}

fileprivate extension UIColor {
    func chatTintColor(_ color: UIColor?) -> UIColor {
        if let tintColor = color {
            return tintColor
        }

        return self
    }
}

//展示管理员对『会话窗口』所勾选的字段，替换签名展示
//目前只支持勾选1或2个字段
private final class MultiFieldsView: UIView {
    private let dividerWidth: CGFloat = 1
    private let space: CGFloat = 4
    private var labels = [UILabel]()
    private var divider: UIView?

    func setupFields(field1: String, field2: String) {
        clean()
        let label1 = self.createLabel()
        label1.text = field1
        label1.textAlignment = .right
        let label2 = self.createLabel()
        label2.text = field2
        label2.textAlignment = .left
        labels.append(label1)
        labels.append(label2)
        divider = createDivider()
        updateLayoutForTwoFields()
    }

    func setupFields(field: String) {
        clean()
        let label = self.createLabel()
        label.text = field
        label.textAlignment = .center
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        labels.append(label)
    }

    private func clean() {
        for label in labels where label.superview != nil {
            label.removeFromSuperview()
        }
        labels.removeAll()
        if divider?.superview != nil {
            divider?.removeFromSuperview()
        }
        divider = nil
    }

    private func createLabel() -> UILabel {
        let label = UILabel()
        addSubview(label)
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.textColor = .ud.textPlaceholder
        return label
    }

    private func createDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = .ud.lineDividerDefault
        addSubview(divider)
        divider.snp.makeConstraints { make in
            make.height.equalTo(10)
            make.width.equalTo(1)
            make.centerY.equalToSuperview()
        }
        return divider
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.width > 0,
           labels.count == 2 {
            updateLayoutForTwoFields()
        }
    }

    private func updateLayoutForTwoFields() {
        guard labels.count == 2,
              let label1 = labels.first,
              let label2 = labels.last,
              let divider = self.divider else {
                  return
              }
        let fieldsMaxTotalWidth = self.bounds.width - dividerWidth - space * 2
        let width1 = widthForString(label1.text ?? "", withFont: label1.font)
        let width2 = widthForString(label2.text ?? "", withFont: label2.font)
        if width1 + width2 < fieldsMaxTotalWidth {
            let margin = (fieldsMaxTotalWidth - width1 - width2) / 2
            label1.snp.remakeConstraints { make in
                make.height.equalToSuperview()
                make.right.equalTo(divider.snp.left).offset(-space)
                make.left.equalToSuperview().offset(margin)
            }
            label2.snp.remakeConstraints { make in
                make.height.equalToSuperview()
                make.left.equalTo(divider.snp.right).offset(space)
            }
            return
        }
        label1.snp.remakeConstraints { make in
            make.height.left.equalToSuperview()
            make.right.equalTo(divider.snp.left).offset(-space)
        }
        label2.snp.remakeConstraints { make in
            make.height.right.equalToSuperview()
            make.left.equalTo(divider.snp.right).offset(space)
        }
        if width1 > width2 {
            label1.snp.makeConstraints { make in
                make.width.equalTo(width1).priority(.low)
            }
            label2.snp.makeConstraints { make in
                make.width.greaterThanOrEqualTo(min(width2, fieldsMaxTotalWidth / 2)).priority(.high)
            }
        } else {
            label1.snp.makeConstraints { make in
                make.width.greaterThanOrEqualTo(min(width1, fieldsMaxTotalWidth / 2)).priority(.high)
            }
            label2.snp.makeConstraints { make in
                make.width.equalTo(width2).priority(.low)
            }
        }
    }

    private func widthForString(_ string: String, withFont font: UIFont) -> CGFloat {
        let rect = (string as NSString).boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: font.pointSize + 10),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.width)
    }
}

private final class ChatterCountInfoView: UIView {

    public init() {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    struct Config {
        let isHidden: Bool
        let userCount: Int
        let isUserCountVisible: Bool
        let chatterCount: Int
    }

    func set(_ config: Config) {
        if config.isHidden {
            self.isHidden = true
            return
        }
        self.isHidden = false
        let botCount = config.chatterCount - config.userCount
        /// 判断群人数是否可见 && 是否存在机器人
        if config.isUserCountVisible {
            if botCount > 0 {
                self.status = .userAndBot(userCount: config.userCount, botCount: botCount)
            } else {
                self.status = .user(config.userCount)
            }
        } else {
            if botCount > 0 {
                self.status = .bot(botCount)
            } else {
                self.isHidden = true
            }
        }
    }

    func updateTextColor(_ textColor: UIColor) {
        self.countLabel.textColor = textColor
        self.userAndBotCountSubView.updateTextColor(textColor)
    }

    private lazy var userAndBotCountSubView: UserAndBotCountSubView = {
        let userAndBotCountSubView = UserAndBotCountSubView()
        return userAndBotCountSubView
    }()

    private lazy var countLabel: UILabel = {
        let countLabel = UILabel()
        countLabel.font = UIFont.systemFont(ofSize: 10)
        countLabel.textColor = UIColor.ud.textCaption
        countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        return countLabel
    }()

    private enum Status {
        case none
        case user(Int)
        case bot(Int)
        case userAndBot(userCount: Int, botCount: Int)
    }

    private var status: Status = .none {
        didSet {
            switch status {
            case .none:
                self.userAndBotCountSubView.removeFromSuperview()
                self.countLabel.removeFromSuperview()
            case .user(let userCount):
                userAndBotCountSubView.removeFromSuperview()
                addSubview(countLabel)
                countLabel.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }
                countLabel.text = BundleI18n.LarkMessageCore.Lark_Group_TitleNumberMembers(userCount)
            case .bot(let botCount):
                userAndBotCountSubView.removeFromSuperview()
                addSubview(countLabel)
                countLabel.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }
                countLabel.text = BundleI18n.LarkMessageCore.Lark_IM_GroupChat_NumBot_Text(botCount)
            case .userAndBot(let userCount, let botCount):
                countLabel.removeFromSuperview()
                addSubview(userAndBotCountSubView)
                userAndBotCountSubView.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }
                self.userAndBotCountSubView.updateCountNum(userCount: userCount, botCount: botCount)
            }
        }
    }
}

// 人类用户和机器人数量标签均显示
private final class UserAndBotCountSubView: UIView {
    private(set) lazy var userLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    private(set) lazy var botLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    private lazy var dividerLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    func updateTextColor(_ textColor: UIColor) {
        userLabel.textColor = textColor
        botLabel.textColor = textColor
    }

    init() {
        super.init(frame: .zero)
        self.addSubview(dividerLine)
        self.addSubview(userLabel)
        self.addSubview(botLabel)
        userLabel.textAlignment = .right
        userLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.height.equalToSuperview()
        }
        dividerLine.snp.makeConstraints { make in
            make.height.equalTo(8)
            make.width.equalTo(0.5)
            make.left.equalTo(userLabel.snp.right).offset(6)
            make.right.equalTo(botLabel.snp.left).offset(-6)
            make.top.equalToSuperview().offset(2.5)
        }
        botLabel.snp.makeConstraints { make in
            make.right.equalToSuperview()
        }
        self.userLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.botLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateCountNum(userCount: Int, botCount: Int) {
        userLabel.text = BundleI18n.LarkMessageCore.Lark_Group_TitleNumberMembers(userCount)
        botLabel.text = BundleI18n.LarkMessageCore.Lark_IM_GroupChat_NumBot_Text(botCount)
    }
}
