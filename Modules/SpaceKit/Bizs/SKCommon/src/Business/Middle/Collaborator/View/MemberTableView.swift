//  Created by Songwen Ding on 2018/4/9.

import UIKit
import Kingfisher
import SnapKit
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignColor
import UniverseDesignTheme
import ByteWebImage

public protocol MemberItemProtocol {
    var identifier: String { get set }
    var selectType: MemberItem.SelectType { get set }
    var imageURL: String? { get set }
    var title: String { get set }
    var detail: String? { get set }
    var isExternal: Bool { get set }
    var isCrossTenanet: Bool { get set }
    var isShowSeparatorLine: Bool { get set }
    var displayTag: DisplayTagSimpleInfo? { get set }
    var isNoCheckBox: Bool { get set }
    var avatarKey: String? { get set }
}


public struct MemberItem: MemberItemProtocol, Equatable {
    
    public enum SelectType {
        case none
        case blue
        case gray
        case disable
    }

    public var identifier: String
    public var selectType: MemberItem.SelectType
    public var imageURL: String?
    public var title: String
    public var detail: String?
    public var isExternal: Bool
    public var isCrossTenanet: Bool
    public var isShowSeparatorLine: Bool
    public var displayTag: DisplayTagSimpleInfo? // 显示关联标签
    public var token: String?
    public var callbackId: String?
    public var isShow: Bool?
    
    public var isNoCheckBox: Bool = false
    
    public var avatarKey: String?

    public init(identifier: String,
                selectType: SelectType,
                imageURL: String?,
                title: String,
                detail: String?,
                token: String?,
                isExternal: Bool,
                displayTag: DisplayTagSimpleInfo?,
                isCrossTenanet: Bool,
                isShowSeparatorLine: Bool = true,
                isShow: Bool? = nil,
                callbackId: String? = nil) {
        self.identifier = identifier
        self.selectType = selectType
        self.imageURL = imageURL
        self.title = title
        self.detail = detail
        self.token = token
        self.isExternal = isExternal
        self.isCrossTenanet = isCrossTenanet
        self.isShowSeparatorLine = isShowSeparatorLine
        self.displayTag = displayTag
        self.isShow = isShow
        self.callbackId = callbackId
    }
    
    public static func == (lhs: MemberItem, rhs: MemberItem) -> Bool {
        return (lhs.identifier == rhs.identifier) && (lhs.title == rhs.title)
    }

}

// MARK: - TableView
public final class MembersTableView: UITableView {
    
    public var items = [MemberItemProtocol]()
    
    public var isShowHeadLine: Bool = true
    
    public var itemBackgroundColor: UIColor = UDColor.bgFloat

    private lazy var noFoundMessageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.docs.pfsc(18)
        label.textColor = UDColor.N500
        label.text = BundleI18n.SKResource.Doc_Share_NothingFound
        return label
    }()
    
    public var isNoCheckBox = false

    private let cellReuseIdentifier = String(describing: MembersTableCell.self)
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        rowHeight = 56
        tableFooterView = UIView()
        showsVerticalScrollIndicator = false
        separatorStyle = .none
        dataSource = self
        addSubview(noFoundMessageLabel)
        noFoundMessageLabel.snp.makeConstraints({ (make) in
            make.center.equalToSuperview()
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MembersTableView {
    override public func reloadData() {
        super.reloadData()
        noFoundMessageLabel.isHidden = items.count > 0
    }
}

extension MembersTableView: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: MembersTableCell
        if let c = (tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as? MembersTableCell) {
            cell = c
        } else {
            cell = MembersTableCell(style: .subtitle, reuseIdentifier: cellReuseIdentifier)
        }
        cell.contentView.backgroundColor = itemBackgroundColor
        var item = items[indexPath.row]
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
            item.isNoCheckBox = isNoCheckBox
        }
        cell.item = item
        if isShowHeadLine {
            cell.isFirst = indexPath.row == 0
        }
        return cell
    }
}

