//  通用的列表功能项，全自适应布局，采用 StackView 来进行布局，可方便扩展
//  BTCommonCell.swift
//  SKBitable
//
//  Created by yinyuan on 2023/2/20.
//
import UIKit
import SKUIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignBadge
import UniverseDesignTag
import UniverseDesignCheckBox
import UniverseDesignInput
import UniverseDesignFont
import RxSwift
import RxCocoa
import RxRelay
import SKFoundation
import SKCommon

struct BTCommonDataModel {
    var groups: [BTCommonDataGroup]
    let contentExtendModel: ContentCustomViewType?
    let extra: String?

    var isCaptureAllowed: Bool

    init(groups: [BTCommonDataGroup], contentExtendModel: ContentCustomViewType? = nil, extra: String? = nil, isCaptureAllowed: Bool = true) {
        self.groups = groups
        self.contentExtendModel = contentExtendModel
        self.extra = extra
        self.isCaptureAllowed = isCaptureAllowed
    }
}

struct BTCommonDataGroup {
    enum CornersMode {
        case normal // 顶部和底部 cell 显示圆角
        case always // cell 总是显示圆角
    }

    let groupName: String?
    var items: [BTCommonDataItem]
    let showSeparatorLine: Bool?    // 是否在分组内显示分割线
    let cornersMode: CornersMode
    let leftIconTitleSpacing: CGFloat? //左边图标和标题文本之间的间距， 默认12
    
    init(
        groupName: String?,
        items: [BTCommonDataItem],
        showSeparatorLine: Bool? = nil,
        cornersMode: CornersMode = .normal,
        leftIconTitleSpacing: CGFloat? = nil
    ) {
        self.groupName = groupName
        self.items = items
        self.showSeparatorLine = showSeparatorLine
        self.cornersMode = cornersMode
        self.leftIconTitleSpacing = leftIconTitleSpacing
    }
}

struct BTCommonDataItemBackground {
    let color: UIColor?
    let selectedColor: UIColor?
}

/// 完全自定义 cell
struct BTCommonDataItemCustomCell {
    let reuseID: String
    let cellForRowProvider: ((_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell)
}

struct BTCommonDataItem {
    typealias SelectCallback = ((_ cell: BTCommonCell, _ id: String?, _ userInfo: Any?) -> Void)?

    let id: String?
    let selectable: Bool? // 是否显示按压态
    let selectCallback: SelectCallback
    let userInfo: Any?
    let customCell: BTCommonDataItemCustomCell? // 完全自定义 cell
    let background: BTCommonDataItemBackground?
    let leftIcon: BTCommonDataItemIconInfo?
    let leftIconTag: BTCommonDataItemIconInfo?
    let mainTitle: BTCommonDataItemTextInfo?
    let titleBadge: BTCommonDataItemBadgeInfo?
    let subTitle: BTCommonDataItemTextInfo?
    let rightInfo: BTCommonDataItemTextInfo?
    let switchInfo: BTCommonDataItemSwitchInfo?
    let rightBadge: BTCommonDataItemBadgeInfo?
    let rightIcon: BTCommonDataItemIconInfo?
    let tagText: String?
    
    var checkbox: Bool?
    
    var editable: Bool?
    
    var isSync: Bool?
    
    var isSelected: Bool?
    
    var placeholder: String?
    
    let edgeInset: UIEdgeInsets? // 内边距
    
    var hideRightIcon: Bool = false
    
