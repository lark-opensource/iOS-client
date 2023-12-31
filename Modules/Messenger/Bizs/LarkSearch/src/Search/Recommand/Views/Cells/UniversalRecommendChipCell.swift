//
//  UniversalRecommendChipCell.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/12.
//

import UIKit
import Foundation
import UniverseDesignIcon
import LarkAccountInterface

// 一行显示多个title的流式cell
final class UniversalRecommendChipCell: UITableViewCell, SearchCellProtocol {
    static var textFont: UIFont { UIFont.systemFont(ofSize: 14) }
    static var cellHeight: CGFloat { 40 }
    static var itemHeight: CGFloat { 28 }
    static var spacing: CGFloat { 12 }
    static var padding: CGFloat { 8 }
    static var cornerRadius: CGFloat { 8 }
    static var inset: CGFloat { 8 }
    static var foldBtnWidth: CGFloat { 35 }
    static var noQueryIconWidth: CGFloat { 16 }

    var touchFold: ((Bool) -> Void)? // (currentIsFold)
    var touchItem: ((Int) -> Void)? // (index)

    enum FoldType {
        case none, fold, unfold
    }
    private var items: [UIButton] = [] {
        willSet { items.forEach { $0.removeFromSuperview() } }
        didSet {
            items.forEach {
                contentView.addSubview($0)
                $0.addTarget(self, action: #selector(touch(item:)), for: .touchUpInside)
            }
        }
    }
    lazy var foldIcon = { () -> UIButton in
        let btn = UIButton()
        btn.frame = CGRect(origin: .zero, size: CGSize(width: Self.foldBtnWidth, height: Self.itemHeight))
        // bug? target action not work.. non-lazy var shouldn't access self
        btn.addTarget(self, action: #selector(touch(fold:)), for: .touchUpInside)
        btn.setImage(Resources.icon_down_outlined.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.imageView?.tintColor = UIColor.ud.N800
        btn.contentEdgeInsets = .init(horizontal: 8, vertical: 7) // size 16
        btn.contentMode = .center
        btn.backgroundColor = UIColor.ud.bgBody
        btn.layer.cornerRadius = Self.cornerRadius
        return btn
    }()
    // 计算给定宽度能放下几个items
    static func layout<T>(in width: CGFloat, items: T, fold: FoldType, sample: UILabel) -> Int where T: Sequence, T.Element == UniversalRecommendChipItem {
        var left = width - Self.inset * 2
        if fold != .none {
            left -= Self.foldBtnWidth + Self.spacing // give fold button space
        }
        var count = 0
        for i in items {
            var tw: CGFloat = 0
            if case let .history(history) = i.content,
               history.iconStyle == .noQuery {
                sample.text = history.noQueryDigest

                tw = sample.intrinsicContentSize.width + self.noQueryIconWidth + Self.padding * 3
            } else {
                sample.text = i.title
                tw = sample.intrinsicContentSize.width + Self.padding * 2
            }
            if tw <= left {
                count += 1
                left -= tw + Self.spacing
            } else {
                if left >= width / 3 { count += 1 } // 剩余空间较多时，进行压缩，放一个item
                break
            }
        }
        // 最少放1个
        return max(count, 1)
    }
    static func makeLabel() -> UILabel {
        let label = UILabel()
        label.font = textFont
        return label
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupView()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        selectionStyle = .none
        backgroundColor = nil
        backgroundView = UIView()
        contentView.backgroundColor = UIColor.ud.bgBase
    }

    func setup(withViewModel viewModel: SearchCellPresentable, currentAccount: User?) {
        guard let viewModel = viewModel as? UniversalRecommendChipCellPresentable else { return }
        self.items = viewModel.items.compactMap {
            let itemButton = UIButton()
            itemButton.titleLabel?.font = Self.textFont
            itemButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
            itemButton.backgroundColor = UIColor.ud.bgBody
            itemButton.titleLabel?.lineBreakMode = .byTruncatingTail
            switch $0.iconStyle {
            case .circle:
                itemButton.contentEdgeInsets = UIEdgeInsets(horizontal: Self.padding, vertical: 4)
                itemButton.setTitle($0.title, for: .normal)
                itemButton.layer.cornerRadius = Self.itemHeight / 2
            case .rectangle:
                itemButton.contentEdgeInsets = UIEdgeInsets(horizontal: Self.padding, vertical: 4)
                let query = $0.title
                itemButton.setTitle($0.title, for: .normal)
                itemButton.layer.cornerRadius = Self.cornerRadius
            case .noQuery:
                if case let .history(history) = $0.content {
                    itemButton.setTitle(history.noQueryDigest, for: .normal)
                    if history.noQueryDigest.isEmpty {
                        /// 对于FG过滤的搜索历史，不展示
                        return nil
                    }
                }
                itemButton.layer.cornerRadius = Self.cornerRadius
                itemButton.setImage(Resources.listFilterOutlined, for: .normal)
                itemButton.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: Self.padding, bottom: 0.0, right: -Self.padding)
                itemButton.contentEdgeInsets = UIEdgeInsets(top: 4.0, left: Self.padding, bottom: 4.0, right: Self.padding * 2)

                itemButton.imageView?.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                itemButton.imageView?.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

                itemButton.titleLabel?.setContentHuggingPriority(.defaultLow, for: .horizontal)
                itemButton.titleLabel?.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            }
            return itemButton
        }
        touchFold = viewModel.didSelectFold
        touchItem = viewModel.didSelectItem
        // layout
        guard let width = viewModel.sectionWidth?() else {
            assertionFailure("sectionWidth not implemented")
            return
        }
        var maxX = width - Self.inset
        if viewModel.foldType != .none {
            maxX -= Self.foldBtnWidth + Self.spacing // give fold button space
        }
        var x = Self.inset
        for i in self.items {
            i.sizeToFit()
            i.frame.size.height = Self.itemHeight // 保证高度和foldbtn一致
            i.frame.origin.x = x
            i.center.y = Self.cellHeight / 2
            x = i.frame.maxX + Self.spacing
        }
        if let last = self.items.last, last.frame.maxX > maxX {
            // compress last label to ensure fold and inset
            x = maxX + Self.spacing
            last.frame.size.width = max(maxX - last.frame.minX, 0)
        }

        if viewModel.foldType == .none {
            foldIcon.removeFromSuperview()
        } else {
            contentView.addSubview(foldIcon)
            if viewModel.foldType == .fold {
                foldIcon.tag = 0
                foldIcon.transform = .identity
            } else {
                foldIcon.tag = 1
                foldIcon.transform = .init(rotationAngle: CGFloat.pi)
            }
            foldIcon.frame.origin.x = x
            foldIcon.center.y = Self.cellHeight / 2
        }
    }

    @objc
    func touch(fold button: UIButton) {
        touchFold?(button.tag == 0)
    }
    @objc
    func touch(item button: UIButton) {
        guard let index = items.firstIndex(of: button) else {
            return
        }
        touchItem?(index)
    }
}
