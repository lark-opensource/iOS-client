//
//  TemplateCategoriesView.swift
//  SpaceKit
//
//  Created by 邱沛 on 2020/5/19.
//

import RxSwift
import RxCocoa
import UniverseDesignColor

// 二级分类选择
class TemplateCategoriesView: UIView {

    typealias ClickCallback = (String) -> Void
    
    var selectedIndex = BehaviorRelay<Int?>(value: nil)
    var selectedName: String? {
        guard let index = selectedIndex.value else { return nil }
        guard !categoryNames.isEmpty, index >= 0, index < categoryNames.count else { return nil }
        return categoryNames[index]
    }

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var items = [UIButton]()
    
    private var needScrollToTargetCategory = false

    private let bag = DisposeBag()
    
    private let stackViewLeftPadding: CGFloat = 16
    private let clickCallback: ClickCallback?

    var categoryNames: [String] {
        didSet {
            updateContent()
        }
    }
    private let tabName: String
    init(categoryNames: [String], tabName: String, didClickCategory: ClickCallback?) {
        self.categoryNames = categoryNames
        self.tabName = tabName
        self.clickCallback = didClickCategory
        super.init(frame: .zero)
        setupUI()
        updateContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody
        
        scrollView.showsHorizontalScrollIndicator = false
        addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center

        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview().inset(stackViewLeftPadding)
        }
    }

    private func updateContent() {
        stackView.subviews.forEach({ $0.removeFromSuperview() })
        items.removeAll()

        for i in 0..<categoryNames.count {
            let name = categoryNames[i]
            let button = UIButton()
            button.setTitle(name, for: .normal)
            button.setTitleColor(UDColor.iconN2, for: .normal)
            button.setTitleColor(UDColor.primaryContentDefault, for: .selected)
            button.titleLabel?.font = .systemFont(ofSize: 14)
            button.backgroundColor = UDColor.bgFiller
            button.adjustsImageWhenHighlighted = false
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
            button.layer.cornerRadius = 6
            button.layer.masksToBounds = true
            button.docs.addStandardLift()
            self.items.append(button)

            button.rx.tap
                .subscribe(onNext: {[weak self] _ in
                    guard let self = self else { return }
                    self.selectedIndex.accept(i)
                    self.items.forEach { self.selectCategoryButton($0, selected: false) }
                    self.selectCategoryButton(button, selected: true)
                    if let callback = self.clickCallback {
                        callback(name)
                    }
                }).disposed(by: bag)

            stackView.addArrangedSubview(button)
        }

        self.layoutIfNeeded()

        scrollView.contentSize = CGSize(width: stackView.bounds.size.width + 2 * stackViewLeftPadding, height: stackView.bounds.size.height)

        updateItemState()
    }

    private func updateItemState() {
        if let selectIndex = selectedIndex.value {
            if selectIndex >= 0, selectIndex < items.count {
                let selectBtn = items[selectIndex]
                selectCategoryButton(selectBtn, selected: true)
                // scroll 到对应的item
                if needScrollToTargetCategory {
                    needScrollToTargetCategory = false
                    let btnFrame = items[selectIndex].frame
                    let rect = CGRect(x: btnFrame.origin.x, y: 0, width: scrollView.frame.width, height: scrollView.frame.height)
                    scrollView.scrollRectToVisible(rect, animated: true)
                }
            }
        } else {
            if categoryNames.isEmpty { return }
            selectedIndex.accept(0)
            if let selectBtn = items.first {
                selectCategoryButton(selectBtn, selected: true)
            }
        }
    }
    
    func updateTargetCategory(index: Int?) {
        guard let categoryIndex = index else { return }
        selectedIndex.accept(categoryIndex)
        needScrollToTargetCategory = true
    }
    
    private func selectCategoryButton(_ button: UIButton, selected: Bool) {
        button.isSelected = selected
        button.backgroundColor = selected ? UDColor.primaryFillSolid02 : UDColor.bgFiller
    }
}

extension UIButton {
    private func imageWithColor(color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()

        context?.setFillColor(color.cgColor)
        context?.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        self.setBackgroundImage(imageWithColor(color: color), for: state)
    }
}