    init(id: String? = nil,
         selectable: Bool? = true,
         selectCallback: ((_ cell: BTCommonCell, _ id: String?, _ userInfo: Any?) -> Void)? = nil,
         userInfo: Any? = nil,
         customCell: BTCommonDataItemCustomCell? = nil,
         background: BTCommonDataItemBackground? = nil,
         leftIcon: BTCommonDataItemIconInfo? = nil,
         leftIconTag: BTCommonDataItemIconInfo? = nil,
         mainTitle: BTCommonDataItemTextInfo? = nil,
         titleBadge: BTCommonDataItemBadgeInfo? = nil,
         subTitle: BTCommonDataItemTextInfo? = nil,
         rightInfo: BTCommonDataItemTextInfo? = nil,
         switchInfo: BTCommonDataItemSwitchInfo? = nil,
         rightBadge: BTCommonDataItemBadgeInfo? = nil,
         rightIcon: BTCommonDataItemIconInfo? = nil,
         tagText: String? = nil,
         edgeInset: UIEdgeInsets? = nil) {
        self.id = id
        self.selectable = selectable
        self.selectCallback = selectCallback
        self.userInfo = userInfo
        self.customCell = customCell
        self.background = background
        self.leftIcon = leftIcon
        self.leftIconTag = leftIconTag
        self.mainTitle = mainTitle
        self.titleBadge = titleBadge
        self.subTitle = subTitle
        self.rightInfo = rightInfo
        self.switchInfo = switchInfo
        self.rightBadge = rightBadge
        self.rightIcon = rightIcon
        self.tagText = tagText
        self.edgeInset = edgeInset
    }
}

struct BTCommonDataItemIconInfo {
    enum ItemIconAlignment {
        case center
        case top(offset: CGFloat)
    }
    
    let image: UIImage?       // 图片
    let url: String?          // 优先使用 image, 没有 image 使用 url
    let size: CGSize?         // 大小
    var color: UIColor?      // 颜色
    var highlightColor: UIColor?  // 高亮颜色
    let alignment: ItemIconAlignment?
    let customRender: ((_ imageView: UIView) -> Void)?   // 自定义渲染器，可自己往 imageView 上加子Layer/子view，需要自行处理好重用
    let clickCallback: ((_ view: UIView) -> Void)?
    
    init(image: UIImage? = nil,
         url: String? = nil,
         size: CGSize? = nil,
         color: UIColor? = nil,
         highlightColor: UIColor? = nil,
         alignment: ItemIconAlignment = .center,
         customRender: ((_: UIView) -> Void)? = nil,
         clickCallback: ((_ view: UIView) -> Void)? = nil) {
        self.image = image
        self.url = url
        self.size = size
        self.color = color
        self.highlightColor = highlightColor
        self.alignment = alignment
        self.customRender = customRender
        self.clickCallback = clickCallback
    }
}

struct BTCommonDataItemTextInfo {
    let text: String?          // 文本内容
    let color: UIColor?        // 文本颜色
    let font: UIFont?          // 字体大小
    let lineNumber: Int       // 行数
    let lineSpacing: CGFloat      // 行间距
    
    init(text: String? = nil,
         color: UIColor? = nil,
         font: UIFont? = nil,
         lineNumber: Int = 1,
         lineSpacing: CGFloat = 0) {
        self.text = text
        self.color = color
        self.font = font
        self.lineNumber = lineNumber
        self.lineSpacing = lineSpacing
    }
}

struct BTCommonDataItemSwitchInfo {
    let isOn: Bool        // 是否开启
    let switchCallback: ((_ switch: UISwitch, _ id: String?, _ userInfo: Any?) -> Void)?
    
    init(isOn: Bool = false, switchCallback: ((_: UISwitch, _: String?, _: Any?) -> Void)? = nil) {
        self.isOn = isOn
        self.switchCallback = switchCallback
    }
}

struct BTCommonDataItemBadgeInfo {
    let text: String?          // 文本内容
}

class BTCommonCell: UITableViewCell {
    
    var item: BTCommonDataItem?
    
    func update(item: BTCommonDataItem, group: BTCommonDataGroup, indexPath: IndexPath) {
        self.item = item
    }
}

final class BTCommonItemCell: BTCommonCell {
    
    private static let defaultEdgeInsets = UIEdgeInsets(horizontal: 16, vertical: 15)
    
    let bag = DisposeBag()
    
