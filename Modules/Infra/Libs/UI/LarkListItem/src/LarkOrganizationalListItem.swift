//
//  LarkOrganizationalListItem.swift
//  LarkListItem
//
//  Created by zhangxingcheng on 2021/8/31.
//

import Foundation
import LarkTag
import LarkUIKit
import RxSwift
import SnapKit
import LarkBizAvatar
import UIKit

public struct LarkOrganizationalListItemProps {

    var checkStatus: LarkOrganizationalListItem.CheckBoxStaus = .invalid
    var description: NSAttributedString?
    var descriptionType: LarkOrganizationalListItem.DescriptionType?

    var avatarKey: String = ""
    var avatarID: String = ""

    var infoText: String = ""

    var timeString: String = ""

    var tags: [TagType] = []
    var additionalTags: [TagType] = []
}

public struct LarkOrganizationalListUIConfig {
    var maxTags: Int = 3
    var maxAdditionalTags: Int = 3

    var infoColor: UIColor = UIColor.ud.textPlaceholder
    var infoFont: UIFont = UIFont.systemFont(ofSize: 14)

    var secondaryInfoColor: UIColor = UIColor.ud.textPlaceholder
    var secondaryInfoFont: UIFont = UIFont.systemFont(ofSize: 14)
}

open class LarkOrganizationalListItem: UIView {
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
    public let avatarView = LarkMedalAvatar()
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

    /* description */
    public lazy var infoLabel: ItemLabel = {
        let infoLabel = ItemLabel()
        infoLabel.textColor = UIColor.ud.textPlaceholder
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        infoLabel.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
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
    private lazy var contentView: UIStackView = {
        // CheckBox + Avatar
        let contentView = UIStackView()
        contentView.axis = .horizontal
        contentView.alignment = .center
        return contentView
    }()

    /// professional + （name + status）（竖向布局）
    public lazy var professionalStackView: UIStackView = {
        let professionalStackView = UIStackView()
        professionalStackView.axis = .vertical
        professionalStackView.spacing = 6
        professionalStackView.alignment = .leading
        professionalStackView.distribution = .fill
        return professionalStackView
    }()

    /// name + status
    private let nameStatusView = LarkListNameStatusView()

    /// name + status + info stackView
    public lazy var nameStatusAndInfoStackView: UIStackView = {
        let nameStatusAndInfoStackView = UIStackView()
        nameStatusAndInfoStackView.axis = .vertical
        nameStatusAndInfoStackView.spacing = 7
        nameStatusAndInfoStackView.alignment = .leading
        nameStatusAndInfoStackView.distribution = .fill
        return nameStatusAndInfoStackView
    }()

    /// name + status + info + icon stackView
    public lazy var nameStatusInfoAndIconStackView: UIStackView = {
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
            make.centerY.equalToSuperview()
            rightMarginConstraint = make.right.equalToSuperview().offset(-16).constraint
        }

        let checkBoxSpace = UIView()

        contentView.addArrangedSubview(checkBox)
        contentView.addArrangedSubview(checkBoxSpace)
        contentView.addArrangedSubview(avatarView)
        contentView.addArrangedSubview(professionalStackView)
//        contentView.addArrangedSubview(nameStatusInfoAndIconStackView)

        /// not intercept the cell click event
        checkBox.isUserInteractionEnabled = false
        checkBox.snp.makeConstraints({ make in
            make.size.equalTo(LKCheckbox.Layout.iconMidSize)
        })

        var checkBoxAfterSpace: Constraint!
        checkBoxSpace.snp.makeConstraints {
            checkBoxAfterSpace = $0.width.equalTo( checkBox.isHidden ? 6 : 16 ).constraint
            $0.height.equalTo(0)
        }

        checkBox.rx.methodInvoked(#selector(setter: checkBox.isHidden))
            .subscribe { [weak checkBox](event) in
                guard case .next = event, let checkBox = checkBox else { return }
                // hidden时，左间距10 + 6 = 16, visible时，后面和原来一样有16的间距
                checkBoxAfterSpace.update(offset: checkBox.isHidden ? 6 : 16)
            }
            .disposed(by: disposeBag)

        avatarView.snp.makeConstraints({ make in
            make.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
        })
        contentView.setCustomSpacing(12, after: avatarView) // 如果avatarView隐藏，后面的内容往前面补上

        nameStatusAndInfoStackView.addArrangedSubview(nameStatusView)
        nameStatusView.nameTag.isHidden = true
        nameStatusAndInfoStackView.addArrangedSubview(infoLabel)
        nameStatusAndInfoStackView.addArrangedSubview(secondaryInfoLabel)

        nameStatusInfoAndIconStackView.addArrangedSubview(nameStatusAndInfoStackView)
        nameStatusInfoAndIconStackView.addArrangedSubview(additionalIcon)

        professionalStackView.addArrangedSubview(nameStatusInfoAndIconStackView)

        bottomSeperator.backgroundColor = UIColor.ud.commonTableSeparatorColor
        addSubview(bottomSeperator)
        bottomSeperator.snp.makeConstraints { (make) in
            make.left.equalTo(nameStatusView.snp.left)
            make.height.equalTo(1 / UIScreen.main.scale)
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }
    }

    public func setUIConfig(_ uiConfig: LarkOrganizationalListUIConfig) {
        self.nameTag.maxTagCount = uiConfig.maxTags
        self.additionalIcon.maxTagCount = uiConfig.maxAdditionalTags

        self.infoLabel.textColor = uiConfig.infoColor
        self.infoLabel.font = uiConfig.infoFont

        self.secondaryInfoLabel.textColor = uiConfig.secondaryInfoColor
        self.secondaryInfoLabel.font = uiConfig.secondaryInfoFont
    }

    public func setProps(_ props: LarkOrganizationalListItemProps) {

        self.checkStatus = props.checkStatus

        self.setDescription(props.description, descriptionType: props.descriptionType)

        self.avatarView.setAvatarByIdentifier(props.avatarID, avatarKey: props.avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))

        self.infoLabel.isHidden = props.infoText.isEmpty
        self.infoLabel.text = props.infoText

        self.timeLabel.isHidden = props.timeString.isEmpty
        self.timeLabel.timeString = props.timeString

        self.nameTag.isHidden = true
        if !props.tags.isEmpty {
            self.nameTag.setTags(props.tags)
            self.nameTag.isHidden = false
        }
        self.additionalIcon.setTags(props.additionalTags)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Set description
    /// - Parameters:
    ///   - description:
    ///   - descriptionType:
    public func setDescription(_ description: NSAttributedString?, descriptionType: DescriptionType?) {
        self.statusLabel.isHidden = true
        var image: UIImage?
        if description?.string.isEmpty ?? true {
            self.statusLabel.isHidden = true
        } else {
            image = Resources.verticalLineImage
            self.statusLabel.isHidden = false
        }
        self.statusLabel.set(description: description, descriptionIcon: image)
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
