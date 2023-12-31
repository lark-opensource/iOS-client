//
//  PublicPermissionView.swift
//  SKCommon
//
//  Created by guoqp on 2021/8/25.
//

import Foundation
import SnapKit
import SKResource
import RxSwift
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignCheckBox
import UniverseDesignTag

struct PublicPermissionCellV2Model {
    let title: String
    let type: PublicPermissionCellV2Type
    let accessOn: Bool
    let showSinglePageTag: Bool  //展示单页面提示
    let disableArrow: Bool
    let disablePowerSwitch: Bool
    let accessoryItem: PublicPermissionCellModel.AccessoryItem?
}

enum PublicPermissionCellV2Type {
    case powerSwitch
    case arrow
}


class PublicPermissionCellV2: SKGroupTableViewCell {
    static let reuseIdentifier = "PublicPermissionCellV2"
    private let disposeBag: DisposeBag = DisposeBag()
    static let cellHeight: CGFloat = 54
    var switchTap: ((Bool) -> Void)?
    var disableSwitchTap: (() -> Void)?
    private var accessoryItemHandler: (() -> Void)?

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        label.numberOfLines = 2
        return label
    }()

    lazy var singlePageTag: UDTag = {
        let config = UDTagConfig.TextConfig(cornerRadius: 4,
                                            textColor: UDColor.udtokenTagTextSBlue,
                                            backgroundColor: UDColor.udtokenTagBgBlue)
        let tag = UDTag(text: BundleI18n.SKResource.CreationMobile_Wiki_Perm_ExternalShare_Current_tag,
                        textConfig: config)
        return tag
    }()

    private lazy var accessoryButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didClickAccessoryButton), for: .touchUpInside)
        return button
    }()

    private lazy var infoPanelView: UIStackView = {
        let view = UIStackView()
        view.alignment = .leading
        view.axis = .vertical
        view.distribution = .fill
        view.spacing = 6
        return view
    }()


    lazy var accessSwitch: UISwitch = {
        let sw = UISwitch(frame: CGRect(x: 0, y: 0, width: 45, height: 26))
        sw.onTintColor = UIColor.ud.colorfulBlue
        sw.addTarget(self, action: #selector(tapAccessSwitch(sw:)), for: .valueChanged)
        return sw
    }()

    private lazy var switchFloatView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        view.backgroundColor = .clear
        view.addGestureRecognizer(self.singleTapGestureRecognizer)
        return view
    }()

    private lazy var singleTapGestureRecognizer: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                       action: #selector(tapDisableAccessSwitch(_:)))

        return gestureRecognizer
    }()

    lazy var modifyArrowView: ModifyArrowView = {
        let view = ModifyArrowView()
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        doInitUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func doInitUI() {
        containerView.docs.removeAllPointer()
        containerView.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        containerView.addSubview(infoPanelView)
        containerView.addSubview(accessoryButton)
        containerView.addSubview(accessSwitch)
        containerView.addSubview(switchFloatView)
        containerView.addSubview(modifyArrowView)

        infoPanelView.addArrangedSubview(descriptionLabel)
        infoPanelView.addArrangedSubview(singlePageTag)

        infoPanelView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        infoPanelView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(accessSwitch.snp.left).offset(-2 - 20 - 4)
            make.top.bottom.equalToSuperview().inset(15)
        }

        accessoryButton.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.left.equalTo(descriptionLabel.snp.right).offset(4)
        }

        accessSwitch.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        switchFloatView.snp.remakeConstraints { (make) in
            make.top.bottom.left.right.equalToSuperview()
        }
        modifyArrowView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    @objc
    func tapAccessSwitch(sw: UISwitch) {
        switchTap?(sw.isOn)
    }

    @objc
    fileprivate func tapDisableAccessSwitch(_ sender: AnyObject?) {
        disableSwitchTap?()
    }

    @objc
    private func didClickAccessoryButton() {
        accessoryItemHandler?()
    }

    public func setModel(_ model: PublicPermissionCellV2Model) {
        contentView.backgroundColor = .clear
        descriptionLabel.text = model.title

        if let accessoryItem = model.accessoryItem {
            accessoryButton.setImage(accessoryItem.image.ud.withTintColor(UDColor.iconN1), for: .normal)
            accessoryButton.isHidden = false
            accessoryItemHandler = accessoryItem.handler
            infoPanelView.snp.updateConstraints { make in
                make.right.equalTo(accessSwitch.snp.left).offset(-2 - 20 - 4)
            }
        } else {
            accessoryButton.isHidden = true
            accessoryItemHandler = nil
            infoPanelView.snp.updateConstraints { make in
                make.right.equalTo(accessSwitch.snp.left).offset(-2)
            }
        }

        if case .powerSwitch = model.type {
            accessSwitch.isHidden = false
            switchFloatView.isHidden = !model.disablePowerSwitch
            descriptionLabel.textColor = model.disablePowerSwitch ? UDColor.textDisabled : UIColor.ud.N900
            accessSwitch.isOn = model.accessOn
            accessSwitch.isEnabled = !model.disablePowerSwitch
            modifyArrowView.isHidden = true
            singlePageTag.isHidden = !model.showSinglePageTag
            accessoryButton.isEnabled = !model.disablePowerSwitch
        } else {
            descriptionLabel.textColor = model.disableArrow ? UDColor.textDisabled : UIColor.ud.N900
            accessSwitch.isHidden = true
            switchFloatView.isHidden = true
            modifyArrowView.isHidden = false
            singlePageTag.isHidden = true
            modifyArrowView.configColor(model.disableArrow)
            accessoryButton.isEnabled = !model.disableArrow
        }
    }
}

