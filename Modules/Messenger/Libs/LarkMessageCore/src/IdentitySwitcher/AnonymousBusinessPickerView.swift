//
//  AnonymousBusinessPickerView.swift
//  LarkThread
//
//  Created by bytedance on 2020/11/4.
//
import Foundation
import LarkUIKit
import SnapKit
import LarkBizAvatar
import UIKit
import UniverseDesignBadge

public protocol AnonymousBusinessPickerViewDelegate: AnyObject {
    func pickViewDidSelectItem(pickView: AnonymousBusinessPickerView, selectedIndex: Int?, entityID: String?)
    func pickViewWillDidReceiveUserInteraction(selectedIndex: Int?)
    func pickViewWillDismiss(pickView: AnonymousBusinessPickerView)
}

public extension AnonymousBusinessPickerViewDelegate {
    func pickViewWillDidReceiveUserInteraction(selectedIndex: Int?) {}
}

public final class PickerItem {
    let icon: UIImage?
    let normalImage: UIImage?
    let seletedImage: UIImage
    /// 如果有avatarKey，会忽略icon
    let avatarKey: String?
    let entityId: String?
    let title: String
    let subTitle: String
    let badgeCount: Int
    var canSelect: Bool = true
    fileprivate var selected: Bool = false

    public init(icon: UIImage?,
                normalImage: UIImage? = nil,
                seletedImage: UIImage = BundleResources.identitySelected,
                avatarKey: String?,
                entityId: String?,
                title: String,
                subTitle: String,
                badgeCount: Int,
                canSelect: Bool) {
        self.icon = icon
        self.normalImage = normalImage
        self.seletedImage = seletedImage
        self.avatarKey = avatarKey
        self.entityId = entityId
        self.title = title
        self.subTitle = subTitle
        self.badgeCount = badgeCount
        self.canSelect = canSelect
    }
}

public final class AnonymousPickerItemView: UIView {

    let item: PickerItem
    let tapHander: (PickerItem) -> Void
    let rightImageView = UIImageView()
    private lazy var iconImageView: BizAvatar = {
        let avatar = BizAvatar()
        avatar.backgroundColor = UIColor.ud.N300
        return avatar
    }()
    let titleLabel = UILabel()
    let subTitleLabel = UILabel()
    let coverView = UIView()
    let lineView = UIView()
    weak var delegate: AnyObject?

