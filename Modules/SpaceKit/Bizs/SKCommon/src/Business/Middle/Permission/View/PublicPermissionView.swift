//
//  PublicPermissionCell.swift
//  Collaborator
//
//  Created by Da Lei on 2018/4/10.
//

import Foundation
import SnapKit
import SKResource
import RxSwift
import UniverseDesignColor
import UniverseDesignCheckBox

protocol PublicPermissionCellDelegate: AnyObject {
    func didClickModel(model: InviteExternalCellModel, at index: Int)
}

enum PublicPermissionSection: Int {
    case canSharingOutside  // 允许文档被分享到组织外？
    case canComment         // 哪些人可以评论此文档
    case canShare           // 哪些人可以共享文档（添加管理协作者）
    case canCopyOrExport    // 哪些人可以创建副本、打印、导出、复制、内容
}

class PublicPermissionCell: SKGroupCollectionViewCell {
    static let reuseIdentifier = "PublicPermissionCell"
    private let disposeBag: DisposeBag = DisposeBag()
    static let cellHeight: CGFloat = 54
    var isHasSubModel = false
    var submodels = [InviteExternalCellModel]()
    var isLastCell: Bool = false
    weak var delegate: PublicPermissionCellDelegate?
    var model: PublicPermissionModel?
    
    var subSeparatorView: UIView = {
        let separator = UIView()
        separator.backgroundColor = UIColor.ud.lineDividerDefault
        separator.isHidden = true
        return separator
    }()
    
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

    lazy var submodelTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.rowHeight = PublicPermissionCell.cellHeight
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        return tableView
    }()
    
    private lazy var bottomSplitView: UIView = {
           let view = UIView()
           view.backgroundColor = UIColor.ud.N300
           return view
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.doInitUI()
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    func doInitUI() {
        containerView.docs.removeAllPointer()
        containerView.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(checkBox)
        containerView.addSubview(submodelTableView)
        containerView.addSubview(subSeparatorView)

        checkBox.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(18)
            make.height.width.equalTo(18)
        }
        
        descriptionLabel.snp.makeConstraints { (make) in
            make.left.equalTo(checkBox.snp.right).offset(10)
            make.centerY.equalTo(checkBox)
            make.right.equalToSuperview().offset(-16)
        }

        submodelTableView.snp.makeConstraints { (make) in
            make.top.equalTo(checkBox.snp.bottom).offset(18)
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        
        subSeparatorView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(44)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.top.equalTo(submodelTableView.snp.top)
        }
    }
    
    public func setModel(_ model: PublicPermissionModel) {
        self.model = model
        contentView.backgroundColor = .clear
        descriptionLabel.text = model.title
        descriptionLabel.textColor = model.isGray ? UIColor.ud.N400 : UIColor.ud.N900
        submodels = model.submodels ?? []
        submodelTableView.reloadData()
        subSeparatorView.isHidden = submodels.isEmpty
        submodelTableView.snp.updateConstraints { (make) in
            make.height.equalTo(CGFloat(submodels.count) * PublicPermissionCell.cellHeight)
        }
    }

    public func setSelected(_ selected: Bool) {
        isItemSelected = selected
    }
}

extension PublicPermissionCell: UITableViewDataSource & UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return submodels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PublicPermissionSubModelCell") ?? PublicPermissionSubModelCell(style: .value1, reuseIdentifier: "PublicPermissionSubModelCell")
        guard let submodelCell = cell as? PublicPermissionSubModelCell else { return cell }
        let model = submodels[indexPath.row]
        submodelCell.descriptionLabel.text = model.title
        submodelCell.isGray = model.isGray
        submodelCell.descriptionLabel.textColor = model.isGray ? UIColor.ud.N400 : UIColor.ud.N900
        submodelCell.isItemSelected = model.isSelected

        return submodelCell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = submodels[indexPath.row]
        guard !model.isSelected else { return }
        delegate?.didClickModel(model: model, at: indexPath.row)
    }
}

