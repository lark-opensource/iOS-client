//
//  SpaceMultiListPickerView.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/3.
//

import UIKit
import SKFoundation

public struct SpaceMultiListPickerItem {
    public let identifier: String
    public let title: String
    public init(identifier: String, title: String) {
        self.identifier = identifier
        self.title = title
    }
}

private extension SpaceMultiListPickerView {

    typealias Item = SpaceMultiListPickerItem

    class ItemView: UIView {
        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 14, weight: .regular)
            label.textAlignment = .center
            label.textColor = UIColor.ud.N600
            label.isUserInteractionEnabled = true
            return label
        }()
        
        private lazy var bgView: UIView = {
            let bgView = UIView()
            bgView.backgroundColor = UIColor.ud.bgFiller
            bgView.layer.cornerRadius = 4
            bgView.layer.masksToBounds = true
            return bgView
        }()

        private lazy var indicatorView: UIView = {
            let view = UIView()
            view.layer.cornerRadius = 2
            view.backgroundColor = UIColor.ud.colorfulBlue
            return view
        }()
        
        var innerLabelWidth : CGFloat = 0.0
        var innerLabelHeight : CGFloat = 0.0

        private var clickHandler: () -> Void

        init(item: Item, newStyle: Bool,handler: @escaping () -> Void) {
            clickHandler = handler
            super.init(frame: .zero)
            if newStyle {
                setupUIForNewStyle(item: item)
            }else{
                setupUI(item: item)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupUI(item: Item) {
            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            addSubview(indicatorView)
            indicatorView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(4)
                make.centerY.equalTo(snp.bottom)
            }
            indicatorView.isHidden = true

            titleLabel.text = item.title
            let clickGesture = UITapGestureRecognizer(target: self, action: #selector(didClick))
            titleLabel.addGestureRecognizer(clickGesture)
            // 加在 titleLabel 上是为了避免 highlight 自带的缩放效果影响底部 indicator 的 UI 效果
            titleLabel.docs.addHighlight(with: UIEdgeInsets(top: 4, left: -8, bottom: 4, right: -8),
                                         radius: 8)
        }
        
        private func setupUIForNewStyle(item: Item) {
            addSubview(bgView)
            bgView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            titleLabel.text = item.title
            bgView.addSubview(titleLabel)
            titleLabel.sizeToFit()
            self.innerLabelWidth = titleLabel.btd_width
            self.innerLabelHeight = titleLabel.btd_height
            titleLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
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
                titleLabel.textColor = UIColor.ud.colorfulBlue
                titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
                indicatorView.isHidden = false
                bgView.backgroundColor = UIColor.ud.primaryFillSolid02
            } else {
                titleLabel.textColor = UIColor.ud.N600
                titleLabel.font = .systemFont(ofSize: 14, weight: .regular)
                indicatorView.isHidden = true
                bgView.backgroundColor = UIColor.ud.bgFiller
            }
        }
    }
}

public final class SpaceMultiListPickerView: UIView {
    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 20
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()

    private var itemViews: [ItemView] = []
    private var currentItemIndex = 0
    private var currentItemView: ItemView { itemViews[currentItemIndex] }
    
    public var clickHandler: ((Int) -> Void)?

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

    public func cleanUp() {
        itemViews.forEach { $0.removeFromSuperview() }
        itemViews = []
        currentItemIndex = 0
    }

    public func update(items: [SpaceMultiListPickerItem], currentIndex: Int, shouldUseNewestStyle: Bool = false) {
        guard !items.isEmpty else {
            DocsLogger.error("space.multi-list.header --- sub sections is empty when setup")
            return
        }
        
        self.stackView.spacing = shouldUseNewestStyle ? 10 : 20
        setup(items: items, shouldUseNewestStyle: shouldUseNewestStyle)
        currentItemIndex = currentIndex
        if currentIndex >= items.count {
            assertionFailure("space.multi-list.header --- current index out of bounds!")
            currentItemIndex = 0
        }
        currentItemView.update(isSelected: true)
    }
    
    private func setup(items: [SpaceMultiListPickerItem], shouldUseNewestStyle: Bool = false) {
        for (index, item) in items.enumerated() {
            let itemView = ItemView(item: item, newStyle: shouldUseNewestStyle) { [weak self] in
                self?.didClick(index: index)
            }
            itemViews.append(itemView)
            stackView.addArrangedSubview(itemView)
            if shouldUseNewestStyle {
                let itemW  = itemView.innerLabelWidth + 24
                let itemH = itemView.innerLabelHeight + 14
                itemView.snp.remakeConstraints { make in
                    make.width.equalTo(itemW)
                    make.height.equalTo(itemH)
                }
            }else{
                itemView.snp.makeConstraints { make in
                    make.top.bottom.equalToSuperview()
                }
            }
        }
    }

    private func didClick(index: Int) {
        guard index < itemViews.count else {
            assertionFailure("section index out of range!")
            return
        }
        if currentItemIndex == index { return }
        DocsLogger.info("space.multi-list.header --- did click at index: \(index)")
        currentItemView.update(isSelected: false)
        currentItemIndex = index
        currentItemView.update(isSelected: true)
        clickHandler?(index)
    }
}