    init(item: PickerItem,
         tapHander: @escaping (PickerItem) -> Void) {
        self.item = item
        self.tapHander = tapHander
        super.init(frame: .zero)
        self.addTapGes()
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addTapGes() {
        let ges = UITapGestureRecognizer(target: self, action: #selector(pickerViewClick))
        self.addGestureRecognizer(ges)
    }

    @objc
    private func pickerViewClick() {
        if !self.item.canSelect {
            return
        }
        self.tapHander(self.item)
    }

    private func setup() {
        if let icon = self.item.icon {
            iconImageView.image = icon
        } else if let key = self.item.avatarKey, let entityId = self.item.entityId {
            iconImageView.setAvatarByIdentifier(entityId,
                                                avatarKey: key,
                                                scene: .Moments,
                                                backgroundColorWhenError: UIColor.ud.N300)
        }
        self.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 48, height: 48))
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        if item.badgeCount > 0 {
            let badge = iconImageView.addBadge(.number, anchor: .topRight, anchorType: .rectangle)
            badge.config.number = item.badgeCount
            badge.config.anchorOffset = .init(width: -7, height: 7)
        }

        let containView = UIView()
        containView.isUserInteractionEnabled = false
        self.addSubview(containView)
        containView.snp.makeConstraints { (make) in
            make.left.equalTo(iconImageView.snp.right).offset(12)
            make.right.equalToSuperview().offset(55)
            make.centerY.equalToSuperview()
        }

        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.text = self.item.title
        containView.addSubview(titleLabel)
        subTitleLabel.text = self.item.subTitle
        subTitleLabel.font = UIFont.systemFont(ofSize: 14)
        containView.addSubview(subTitleLabel)
        subTitleLabel.isHidden = self.item.subTitle.isEmpty
        self.addSubview(rightImageView)
        rightImageView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-18)
            make.centerY.equalToSuperview()
            make.size.equalTo(item.seletedImage.size)
        }
        updateRightImageView()
        titleLabel.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview()
            make.right.equalTo(rightImageView.snp.left).offset(8)
        }

        let offset = self.item.subTitle.isEmpty ? 0 : 4
        subTitleLabel.snp.makeConstraints { (make) in
            make.left.bottom.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(offset)
            make.right.equalTo(rightImageView.snp.left).offset(8)
        }

        coverView.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.5)
        self.addSubview(coverView)
        coverView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        coverView.isHidden = self.item.canSelect
        self.addSubview(lineView)
        lineView.backgroundColor = UIColor.ud.commonTableSeparatorColor
        lineView.snp.makeConstraints { (make) in
            make.left.equalTo(containView)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        lineView.isHidden = true
    }

    func showLineView(_ show: Bool) {
        self.lineView.isHidden = !show
    }

    /// 更新右侧标签
    func updateRightImageView() {
        if let normalImage = item.normalImage {
            rightImageView.image = item.selected ? item.seletedImage : normalImage
            rightImageView.isHidden = false
        } else {
            rightImageView.image = item.seletedImage
            rightImageView.isHidden = !self.item.selected
        }
    }

    func reloadData() {
        updateRightImageView()
        if let icon = self.item.icon {
            iconImageView.image = icon
        } else if let key = self.item.avatarKey, let entityId = self.item.entityId {
            iconImageView.setAvatarByIdentifier(entityId,
                                                avatarKey: key,
                                                scene: .Moments,
                                                backgroundColorWhenError: UIColor.ud.N300)
        }
        titleLabel.text = self.item.title
        subTitleLabel.text = self.item.subTitle
        coverView.isHidden = self.item.canSelect
        // 是否有文案 更新约束
        let offset = self.item.subTitle.isEmpty ? 0 : 4
        subTitleLabel.snp.updateConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(offset)
        }
    }
}

public final class AnonymousBusinessPickerView: UIView {
    //展示样式
    public enum ShowStyle {
        //会有一个自下而上弹出的动画效果；依赖Bottom布局
        case animateToShow
        //依赖Top来布局
        case alwaysAlignTop
    }

    /// view弹出的样式
    public let showStyle: ShowStyle
    /// 点击之后是否会自动消失 default is true
    public var autoDismiss: Bool = true
    private let title: String
    private let defaultIndex: Int?
    private let showBottomLine: Bool
    private let containerView: UIView = UIView()
    public var containerHeight = 0
    private var pickItems: [PickerItem] = []
    private var pickItemViews: [AnonymousPickerItemView] = []
    public let contentBackgroundColor: UIColor = .ud.bgBody
    public weak var delegate: AnonymousBusinessPickerViewDelegate?

    public init(title: String,
                showStyle: ShowStyle,
                showBottomLine: Bool = true,
                pickItems: [PickerItem],
                defaultIndex: Int? = nil) {
        self.pickItems = pickItems
        self.showStyle = showStyle
        self.defaultIndex = defaultIndex
        self.title = title
        self.showBottomLine = showBottomLine
        super.init(frame: .zero)
        self.backgroundColor = showStyle == .alwaysAlignTop ? contentBackgroundColor : UIColor.ud.bgMask
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        // 避免子视图动画超过自身
        self.clipsToBounds = true
        // 添加点击手势
        let tap = UITapGestureRecognizer(target: self, action: #selector(pickerViewBgClick))
        self.addGestureRecognizer(tap)
        containerView.backgroundColor = .clear
        self.addSubview(self.containerView)
        let titleHeight = 49
        let containerHeight = titleHeight + self.pickItems.count * 72
        self.containerHeight = containerHeight
        if self.showStyle == .alwaysAlignTop {
            containerView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.height.equalTo(containerHeight)
                make.top.equalToSuperview()
            }
        } else {
            containerView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.height.equalTo(containerHeight)
                make.top.equalTo(self.snp.bottom).offset(0)
            }
        }

        if let defaultIndex = defaultIndex, defaultIndex >= 0 && defaultIndex < self.pickItems.count {
            self.pickItems[defaultIndex].selected = true
        }

