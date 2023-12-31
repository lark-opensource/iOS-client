//
//  GenericAvatarTypePickerView.swift
//  LarkChatSetting
//
//  Created by ByteDance on 2023/10/8.
//

import RustPB
import UniverseDesignIcon
import UniverseDesignColor
import SnapKit

protocol AvatarTypePickerDelegate: AnyObject {
    func chooseAvatarType(avatarType: Basic_V1_AvatarMeta.AvatarStyleType)
}

struct TextAvatarLayoutInfo {
    static let innerIconSize: CGSize = CGSize(width: 22, height: 22)
    static let itemSize: CGSize = CGSize(width: 48, height: 48)
    static let itemBorderWidth: CGFloat = 2.0
    static let checkViewSize: CGSize = CGSize(width: 16, height: 16)
    static let checkViewBorderWidth: CGFloat = 2.0
    static let itemRowCount: CGFloat = 5.0
    static let itemLineSpace: CGFloat = 16.0
}
final class AvatarTypeCell: UIView {

    private var avatarIcon = UDIcon.getIconByKey(.groupFilled, size: TextAvatarLayoutInfo.innerIconSize)
    private var checkedIcon = UDIcon.getIconByKey(.checkOutlined, size: TextAvatarLayoutInfo.checkViewSize).ud.withTintColor(UIColor.ud.staticWhite)
    private var avatarImageView: UIImageView
    private var checkedImageView: UIImageView
    private var avatarWrapperView = UIView()
    private var checkedWrapperView = UIView()

    let typeIdentifier: Basic_V1_AvatarMeta.AvatarStyleType
    init(avatarType: Basic_V1_AvatarMeta.AvatarStyleType) {
        self.typeIdentifier = avatarType
        avatarImageView = UIImageView(image: avatarIcon)
        checkedImageView = UIImageView(image: checkedIcon)
        super.init(frame: .zero)
        setupView()
        updateUI(avatarType: avatarType)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        self.addSubview(avatarWrapperView)
        self.addSubview(checkedWrapperView)
        avatarWrapperView.addSubview(avatarImageView)
        checkedWrapperView.addSubview(checkedImageView)
        self.snp.makeConstraints { make in
            make.width.equalTo(TextAvatarLayoutInfo.itemSize.width)
            make.height.equalTo(TextAvatarLayoutInfo.itemSize.height)
        }
        avatarWrapperView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        avatarImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        checkedWrapperView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(TextAvatarLayoutInfo.checkViewBorderWidth)
            make.trailing.equalToSuperview().offset(TextAvatarLayoutInfo.checkViewBorderWidth)
        }
        checkedImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(edges: TextAvatarLayoutInfo.checkViewBorderWidth))
        }
        /// 默认不展示选中态
        checkedWrapperView.isHidden = true

        avatarWrapperView.layer.cornerRadius = TextAvatarLayoutInfo.itemSize.width / 2.0
        avatarWrapperView.layer.masksToBounds = true
        avatarWrapperView.layer.borderWidth = TextAvatarLayoutInfo.itemBorderWidth
        avatarWrapperView.layer.ud.setBorderColor(UIColor.ud.functionInfoContentDefault)

        checkedWrapperView.layer.cornerRadius = TextAvatarLayoutInfo.checkViewSize.width / 2.0 + TextAvatarLayoutInfo.checkViewBorderWidth
        checkedWrapperView.layer.masksToBounds = true
        checkedWrapperView.layer.borderWidth = TextAvatarLayoutInfo.checkViewBorderWidth
        checkedWrapperView.layer.ud.setBorderColor(UIColor.ud.bgBody)
        checkedWrapperView.backgroundColor = UIColor.ud.functionInfoContentDefault
    }

    func updateUI(avatarType: Basic_V1_AvatarMeta.AvatarStyleType) {
        switch avatarType {
        case .border:
            avatarImageView.image = avatarIcon.ud.withTintColor(UIColor.ud.functionInfoContentDefault)
            avatarWrapperView.backgroundColor = UIColor.ud.staticWhite
        case .fill:
            avatarImageView.image = avatarIcon.ud.withTintColor(UIColor.ud.staticWhite)
            avatarWrapperView.backgroundColor = UIColor.ud.functionInfoContentDefault
        default: return
        }

    }

    /// 设置选中态
    func checkedOrNot(isChecked: Bool) {
        self.checkedWrapperView.isHidden = !isChecked
    }

}
/// 选择头像类型
final class GenericAvatarTypePickerView: UIView {
    public var currentAvatarType: Basic_V1_AvatarMeta.AvatarStyleType = .fill {
        didSet {
            setCheckedState(type: oldValue, isChecked: false)
            setCheckedState(type: currentAvatarType, isChecked: true)
        }
    }

    private lazy var filledTypeCell: AvatarTypeCell = {
        let cell = AvatarTypeCell(avatarType: .fill)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(filledTypeClicked))
        cell.addGestureRecognizer(tapGesture)
        return cell
    }()

    private lazy var borderTypeCell: AvatarTypeCell = {
        let cell = AvatarTypeCell(avatarType: .border)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(borderTypeClicked))
        cell.addGestureRecognizer(tapGesture)
        return cell
    }()

    weak var delegate: AvatarTypePickerDelegate?
    init(delegate: AvatarTypePickerDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        self.addSubview(filledTypeCell)
        self.addSubview(borderTypeCell)
        filledTypeCell.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        borderTypeCell.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            make.leading.equalTo(filledTypeCell.snp.trailing).offset(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func refreshView() {
        // 对齐页面下方的颜色选择布局。规则是：选项固定大小为44，一行可放置5个选项，按页面缩放间距
        let itemSpace = floor((self.frame.width - TextAvatarLayoutInfo.itemSize.width * CGFloat(TextAvatarLayoutInfo.itemRowCount)) / CGFloat(TextAvatarLayoutInfo.itemRowCount - 1))
        borderTypeCell.snp.updateConstraints { make in
            make.leading.equalTo(filledTypeCell.snp.trailing).offset(itemSpace)
        }
    }

    @objc
    func filledTypeClicked() {
        currentAvatarType = .fill
    }

    @objc
    func borderTypeClicked() {
        currentAvatarType = .border
    }

    func setCheckedState(type: Basic_V1_AvatarMeta.AvatarStyleType, isChecked: Bool) {
        guard type != .unknownStyle else {
            fatalError("avatar got wrong type")
        }
        if isChecked {
            delegate?.chooseAvatarType(avatarType: type)
        }
        if case .fill = type {
            filledTypeCell.checkedOrNot(isChecked: isChecked)
        } else if case .border = type {
            borderTypeCell.checkedOrNot(isChecked: isChecked)
        }
    }
}
