//
//  WorkPlaceIconCell.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/5/20.
//

import Foundation
import LarkUIKit
import LarkInteraction
import LarkSceneManager
import UniverseDesignBadge
import UniverseDesignColor
import UniverseDesignIcon
import ByteWebImage
import UniverseDesignTag
import UIKit
import RxSwift
import LarkContainer
import LarkSetting
import LKCommonsLogging
import LarkAccountInterface

protocol WorkPlaceIconCellDelegate: NSObjectProtocol {
    func iconLongGestureShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool

    func deleteItem(_ cell: UICollectionViewCell)
}

extension WorkPlaceIconCell {
    enum Layout {
        static let badgeAnchorOffset: CGSize = CGSize(width: -4.0, height: 4.0)
    }

    enum Style {
        static let badgeMaxNumber: Int = 999
    }
}

class WorkPlaceIconCell: WorkplaceBaseCell, UIGestureRecognizerDelegate {
    static let logger = Logger.log(WorkPlaceIconCell.self)

    // MARK: 成员属性
    /// 新应用蓝点尺寸
    static let newPointSide: CGFloat = 6.0
    /// 长按手势监听
    private var longPressAction: ((_ cell: WorkPlaceIconCell, _ gesture: UIGestureRecognizer) -> Void)?
    /// 是否是添加常用的样式item
    private var isAddAppItem: Bool = false
    /// 当前item的图标url
    private var currentIconUrl: String = ""
    /// 当前cell的title
    private var currentTitle: String = ""

    weak var delegate: WorkPlaceIconCellDelegate?

    /// 是否处于编辑态
    private var isEditing = false

    private var fromTemplate: Bool = false

    private var itemModel: ItemModel?

    private let titleFont: UIFont = .systemFont(ofSize: 12, weight: .regular)

    /// icon圆形图标
    lazy var iconView: WPMaskImageView = {
        let iconView = WPMaskImageView()
        iconView.clipsToBounds = true
        iconView.contentMode = .scaleToFill
        iconView.sqBorder = WPUIConst.BorderW.pt1
        iconView.sqRadius = WPUIConst.AvatarRadius.large
        return iconView
    }()

