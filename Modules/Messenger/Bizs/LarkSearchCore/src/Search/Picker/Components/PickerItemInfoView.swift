//
//  PickerItemInfoView.swift
//  LarkSearchCore
//
//  Created by Xiexufeng on 2022/11/11.
//

import Foundation
import LarkTag
import LarkUIKit
import RxSwift
import SnapKit
import UIKit
import LarkListItem
import LarkSearchFilter

public struct PickerItemProps {
    public var checkStatus: PickerItemInfoView.CheckBoxStaus = .invalid
    public var description: NSAttributedString?
    public var descriptionType: PickerItemInfoView.DescriptionType?

    public var avatarKey: String = ""
    public var avatarID: String = ""

    public var infoText: String = ""

    public var timeString: String = ""

    public var tags: [TagType] = []
    public var additionalTags: [TagType] = []
}

public struct PickerItemUIConfig {
    public var maxTags: Int = 3
    public var maxAdditionalTags: Int = 3

    public var infoColor: UIColor = UIColor.ud.textPlaceholder
    public var infoFont: UIFont = UIFont.systemFont(ofSize: 14)

    public var secondaryInfoColor: UIColor = UIColor.ud.textPlaceholder
    public var secondaryInfoFont: UIFont = UIFont.systemFont(ofSize: 14)
}

open class PickerItemInfoView: UIView {
    public enum CheckBoxStaus {
        case invalid, selected, unselected, defaultSelected, disableToSelect
    }

    public enum DescriptionType: Int {
        public typealias RawValue = Int

        /// 默认
        case onDefault // = 0

        /// 出差
        case onBusiness // = 1

        /// 请假
        case onLeave // = 2

        /// 开会
        case onMeeting // = 3

        public init() {
          self = .onDefault
        }

        public init?(rawValue: Int) {
          switch rawValue {
          case 0: self = .onDefault
          case 1: self = .onBusiness
          case 2: self = .onLeave
          case 3: self = .onMeeting
          default: return nil
          }
        }

        public var rawValue: Int {
          switch self {
          case .onDefault: return 0
          case .onBusiness: return 1
          case .onLeave: return 2
          case .onMeeting: return 3
          }
        }
    }

    /// CheckBox Status
    public var checkStatus: CheckBoxStaus = .invalid {
        didSet {
            switch self.checkStatus {
            case .invalid:
                checkBox.isHidden = true
            case .selected:
                checkBox.isHidden = false
                updateCheckBox(selected: true, enabled: true)
            case .unselected:
                checkBox.isHidden = false
                updateCheckBox(selected: false, enabled: true)
            case .defaultSelected:
                checkBox.isHidden = false
                self.updateCheckBox(selected: true, enabled: false)
            case .disableToSelect:
                checkBox.isHidden = false
                self.updateCheckBox(selected: false, enabled: false)
            }
        }
    }

    public let checkBox = LKCheckbox(boxType: .multiple)
    public let avatarView = PickerAvatarView()
    public let avatarSize: CGFloat = 40

    public var textContentView: UIStackView {
        return nameStatusView.textContentView
    }
    public var nameLabel: ItemLabel {
        return nameStatusView.nameLabel
    }
    public var nameTag: TagWrapperView {
        return nameStatusView.nameTag
    }
    public var statusLabel: StatusLabel {
        return nameStatusView.statusLabel
    }
    public var timeLabel: LarkTimeLabel {
        return nameStatusView.timeLabel
    }

    public var info: PickerSearchItemInfo? {
        didSet {
            guard let info = info else { return }
            setInfo(info)
        }
    }

    // MARK: - Private
    private func setInfo(_ info: PickerSearchItemInfo) {
        setAvatar(info)
        nameLabel.attributedText = info.title

        setSummary(info)

        layoutAvatarView(info)
    }

    private func setAvatar(_ info: PickerSearchItemInfo) {
        if !info.avatarKey.isEmpty {
            avatarView.setAvatarByIdentifier(info.avatarId ?? "",
                                             avatarKey: info.avatarKey,
                                             markScene: true,
                                             avatarSize: 48)
        } else {
            if let backupImage = info.avatarBackgroundImage {
                avatarView.image = backupImage
            } else if let avatarImageURL = info.avatarImageURL, !avatarImageURL.isEmpty {
                avatarView.setAvatarByImageURL(URL(string: avatarImageURL))
            } else {
                // 邮件联系人兜底需要展示前两个字符
                avatarView.image = SearchImageUtils.generateAvatarImage(withTitle: info.title.string, length: 2)
            }
        }
    }

