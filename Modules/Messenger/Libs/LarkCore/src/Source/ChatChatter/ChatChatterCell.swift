//
//  ChatChatterCell.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/2/24.
//

import Foundation
import UIKit
import SnapKit
import LarkTag
import RxSwift
import RxCocoa
import LarkUIKit
import LarkModel
import LarkFocusInterface
import LarkContainer
import LarkListItem
import LarkBizTag
import EENavigator
import LarkMessengerInterface
import UniverseDesignIcon

// UI强相关，由于LarkChat LarkUrgent都要用，所以放到这里
@frozen
public enum ChatChatterViewStatus {
    case loading
    case error(Error)
    case viewStatus(ChatChatterBaseTable.Status)
}

public protocol ChatChatterCellProtocol {
    var isCheckboxHidden: Bool { get set }
    var isCheckboxSelected: Bool { get set }
    var item: ChatChatterItem? { get }
    func set(_ item: ChatChatterItem, filterKey: String?, userResolver: UserResolver)
    func setCellSelect(canSelect: Bool,
                       isSelected: Bool,
                       isCheckboxHidden: Bool)
}

public extension ChatChatterCellProtocol {
    func setCellSelect(canSelect: Bool,
                       isSelected: Bool,
                       isCheckboxHidden: Bool) {
    }
}

public protocol ChatChatterSectionHeaderProtocol {
    func set(_ item: ChatChatterSection)
}

extension ContactTableHeader: ChatChatterSectionHeaderProtocol {
    public func set(_ item: ChatChatterSection) {
        setContent(item.indexKey, left: 16, textColor: UIColor.ud.textCaption)
    }
}

open class ChatChatterCell: BaseTableViewCell, ChatChatterCellProtocol {
    public private(set) var infoView: ListItem
    public var isCheckboxHidden: Bool {
        get { return infoView.checkBox.isHidden }
        set {
            guard item?.isSelectedable ?? false else {
                infoView.checkBox.isHidden = true
                return
            }
            infoView.checkBox.isHidden = newValue
        }
    }
    private lazy var builder = ChatterTagViewBuilder()

    public func setCellSelect(canSelect: Bool,
                              isSelected: Bool,
                              isCheckboxHidden: Bool) {
        self.isCheckboxHidden = isCheckboxHidden
        infoView.checkBox.isSelected = isSelected
        infoView.checkBox.isEnabled = canSelect
        self.isUserInteractionEnabled = canSelect
    }

    public var isCheckboxSelected: Bool {
        get { return infoView.checkBox.isSelected }
        set { infoView.checkBox.isSelected = newValue }
    }

    public private(set) var item: ChatChatterItem?

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        infoView = ListItem()
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(infoView)
        infoView.snp.makeConstraints { $0.edges.equalToSuperview() }

        infoView.checkBox.isHidden = true
        infoView.statusLabel.isHidden = true
        infoView.additionalIcon.isHidden = true
        infoView.setNameTag(builder.build())
        builder.setDisplayedCount(3)
        infoView.nameTag.isHidden = true
        infoView.infoLabel.isHidden = true