    lazy var checkbox = UDCheckBox(boxType: .multiple)
    
    lazy var input: BTUDConditionalTextField = {
        let config = UDTextFieldUIConfig(isShowBorder: false, clearButtonMode: .always, backgroundColor: UDColor.bgFloat, textColor: UDColor.textTitle, font: .systemFont(ofSize: 16), maximumTextLength: 50)
        let view = BTUDConditionalTextField(config: config)
        view.isHidden = true
        return view
    }()
    
    lazy var checkboxWrapper: UIView = {
        let view = UIView()
        view.addSubview(checkbox)
        checkbox.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
        }
        return view
    }()
    
    lazy var baseStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [mainStackView, input])
        view.axis = .vertical
        return view
    }()
    
    lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        view.isHidden = true
        return view
    }()
    
    lazy var mainStackView: UIStackView = {
        let view: UIStackView
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
            view = UIStackView(arrangedSubviews: [checkboxWrapper, leftIconWrapperView, titleVStackView, centerSpacingView, rightInfoView, rightSwitchView, rightBadgeView, rightIconButton])
        } else {
            view = UIStackView(arrangedSubviews: [leftIconWrapperView, titleVStackView, centerSpacingView, rightInfoView, rightSwitchView, rightBadgeView, rightIconButton])
        }
        view.axis = .horizontal
        view.alignment = .center
        view.spacing = 4
        return view
    }()
    
    lazy var leftIconWrapperView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()
    
    lazy var leftIconView: BTLightingIconView = {
        let view = BTLightingIconView()
        view.lightingTintColor = UDColor.iconN1
        return view
    }()
    
    private lazy var leftIconTagView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    lazy var leftIconTagWrapperView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()
    
    lazy var titleVStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [titleHStackView, subTitleView])
        view.axis = .vertical
        view.spacing = 4
        return view
    }()
    
    lazy var titleHStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [titleView, titleBadgeView, tagView, leftIconTagWrapperView])
        view.axis = .horizontal
        view.alignment = .center
        view.spacing = 4
        return view
    }()
    
    lazy var titleView: UILabel = {
        let view = UILabel()
        view.isHidden = true
        return view
    }()
    
    lazy var titleBadgeView: UDBadge = {
        let config = UDBadgeConfig(
            type: .text,
            style: .characterBGRed,
            text: "",
            showEmpty: false,
            contentStyle: .dotCharacterText
        )
        let view = UDBadge(config: config)
        view.isHidden = true
        view.setContentHuggingPriority(.required, for: .horizontal) // 不可拉伸
        view.setContentCompressionResistancePriority(.required, for: .horizontal)   // 不可压缩
        return view
    }()
    
    /// 中间的空白占位，用于分割调节左右侧view，使左侧view靠左，右侧view靠右
    lazy var centerSpacingView: UIView = {
        let view = UIView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal) // 不可拉伸
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)   // 不可压缩
        return view
    }()
    
    lazy var subTitleView: UILabel = {
        let view = UILabel()
        view.isHidden = true
        return view
    }()
    
    lazy var rightInfoView: UILabel = {
        let view = UILabel()
        view.isHidden = true
        view.textAlignment = .right
        return view
    }()
    
    lazy var rightSwitchView: SKSwitch = {
        let view = SKSwitch()
        view.isHidden = true
        view.addTarget(self, action: #selector(rightSwitchViewAction), for: .valueChanged)
        return view
    }()
    
    lazy var rightBadgeView: UDBadge = {
        let config = UDBadgeConfig(
            type: .text,
            style: .characterBGRed,
            text: "New",
            showEmpty: false,
            contentStyle: .dotCharacterText
        )
        let view = UDBadge(config: config)
        view.isHidden = true
        view.setContentHuggingPriority(.required, for: .horizontal) // 不可拉伸
        view.setContentCompressionResistancePriority(.required, for: .horizontal)   // 不可压缩
        return view
    }()
    
    lazy var rightIconButton: BTCommonButton = {
        let button = BTCommonButton()
        button.isHidden = true
        button.backgroundColor = .clear
        return button
    }()
    
    private lazy var tagView: UDTag = {
        let config = UDTag.Configuration(icon: nil,
                                         text: nil,
                                         height: 18,
                                         backgroundColor: UDColor.O100,
                                         cornerRadius: 4,
                                         horizontalMargin: 4,
                                         iconTextSpacing: 0,
                                         textAlignment: .center,
                                         textColor: UDColor.O600,
                                         iconSize: .zero,
                                         iconColor: nil,
                                         font: UIFont.systemFont(ofSize: 12, weight: .medium))
        let tag = UDTag(configuration: config)
        return tag
    }()

    private var margins: UIEdgeInsets = .zero

    private lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = [] // 目录这里的防护不需要toast,因为正文已经有了
        return preventer
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        self.backgroundColor = UDColor.bgFloat
        
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UDColor.N900.withAlphaComponent(0.1)

        let preventerContentView: UIView
        if ViewCapturePreventer.isFeatureEnable {
            preventerContentView = viewCapturePreventer.contentView
        } else {
            preventerContentView = UIView()
        }
        preventerContentView.backgroundColor = .clear
        contentView.addSubview(preventerContentView)
        preventerContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        preventerContentView.addSubview(baseStackView)
        updateBaseStackViewEdgeInset(BTCommonItemCell.defaultEdgeInsets)
        
        preventerContentView.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        leftIconWrapperView.addSubview(leftIconView)
        leftIconTagWrapperView.addSubview(leftIconTagView)
        
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
            input.snp.makeConstraints { make in
                make.height.equalTo(54)
            }
            input
                .input
                .rx
                .text
                .asObservable()
                .skip(1) // 不skip的话new出来就会回调一次
                .subscribe(onNext: { [weak self] newText in
                    guard let self = self else { return }
                    self
                        .item?
                        .selectCallback?(
                            self,
                            self.item?.id,
                            newText
                        )
                })
                .disposed(by: bag)
        }
        
        let tapGesture = UITapGestureRecognizer()
        contentView.addGestureRecognizer(tapGesture)
        tapGesture.delegate = self
        tapGesture.addTarget(self, action: #selector(didClickItem(sender:)))
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
//        if selected {
//            item?.selectCallback?(self, item?.id, item?.userInfo)
//        }
    }
    
    private var baseStackViewEdgeInset: UIEdgeInsets?
    private func updateBaseStackViewEdgeInset(_ edgeInset: UIEdgeInsets?) {
        guard let edgeInset = edgeInset else {
            return  // 传入空就不需要更新了
        }
        if edgeInset == baseStackViewEdgeInset {
            return  // 相同值也不需要更新了
        }
        self.baseStackViewEdgeInset = edgeInset
        baseStackView.snp.remakeConstraints { make in
            make.edges.equalTo(edgeInset)
        }
    }

    override func update(item: BTCommonDataItem, group: BTCommonDataGroup, indexPath: IndexPath) {
        update(item: item, group: group, indexPath: indexPath, isCaptureAllowed: true)
    }

    func update(isCaptureAllowed: Bool) {
        viewCapturePreventer.isCaptureAllowed = isCaptureAllowed
    }

    func update(item: BTCommonDataItem, group: BTCommonDataGroup, indexPath: IndexPath, isCaptureAllowed: Bool) {
        super.update(item: item, group: group, indexPath: indexPath)
        update(isCaptureAllowed: isCaptureAllowed)

        let sectionItemsCount: Int = group.items.count
        let isLast = indexPath.row == sectionItemsCount - 1
        
        var baseStackViewEdgeInset = item.edgeInset ?? BTCommonItemCell.defaultEdgeInsets
        
        if let text = item.tagText, !text.isEmpty {
            tagView.isHidden = false
            tagView.text = text
        } else {
            tagView.isHidden = true
        }
        
        if let leftIconTag = item.leftIconTag, (leftIconTag.image != nil || leftIconTag.customRender != nil) {
            leftIconTagWrapperView.isHidden = false
            leftIconTagView.setContentCompressionResistancePriority(.required, for: .horizontal)
            leftIconTagView.image = leftIconTag.image
            
            leftIconTagWrapperView.snp.makeConstraints { make in
                make.height.equalToSuperview()
                make.width.equalTo(leftIconTag.size?.width ?? 12)
            }
            
            if case let .top(topOffset) = leftIconTag.alignment {
                leftIconTagView.snp.remakeConstraints { make in
                    make.size.equalTo(leftIconTag.size ?? CGSize(width: 12, height: 12))
                    make.top.equalToSuperview().offset(topOffset)
                }
            } else {
                leftIconTagView.snp.remakeConstraints { make in
                    make.size.equalTo(leftIconTag.size ?? CGSize(width: 12, height: 12))
                    make.centerY.equalToSuperview()
                }
            }
            
            // 自定义渲染逻辑
            leftIconTag.customRender?(leftIconView)
        } else {
            leftIconTagWrapperView.isHidden = true
        }
        
        if item.selectCallback != nil && item.selectable == true {
            selectionStyle = .default
        } else {
            selectionStyle = .none  // 禁用点击效果
        }
        
        updateCorners(item: item, group: group, indexPath: indexPath)
        
        // 分割线处理
        if isLast {
            lineView.isHidden = true
        } else {
            lineView.isHidden = !(group.showSeparatorLine ?? true)
        }

        if let background = item.background {
            if let color = background.color {
                self.backgroundColor = color
            } else {
                self.backgroundColor = UDColor.bgFloat
            }
            if let selectedColor = background.selectedColor {
                selectedBackgroundView?.backgroundColor = selectedColor
            } else {
                selectedBackgroundView?.backgroundColor = UDColor.N900.withAlphaComponent(0.1)
            }
        }
        
        if let leftIcon = item.leftIcon, (leftIcon.image != nil || leftIcon.customRender != nil || leftIcon.url != nil) {
            leftIconWrapperView.isHidden = false
            leftIconView.setContentCompressionResistancePriority(.required, for: .horizontal)
            leftIconView.tintColor = UDColor.iconN1
            if let image = leftIcon.image {
                leftIconView.image = image
            } else if let urlString = leftIcon.url {
                leftIconView.image = nil
                leftIconView.update(urlString, grayScale: true)
            } else {
                leftIconView.image = nil
                DocsLogger.btError("[BTCommonCell] leftIconView.image = nil, should not attach here")
            }
            leftIconWrapperView.snp.remakeConstraints { make in
                make.height.equalToSuperview()
                make.width.equalTo(leftIcon.size?.width ?? 22)
            }
            
            if case let .top(topOffset) = leftIcon.alignment {
                leftIconView.snp.remakeConstraints { make in
                    make.size.equalTo(leftIcon.size ?? CGSize(width: 22, height: 22))
                    make.top.equalToSuperview().offset(topOffset)
                }
            } else {
                leftIconView.snp.remakeConstraints { make in
                    make.size.equalTo(leftIcon.size ?? CGSize(width: 22, height: 22))
                    make.centerY.equalToSuperview()
                }
            }
            
            // 自定义渲染逻辑
            leftIcon.customRender?(leftIconView)
        } else {
            leftIconWrapperView.isHidden = true
            leftIconView.snp.remakeConstraints { make in
                make.size.equalTo(0)
            }
            
            leftIconWrapperView.snp.remakeConstraints { make in
                make.size.equalTo(0)
            }
        }
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
            if let checkboxValue = item.checkbox {
                checkboxWrapper.isHidden = false
                checkboxWrapper.snp.remakeConstraints { make in
                    make.height.equalToSuperview()
                    make.width.equalTo(24)
                }
                checkbox.isSelected = checkboxValue
            } else {
                checkboxWrapper.isHidden = true
                checkboxWrapper.snp.remakeConstraints { make in
                    make.size.equalTo(0)
                }
            }
            
            if item.editable == true {
                mainStackView.isHidden = true
                input.isHidden = false
                input.text = item.mainTitle?.text
                input.placeholder = item.placeholder
                selectionStyle = .none  // 禁用点击效果
                // 这里优先级更高，会覆盖之前的 baseStackViewEdgeInset 设置
                baseStackViewEdgeInset = UIEdgeInsets(horizontal: 16, vertical: 0)
            } else {
                mainStackView.isHidden = false
                input.isHidden = true
            }
            
            if item.isSync == true {
                leftIconView.showLighting = true
            } else {
                leftIconView.showLighting = false
            }
        }
        
        titleVStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleVStackView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        if let mainTitle = item.mainTitle, let mainText = mainTitle.text, !mainText.isEmpty {
            titleView.isHidden = false
            titleView.numberOfLines = mainTitle.lineNumber
            
            let mutableParagraphStyle = NSMutableParagraphStyle()
            mutableParagraphStyle.lineSpacing = mainTitle.lineSpacing
            mutableParagraphStyle.lineBreakMode = .byTruncatingTail
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: mainTitle.font ?? UIFont.systemFont(ofSize: 16),
                .foregroundColor: mainTitle.color ?? UIColor.ud.textTitle,
                .paragraphStyle: mutableParagraphStyle
            ]
            
            let attributedText = NSMutableAttributedString(string: mainText, attributes: attributes)
            
            titleView.attributedText = attributedText
            titleVStackView.spacing = 4
        } else {
            titleView.isHidden = true
            titleVStackView.spacing = 0
        }
        
        if let subTitle = item.subTitle, let subText = subTitle.text, !subText.isEmpty {
            subTitleView.isHidden = false
            subTitleView.text = subText
            subTitleView.font = subTitle.font ?? UIFont.systemFont(ofSize: 14)
            subTitleView.textColor = subTitle.color ?? UIColor.ud.textPlaceholder
            subTitleView.numberOfLines = subTitle.lineNumber
        } else {
            subTitleView.isHidden = true
        }
        
        if let titleBadge = item.titleBadge {
            titleBadgeView.isHidden = false // 本行调用无效，因为 UDBadge 内部自己改了 isHidden
            let config = UDBadgeConfig(
                type: .text,
                style: .characterBGRed,
                text: titleBadge.text ?? "",
                showEmpty: false,
                contentStyle: .dotCharacterText
            )
            titleBadgeView.config = config
        } else {
            titleBadgeView.isHidden = true  // 本行调用无效，因为 UDBadge 内部自己改了 isHidden
            let config = UDBadgeConfig(
                type: .text,
                style: .characterBGRed,
                text: "",   // 只有这里设置为空字符串，才能成功隐藏
                showEmpty: false,
                contentStyle: .dotCharacterText
            )
            titleBadgeView.config = config
        }
        
        if let rightInfo = item.rightInfo {
            rightInfoView.isHidden = false
            rightInfoView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            rightInfoView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            rightInfoView.text = rightInfo.text
            rightInfoView.font = rightInfo.font ?? UIFont.systemFont(ofSize: 14)
            rightInfoView.textColor = rightInfo.color ?? UIColor.ud.textPlaceholder
            rightInfoView.numberOfLines = 10
        } else {
            rightInfoView.isHidden = true
        }
        
        if let rightBadge = item.rightBadge {
            rightBadgeView.isHidden = false // 本行调用无效，因为 UDBadge 内部自己改了 isHidden
            let config = UDBadgeConfig(
                type: .text,
                style: .characterBGRed,
                text: rightBadge.text ?? "",
                showEmpty: false,
                contentStyle: .dotCharacterText
            )
            rightBadgeView.config = config
        } else {
            rightBadgeView.isHidden = true  // 本行调用无效，因为 UDBadge 内部自己改了 isHidden
            let config = UDBadgeConfig(
                type: .text,
                style: .characterBGRed,
                text: "",   // 只有这里设置为空字符串，才能成功隐藏
                showEmpty: false,
                contentStyle: .dotCharacterText
            )
            rightBadgeView.config = config
        }
        
        if let rightIcon = item.rightIcon, (rightIcon.image != nil || rightIcon.customRender != nil), item.hideRightIcon != true {
            rightIconButton.isHidden = false
            rightIconButton.snp.remakeConstraints { make in
                make.height.equalToSuperview()
                make.width.equalTo(36)
            }
        } else {
            rightIconButton.isHidden = true
            rightIconButton.snp.remakeConstraints { make in
                make.size.equalTo(0)
            }
        }
        rightIconButton.update(data: item.rightIcon)
        
        if let switchInfo = item.switchInfo {
            rightSwitchView.isHidden = false
            rightSwitchView.setContentCompressionResistancePriority(.required, for: .horizontal)
            rightSwitchView.isOn = switchInfo.isOn
        } else {
            rightSwitchView.isHidden = true
        }
        
        // 上面逻辑确认了最终的 EdgeInset 后再统一设置，如果传入空表示不需要更新
        updateBaseStackViewEdgeInset(baseStackViewEdgeInset)
        
        setCustomSpacing(hasCheckBox: item.checkbox != nil, group: group)
    }

    private func updateCorners(item: BTCommonDataItem, group: BTCommonDataGroup, indexPath: IndexPath) {
        // 圆角处理
        let cell = self
        if group.cornersMode == .always {
            let cornerRadius: CGFloat = 8
            cell.layer.maskedCorners = .all
            cell.layer.cornerRadius = cornerRadius
            cell.layer.masksToBounds = true
        } else {
            let sectionItemsCount: Int = group.items.count
            let cornerRadius: CGFloat = 10
            let cell = self
            if indexPath.row == 0, indexPath.row == sectionItemsCount - 1 {
                cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                cell.layer.cornerRadius = cornerRadius
                cell.layer.masksToBounds = true
            } else if indexPath.row == 0 {
                cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                cell.layer.masksToBounds = true
                cell.layer.cornerRadius = cornerRadius
            } else if indexPath.row == sectionItemsCount - 1 {
                cell.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                cell.layer.masksToBounds = true
                cell.layer.cornerRadius = cornerRadius
            } else {
                cell.layer.maskedCorners = []
                cell.layer.cornerRadius = 0
                cell.layer.masksToBounds = true
            }
        }
        cell.selectedBackgroundView?.layer.maskedCorners = cell.layer.maskedCorners
        cell.selectedBackgroundView?.layer.cornerRadius = cell.layer.cornerRadius
    }
    
    // 自定义间距
    private func setCustomSpacing(hasCheckBox: Bool, group: BTCommonDataGroup) {
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
            mainStackView.setCustomSpacing(hasCheckBox ? 6 : (group.leftIconTitleSpacing ?? 12), after: leftIconWrapperView)
        } else {
            mainStackView.setCustomSpacing(group.leftIconTitleSpacing ?? 12, after: leftIconWrapperView)
        }
    }
    
    @objc
    private func rightSwitchViewAction() {
        item?.switchInfo?.switchCallback?(rightSwitchView, item?.id, item?.userInfo)
    }
    
    @objc
    private func didClickItem(sender: UITapGestureRecognizer) {
        item?.selectCallback?(self, item?.id, item?.userInfo)
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer is UITapGestureRecognizer else {
            return true
        }
        
        let gestureLocation = touch.location(in: self)
        
        if item?.rightIcon?.clickCallback != nil {
            let rightButtonFrame = rightIconButton.convert(rightIconButton.bounds, to: self)
            
            if rightButtonFrame.contains(gestureLocation) {
                return false
            }
        }
        
        return true
    }
}
