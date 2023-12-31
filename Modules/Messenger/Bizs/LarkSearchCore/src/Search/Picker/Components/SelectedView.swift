//
//  SelectedView.swift
//  LarkSearch
//
//  Created by SolaWing on 2020/8/3.
//

import Foundation
import LarkSDKInterface
import UniverseDesignFont
import UIKit
import LarkUIKit
import LarkBizAvatar
import RxSwift
import Homeric
import LarkModel
import LarkListItem

public protocol SelectedViewDelegate: AnyObject {
    /// should call reloadData after selected changed
    var selected: [Option] { get }
    func deselect(option: Option, from: Any?) -> Bool // 取消选中，返回是否成功

    func avatar(for option: Option, callback: @escaping (SelectedOptionInfo?) -> Void)
    func unfold() // 展开选中项
}

extension SelectedViewDelegate {
    public func unfold() {}
}

public protocol SelectedViewControllerDelegate: AnyObject {
    var selected: [Option] { get }
    var selectedObservable: Observable<[Option]> { get }
    @discardableResult
    func deselect(option: Option, from: Any?) -> Bool // 取消选中，返回是否成功
    func configureInfo(for option: Option, callback: @escaping (SelectedOptionInfo?) -> Void)
}

/// Selected Option should implement this, or SelectedOptionInfoConvertable, to show avatar in selectedView
public protocol SelectedOptionInfo {
    var avaterIdentifier: String { get } /// avatar identifier for option, return "" to mean invalid
    var avatarKey: String { get } /// avatar image key for option, return "" to mean invalid
    var avatarImageURLStr: String? { get }
    var backupImage: UIImage? { get } /// 默认图(如果没给avatar的话)
    /// avatar name for option
    var name: String { get }
    var selectedOptionDescription: String? { get }
    /// 头像右下角的修饰用的图标
    var miniIcon: UIImage? { get }

    var isMsgThread: Bool { get }
}

extension SelectedOptionInfo {
    public var selectedOptionDescription: String? { nil }
    public var avatarImageURLStr: String? { nil }
    public var backupImage: UIImage? { nil }
    public var miniIcon: UIImage? { nil }
    public var isMsgThread: Bool { false }
}

public protocol SelectedChatOptionInfo: SelectedOptionInfo {
    var chatUserCount: Int32 { get }
    var chatDescription: String { get }
    var crossTenant: Bool? { get }
    var isUserCountVisible: Bool { get }
}

public extension SelectedChatOptionInfo {
    var crossTenant: Bool? { return nil }
}

public protocol SelectedOptionInfoConvertable {
    func asSelectedOptionInfo() -> SelectedOptionInfo
}