    /// 应用名称标题
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = titleFont
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        return titleLabel
    }()

    /// 标签
    let tagView = IconTagView()

    var badgeView: UDBadge? {
        return iconContentView.badge
    }

    /// 删除按钮
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKeyNoLimitSize(.deleteNormalColorful), for: .normal)
        button.addTarget(self, action: #selector(deleteItem), for: .touchUpInside)
        return button
    }()

    private lazy var pressedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.fillHover
        view.layer.cornerRadius = WPUIConst.hoverRadius
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var iconContentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        view.layer.cornerRadius = WPUIConst.AvatarRadius.large
        return view
    }()

    // MARK: 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestureRecognizer()
    }

    private var badgeService: WorkplaceBadgeService?
    private var configService: WPConfigService?
    private var userResolver: UserResolver?
    private var sectionType: SectionType = .favorite
    private var primaryTag: String = ""     // app 所属一级分类名
    private var secondaryTag: String = ""   // app 所属二级分类名

    private var badgeDisposeBag = DisposeBag()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        badgeDisposeBag = DisposeBag()
        badgeKey = nil
        badgeView?.config.number = 0
        tagView.isHidden = true
        super.prepareForReuse()
    }

    /// 初始化视图
    private func setupViews() {
         /// 按压态背景
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor.ud.fillHover
        selectedBackgroundView?.layer.cornerRadius = WPUIConst.hoverRadius
        selectedBackgroundView?.layer.masksToBounds = true

        /// 由于有长按手势识别后1s会触发弹窗事件，在这个状态要保持按压态，所以要使用自定义的view来显示按压态
        contentView.addSubview(pressedView)

        // icon背景图，当icon带透明度时，底部有bgColor颜色的view，解决拖动图标时的重叠问题
        contentView.addSubview(iconContentView)
        contentView.addSubview(titleLabel)  // 应用名称标题
        contentView.addSubview(tagView)
        contentView.addSubview(deleteButton)

        iconContentView.addSubview(iconView)    // icon圆形图标
        let badge = iconContentView.addBadge(.number)
        badge.config.anchor = .topRight
        badge.config.anchorType = .rectangle
        badge.config.anchorExtendType = .leading
        badge.config.anchorOffset = Layout.badgeAnchorOffset
        badge.config.maxNumber = Style.badgeMaxNumber

        setupConstraint()
        // 键鼠动效
        iconView.addPointer(.init(effect: .lift))
        // 删除按钮
        deleteButton.isHidden = true
        tagView.isHidden = true
        pressedView.isHidden = true
    }

    /// 初始化布局约束
    private func setupConstraint() {
        pressedView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        iconContentView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(appListItemInnerVGap)
            make.height.width.equalTo(WPUIConst.AvatarSize.large)
            make.centerX.equalToSuperview()
        }
        iconView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(iconView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.height.lessThanOrEqualTo(36)
            make.left.right.equalToSuperview().inset(4)
        }
        tagView.snp.makeConstraints { (make) in
            make.bottom.equalTo(iconView).offset(6)
            make.centerX.equalTo(iconView)
        }
        deleteButton.snp.makeConstraints { (make) in
            make.top.equalTo(iconView.snp.top).offset(-5.2)
            make.right.equalTo(iconView.snp.right).offset(5.2)
            make.height.width.equalTo(19)
        }
    }

    func setupGestureRecognizer() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleGesture(gesture:))
        )
        longPressGestureRecognizer.delegate = self
        self.addGestureRecognizer(longPressGestureRecognizer)
        let rightClick = RightClickRecognizer(target: self, action: #selector(handleGesture(gesture:)))
        self.addGestureRecognizer(rightClick)
    }

    @objc
    private func handleGesture(gesture: UIGestureRecognizer) {
        guard gesture is UILongPressGestureRecognizer || gesture is RightClickRecognizer else {
            return
        }
        if !fromTemplate && gesture.state == .began {
            longPressAction?(self, gesture)
            return
        }
        if fromTemplate {
            longPressAction?(self, gesture)
        }
    }

    /// 通过数据刷新UI的方法
    /// - Parameters:
    ///   - singleAppInfo: 应用信息
    ///   - isNewApp: 是否是新应用
    ///   - isCommon: 是否是常用应用
    func refreshCell(
        with item: ItemModel,
        isNewApp: Bool,
        fromTemplate: Bool,
        isEditing: Bool,
        badgeService: WorkplaceBadgeService,
        configService: WPConfigService,
        userResolver: UserResolver,
        sectionType: SectionType,
        primaryTag: String = "",
        secondaryTag: String = "",
        block: @escaping (_ cell: WorkPlaceIconCell, _ gesture: UIGestureRecognizer) -> Void
    ) {
        guard let singleAppInfo = item.getSingleAppInfo() else {
            Self.logger.error("get singleAppInfo from item failed, refresh item failed")
            return
        }
        pressedView.isHidden = true
        self.badgeService = badgeService
        self.configService = configService
        self.userResolver = userResolver
        self.sectionType = sectionType
        self.primaryTag = primaryTag
        self.secondaryTag = secondaryTag
        self.workplaceItem = item.item
        self.longPressAction = block
        self.fromTemplate = fromTemplate
        self.itemModel = item
        self.isEditing = isEditing

        // badge
        if fromTemplate {
            subscribeTemplateBadge()
        } else {
            subscribeWorkplaceBdage()
        }

        isAddAppItem = singleAppInfo.isAddAppItem
        currentIconUrl = singleAppInfo.imageKey
        /// 清理上一次复用时的图片内容
        self.iconView.image = nil
        titleLabel.text = ""
        titleLabel.isHidden = false
        /// 处理添加应用item
        if isAddAppItem {
            updateAddAppItem()
            return
        }
        /// 更新icon刷新(旧工作台的icon加载有特化逻辑，新版的url会加载失败)
        let iconUrl = singleAppInfo.imageKey
        let imageResource = singleAppInfo.getIconResource()

        iconView.bt.setLarkImage(
            with: imageResource,
            cacheName: LarkImageService.shared.thumbCache.name,
            completion: { [weak self] result in
                /// 为什么这里还需重新设置，因为图片资源返回的时候，这个cell对应的model发生了变化
                guard let self = self else {
                    Self.logger.error("WorkPlaceIconCell reference missed, refresh cell failed")
                    return
                }
                var image: UIImage?
                if let img = try? result.get().image {
                    self.iconView.backgroundColor = UIColor.clear
                    image = img
                }
                if self.isAddAppItem {
                    self.updateAddAppItem()
                } else if iconUrl == self.currentIconUrl {
                    self.iconView.hideMask(false).image = image
                } else {    // 如果展示的不是正在加载的图片，则不刷新
                    Self.logger.warn("WorkPlaceIconCell img refresh confused, not refresh img")
                }
            }
        )
        /// 更新标题
        updateTitle(title: singleAppInfo.name, isNewApp: isNewApp)
        updateEditStatus(isEditing)
    }

    /// 老版工作台 badge 监听，新版工作台不走这一套。
    private func subscribeWorkplaceBdage() {
        badgeKey = itemModel?.badgeKey()
    }

    /// 模版化工作台 badge 监听。
    private func subscribeTemplateBadge() {
        guard !isEditing, /* 编辑态的 icon 不需要监听 badge，如果要监听，记得在 subscribe 中处理好 isEditing 判断。 */
              let appId = itemModel?.appId,
              let appAbility = itemModel?.item.badgeAbility(),
              let badgeService = badgeService else {
            badgeView?.config.number = 0
            return
        }
        // 修复工作台 icon 角标闪动问题，规避异步监听导致的 icon 角标延迟刷新
        badgeView?.config.number = badgeService.getAppBadgeNumber(for: appId, appAbility: appAbility)
        badgeService
            .subscribeApp(for: appId, appAbility: appAbility)
            .subscribe(onNext: { [weak self] badgeNumber in
                Self.logger.info("did received app badge number", additionalData: [
                    "badgeNumber": "\(badgeNumber)",
                    "appId": appId,
                    "appAbility": "\(appAbility)"
                ])
                self?.badgeView?.config.number = badgeNumber
            }).disposed(by: badgeDisposeBag)
    }

    /// 更新样式为添加应用
    private func updateAddAppItem() {
        iconView.hideMask(true).image = Resources.add_app
        titleLabel.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AddApp
        tagView.isHidden = true
    }

    func updatePressState(isPressed: Bool) {
        pressedView.isHidden = !isPressed
    }

    /// 编辑态
    private func updateEditStatus(_ editing: Bool) {
        let deletable = (itemModel?.isDeletable == true)
        let sortable = (itemModel?.isSortable == true)

        let (tagConfig, hiddenTag) = itemModel?.makeTagConfig(for: editing) ?? (.default, true)
        tagView.config = tagConfig
        tagView.isHidden = hiddenTag

        if fromTemplate && editing {
            deleteButton.isHidden = !deletable
            let badgeNumber = badgeView?.config.number ?? 0
            badgeView?.isHidden = deletable || sortable || badgeNumber <= 0
            if sortable {
                startShake()
            }
        } else {
            deleteButton.isHidden = true
            stopShake()
        }
    }

    func cellStartDragging() {
        deleteButton.isHidden = true
        badgeView?.isHidden = true
        titleLabel.isHidden = true
    }

    func cellEndDragging() {
        let canDel = fromTemplate && (itemModel?.isDeletable == true)
        deleteButton.isHidden = !isEditing || !canDel
        badgeView?.forceUpdate() // 不能使用原 number 更新，number 前后相同可能会被组件忽略刷新
        titleLabel.isHidden = false
    }

    /// 刷新标题
    private func updateTitle(title: String, isNewApp: Bool) {
        self.currentTitle = title
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 18
        paragraphStyle.minimumLineHeight = 18
        paragraphStyle.alignment = .center

        var adjustTitle = title
        if isNewApp, !holdFirstWord(title: title) {
            /// 展示蓝点&第一个单词无法放下第一行
            /// 开放平台 非 Office 场景，暂时逃逸
            // swiftlint:disable ban_linebreak_byChar
            paragraphStyle.lineBreakMode = .byCharWrapping
            // swiftlint:enable ban_linebreak_byChar
            adjustTitle = adjustTitleLongText(title: title)
        } else {
            paragraphStyle.lineBreakMode = .byTruncatingTail
        }

        if isNewApp {
            /// 蓝点标记
            let attchment = NSTextAttachment()
            attchment.bounds = CGRect(
                x: 0,
                y: 2,
                width: WorkPlaceIconCell.newPointSide,
                height: WorkPlaceIconCell.newPointSide
            )
            attchment.image = Resources.blue_dot
            let attchmentString = NSAttributedString(attachment: attchment)
            /// 附着到title左侧
            let attributeString = NSMutableAttributedString(string: adjustTitle)
            attributeString.insert(attchmentString, at: 0)
            attributeString.insert(NSMutableAttributedString(string: " "), at: 1)
            /// 行高
            attributeString.addAttribute(
                .paragraphStyle,
                value: paragraphStyle,
                range: NSRange(location: 0, length: attributeString.length)
            )
            /// 展示带蓝点的title
            titleLabel.attributedText = attributeString
        } else {
            let attrString = NSMutableAttributedString(string: adjustTitle)
            attrString.addAttribute(
                .paragraphStyle,
                value: paragraphStyle,
                range: NSRange(location: 0, length: attrString.length)
            )
            titleLabel.attributedText = attrString
        }
    }
    /// 消除新应用蓝点标记
    func cleanNewAppFlag() {
        titleLabel.text = self.currentTitle
    }

    /// 老版本 badge update 响应，模版化不做处理
    override func onBadgeUpdate() {
        guard !fromTemplate else { return }
        let badgeNumber = self.getBadge()
        self.badgeView?.config.number = badgeNumber ?? 0
    }

    /// 超长文案处理
    private func adjustTitleLongText(title: String) -> String {
        var adjustTitle = title
        let originWidth = title.size(withAttributes: [.font: titleFont]).width  // 这样的计算方式有误差，有时候计算结果能放下，实际无法放下
        let placeWidth = ItemModel.iconItemWidth * 2 - 26   // 预留蓝点空间

        if originWidth > placeWidth {
            // 文案超长
            let maxNum = title.count - 1
            let point = title.index(title.startIndex, offsetBy: maxNum)
            var testStr = title.substring(to: point)
            var testWidth = testStr.size(withAttributes: [.font: titleFont]).width

            let adjustTitleWidth = placeWidth - 30   // 预留...的宽度
            if testWidth > adjustTitleWidth {
                for i in 1..<(title.count - 1) {
                    let tryPoint = title.index(title.startIndex, offsetBy: maxNum - i)
                    testStr = title.substring(to: tryPoint)
                    testWidth = testStr.size(withAttributes: [.font: titleFont]).width
                    if testWidth < adjustTitleWidth {
                        adjustTitle = testStr.appending("...")
                        break
                    }
                }
            } else {
                adjustTitle = testStr.appending("...")
            }
        }
        return adjustTitle
    }

    /// 有蓝点的情况，是否能放下第一个
    private func holdFirstWord(title: String) -> Bool {
        let placeWidth = ItemModel.iconItemWidth - 26
        let originWidth = title.size(withAttributes: [.font: titleFont]).width
        if placeWidth > originWidth {
            return true
        } else {
            let strs = title.components(separatedBy: " ")
            if strs.count > 1 {
                let firstWordWidth = strs[0].size(withAttributes: [.font: titleFont]).width
                return firstWordWidth < placeWidth
            } else {
                return false
            }
        }
    }

    @objc
    private func deleteItem() {
        delegate?.deleteItem(self)
    }

    private func startShake() {
        let vibrateAnim = CAKeyframeAnimation()
        vibrateAnim.keyPath = "transform.rotation"
        let angle = Double.pi / 90
        vibrateAnim.values = [0, -angle, 0, angle, 0]
        vibrateAnim.repeatCount = MAXFLOAT
        vibrateAnim.isRemovedOnCompletion = false
        vibrateAnim.duration = 0.5
        vibrateAnim.timeOffset = Double.random(in: 0...0.1)
        let layer: CALayer = self.layer
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.add(vibrateAnim, forKey: "vibrate")
    }

    private func stopShake() {
        let layer: CALayer = self.layer
        layer.removeAnimation(forKey: "vibrate")
    }

    /// 获取每个应用对应的Scene
    override func supportDragScene() -> Scene? {
        guard let appItem = self.workplaceItem else {
            Self.logger.error("workplace iconcell to scene failed, workplaceItem is nil", tag: "workplace")
            return nil
        }
        guard let appAbility = appItem.badgeAbility(),
              appAbility == .web else {
            Self.logger.error("workplace iconcell to scene failed, appAbility is not h5", tag: "workplace")
            return nil
        }
        if configService?.fgValue(for: .openH5SceneInWebWay) ?? false {
            Self.logger.info("open h5 in web way with id \(appItem.sceneId)")
            let workplaceScene = LarkSceneManager.Scene(
                key: WorkPlaceScene.webWaySceneKey,
                id: appItem.sceneId,
                title: appItem.name,
                needRestoration: true,
                windowType: WorkPlaceScene.WindowType.web_app.rawValue,
                createWay: WorkPlaceScene.CreateWay.drag.rawValue
            )
            return workplaceScene
        } else {
            var itemData: Data?
            do {
                itemData = try JSONEncoder().encode(appItem)
            } catch {
                Self.logger.error("workplace iconcell to scene failed", tag: "workplace", error: error)
            }
            if let itemJsonData = itemData, let itemString = String(data: itemJsonData, encoding: .utf8) {
                let workplaceScene = LarkSceneManager.Scene(
                    key: WorkPlaceScene.sceneKey,
                    id: appItem.sceneId,
                    needRestoration: true,
                    userInfo: [WorkPlaceScene.itemKey: itemString],
                    windowType: WorkPlaceScene.WindowType.web_app.rawValue,
                    createWay: WorkPlaceScene.CreateWay.drag.rawValue
                )
                return workplaceScene
            }
        }
        return nil
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard (gestureRecognizer as? UILongPressGestureRecognizer) != nil else {
            return true
        }
        return delegate?.iconLongGestureShouldBegin(gestureRecognizer) ?? true
    }
}

