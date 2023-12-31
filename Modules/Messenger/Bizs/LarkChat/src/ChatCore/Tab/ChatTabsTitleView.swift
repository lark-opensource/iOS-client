//
//  ChatTabsTitleView.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/3/23.
//

import UIKit
import Foundation
import LarkFeatureGating
import SnapKit
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon
import RxSwift
import RxCocoa
import LarkBadge
import LarkOpenChat
import LKCommonsLogging
import LarkRichTextCore
import ByteWebImage

protocol ChatTabsTitleRouter: AnyObject {
    func clickTab(_ tabId: Int64)
    func clickAdd(_ button: UIButton)
    func clickManage(_ button: UIButton, displayCount: Int)
}

final class ChatTabsTitleView: UIView {
    static let ViewHeight: CGFloat = 44

    /// collection 右侧 margin
    private static let RightMargin: CGFloat = 48
    private static let collectionPaddingLeft: CGFloat = 8
    private static let collectionPaddingRight: CGFloat = 8
    private static let collectionMinimumInteritemSpacing: CGFloat = 8
    private static let maxLength: Int = 16

    private let disposeBag = DisposeBag()
    private var originTabModels: [ChatTabTitleModel] = []
    /// collection 数据源
    private var dataSource: [ChatTabTitleModel] = []
    private var rightConstraint: SnapKit.Constraint?
    /// 计算的文本宽度缓存
    private var titleWidthCache: [String: CGFloat] = [:]
    private var containerWidth: CGFloat
    var lastCollectionItemWidth: CGFloat?
    weak var router: ChatTabsTitleRouter?
    private var panHandler: ((UIPanGestureRecognizer) -> Void)?

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = Self.collectionMinimumInteritemSpacing
        layout.headerReferenceSize = CGSize(width: Self.collectionPaddingLeft, height: 0)
        layout.footerReferenceSize = CGSize(width: Self.collectionPaddingRight, height: 0)
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(ChatTabTitleCell.self, forCellWithReuseIdentifier: ChatTabTitleCell.reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

    lazy var manageButton: UIButton = {
        let manageButton = UIButton()
        manageButton.imageEdgeInsets = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        manageButton.setImage(UDIcon.getIconByKey(.moreBoldOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 16, height: 16)), for: .normal)
        manageButton.addTarget(self, action: #selector(clickManagement(_:)), for: .touchUpInside)
        return manageButton
    }()

    lazy var addButton: UIButton = {
        let addButton = UIButton()
        addButton.imageEdgeInsets = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        addButton.setImage(UDIcon.getIconByKey(.addMiddleOutlined, size: CGSize(width: 16, height: 16)).withRenderingMode(.alwaysTemplate), for: .normal)
        addButton.addTarget(self, action: #selector(clickAdd(_:)), for: .touchUpInside)
        return addButton
    }()

    init(containerWidth: CGFloat, enableAddDriver: Driver<Bool>) {
        self.containerWidth = containerWidth
        super.init(frame: .zero)

        self.addSubview(collectionView)
        self.addSubview(manageButton)
        self.addSubview(addButton)
        collectionView.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview()
            self.rightConstraint = make.right.equalToSuperview().inset(Self.RightMargin).constraint
        }
        manageButton.snp.makeConstraints { make in
            make.width.equalTo(48)
            make.height.equalTo(44)
            make.centerY.equalToSuperview()
            make.left.equalTo(collectionView.snp.right)
        }
        addButton.snp.makeConstraints { make in
            make.width.equalTo(48)
            make.height.equalTo(44)
            make.centerY.equalToSuperview()
            make.left.equalTo(collectionView.snp.right)
        }
        enableAddDriver
            .distinctUntilChanged()
            .drive(onNext: { [weak self] enable in
                self?.addButton.tintColor = enable ? UIColor.ud.iconN2 : UIColor.ud.iconDisabled
            }).disposed(by: self.disposeBag)

        let panGes = UIPanGestureRecognizer(target: self, action: #selector(panGes))
        self.addGestureRecognizer(panGes)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setModels(_ models: [ChatTabTitleModel]) {
        var originTabModels: [ChatTabTitleModel] = models.map { model in
            var model = model
            let title = model.title
            if self.getLength(forText: title) > Self.maxLength {
                model.title = self.getPrefix(Self.maxLength, forText: title) + "..."
            }
            return model
        }
        self.originTabModels = originTabModels
        self.reloadData()
    }

    func resizeIfNeeded(_ width: CGFloat) {
        guard self.containerWidth != width else { return }
        self.containerWidth = width
        self.reloadData()
    }

    private func reloadData() {
        let result = self.calculateCollectionLayout(self.originTabModels.map { ($0.title, $0.count) })
        let collectionWidth = result.0
        let showNumber = result.1

        if showNumber == self.originTabModels.count {
            self.addButton.isHidden = false
            self.manageButton.isHidden = true
        } else {
            self.addButton.isHidden = true
            self.manageButton.isHidden = false
        }
        self.dataSource = Array(self.originTabModels.prefix(showNumber))
        self.collectionView.reloadData()
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.rightConstraint?.update(inset: self.containerWidth - collectionWidth)
    }

    private func calculateTitleWidth(_ title: String) -> CGFloat {
        if let width = self.titleWidthCache[title] {
            return width
        } else {
            let textWidth = NSString(string: title)
                .boundingRect(with: CGSize(width: CGFloat.infinity,
                                           height: CGFloat.infinity),
                              options: [.usesFontLeading,
                                        .usesLineFragmentOrigin],
                              attributes: [NSAttributedString.Key.font: ChatTabTitleCell.Layout.titleFont],
                              context: nil).size.width
            let calculatedWidth = CGFloat(ceilf(Float(textWidth)))
            self.titleWidthCache[title] = calculatedWidth
            return calculatedWidth
        }
    }

    private func calculateCollectionLayout(_ titleAndCountArray: [(String, Int?)]) -> (CGFloat, Int) {
        var totalContentWidth: CGFloat = Self.collectionPaddingLeft + Self.collectionPaddingRight
        let maxCollectionWidth = self.containerWidth - Self.RightMargin

        for (index, titleAndCount) in titleAndCountArray.enumerated() {
            var countWidth: CGFloat?
            if let count = titleAndCount.1 {
                countWidth = self.calculateTitleWidth("\(count)")
            }
            var addedWidth: CGFloat = ChatTabTitleCell.Layout.calculateCellWidth(self.calculateTitleWidth(titleAndCount.0), countWidth: countWidth)
            if index != 0 {
                addedWidth += Self.collectionMinimumInteritemSpacing
            }
            totalContentWidth += addedWidth

            if totalContentWidth > maxCollectionWidth {
                let remainWidth: CGFloat = maxCollectionWidth - totalContentWidth + addedWidth
                if remainWidth > 72 {
                    lastCollectionItemWidth = remainWidth - Self.collectionMinimumInteritemSpacing
                    return (maxCollectionWidth, index + 1)
                }
                lastCollectionItemWidth = nil
                return (totalContentWidth - addedWidth, index)
            }
        }
        lastCollectionItemWidth = nil
        return (totalContentWidth, titleAndCountArray.count)
    }

    // 按照特定字符计数规则，获取字符串长度
    private func getLength(forText text: String) -> Int {
        return text.reduce(0) { res, char in
            // 单字节的 UTF-8（英文、半角符号）算 1 个字符，其余的（中文、Emoji等）算 2 个字符
            return res + min(char.utf8.count, 2)
        }
    }

    // 按照特定字符计数规则，截取字符串
    private func getPrefix(_ maxLength: Int, forText text: String) -> String {
        guard maxLength >= 0 else { return "" }
        var currentLength: Int = 0
        var maxIndex: Int = 0
        for (index, char) in text.enumerated() {
            guard currentLength <= maxLength else { break }
            currentLength += min(char.utf8.count, 2)
            maxIndex = index
        }
        return String(text.prefix(maxIndex))
    }

    @objc
    private func clickAdd(_ button: UIButton) {
        self.router?.clickAdd(button)
    }

    @objc
    private func clickManagement(_ button: UIButton) {
        self.router?.clickManage(button, displayCount: dataSource.count)
    }

    func getTabItemView(_ tabId: Int64) -> UIView? {
        guard let index = self.dataSource.firstIndex(where: { $0.tabId == tabId }) else {
            return nil
        }
        return self.collectionView.cellForItem(at: IndexPath(item: index, section: 0))
    }
}

extension ChatTabsTitleView: UICollectionViewDataSource, UICollectionViewDelegate {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = dataSource[indexPath.item]
        let tabId = model.tabId
        self.router?.clickTab(tabId)
        if let badgePath = model.badgePath {
            BadgeManager.clearBadge(badgePath)
        }
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatTabTitleCell.reuseIdentifier, for: indexPath) as? ChatTabTitleCell else {
            return UICollectionViewCell()
        }
        cell.reloadData(model: dataSource[indexPath.item])
        return cell
    }
}

extension ChatTabsTitleView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.item == dataSource.count - 1, let lastItemWidth = self.lastCollectionItemWidth {
            return CGSize(width: lastItemWidth, height: collectionView.bounds.size.height)
        }
        let model = dataSource[indexPath.item]
        let titleWidth = self.calculateTitleWidth(model.title)
        var countWidth: CGFloat?
        if let count = model.count {
            countWidth = self.calculateTitleWidth("\(count)")
        }
        return CGSize(width: ChatTabTitleCell.Layout.calculateCellWidth(titleWidth, countWidth: countWidth), height: collectionView.bounds.size.height)
    }
}