        // 禁掉 UserInteractionEnabled 然后使用TableView的didselected回调
        infoView.checkBox.isUserInteractionEnabled = false
        contentView.backgroundColor = .clear
        setupBackgroundViews(highlightOn: true)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(_ item: ChatChatterItem, filterKey: String?, userResolver: UserResolver) {
        self.item = item
        infoView.avatarView.medalImageView.isHidden = !item.isShowMedal
        if item.itemAvatarKey.isEmpty {
            infoView.avatarView.image = Resources.avatar_default
        } else {
            infoView.avatarView.setAvatarByIdentifier(item.itemId,
                                                      avatarKey: item.itemAvatarKey,
                                                      medalKey: item.itemMedalKey,
                                                      medalFsUnit: "",
                                                      scene: .Chat,
                                                      placeholder: Resources.avatar_default,
                                                      avatarViewParams: .init(sizeType: .size(infoView.avatarSize)))
        }

        infoView.nameLabel.text = item.itemName

        if filterKey?.isEmpty == false {
            infoView.nameLabel.attributedText = item.itemName.lu.stringWithHighlight(
                highlightText: filterKey ?? "",
                pinyinOfString: item.itemPinyinOfName,
                normalColor: UIColor.ud.N900)
        } else {
            infoView.nameLabel.text = item.itemName
        }

        if let tags = item.itemTags {
            infoView.nameTag.isHidden = false
            builder.update(with: tags)
        }

        if let timeID = item.itemTimeZoneId {
            infoView.infoLabel.isHidden = false
            infoView.timeLabel.timeString = nil
        } else {
            infoView.infoLabel.isHidden = true
        }

        if item.supportShowDepartment == true {
            if item.needDisplayDepartment == true {
                // 群成员列表场景，展示部门信息：签名在第一行，部门信息在第二行
                setDescriptionInFirstLine()
                setDepartmentNameInSecLine()
            } else {
                // 群成员列表场景，不展示部门信息：签名展示在第二行
                setDescriptionInSecLine()
            }
        } else {
            // 非群成员列表场景：不展示部门信息，签名展示在第一行，隐藏第一行以外的label
            infoView.subStatusLabel.isHidden = true
            infoView.infoLabel.isHidden = true
            infoView.secondaryInfoLabel.isHidden = true
            setDescriptionInFirstLine()
        }

        if let chatter = item.itemUserInfo as? Chatter,
           let focusStatus = chatter.focusStatusList.topActive,
           let focusService = try? userResolver.resolve(assert: FocusService.self) {
            let tagView = focusService.generateTagView()
            tagView.config(with: focusStatus)
            infoView.setFocusTag(tagView)
        } else {
            infoView.setFocusIcon(nil)
        }

        infoView.bottomSeperator.isHidden = true

        // 签名展示在第一行
        func setDescriptionInFirstLine() {
            if let descUIConfig = item.descUIConfig {
                infoView.statusLabel.setUIConfig(descUIConfig)
            }
            if let desc = item.itemDescription {
                infoView.setDescription(NSAttributedString(string: desc.text), descriptionType: ListItem.DescriptionType(rawValue: desc.type.rawValue))
                item.descInlineProvider?({ [weak self] sourceID, attr, urlRangeMap, textUrlRangeMap in
                    // 此处非数据驱动UI，而是由UI直接调用，因此需要处理复用问题
                    guard sourceID == self?.item?.itemId else { return }
                    if urlRangeMap.isEmpty, textUrlRangeMap.isEmpty { return }
                    self?.infoView.setDescription(
                        attr,
                        descriptionType: ListItem.DescriptionType(rawValue: desc.type.rawValue),
                        urlRangeMap: urlRangeMap,
                        textUrlRangeMap: textUrlRangeMap
                    )
                })
            } else {
                infoView.setDescription(NSAttributedString(string: ""), descriptionType: .onDefault)
            }
        }

        // 签名展示在第二行,隐藏部门信息,隐藏首行签名栏
        func setDescriptionInSecLine() {
            infoView.infoLabel.isHidden = true
            infoView.secondaryInfoLabel.isHidden = true
            infoView.nameStatusView.statusLabel.isHidden = true
            infoView.subStatusLabel.isHidden = false
            // nameStatusAndInfoStackView中头插一个StatusLabel用来展示签名，并隐藏分割线
            if let descUIConfig = item.descUIConfig {
                infoView.subStatusLabel.setUIConfig(descUIConfig)
            }
            if let desc = item.itemDescription {
                infoView.setSubDescription(NSAttributedString(string: desc.text), descriptionType: ListItem.DescriptionType(rawValue: desc.type.rawValue))
                item.descInlineProvider?({ [weak self] sourceID, attr, urlRangeMap, textUrlRangeMap in
                    // 此处非数据驱动UI，而是由UI直接调用，因此需要处理复用问题
                    guard sourceID == self?.item?.itemId else { return }
                    if urlRangeMap.isEmpty, textUrlRangeMap.isEmpty { return }
                    self?.infoView.setSubDescription(
                        attr,
                        descriptionType: ListItem.DescriptionType(rawValue: desc.type.rawValue),
                        urlRangeMap: urlRangeMap,
                        textUrlRangeMap: textUrlRangeMap
                    )
                })
            } else {
                infoView.setSubDescription(NSAttributedString(string: ""), descriptionType: .onDefault)
            }
        }

        // 部门信息展示在第二行,隐藏第二行签名栏
        func setDepartmentNameInSecLine() {
            infoView.subStatusLabel.isHidden = true
            infoView.infoLabel.isHidden = false
            infoView.infoLabel.font = .systemFont(ofSize: 12)
            infoView.infoLabel.lineBreakMode = .byTruncatingHead
            infoView.infoLabel.text = item.itemDepartment ?? ""
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        infoView.avatarView.setAvatarByIdentifier("", avatarKey: "", placeholder: Resources.avatar_default)
        infoView.avatarView.image = nil
        infoView.nameLabel.text = nil
        infoView.nameTag.isHidden = true
    }

    public override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }
}

public class ChatChatterProfileCell: ChatChatterCell {

    public var personCardButtonTapHandler: ((String) -> Void)?
    let personCardButton = UIButton()

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupPersonalCardButton()
    }

    func setupPersonalCardButton() {
        contentView.addSubview(personCardButton)
        personCardButton.setImage(UDIcon.getIconByKey(.groupCardOutlined).withRenderingMode(.alwaysTemplate), for: .normal)
        personCardButton.tintColor = UIColor.ud.iconN3
        personCardButton.addTarget(self, action: #selector(personCardButtonDidClick), for: .touchUpInside)
        personCardButton.setContentHuggingPriority(.required, for: .horizontal)
        personCardButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        infoView.snp.remakeConstraints { (make) in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.equalTo(personCardButton.snp.leading).offset(4)
        }
        personCardButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(-16)
        }
    }

    @objc
    private func personCardButtonDidClick() {
        guard let id = self.item?.itemId else { return }
        self.personCardButtonTapHandler?(id)
    }
}