class PublicPermissionSubModelCell: UITableViewCell {
    private let disposeBag: DisposeBag = DisposeBag()
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        label.numberOfLines = 2
        return label
    }()

    private lazy var splitView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N300
        return view
    }()
    
    private lazy var checkBox: UIImageView = {
        let view = UIImageView()
        view.image = BundleResources.SKResource.Common.Tool.icon_tool_radiocheckbox_nor
        return view
    }()
    var isGray: Bool = false

    var isItemSelected: Bool = false {
        didSet {
            if isItemSelected {
                if isGray {
                    checkBox.image = BundleResources.SKResource.Common.Tool.icon_tool_radiocheckbox_select_disable
                } else {
                    checkBox.image = BundleResources.SKResource.Common.Tool.icon_tool_radiocheckbox_slt
                }
            } else {
                if isGray {
                    checkBox.image = BundleResources.SKResource.Common.Tool.icon_tool_radiocheckbox_unselect_disable
                } else {
                    checkBox.image = BundleResources.SKResource.Common.Tool.icon_tool_radiocheckbox_nor
                }
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(checkBox)
        contentView.addSubview(splitView)
        checkBox.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(44)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(18)
        }
        descriptionLabel.snp.makeConstraints { (make) in
            make.left.equalTo(checkBox.snp.right).offset(10)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
        splitView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(44)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        contentView.backgroundColor = UDColor.bgBody
        contentView.docs.removeAllPointer()
        contentView.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// section 从评论开始 sectiontitleview
class PublicPermissionSectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "PublicPermissionSectionHeaderView"
    let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.N600
        titleLabel.numberOfLines = 0
        return titleLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.N100
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-4)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }

    static func sectionHeaderViewHeight(section: Int) -> CGFloat {
        guard let sectionType = PublicPermissionSection(rawValue: section) else { return 36 }
        switch sectionType {
        case .canSharingOutside:
            return 64
        case .canComment:
            return 36
        case .canShare:
            return 36
        case .canCopyOrExport:
            return 54
        }
    }

//    static func sectionHeaderViewHeightV2(sectionType: PublicPermissionSectionModelType) -> CGFloat {
//        switch sectionType {
//        case .security:
//            return 54
//        default:
//            return 36
//        }
//    }
}

class PermissionSwitchView: UICollectionReusableView {
    static let reuseIdentifier = "PermissionSwitchView"
    private var switchTap: (() -> Void)?
    private let disposeBag: DisposeBag = DisposeBag()
    
    private lazy var singleTapGestureRecognizer: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                       action: #selector(tapAccessSwitch(_:)))

        return gestureRecognizer
    }()

    private lazy var switchFloatView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        view.backgroundColor = .clear
        view.addGestureRecognizer(self.singleTapGestureRecognizer)
        return view
    }()

    private lazy var accessSplitView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N300
        return view
    }()

    lazy var accessSwitch: UISwitch = {
        return generateSwitch()
    }()

    func generateSwitch() -> UISwitch {
        let sw = UISwitch(frame: CGRect(x: 0, y: 0, width: 45, height: 26))
        sw.onTintColor = UIColor.ud.colorfulBlue
        return sw
    }

    lazy var accessSwitchContainerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UDColor.bgBody
        containerView.layer.cornerRadius = 10
        return containerView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        /// 默认 UI 设置
        ///允许文档分享到组织外部开关
        accessSwitchContainerView.backgroundColor = UDColor.bgBody
        accessSwitchContainerView.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        addSubview(accessSwitchContainerView)
        accessSwitchContainerView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(54)
        }
        let accessLabel = UILabel()
        accessLabel.font = UIFont.systemFont(ofSize: 16)
        accessLabel.text = BundleI18n.SKResource.CreationMobile_Minutes_permissions_settings_ExternalShare_toggle
        accessLabel.textColor = UIColor.ud.N900
        accessLabel.numberOfLines = 0
        accessSwitchContainerView.addSubview(accessLabel)
        accessLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(12)
            make.right.equalTo(-60)
        }
        accessSwitchContainerView.addSubview(accessSwitch)
        accessSwitch.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-12)
        }
    }

//    func addSwtichFloatView(_ tap: (() -> Void)?) {
//        switchTap = tap
//        accessSwitchContainerView.addSubview(switchFloatView)
//        switchFloatView.snp.remakeConstraints { (make) in
//            make.top.bottom.left.right.equalTo(accessSwitch)
//        }
//    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @objc
    fileprivate func tapAccessSwitch(_ sender: AnyObject?) {
        switchTap?()
    }
}

extension PermissionSwitchView {
    ///添加一层 config 接口通过对公共权限的判断决定显示的开关
    func config(publicPermissionMeta: PublicPermissionMeta?) {
        guard let pulicPermissionMeta = publicPermissionMeta else {
            return
        }
        //C 端用户的布局
        if User.current.info?.isToNewC == true {
            accessSwitchContainerView.isHidden = true
        } else {// B 端用户的布局
            accessSwitchContainerView.isHidden = !pulicPermissionMeta.canShowExternalAccessSwitch
        }
    }
}