extension ChatTabsTitleView {
    @objc
    private func panGes(_ getsture: UIPanGestureRecognizer) {
        self.panHandler?(getsture)
    }

    func observePanGesture(_ panHandler: @escaping (UIPanGestureRecognizer) -> Void) {
        self.panHandler = panHandler
    }
}

final class ChatTabTitleCell: UICollectionViewCell {
    static let logger = Logger.log(ChatTabTitleCell.self, category: "Module.IM.ChatTab")
    static let reuseIdentifier: String = "ChatTabTitleCell"
    struct Layout {
        static let marginRight: CGFloat = 8
        static let marginLeft: CGFloat = 8
        static let iconSize: CGFloat = 16
        static let internalSpacing: CGFloat = 2
        static let titleFont: UIFont = UIFont.systemFont(ofSize: 14, weight: .regular)

        static func calculateCellWidth(_ titleWidth: CGFloat, countWidth: CGFloat?) -> CGFloat {
            /// (marginLeft + iconSize + internalSpacing + marginRight) = 34
            var cellWidth: CGFloat = titleWidth + 34
            if let countWidth = countWidth {
                cellWidth += 2
                cellWidth += countWidth
            }
            return cellWidth
        }
    }

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = Layout.titleFont
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return titleLabel
    }()

    private lazy var countLabel: UILabel = {
        let countLabel = UILabel()
        countLabel.font = Layout.titleFont
        countLabel.textColor = UIColor.ud.textTitle
        return countLabel
    }()

    private lazy var selectedMaskView: UIView = {
        let maskView = UIView()
        maskView.backgroundColor = UIColor.ud.fillActive.withAlphaComponent(0.12)
        maskView.layer.cornerRadius = 6
        return maskView
    }()

    private lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        return iconView
    }()

    private lazy var badgeView: UIView = {
        return UIView()
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(selectedMaskView)
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)
        contentView.addSubview(badgeView)
        selectedMaskView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().inset(6)
        }
        iconView.snp.makeConstraints { make in
            make.size.equalTo(Layout.iconSize)
            make.centerY.equalToSuperview().offset(2)
            make.left.equalToSuperview().inset(Layout.marginLeft)
        }
        badgeView.snp.makeConstraints { make in
            make.width.height.equalTo(6)
            make.top.equalToSuperview().inset(14)
            make.right.equalToSuperview()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.iconView.bt.setLarkImage(with: .default(key: ""))
    }

    func reloadData(model: ChatTabTitleModel) {
        switch model.imageResource {
        case .image(let image):
            self.iconView.image = image
        case .key(key: let key, config: let config):
            var passThrough: ImagePassThrough?
            if let pbModel = config?.imageSetPassThrough {
                passThrough = ImagePassThrough.transform(passthrough: pbModel)
            }
            self.iconView.bt.setLarkImage(with: .default(key: key),
                                          placeholder: config?.placeholder,
                                          passThrough: passThrough) { [weak self] res in
                guard let self = self else { return }
                switch res {
                case .success(let imageResult):
                    guard let image = imageResult.image else { return }
                    if let tintColor = config?.tintColor {
                        self.iconView.image = image.ud.withTintColor(tintColor)
                    } else {
                        self.iconView.image = image
                    }
                case .failure(let error):
                    Self.logger.error("set image fail", error: error)
                }
            }
        }
        self.titleLabel.text = model.title
        if model.isSelected {
            self.titleLabel.textColor = UIColor.ud.primaryContentDefault
            self.titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            self.selectedMaskView.isHidden = false
        } else {
            self.titleLabel.textColor = UIColor.ud.textTitle
            self.titleLabel.font = Layout.titleFont
            self.selectedMaskView.isHidden = true
        }

        if let count = model.count {
            countLabel.snp.remakeConstraints { make in
                make.centerY.equalToSuperview().offset(2)
                make.left.equalTo(iconView.snp.right).offset(Layout.internalSpacing)
            }
            titleLabel.snp.remakeConstraints { make in
                make.centerY.equalTo(countLabel)
                make.left.equalTo(countLabel.snp.right).offset(Layout.internalSpacing)
                make.right.equalToSuperview().inset(Layout.marginRight)
            }
            countLabel.isHidden = false
            countLabel.text = "\(count)"
        } else {
            titleLabel.snp.remakeConstraints { make in
                make.centerY.equalToSuperview().offset(2)
                make.left.equalTo(iconView.snp.right).offset(Layout.internalSpacing)
                make.right.equalToSuperview().inset(model.isSelected ? 0 : Layout.marginRight)
            }
            countLabel.isHidden = true
        }

        self.badgeView.isHidden = true
        self.badgeView.badge.removeAllObserver()
        if let badgePath = model.badgePath {
            self.badgeView.isHidden = false
            badgeView.badge.observe(for: badgePath)
            badgeView.badge.set(size: CGSize(width: 6, height: 6))
            badgeView.badge.set(cornerRadius: 3)
            badgeView.badge.set(offset: CGPoint(x: -3, y: 3))
        }
    }
}

struct ChatTabTitleModel {
    var tabId: Int64
    var title: String
    var isSelected: Bool
    var imageResource: ChatTabImageResource
    var badgePath: Path?
    var count: Int?
}