/// picker的选中视图
public class SelectedView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    public let collectionView: UICollectionView
    public let countTextView: UILabel
    public let pickType: UniversalPickerType
    public weak var delegate: SelectedViewDelegate?
    public var isUseDocIcon: Bool = false
    var scene: String?
    var userId: String?
    var customLabelHandler: ((Int) -> String)?

    private lazy var unfoldButton: UIButton = {
        let unfoldButton = UIButton(type: .system)
        unfoldButton.setImage(Resources.LarkSearchCore.Messenger.right_arrow.withRenderingMode(.alwaysTemplate), for: .normal)
        unfoldButton.tintColor = UIColor.ud.iconN3
        unfoldButton.adjustsImageWhenHighlighted = false
        unfoldButton.backgroundColor = UIColor.ud.bgBody
        unfoldButton.imageEdgeInsets = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 18)
        unfoldButton.addTarget(self, action: #selector(unfold(_:)), for: .touchUpInside)
        return unfoldButton
    }()

    public init(frame: CGRect, delegate: SelectedViewDelegate,
                supportUnfold: Bool,
                pickType: UniversalPickerType = .defaultType) {
        self.delegate = delegate
        self.pickType = pickType
        var collectionViewLayout: UICollectionViewLayout {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.itemSize = CGSize(width: 40, height: 40) // 30
            layout.minimumInteritemSpacing = 8             // 10
            return layout
        }

        collectionView = UICollectionView(frame: CGRect(origin: .zero, size: frame.size),
                                          collectionViewLayout: collectionViewLayout)
        self.countTextView = UILabel()
        countTextView.backgroundColor = UIColor.ud.bgBody
        super.init(frame: frame)
        self.backgroundColor = .ud.bgBody

        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)  // 8.0
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(AvatarCollectionCell.self, forCellWithReuseIdentifier: "AvatarCollectionCell")
        collectionView.register(ItemCollectionIconCell.self, forCellWithReuseIdentifier: "ItemCollectionIconCell")
        self.addSubview(collectionView)

        if supportUnfold {
            self.addSubview(unfoldButton)
            switch pickType {
            case .folder, .workspace, .filter, .label(_):
                self.addSubview(countTextView)
                countTextView.font = UDFont.body0
                countTextView.snp.makeConstraints { (make) in
                    make.left.equalToSuperview().offset(16)
                    make.top.bottom.equalToSuperview().inset(13)
                    make.centerY.equalToSuperview()
                    make.right.equalTo(unfoldButton.snp.left)
                }
                unfoldButton.snp.makeConstraints { (make) in
                    make.centerY.right.equalToSuperview()
                    make.width.equalTo(44)
                    make.height.equalTo(40)
                }
            default:
                collectionView.snp.makeConstraints { (make) in
                    make.left.top.bottom.equalToSuperview()
                    make.right.equalTo(unfoldButton.snp.left)
                }
                unfoldButton.snp.makeConstraints { (make) in
                    make.centerY.right.equalToSuperview()
                    make.width.equalTo(44)
                    make.height.equalTo(40)
                }
            }
        } else {
            collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var intrinsicContentSize: CGSize { return CGSize(width: UIView.noIntrinsicMetric, height: 56.0) }
    public func reloadData() {
        assert(Thread.isMainThread, "should occur on main thread!")
        collectionView.reloadData()
        if let count = delegate?.selected.count {
            refreshCountTextView(count: count)
        }
    }
    public func scrollToLeading() {
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, animated: false)
    }
    public func refreshCountTextView(count: Int) {
        switch pickType {
        case .folder:
            countTextView.text = BundleI18n.LarkSearchCore.Lark_ASLSearch_DocsTabFilters_InFolder_SelectMultipleFoldersMobile(count)
        case .workspace:
            countTextView.text = BundleI18n.LarkSearchCore.Lark_ASLSearch_DocsTabFilters_InWorkspace_SelectMultipleWorkspacesMobile(count)
        case .filter:
            countTextView.text = BundleI18n.LarkSearchCore.Lark_ASLSearch_CumstomSearch_NumberOfFilterSelected_Mobile(count)
        case .chat, .defaultType:
            break
        case .label(let handler):
            countTextView.text = handler(count)
        default:
            break
        }
    }
    public func scrollToLastest(animated: Bool) {
        if let total = delegate?.selected.count, total > 1 {
            collectionView.scrollToItem(at: IndexPath(item: total - 1, section: 0), at: .right, animated: animated)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return delegate?.selected.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AvatarCollectionCell", for: indexPath) as? AvatarCollectionCell,
            let selected = delegate?.selected, selected.count > indexPath.row
        else {
            assertionFailure()
            return UICollectionViewCell()
        }
        let option = selected[indexPath.row]
        cell.option = option
        if let item = option as? PickerItem { // 处理doc, wiki, wikiSpace, mailUser的头像
            if case .mailUser(let mailUserMeta) = item.meta, let imageURL = mailUserMeta.imageURL {
                cell.setAvatar(imageURL: imageURL)
                return cell
            } else if case .chatter(let meta) = item.meta, // 文档图标
                      let itemCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCollectionIconCell", for: indexPath) as? ItemCollectionIconCell {
                itemCell.context.userId = self.userId
                itemCell.node = PickerItemTransformer.transform(indexPath: indexPath, item: item)
                return itemCell
            } else if isUseDocIcon, // 文档图标
               let itemCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCollectionIconCell", for: indexPath) as? ItemCollectionIconCell {
                itemCell.context.userId = self.userId
                itemCell.node = PickerItemTransformer.transform(indexPath: indexPath, item: item)
                return itemCell
            } else {
                var image = ListItemNode.Icon.local(nil)
                switch item.meta {
                case .doc(let meta): image = IconTransformer.transform(meta: meta)
                case .wiki(let meta): image = IconTransformer.transform(meta: meta)
                case .wikiSpace(let meta): image = IconTransformer.transform(meta: meta)
                default: break
                }
                if case .local(let img) = image {
                    cell.setAvatar(by: img ?? UIImage())
                }
                return cell
            }
        }
        delegate?.avatar(for: option) { (info) in
            guard option.optionIdentifier == cell.option?.optionIdentifier, let info = info else { return }
            if !info.avatarKey.isEmpty {
                cell.setAvatar(identifier: info.avaterIdentifier, key: info.avatarKey, image: info.isMsgThread ? BundleResources.LarkSearchCore.Picker.thread_msg_icon : nil)
            } else if let backupImage = info.backupImage {
                cell.setAvatar(by: backupImage)
            } else if let avatarImageURLStr = info.avatarImageURLStr, !avatarImageURLStr.isEmpty {
                cell.setAvatar(imageURL: avatarImageURLStr)
            } else if !info.name.isEmpty {
                cell.setAvatar(by: info.name)
            }
        }

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        guard let cell = collectionView.cellForItem(at: indexPath) as? AvatarCollectionCell,
            let option = cell.option
        else {
            if (collectionView.cellForItem(at: indexPath) as? ItemCollectionIconCell) != nil,
               let selected = delegate?.selected {
                let option = selected[indexPath.row]
                if delegate?.deselect(option: option, from: self) == true {
                    SearchTrackUtil.trackPickerSelectClick(scene: scene,
                                                           clickType: .remove(target: Homeric.PUBLIC_PICKER_SELECT_VIEW))
                }
            }
            return
        }
        if delegate?.deselect(option: option, from: self) == true {
            SearchTrackUtil.trackPickerSelectClick(scene: scene,
                                                   clickType: .remove(target: Homeric.PUBLIC_PICKER_SELECT_VIEW))
        }
    }

    @objc
    func unfold(_ button: UIButton) {
        self.delegate?.unfold()
    }
}