        let titleBgView = UIView()
        titleBgView.backgroundColor = contentBackgroundColor
        containerView.addSubview(titleBgView)

        let titleBgViewCorner: CGFloat = 12
        titleBgView.layer.cornerRadius = titleBgViewCorner
        titleBgView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(titleHeight)
        }

        let coverView = UIView()
        coverView.backgroundColor = contentBackgroundColor
        containerView.addSubview(coverView)
        coverView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(titleBgView)
            make.height.equalTo(titleBgViewCorner)
        }
        // 添加粗一点的黑线
        self.addLineView(lineSuperView: coverView)

        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.text = self.title
        titleLabel.textAlignment = .left
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(titleHeight)
        }

        var lastView: UIView = titleLabel
        for (index, item) in self.pickItems.enumerated() {
            let view = AnonymousPickerItemView(item: item, tapHander: { [weak self] (pickerItem) in
                self?.updateDataWithPickerItem(pickerItem)
                self?.reloadData()
                self?.dismissPickView(selectedIdx: index)
            })
            containerView.addSubview(view)
            view.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.height.equalTo(72)
                make.top.equalTo(lastView.snp.bottom)
            }
            lastView = view
            pickItemViews.append(view)
            // 黑线
            var showLineView = true
            if index == self.pickItems.count - 1 {
                showLineView = false
            }
            view.showLineView(showLineView)
            view.backgroundColor = contentBackgroundColor
        }
        if self.showBottomLine {
            containerView.lu.addBottomBorder()
        }
    }

    private func addLineView(lineSuperView: UIView) {
        let view = UIView()
        view.backgroundColor = UIColor.ud.commonTableSeparatorColor
        lineSuperView.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    @objc
    private func pickerViewBgClick() {
        self.dismissPickView()
    }

    private func dismissPickView(selectedIdx: Int? = nil) {
        self.delegate?.pickViewWillDidReceiveUserInteraction(selectedIndex: selectedIdx)
        if self.autoDismiss {
            self.delegate?.pickViewWillDismiss(pickView: self)
            self.hidePickerView()
        }
    }

    public func showPickerView() {
        if self.showStyle == .alwaysAlignTop {
            return
        }
        // 这里为了保证动画的纯粹 在updateConstraints之前先将其他需要更新的约束更新完成 再做动画
        self.containerView.layoutIfNeeded()
        self.containerView.snp.updateConstraints { (make) in
            make.top.equalTo(self.snp.bottom).offset(-self.containerHeight)
        }
        self.animationForPickView(nil)
    }

    public func hidePickerView() {
        if self.showStyle == .animateToShow {
            self.containerView.snp.updateConstraints { (make) in
                make.top.equalTo(self.snp.bottom).offset(0)
            }
        }
        self.animationForPickView { [weak self] in
            self?.removeFromSuperview()
        }
    }

    func animationForPickView(_ completion: (() -> Void)?) {
        self.setNeedsUpdateConstraints()
        let duration = self.showStyle == .animateToShow ? 0.25 : 0
        UIView.animate(withDuration: duration) { [weak self] in
            self?.layoutIfNeeded()
        } completion: { (_) in
            completion?()
        }
    }

    public func setSelectIndex(_ index: Int) {
        // 数组越界 或者 < 0
        if index >= self.pickItems.count || index < 0 {
            return
        }
        self.setItemSelectStatus(pickerItem: self.pickItems[index])
        self.reloadData()
    }

    private func updateDataWithPickerItem(_ pickerItem: PickerItem) {
        if pickerItem.selected {
            return
        }
        delegate?.pickViewDidSelectItem(pickView: self, selectedIndex: self.pickItems.firstIndex(where: { (item) -> Bool in
            return item === pickerItem
        }), entityID: pickerItem.entityId)
        self.setItemSelectStatus(pickerItem: pickerItem)
    }

    private func setItemSelectStatus(pickerItem: PickerItem) {
        self.pickItems.forEach { (item) in
            item.selected = false
        }
        pickerItem.selected = true
    }

    private func reloadData() {
        for view in self.pickItemViews {
            view.reloadData()
        }
    }

    public func selectedSubview() -> UIView? {
        return self.pickItemViews.first { $0.item.selected }
    }

}