class ModifyArrowView: UIView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = UIColor.ud.N500
        label.text = BundleI18n.SKResource.Doc_Normal_PermissionModify
        return label
    }()

    private lazy var arrow: UIImageView = {
        let view = UIImageView()
        let image = UDIcon.getIconByKey(.rightOutlined, renderingMode: .alwaysTemplate, size: .init(width: 16, height: 16))
        view.image = image.ud.withTintColor(UDColor.iconN3)
        view.contentMode = .center
        return view
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody

        addSubview(arrow)
        arrow.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
            make.width.equalTo(16)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(arrow.snp.left).offset(-4)
        }

        sizeToFit()
    }

    func configColor(_ disable: Bool) {
        titleLabel.textColor = disable ? UDColor.textDisabled : UIColor.ud.N500
        arrow.image = arrow.image?.ud.withTintColor(disable ? UDColor.iconDisabled : UDColor.iconN3)
    }
}

//class PublicPermissionCellV2SectionHeaderView: UIView {
//    private lazy var titleLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 14)
//        label.numberOfLines = 0
//        label.textColor = UIColor.ud.textPlaceholder
//        return label
//    }()
//
//    init(title: String) {
//        super.init(frame: .zero)
//        setupUI()
//        titleLabel.text = title
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    private func setupUI() {
//        backgroundColor = UDColor.bgBase
//        addSubview(titleLabel)
//        titleLabel.snp.makeConstraints { make in
//            make.left.equalTo(safeAreaLayoutGuide.snp.left).offset(16)
//            make.right.equalTo(safeAreaLayoutGuide.snp.right).offset(-16)
//            make.top.bottom.equalToSuperview().inset(2)
//        }
//    }
//}
//class PublicPermissionCellV2SectionFooterView: UIView {
//    private lazy var titleLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 1)
//        label.numberOfLines = 0
//        label.textColor = UIColor.ud.textPlaceholder
//        return label
//    }()
//
//    init() {
//        super.init(frame: .zero)
//        setupUI()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    private func setupUI() {
//        backgroundColor = UDColor.bgBase
//        addSubview(titleLabel)
//        titleLabel.snp.makeConstraints { make in
//            make.height.equalTo(12)
//            make.top.bottom.equalToSuperview()
//            make.leading.trailing.equalToSuperview().inset(16)
//        }
//    }
//}




struct PublicPermissionSettingCellModel {
    let title: String
    let isSelected: Bool
    let isGray: Bool
}
class PublicPermissionSettingCell: SKGroupTableViewCell {
    static let reuseIdentifier = "PublicPermissionSettingCell"
    private let disposeBag: DisposeBag = DisposeBag()
    static let cellHeight: CGFloat = 54
    var isLastCell: Bool = false
    var model: PublicPermissionSettingCellModel?
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        label.numberOfLines = 2
        return label
    }()

    private lazy var checkBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .single, config: .init(style: .circle)) { (_) in }
        checkBox.isUserInteractionEnabled = false
        return checkBox
    }()

    var isItemSelected: Bool = false {
        didSet {
            checkBox.isSelected = isItemSelected
            if let isGray = model?.isGray, isGray == true {
                checkBox.isEnabled = false
            } else {
                checkBox.isEnabled = true
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        doInitUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func doInitUI() {
        containerView.docs.removeAllPointer()
        containerView.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(checkBox)

        checkBox.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.bottom.equalToSuperview().inset(18)
            make.height.width.equalTo(18)
        }

        descriptionLabel.snp.makeConstraints { (make) in
            make.left.equalTo(checkBox.snp.right).offset(10)
            make.centerY.equalTo(checkBox)
            make.right.equalToSuperview().offset(-16)
        }
    }

    public func setModel(_ model: PublicPermissionSettingCellModel) {
        self.model = model
        contentView.backgroundColor = .clear
        descriptionLabel.text = model.title
        descriptionLabel.textColor = model.isGray ? UIColor.ud.N400 : UIColor.ud.N900
        isItemSelected = model.isSelected
    }
}
