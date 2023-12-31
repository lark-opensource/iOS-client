//
//  SpaceMultiListPickerView.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/3.
//

import UIKit

//struct SpaceMultiListPickerItem {
//    let identifier: String
//    let title: String
//    init(identifier: String, title: String) {
//        self.identifier = identifier
//        self.title = title
//    }
//}
//
//private extension SpaceMultiListPickerView {
//
//    typealias Item = SpaceMultiListPickerItem
//
//    class ItemView: UIView {
//        private lazy var titleLabel: UILabel = {
//            let label = UILabel()
//            label.font = .systemFont(ofSize: 14, weight: .regular)
//            label.textAlignment = .center
//            label.textColor = UIColor.ud.N600
//            label.isUserInteractionEnabled = true
//            return label
//        }()
//
//        private lazy var indicatorView: UIView = {
//            let view = UIView()
//            view.layer.cornerRadius = 2
//            view.backgroundColor = UIColor.ud.colorfulBlue
//            return view
//        }()
//
//        private var clickHandler: () -> Void
//
//        init(item: Item, handler: @escaping () -> Void) {
//            clickHandler = handler
//            super.init(frame: .zero)
//            setupUI(item: item)
//        }
//
//        required init?(coder: NSCoder) {
//            fatalError("init(coder:) has not been implemented")
//        }
//
//        private func setupUI(item: Item) {
//            addSubview(titleLabel)
//            titleLabel.snp.makeConstraints { make in
//                make.edges.equalToSuperview()
//                make.centerY.equalToSuperview()
//            }
//            addSubview(indicatorView)
//            indicatorView.snp.makeConstraints { make in
//                make.left.right.equalToSuperview()
//                make.height.equalTo(4)
//                make.centerY.equalTo(snp.bottom)
//            }
//            indicatorView.isHidden = true
//
//            titleLabel.text = item.title
//            let clickGesture = UITapGestureRecognizer(target: self, action: #selector(didClick))
//            titleLabel.addGestureRecognizer(clickGesture)
//            // 加在 titleLabel 上是为了避免 highlight 自带的缩放效果影响底部 indicator 的 UI 效果
////            titleLabel.docs.addHighlight(with: UIEdgeInsets(top: 4, left: -8, bottom: 4, right: -8),
////                                         radius: 8)
//        }
//
//        @objc
//        private func didClick() {
//            clickHandler()
//        }
//
//        func update(isSelected: Bool) {
//            if isSelected {
//                titleLabel.textColor = UIColor.ud.colorfulBlue
//                titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
//                indicatorView.isHidden = false
//            } else {
//                titleLabel.textColor = UIColor.ud.N600
//                titleLabel.font = .systemFont(ofSize: 14, weight: .regular)
//                indicatorView.isHidden = true
//            }
//        }
//    }
//}
//
//class SpaceMultiListPickerView: UIView {
//    private lazy var stackView: UIStackView = {
//        let view = UIStackView()
//        view.alignment = .center
//        view.axis = .horizontal
//        view.distribution = .fill
//        view.spacing = 20
//        return view
//    }()
//
//    private lazy var scrollView: UIScrollView = {
//        let view = UIScrollView()
//        view.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
//        view.showsVerticalScrollIndicator = false
//        view.showsHorizontalScrollIndicator = false
//        return view
//    }()
//
//    private var itemViews: [ItemView] = []
//    private var currentItemIndex = 0
//    private var currentItemView: ItemView { itemViews[currentItemIndex] }
//
//    var clickHandler: ((Int) -> Void)?
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupUI()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    private func setupUI() {
//        backgroundColor = .clear
//        addSubview(scrollView)
//        scrollView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//        scrollView.addSubview(stackView)
//        stackView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//            make.centerY.equalToSuperview()
//        }
//    }
//
//    func cleanUp() {
//        itemViews.forEach { $0.removeFromSuperview() }
//        itemViews = []
//        currentItemIndex = 0
//    }
//
//    func update(items: [SpaceMultiListPickerItem], currentIndex: Int) {
//        guard !items.isEmpty else {
//            MailLogger.error("space.multi-list.header --- sub sections is empty when setup")
//            return
//        }
//        setup(items: items)
//        currentItemIndex = currentIndex
//        if currentIndex >= items.count {
//            assertionFailure("space.multi-list.header --- current index out of bounds!")
//            currentItemIndex = 0
//        }
//        currentItemView.update(isSelected: true)
//    }
//
//    private func setup(items: [SpaceMultiListPickerItem]) {
//        for (index, item) in items.enumerated() {
//            let itemView = ItemView(item: item) { [weak self] in
//                self?.didClick(index: index)
//            }
//            itemViews.append(itemView)
//            stackView.addArrangedSubview(itemView)
//            itemView.snp.makeConstraints { make in
//                make.top.bottom.equalToSuperview()
//            }
//        }
//    }
//
//    private func didClick(index: Int) {
//        guard index < itemViews.count else {
//            assertionFailure("section index out of range!")
//            return
//        }
//        if currentItemIndex == index { return }
//        MailLogger.info("space.multi-list.header --- did click at index: \(index)")
//        currentItemView.update(isSelected: false)
//        currentItemIndex = index
//        currentItemView.update(isSelected: true)
//        clickHandler?(index)
//    }
//}