// MARK: - Cell
class MembersTableCell: UITableViewCell {
    public var item: MemberItemProtocol? {
        willSet {
            guard let value = newValue else {
                selectedIcon.image = nil
                iconImageView.image = nil
                titleLabel.update(views: [])
                subTitleLabel.text = nil
                return
            }

            switch value.selectType {
            case .blue:
                selectedIcon.image = BundleResources.SKResource.Common.Collaborator.Selected
            case .gray:
                selectedIcon.image = BundleResources.SKResource.Common.Collaborator.Unselected
            case .disable:
                selectedIcon.image =
                    BundleResources.SKResource.Common.Collaborator.collaborator_icon_selected_disable
            case .none:
                selectedIcon.image = nil
            }
            // 不可选状态z灰色
            let alpha: CGFloat = value.selectType == .disable ? 0.3 : 1
            iconImageView.alpha = alpha
            titleLabel.alpha = alpha
            subTitleLabel.alpha = alpha
            // 内容
            subTitleLabel.text = value.detail
            var externalHidden = !((value.isExternal || value.isCrossTenanet) && EnvConfig.CanShowExternalTag.value)
            
            let tagValue = UserScopeNoChangeFG.HZK.b2bRelationTagEnabled ? (value.displayTag?.tagValue ?? "") : BundleI18n.SKResource.Doc_Widget_External
            titleLabel.update(views: [
                .titleLabel(text: value.title),
                .customTag(text: tagValue, visable: !externalHidden && !tagValue.isEmpty)
            ])
            
            seprateLine.isHidden = !value.isShowSeparatorLine
            if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
                if let key = value.avatarKey, !key.isEmpty {
                    iconImageView
                        .bt
                        .setLarkImage(
                            .avatar(
                                key: key,
                                entityID: ""
                            ),
                            placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder
                        ) { result in
                            switch result {
                            case .success:
                                DocsLogger.info("success request avatar by setLarkImage with key: \(key)")
                            case .failure(let error):
                                DocsLogger.error("fail request avatar by setLarkImage with key: \(key) code: \(error.code) userinfo: \(error.userInfo) localizedDescription: \(error.localizedDescription)", error: error)
                            }
                        }
                } else {
                    if let url = value.imageURL {
                        iconImageView.image = BundleResources.SKResource.Common.Collaborator.avatar_placeholder
                        if let u = URL(string: url) {
                            let resource = ImageResource(downloadURL: u, cacheKey: url.hashValue.description)
                            iconImageView.kf.setImage(with: resource, placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
                        } else {
                            DocsLogger.error("new url error")
                        }
                    } else {
                        iconImageView.image = nil
                    }
                }
            } else {
            guard let url = value.imageURL else {
                iconImageView.image = nil
                return
            }
            iconImageView.image = BundleResources.SKResource.Common.Collaborator.avatar_placeholder
            guard let u = URL(string: url) else { return }
            let resource = ImageResource(downloadURL: u, cacheKey: url.hashValue.description)
            iconImageView.kf.setImage(with: resource, placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
            }
            
            if User.current.info?.isToC == true {
                externalHidden = true
                titleLabel.update(views: [
                    .titleLabel(text: value.title),
                    .customTag(text: tagValue, visable: !externalHidden && !tagValue.isEmpty)
                ])
            }
            
            if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
                if value.isNoCheckBox {
                    selectedIcon.snp.remakeConstraints { (make) in
                        make.centerY.equalToSuperview()
                        make.width.height.equalTo(0)
                        make.left.equalToSuperview().offset(18)
                    }
                    iconImageView.snp.remakeConstraints({ (make) in
                        make.centerY.equalToSuperview()
                        make.width.height.equalTo(36)
                        make.left.equalToSuperview().offset(18)
                    })
                } else {
                    // 非隐藏checkbox维持原先布局
                    selectedIcon.snp.remakeConstraints { (make) in
                        make.centerY.equalToSuperview()
                        make.width.height.equalTo(20)
                        make.left.equalToSuperview().offset(16)
                    }
                    iconImageView.snp.remakeConstraints({ (make) in
                        make.centerY.equalToSuperview()
                        make.width.height.equalTo(36)
                        make.left.equalTo(selectedIcon.snp.right).offset(12)
                    })
                }
            }
            
            titleLabel.snp.remakeConstraints { make in
                if subTitleLabel.text?.isEmpty ?? true {
                    make.centerY.equalTo(iconImageView.snp.centerY)
                } else {
                    make.top.equalTo(iconImageView.snp.top)
                }
                make.right.lessThanOrEqualToSuperview().offset(-16)
                make.left.equalTo(iconImageView.snp.right).offset(12)
            }
        }
    }

    public var isFirst: Bool? {
        willSet {
            guard let value = newValue else {
                headerLine.isHidden = true
                return
            }
            headerLine.isHidden = !value
        }
    }

    private lazy var headerLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.N300
        v.isHidden = true
        return v
    }()

    private lazy var seprateLine: UIView = {
        let v = UIView()
        v.backgroundColor = UDColor.N300
        return v
    }()

    private lazy var selectedIcon: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    lazy var iconImageView: UIImageView = {
        let imageView = SKAvatar(configuration: .init(backgroundColor: UDColor.N100,
                                               style: .circle,
                                               contentMode: .scaleAspectFill))
        imageView.layer.cornerRadius = 24
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var titleLabel: SKListCellView = {
        let label = SKListCellView()
        return label
    }()

    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UDColor.textPlaceholder
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(headerLine)
        contentView.addSubview(selectedIcon)
        contentView.addSubview(seprateLine)
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subTitleLabel)
        contentView.docs.addStandardHover()
        headerLine.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(2 / SKDisplay.scale)
        }
        selectedIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
            make.left.equalToSuperview().offset(18)
        }
        iconImageView.snp.makeConstraints({ (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(36)
            make.left.equalTo(selectedIcon.snp.right).offset(12)
        })
        titleLabel.snp.makeConstraints({ (make) in
            make.top.equalTo(iconImageView.snp.top)
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.left.equalTo(iconImageView.snp.right).offset(12)
        })
        subTitleLabel.snp.makeConstraints({ (make) in
            make.bottom.equalTo(iconImageView)
            make.left.equalTo(titleLabel.snp.left)
            make.right.equalToSuperview().offset(-10)
        })
        seprateLine.snp.makeConstraints { (make) in
            make.bottom.right.equalToSuperview()
            make.height.equalTo(2 / SKDisplay.scale)
            make.left.equalTo(iconImageView.snp.left)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