extension WorkPlaceIconCell: WorkPlaceCellExposeProtocol {
    var exposeId: String {
        guard let appInfo = itemModel?.getSingleAppInfo(), !appInfo.appId.isEmpty else {
            return ""
        }
        let allApp = "workplace_all_app"    // 原生工作台「全部应用」
        let myCommon = "my_common"          // 模板工作台「我的常用/最近使用」
        let prefix = "app_"
        let isSubTagAsDiff = primaryTag == allApp || primaryTag == myCommon
        let tagName = isSubTagAsDiff ? secondaryTag : ""
        return prefix + tagName + "_" + (itemModel?.itemID ?? "") + "_" + appInfo.appId
    }

    func didExpose() {
        guard let appInfo = itemModel?.getSingleAppInfo(), !appInfo.name.isEmpty else {
            return
        }

        let userService = try? userResolver?.resolve(assert: PassportUserService.self)
        let tenantId = userService?.userTenant.tenantID ?? ""
        let eventName = WorkplaceTrackEventName.openplatform_workspace_application_view.rawValue

        WPEventReport(name: eventName, userId: userResolver?.userID, tenantId: tenantId)
            .set(key: WorkplaceTrackEventKey.application_id.rawValue, value: appInfo.appId)
            .set(key: WorkplaceTrackEventKey.module.rawValue, value: sectionType.module)
            .set(key: WorkplaceTrackEventKey.app_name.rawValue, value: appInfo.name)
            .post()
    }
}