    private func setSummary(_ info: PickerSearchItemInfo) {
        let summary = info.summary
        let summaryEmpty: Bool = summary?.length == 0

        let attrSummary: NSMutableAttributedString? = {
            if let s = summary {
                var attr = NSMutableAttributedString(attributedString: s)
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineSpacing = 6
                paragraph.lineBreakMode = info.isChatter ? .byTruncatingHead : .byTruncatingTail
                let dict = [NSAttributedString.Key.paragraphStyle: paragraph]
                attr.addAttributes(dict, range: NSRange(location: 0, length: s.length))
                return attr
            } else {
                return nil
            }
        }()
        infoLabel.attributedText = attrSummary
        infoLabel.isHidden = summaryEmpty
        infoLabel.numberOfLines = info.isDepartment ? 20 : 1
    }

    private func layoutAvatarView(_ info: PickerSearchItemInfo) {
        let hasSummary: Bool = !(info.summary?.length == 0)
        contentView.alignment = hasSummary ? .top : .center
        avatarContentView.transform = CGAffineTransform(translationX: 0, y: hasSummary ? -3 : 0)
    }

    /* description */
    public lazy var infoLabel: ItemLabel = {
        let infoLabel = ItemLabel()
        infoLabel.textColor = UIColor.ud.textPlaceholder
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        infoLabel.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        infoLabel.textChangedCallback = { [weak self] text, attText in
            guard let nameStatusView = self?.nameStatusView,
                  nameStatusView.superview != nil else {
                return
            }
            if text?.isEmpty ?? true,
               (attText?.length ?? 0) == 0 {
                // 如果infoText为空，相当于nameStatusAndInfoStackView只包含nameStatusView，此时让nameStatusView填充父布局（相当于居中）
                nameStatusView.snp.remakeConstraints { make in
                    make.top.bottom.equalToSuperview()
                }
            } else {
                nameStatusView.snp.removeConstraints()
            }
        }
        return infoLabel
    }()

    public lazy var secondaryInfoLabel: ItemLabel = {
        let secondaryInfoLabel = ItemLabel()
        secondaryInfoLabel.textColor = UIColor.ud.textPlaceholder
        secondaryInfoLabel.font = UIFont.systemFont(ofSize: 14)
        secondaryInfoLabel.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        secondaryInfoLabel.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        secondaryInfoLabel.isHidden = true
        return secondaryInfoLabel
    }()

    public let additionalIcon = TagWrapperView()
    public let bottomSeperator = UIView()

    public var rightMarginConstraint: Constraint!

    private let disposeBag = DisposeBag()

    /// horizontal content view, include checkBox + avatar + content StackView
    public lazy var contentView: UIStackView = {
        // CheckBox + Avatar
        let contentView = UIStackView()
        contentView.axis = .horizontal
        contentView.alignment = .center
        contentView.spacing = 12
        return contentView
    }()
    private let avatarContentView = UIStackView()
    private let checkBoxSpace = UIView()

    /// name + status
    public let nameStatusView = LarkListNameStatusView()

    /// name + status + info stackView
    private lazy var nameStatusAndInfoStackView: UIStackView = {
        let nameStatusAndInfoStackView = UIStackView()
        nameStatusAndInfoStackView.axis = .vertical
        nameStatusAndInfoStackView.spacing = 7
        nameStatusAndInfoStackView.alignment = .leading
        nameStatusAndInfoStackView.distribution = .fill
        return nameStatusAndInfoStackView
    }()

    /// name + status + info + icon stackView
    private lazy var nameStatusInfoAndIconStackView: UIStackView = {
        let nameStatusInfoAndIconStackView = UIStackView()

        // nameStatus + info + icon
        nameStatusInfoAndIconStackView.axis = .horizontal
        nameStatusInfoAndIconStackView.spacing = 8
        nameStatusInfoAndIconStackView.alignment = .center
        nameStatusInfoAndIconStackView.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        nameStatusInfoAndIconStackView.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        return nameStatusInfoAndIconStackView
    }()

    public init() {
        super.init(frame: CGRect.zero)

        addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(12)
            rightMarginConstraint = make.right.equalToSuperview().offset(-16).constraint
        }

        setupAvatarContentView()
        contentView.addArrangedSubview(avatarContentView)
        contentView.addArrangedSubview(nameStatusInfoAndIconStackView)

        /// not intercept the cell click event
        checkBox.isUserInteractionEnabled = false
        checkBox.snp.makeConstraints({ make in
            make.size.equalTo(LKCheckbox.Layout.iconMidSize)
        })

        var checkBoxAfterSpace: Constraint!
        checkBoxSpace.snp.makeConstraints {
            checkBoxAfterSpace = $0.width.equalTo( checkBox.isHidden ? 6 : 12 ).constraint
            $0.height.equalTo(0)
        }

