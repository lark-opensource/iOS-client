//
//  BitableMultiListPickerView.swift
//  SKUIKit
//
//  Created by qiyongka on 2023/11/9.
//

import Foundation
import UIKit
import SKFoundation
import SKUIKit
import SKCommon
import UniverseDesignIcon
import UniverseDesignColor

public struct BitableMultiListPickerItem {
    let identifier: String
    let title: String
    init(identifier: String, title: String) {
        self.identifier = identifier
        self.title = title
    }
}

final class BitableMultiListPickerView: UIView {
    private struct Const {
        static let itemSpacing: CGFloat = 12.0
        static let viewCornerRadius: CGFloat = 14.0
        static let titleLabelMargin = 16.0
        static let imageIconMargin = 18.0
    }
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 12
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()
        
    private var itemViews: [BitableMultiListItemView] = []
    
    private var currentItemIndex = 0
 
    var clickHandler: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    func cleanUp() {
        itemViews.forEach { $0.removeFromSuperview() }
        itemViews = []
        currentItemIndex = 0
    }

    func update(items: [BitableMultiListPickerItem], currentIndex: Int) {
        guard !items.isEmpty else {
            DocsLogger.error("bitable.multi-list.header --- sub sections is empty when setup")
            return
        }
        setup(items: items)
        currentItemIndex = currentIndex
        if currentIndex >= items.count {
            assertionFailure("bitable.multi-list.header --- current index out of bounds!")
            currentItemIndex = 0
        }
        let currentItemView = itemViews[currentItemIndex]
        updateStyle(current: currentItemView, last: nil)
    }
    
    private func setup(items: [BitableMultiListPickerItem]) {
        for (index, item) in items.enumerated() {
            let itemView = BitableMultiListItemView(item: item) { [weak self] in
                self?.didClick(index: index)
            }
            itemViews.append(itemView)
            stackView.addArrangedSubview(itemView)
            itemView.snp.makeConstraints { make in
                make.height.equalTo(28)
                make.width.equalTo(itemView.getItemWidth(isSelected: false))
                make.centerY.equalToSuperview()
            }
        }
    }
    
    private func updateStyle(current: BitableMultiListItemView, last: BitableMultiListItemView?) {
        current.snp.updateConstraints { make in
            make.width.equalTo(current.getItemWidth(isSelected: true))
        }
        if let lastItem = last {
            let width = lastItem.getItemWidth(isSelected: false)
            lastItem.snp.updateConstraints({ make in
                make.width.equalTo(width)
            })
        }
        current.update(isSelected: true)
        last?.update(isSelected: false)
    }
    
    private func didClick(index: Int) {
        guard index < itemViews.count else {
            assertionFailure("section index out of range!")
            return
        }
        if currentItemIndex == index { return }
        let selectedView = itemViews[currentItemIndex]
        let willSelectItemView = itemViews[index]
        currentItemIndex = index
        updateStyle(current: willSelectItemView, last: selectedView)
        clickHandler?(index)
    }
}

//MARK: ItemView
private extension BitableMultiListPickerView {
    typealias Item = BitableMultiListPickerItem
    class BitableMultiListItemView: UIView {
        
        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 12, weight: .regular)
            label.textAlignment = .center
            label.textColor = UDColor.textCaption
            label.isUserInteractionEnabled = true
            return label
        }()
 
        private lazy var imgView: UIImageView = {
            let imageView = UIImageView()
            imageView.isHidden = true
            return imageView
        }()
        
        private lazy var bgView: UIView = {
            let bgView = UIView()
            bgView.backgroundColor = UIColor.ud.bgFiller
            bgView.layer.cornerRadius = Const.viewCornerRadius
            bgView.layer.masksToBounds = true
            return bgView
        }()
        
        private var itemInfo: BitableMultiListPickerItem
        private var clickHandler: () -> Void

        init(item: Item,handler: @escaping () -> Void) {
            clickHandler = handler
            itemInfo = item
            super.init(frame: .zero)
            setupUI(item: item)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupUI(item: Item) {
            addSubview(bgView)
            bgView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            titleLabel.text = item.title
            bgView.addSubview(titleLabel)
            titleLabel.sizeToFit()
            titleLabel.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
            }
            
            imgView.image = getIconView(identifier: item.identifier)
            bgView.addSubview(imgView)
            imgView.snp.makeConstraints { make in
                make.width.height.equalTo(14)
                make.centerY.equalToSuperview()
                make.right.equalTo(titleLabel.snp.left).offset(-4)
            }
            let clickGesture = UITapGestureRecognizer(target: self, action: #selector(didClick))
            bgView.addGestureRecognizer(clickGesture)
        }

        @objc
        private func didClick() {
            clickHandler()
        }

        func update(isSelected: Bool) {
            if isSelected {
                titleLabel.textColor = UDColor.textTitle
                titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
                self.imgView.isHidden = false
                
            } else {
                titleLabel.textColor = UDColor.textCaption
                titleLabel.font = .systemFont(ofSize: 12, weight: .regular)
                self.imgView.isHidden = true
            }
        }
        
        private func getIconView(identifier: String) -> UIImage? {
            switch identifier {
            case BitableMultiListSubSectionConfig.recentSectionIdentifier:
                return UDIcon.timeOutlined
            case BitableMultiListSubSectionConfig.quickAccessSectionIdentifier:
                return UDIcon.startOutlined
            case BitableMultiListSubSectionConfig.favoritesSectionIdentifier:
                return UDIcon.collectFilled.ud.withTintColor(UDColor.colorfulYellow)
            default:
                return nil
            }
        }
        
        private func getLabelWidth(title: String, isSelected: Bool) -> CGFloat {
            let constrainedSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            let attributes = [ NSAttributedString.Key.font: isSelected ? UIFont.systemFont(ofSize: 12, weight: .regular) : UIFont.systemFont(ofSize: 12, weight: .medium)]
            let options: NSStringDrawingOptions = [.usesFontLeading, .usesLineFragmentOrigin]
            let bounds = (title as NSString).boundingRect(with: constrainedSize, options: options, attributes: attributes, context: nil)
            return ceil(bounds.size.width)
        }
        
        func getItemWidth(isSelected: Bool) -> CGFloat {
            if isSelected {
                return getLabelWidth(title: itemInfo.title, isSelected: true) + Const.titleLabelMargin * 2 + Const.imageIconMargin
            } else {
                return getLabelWidth(title: itemInfo.title, isSelected: false) + Const.titleLabelMargin * 2
            }
        }
    }
}
