//
//  SpaceNewTabMutilHeaderView.swift
//  SKSpace
//
//  Created by majie.7 on 2023/9/12.
//

import Foundation
import UIKit
import UniverseDesignColor
import SKFoundation


public class SpaceNewTabPickerView: UIView {
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 8
        return view
    }()
    
    private var itemViews: [ItemView] = []
    private var currentItemIndex = 0
    private var currentItemView: ItemView { itemViews[currentItemIndex] }
    
    public var clickHandler: ((Int) -> Void)?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.center.equalToSuperview()
        }
    }
    
    public func cleanUP() {
        itemViews.forEach { $0.removeFromSuperview() }
        itemViews = []
        currentItemIndex = 0
    }
    
    public func update(items: [SpaceMultiListPickerItem], currentIndex: Int) {
        guard !items.isEmpty else {
            DocsLogger.error("space.new.tab.multi-list.header --- sub sections is empty when setup")
            return
        }
        
        setup(items: items)
        currentItemIndex = currentIndex
        if currentIndex >= items.count {
            assertionFailure("space.multi-list.header --- current index out of bounds!")
            currentItemIndex = 0
        }
        currentItemView.update(isSelected: true)
    }
    
    private func setup(items: [SpaceMultiListPickerItem]) {
        for (index, item) in items.enumerated() {
            let itemView = ItemView(item: item) { [weak self] in
                self?.didClick(index: index)
            }
            itemViews.append(itemView)
            stackView.addArrangedSubview(itemView)
            itemView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.centerY.equalToSuperview()
            }
        }
    }
    
    private func didClick(index: Int) {
        guard index < itemViews.count else {
            spaceAssertionFailure("section index out of range")
            return
        }
        if currentItemIndex == index { return }
        currentItemView.update(isSelected: false)
        currentItemIndex = index
        currentItemView.update(isSelected: true)
        clickHandler?(index)
    }
}

private extension SpaceNewTabPickerView {
    typealias Item = SpaceMultiListPickerItem
    
    class ItemView: UIView {
        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 17, weight: .regular)
            label.textAlignment = .center
            label.textColor = UDColor.textPlaceholder
            label.isUserInteractionEnabled = true
            return label
        }()
        
        private lazy var indicatorView: UIView = {
            let view = UIView()
            view.layer.cornerRadius = 2
            view.backgroundColor = UDColor.textLinkNormal
            return view
        }()
        
        private var clickHandler: () -> Void
        
        init(item: Item, handler: @escaping () -> Void) {
            self.clickHandler = handler
            super.init(frame: .zero)
            setupUI(item: item)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupUI(item: Item) {
            addSubview(titleLabel)
            addSubview(indicatorView)
            
            titleLabel.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.right.equalToSuperview().inset(12)
                make.centerY.equalToSuperview()
            }
            
            indicatorView.snp.makeConstraints { make in
                make.height.equalTo(3)
                make.width.equalTo(20)
                make.bottom.equalToSuperview().inset(6)
                make.centerX.equalToSuperview()
            }
            indicatorView.isHidden = true
            
            titleLabel.text = item.title
            let clickGesture = UITapGestureRecognizer(target: self, action: #selector(didClick))
            titleLabel.addGestureRecognizer(clickGesture)
            titleLabel.docs.addHighlight(with: UIEdgeInsets(top: 4, left: -8, bottom: 4, right: -8), radius: 8)
        }
        
        @objc
        private func didClick() {
            clickHandler()
        }
        
        func update(isSelected: Bool) {
            if isSelected {
                titleLabel.textColor = UDColor.textTitle
                titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
                indicatorView.isHidden = false
            } else {
                titleLabel.textColor = UDColor.textPlaceholder
                titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
                indicatorView.isHidden = true
            }
        }
    }
}