        checkBox.rx.methodInvoked(#selector(setter: checkBox.isHidden))
            .subscribe { [weak checkBox](event) in
                guard case .next = event, let checkBox = checkBox else { return }
                // hidden时，左间距10 + 6 = 16, visible时，后面和原来一样有16的间距
                checkBoxAfterSpace.update(offset: checkBox.isHidden ? 6 : 12)
            }
            .disposed(by: disposeBag)

        avatarView.snp.makeConstraints({ make in
            make.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
        })
        contentView.setCustomSpacing(12, after: avatarView) // 如果avatarView隐藏，后面的内容往前面补上

        nameStatusAndInfoStackView.addArrangedSubview(nameStatusView)
        nameStatusView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
        }
        nameStatusAndInfoStackView.addArrangedSubview(infoLabel)
        nameStatusAndInfoStackView.addArrangedSubview(secondaryInfoLabel)

        nameStatusInfoAndIconStackView.addArrangedSubview(nameStatusAndInfoStackView)
        nameStatusInfoAndIconStackView.addArrangedSubview(additionalIcon)

        bottomSeperator.backgroundColor = UIColor.ud.commonTableSeparatorColor
        addSubview(bottomSeperator)
        bottomSeperator.snp.makeConstraints { (make) in
            make.left.equalTo(nameStatusView.snp.left)
            make.height.equalTo(1 / UIScreen.main.scale)
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(12)
        }
    }

    // MARK: - Private UI
    private func setupAvatarContentView() {
        avatarContentView.axis = .horizontal
        avatarContentView.alignment = .center
        contentView.addArrangedSubview(avatarContentView)
        avatarContentView.snp.makeConstraints {
            $0.height.equalTo(48)
        }

        avatarContentView.addArrangedSubview(checkBox)
        avatarContentView.addArrangedSubview(checkBoxSpace)
        avatarContentView.addArrangedSubview(avatarView)
    }

    public func setUIConfig(_ uiConfig: PickerItemUIConfig) {
        self.nameTag.maxTagCount = uiConfig.maxTags
        self.additionalIcon.maxTagCount = uiConfig.maxAdditionalTags

        self.infoLabel.textColor = uiConfig.infoColor
        self.infoLabel.font = uiConfig.infoFont

        self.secondaryInfoLabel.textColor = uiConfig.secondaryInfoColor
        self.secondaryInfoLabel.font = uiConfig.secondaryInfoFont
    }

    public func setProps(_ props: PickerItemProps) {
        self.checkStatus = props.checkStatus

        self.setDescription(props.description, descriptionType: props.descriptionType)

        self.avatarView.setAvatarByIdentifier(props.avatarID, avatarKey: props.avatarKey, avatarSize: avatarSize)

        self.infoLabel.text = props.infoText

        self.timeLabel.timeString = props.timeString

        self.nameTag.setTags(props.tags)
        self.additionalIcon.setTags(props.additionalTags)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Set description
    /// - Parameters:
    ///   - description:
    ///   - descriptionType:
    public func setDescription(_ description: NSAttributedString?,
                             descriptionType: DescriptionType?) {
        setDescription(description, descriptionType: descriptionType, urlRangeMap: [:], textUrlRangeMap: [:])
    }

    /// Set description
    /// - Parameters:
    ///   - description:
    ///   - descriptionType:
    public func setDescription(_ description: NSAttributedString?,
                             descriptionType: DescriptionType?,
                             urlRangeMap: [NSRange: URL],
                             textUrlRangeMap: [NSRange: String]) {
        var image: UIImage?
        if description?.string.isEmpty ?? true {
            self.statusLabel.isHidden = true
        } else {
            image = PickerItemResources.verticalLineImage
            self.statusLabel.isHidden = false
        }
        self.statusLabel.set(description: description,
                             descriptionIcon: image,
                             urlRangeMap: urlRangeMap,
                             textUrlRangeMap: textUrlRangeMap)
    }

    // Set custom status icon after name label.
    public func setFocusIcon(_ icon: UIImage?) {
        nameStatusView.setFocusIcon(icon)
    }

    // Set focus tag after name label.
    public func setFocusTag(_ tagView: UIView?) {
        nameStatusView.setFocusTag(tagView)
    }

    // Set name tag after name label.
    public func setNameTag(_ tagView: TagWrapperView?) {
        tagView?.maxTagCount = self.nameTag.maxTagCount
        nameStatusView.setNameTag(tagView)
    }

    /// update checkBox UI
    /// - Parameters:
    ///   - selected:
    ///   - enabled:
    private func updateCheckBox(selected: Bool, enabled: Bool) {
        checkBox.isEnabled = enabled
        checkBox.isSelected = selected
    }
}

public struct PickerItemResources {
    public static let verticalLineImage = getVerticalLineImage()

    private static func getVerticalLineImage() -> UIImage {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: 1, height: 16)
        let view = UIView()
        view.frame = CGRect(x: 0, y: 2, width: 1, height: 12)
        view.backgroundColor = UIColor.ud.lineDividerDefault
        containerView.addSubview(view)
        UIGraphicsBeginImageContextWithOptions(containerView.frame.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }
        containerView.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}