private let avatarSize: CGFloat = 40 // 30
private let miniIconSize: CGFloat = 18
private final class AvatarCollectionCell: UICollectionViewCell {

    private let avatarView = BizAvatar()
    private let miniIcon = UIImageView()
    private lazy var thumbnailAvatarView: BizAvatar = {
        let avatarView = BizAvatar()
        avatarView.isHidden = true
        return avatarView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(avatarView)
        avatarView.avatar.ud.setMaskView()
        avatarView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
        }

        miniIcon.isHidden = true
        self.contentView.addSubview(miniIcon)
        miniIcon.snp.makeConstraints { (make) in
            make.bottom.trailing.equalTo(avatarView)
            make.size.equalTo(CGSize(width: miniIconSize, height: miniIconSize))
        }
        self.contentView.addSubview(thumbnailAvatarView)
        let width = avatarSize / 2.0 - 1
        thumbnailAvatarView.avatar.ud.setMaskView()
        thumbnailAvatarView.snp.makeConstraints { make in
            make.bottom.right.equalTo(avatarView)
            make.size.equalTo(CGSize(width: width, height: width))
        }
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var option: Option?

    override func prepareForReuse() {
        super.prepareForReuse()
        option = nil
        avatarView.image = nil
        miniIcon.isHidden = true
        thumbnailAvatarView.isHidden = true
    }

    func setAvatar(identifier: String, key: String, image: UIImage?) {
        self.thumbnailAvatarView.isHidden = image == nil
        if let image = image {
            avatarView.setAvatarByIdentifier("0", avatarKey: "")
            avatarView.image = image
            thumbnailAvatarView.setAvatarByIdentifier(identifier,
                                             avatarKey: key,
                                             scene: .Search,
                                                      avatarViewParams: .init(sizeType: .size(avatarSize / 2.0)))
        } else {
            avatarView.image = nil
            avatarView.setAvatarByIdentifier(identifier,
                                             avatarKey: key,
                                             scene: .Search,
                                             avatarViewParams: .init(sizeType: .size(avatarSize)))
        }
    }

    func setAvatar(by image: UIImage) {
        avatarView.image = image
        self.thumbnailAvatarView.isHidden = true
    }
    func setAvatar(imageURL: String) {
        avatarView.avatar.bt.setImage(URL(string: imageURL))
        self.thumbnailAvatarView.isHidden = true
    }
    func setAvatar(by name: String) {
        let image = self.generateAvatarImage(withNameString: String(name.prefix(2)).uppercased())
        avatarView.image = image
        self.thumbnailAvatarView.isHidden = true
    }
    func setMiniIcon(image: UIImage?) {
        guard let image = image else { return }
        miniIcon.image = image
        miniIcon.isHidden = false
    }

    // nolint: duplicated_code 生成图片的逻辑不同
    private func generateAvatarImage(withNameString string: String) -> UIImage? {
        var attribute = [NSAttributedString.Key: Any]()
        attribute[NSAttributedString.Key.foregroundColor] = UIColor.ud.bgBody
        attribute[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 20)
        let nameString = NSAttributedString(string: string, attributes: attribute)
        let stringSize = nameString.boundingRect(with: CGSize(width: 100.0, height: 100.0),
                                                 options: .usesLineFragmentOrigin,
                                                 context: nil)
        let padding: CGFloat = 8.0    // 10.0
        let width = max(stringSize.width, stringSize.height) + padding * 2
        let size = CGSize(width: width, height: width)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size),
                                cornerRadius: size.width / 2.0)
        UIColor.ud.functionInfoContentDefault.setFill()
        path.fill()
        nameString.draw(at: CGPoint(x: (size.width - stringSize.width) / 2.0,
                                    y: (size.height - stringSize.height) / 2.0))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    // enable-lint: duplicated_code
}
