//
//  ChoiceView.swift
//  ByteViewUI
//
//  Created by fakegourmet on 2023/4/17.
//

import Foundation
import SnapKit
import RichLabel
import UIKit
import ByteViewCommon
import UniverseDesignCheckBox

public protocol ChoiceViewDelegate: AnyObject {
    func goToPickerBody()
    func toastI18Key(toastStr: String)
}

public protocol PickedCollectionProtocol: UIView {
    var totalHeadCount: Int { get }
    var pickedViewHeight: CGFloat { get }
}

public final class ChoiceView: UIView {

    public weak var delegate: ChoiceViewDelegate?

    private var items: [AnyChoiceItem] {
        didSet {
            updateItemViews()
        }
    }

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 0.0
        return stackView
    }()

    let pickedContainerView = UIView(frame: .zero)

    private let interitemSpacing: CGFloat

    private var itemViews: [ChoiceItemView] {
        return stackView.arrangedSubviews
            .compactMap { $0 as? ChoiceItemView }
    }

    var textColor: UIColor = UIColor.ud.textCaption {
        didSet {
            itemViews.forEach {
                $0.label.textColor = textColor
            }
        }
    }

    var selectedItems: [ChoiceItem] {
        return items
            .filter { $0.isSelected }
            .map { $0.base }
    }

    public var handler: (([ChoiceItem]) -> Void)?

    public init(items: [AnyChoiceItem],
                interitemSpacing: CGFloat,
                itemImageSize: CGSize,
                textColor: UIColor = UIColor.ud.textCaption) {
        self.items = items
        self.interitemSpacing = interitemSpacing
        super.init(frame: CGRect(x: 0.0, y: 0.0, width: 375.0, height: 0.0))
        initialize()
        self.textColor = textColor
        self.updateConfiguration(itemImageSize: itemImageSize)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initialize() {
        stackView.spacing = interitemSpacing
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.items = { self.items }()
    }

    private func updateItemViews() {
        for (index, item) in items.enumerated() {
            let arrangedSubviews = stackView.arrangedSubviews
            let realArrangedSubviews: [UIView] = getRealArrangedSubviews(arrangedSubviews)
            if index < realArrangedSubviews.count {
                let itemView = realArrangedSubviews[index] as? ChoiceItemView
                itemView?.setItem(item)
            } else {
                let itemView = ChoiceItemView()
                itemView.checkbox.tapCallBack = { [weak self] _ in
                    self?.didTapChoiceItem(index: index)
                }
                itemView.label.textColor = textColor
                itemView.setItem(item)
                stackView.addArrangedSubview(itemView)

                let tap = IndexTapGestureRecognizer(index: index)
                tap.addTarget(self, action: #selector(didTapChoiceItem(gesture:)))
                itemView.addGestureRecognizer(tap)
                tap.cancelsTouchesInView = false
                tap.delegate = itemView
            }
        }
    }

    @objc func didTapChoiceItem(gesture: IndexTapGestureRecognizer) {
        didTapChoiceItem(index: gesture.index)
    }

    private func didTapChoiceItem(index: Int) {
        var newItems: [AnyChoiceItem] = []
        var needSelect: Bool = true
        var _: Bool = self.checkIsAllDisable(items: self.items)
        for (i, var item) in self.items.enumerated() {
            if item.isEnabled {
                if item.isSupportUnselected, i == index {
                    item.isSelected = !item.isSelected
                } else {
                    item.isSelected = (i == index)
                }
            } else {
                if i == index {
                    needSelect = false
                    if let disableToast = item.disableHoverKey {
                        self.delegate?.toastI18Key(toastStr: disableToast)
                    }
                    return
                }
            }
            newItems.append(item)
        }
        self.items = newItems
        if needSelect {
            self.handler?(self.selectedItems)
        }
    }

    func getRealArrangedSubviews(_ arrangedSubviews: [UIView]) -> [UIView] {
        arrangedSubviews.compactMap { $0 as? ChoiceItemView }
    }

    func checkIsAllDisable(items: [AnyChoiceItem]) -> Bool {
        items.allSatisfy { !$0.isEnabled }
    }

    public func addLineView(at: Int) {
        let containerView = UIView(frame: .zero)
        let line = UIView(frame: .zero)
        line.backgroundColor = UIColor.ud.lineDividerDefault
        containerView.addSubview(line)
        line.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().offset(32)
            $0.right.equalToSuperview().offset(16)
            $0.height.equalTo(0.5)
        }
        stackView.insertArrangedSubview(containerView, at: at)
    }

    public func addPickedView(pickedCollection: PickedCollectionProtocol, at: Int, isOversea: Bool, allowExternal: Bool) {
        configCountNum(at: at, count: pickedCollection.totalHeadCount)
        if isOversea && !allowExternal {
            setStackCuttomSpace(at: at, spaceHeight: pickedCollection.pickedViewHeight + 10)
        } else {
            setStackCuttomSpace(at: at, spaceHeight: pickedCollection.pickedViewHeight + 20)
        }

        pickedContainerView.subviews.forEach {
            $0.removeFromSuperview()
        }
        pickedContainerView.addSubview(pickedCollection)

        pickedCollection.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(-16)
            if isOversea && !allowExternal {
                make.top.equalToSuperview().offset(-pickedCollection.pickedViewHeight)
            } else {
                make.top.equalToSuperview().offset(-pickedCollection.pickedViewHeight - 10)
            }
            make.height.equalTo(pickedCollection.pickedViewHeight)
        }

        if !(isOversea && !allowExternal) {
            let line = UIView(frame: .zero)
            line.backgroundColor = UIColor.ud.lineDividerDefault

            pickedContainerView.addSubview(line)
            line.snp.remakeConstraints { make in
                make.top.equalTo(pickedCollection.snp.bottom).offset(12)
                make.left.equalToSuperview().offset(32)
                make.right.equalToSuperview().offset(16)
                make.height.equalTo(0.5)
            }
        }

        stackView.insertArrangedSubview(pickedContainerView, at: at)
        addPickedArea(at: at, pickedHeight: pickedCollection.pickedViewHeight)
    }

    public func setStackCuttomSpace(at: Int, spaceHeight: CGFloat) {
        stackView.setCustomSpacing(spaceHeight, after: stackView.arrangedSubviews[at - 1])
    }

    func configCountNum(at: Int, count: Int) {
        guard count != 0 else { return }
        if let itemView = stackView.arrangedSubviews[at - 1] as? ChoiceItemView {
            itemView.configCountNum(count: count)
        }
    }

    func updateConfiguration(itemImageSize: CGSize) {
        for itemView in stackView.subviews {
            if let itemView = itemView as? ChoiceItemView {
                itemView.imageSize = itemImageSize
            } else {
                break
            }
        }
    }

    func addPickedArea(at: Int, pickedHeight: CGFloat ) {
        let pickedOnClickedArea: UIButton = {
            let btn = UIButton()
            btn.backgroundColor = .clear
            btn.addTarget(self, action: #selector(goToPicker), for: .touchUpInside)
            return btn
        }()
        addSubview(pickedOnClickedArea)
        pickedOnClickedArea.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(pickedHeight)
            make.top.equalToSuperview().offset(at * 25)
        }
    }

    @objc
    func goToPicker() {
        self.delegate?.goToPickerBody()
    }
}

class IndexTapGestureRecognizer: UITapGestureRecognizer {
    var index: Int = 0

    convenience init(index: Int) {
        self.init()
        self.index = index
    }
}
