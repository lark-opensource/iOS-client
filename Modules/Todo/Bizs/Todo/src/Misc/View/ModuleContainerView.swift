//
//  ModuleContainerView.swift
//  Todo
//
//  Created by 张威 on 2020/11/16.
//

import RxSwift
import RxCocoa

// MARK: - Module Item

protocol ModuleItem {
    var view: UIView { get }
}

private let leastHeight: CGFloat = 0.3

struct ModuleEmptyComponent {
    var height = CGFloat.leastNormalMagnitude
    var color = UIColor.clear

    fileprivate var isValid: Bool { height >= leastHeight }
}

struct ModuleGroup {
    var items: [ModuleItem]
    var showTopLine = false
    var showBottomLine = false
    var showSeparatorLine = false
    var separatorInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
    var topPadding = ModuleEmptyComponent()
    var bottomPadding = ModuleEmptyComponent()
    var topMargin = ModuleEmptyComponent()
    var bottomMargin = ModuleEmptyComponent()
    var spacing = ModuleEmptyComponent()
}

private class ModuleItemContainerView: UIView {

    var contentView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }

}

class StackView: UIStackView {

    /// 描述期望的 size 已改变
    var onPreferredSizeChanged: ((CGSize) -> Void)?

    override var frame: CGRect {
        didSet { onPreferredSizeChanged?(frame.size) }
    }

    override var bounds: CGRect {
        didSet { onPreferredSizeChanged?(frame.size) }
    }

    override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        onPreferredSizeChanged?(intrinsicContentSize)
    }

}

class ModuleContainerView: UIView {

    let stackView = StackView()

    var groups = [ModuleGroup]() {
        didSet { setupModuleItems() }
    }

    private typealias ItemAssociated = (seperator: UIView?, spacing: UIView?)
    private enum GroupItemType {
        case topMargin
        case topBorder
        case topPadding
        case item(associated: ItemAssociated)
        case bottomPadding
        case bottomBorder
        case bottomMargin
    }

    private typealias TypeView = (type: GroupItemType, view: UIView)
    private var typeView2DMatrix = [[TypeView]]()
    private let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)

        stackView.axis = .vertical
        stackView.alignment = .trailing
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.width.equalToSuperview()
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addEmptyView(with height: CGFloat, color: UIColor = .clear) -> UIView {
        let view = NoInteractionView()
        view.backgroundColor = color
        stackView.addArrangedSubview(view)
        view.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(height)
        }
        return view
    }

    private func addLineView(with insets: UIEdgeInsets = .zero) -> UIView {
        let wrapperView = UIView()
        wrapperView.isUserInteractionEnabled = false
        stackView.addArrangedSubview(wrapperView)
        wrapperView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
        }

        let colorView = UIView()
        colorView.backgroundColor = UIColor.ud.lineBorderComponent
        wrapperView.addSubview(colorView)
        colorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(insets)
            make.top.bottom.equalToSuperview()
        }

        return wrapperView
    }

    private func setupModuleItems() {
        typeView2DMatrix
            .flatMap { $0 }
            .forEach { (type, view) in
                if case .item(let associated) = type {
                    associated.seperator?.removeFromSuperview()
                    associated.spacing?.removeFromSuperview()
                }
                view.removeFromSuperview()
            }
        typeView2DMatrix.removeAll()

        var matrix2D = [[TypeView]]()
        for group in groups where !group.items.isEmpty {
            /// group layout:
            ///  |--- top margin ---|
            ///  |--- top border ---|
            ///  |--- top padding --|
            ///  |----- item 1 -----|
            ///  |----- spacing ----|
            ///  |----- item 2 -----|
            ///  |----- spacing ----|
            ///  |----- item 3 -----|
            ///  |- bottom padding -|
            ///  |-- bottom border -|
            ///  |-- bottom margin -|
            var typeViews = [TypeView]()
            if group.topMargin.isValid {
                let emptyView = addEmptyView(with: group.topMargin.height, color: group.topMargin.color)
                typeViews.append((type: .topMargin, view: emptyView))
            }
            if group.showTopLine {
                typeViews.append((type: .topBorder, view: addLineView()))
            }
            if group.topPadding.isValid {
                let emptyView = addEmptyView(with: group.topPadding.height, color: group.topPadding.color)
                typeViews.append((type: .topPadding, view: emptyView))
            }

            for item in group.items {
                var seperator: UIView?
                if group.showSeparatorLine {
                    seperator = addLineView(with: group.separatorInset)
                }
                var spacing: UIView?
                if group.spacing.isValid {
                    spacing = addEmptyView(with: group.spacing.height, color: group.spacing.color)
                }
                let associated = (seperator: seperator, spacing: spacing)
                stackView.addArrangedSubview(item.view)
                item.view.snp.makeConstraints { $0.left.right.equalToSuperview() }
                typeViews.append((type: .item(associated: associated), view: item.view))

                // adjust margin and seperator
                item.view.rx.observe(Bool.self, #keyPath(UIView.isHidden))
                    .distinctUntilChanged()
                    .bind { [weak self] _ in self?.setNeedsUpdateEmptyAndSeperator() }
                    .disposed(by: disposeBag)
            }

            if group.bottomPadding.isValid {
                let emptyView = addEmptyView(with: group.bottomPadding.height, color: group.bottomPadding.color)
                typeViews.append((type: .bottomPadding, view: emptyView))
            }
            if group.showBottomLine {
                typeViews.append((type: .bottomBorder, view: addLineView()))
            }
            if group.bottomMargin.isValid {
                let emptyView = addEmptyView(with: group.bottomMargin.height, color: group.bottomMargin.color)
                typeViews.append((type: .bottomMargin, view: emptyView))
            }

            matrix2D.append(typeViews)
        }
        typeView2DMatrix = matrix2D
    }

    private var willUpdateEmptyAndSeperator = false
    private func setNeedsUpdateEmptyAndSeperator() {
        guard !willUpdateEmptyAndSeperator else { return }
        willUpdateEmptyAndSeperator = true
        DispatchQueue.main.async {
            self.updateEmptyAndSeperatorHidden()
            self.willUpdateEmptyAndSeperator = false
        }
    }

    private func updateEmptyAndSeperatorHidden() {
        var (viewsNeedShown, viewsNeedHidden) = ([UIView](), [UIView]())
        for groupTypeViews in typeView2DMatrix {
            var (topMarginView, topBorderView, topPaddingView): (UIView?, UIView?, UIView?)
            var (bottomPaddingView, bottomBorderView, bottomMarginView): (UIView?, UIView?, UIView?)
            var (needShown, needHidden) = ([UIView](), [UIView]())
            var groupVisibleItemCount = 0
            for typeView in groupTypeViews {
                switch typeView.type {
                case .topMargin: topMarginView = typeView.view
                case .topBorder: topBorderView = typeView.view
                case .topPadding: topPaddingView = typeView.view
                case .bottomPadding: bottomPaddingView = typeView.view
                case .bottomBorder: bottomBorderView = typeView.view
                case .bottomMargin: bottomMarginView = typeView.view
                case .item(let associated):
                    let hidden = typeView.view.isHidden
                    let arrayPointer: UnsafeMutablePointer<[UIView]>
                    if hidden || groupVisibleItemCount == 0 {
                        arrayPointer = UnsafeMutablePointer<[UIView]>(&needHidden)
                    } else {
                        arrayPointer = UnsafeMutablePointer<[UIView]>(&needShown)
                    }
                    if let seperator = associated.seperator {
                        arrayPointer.pointee.append(seperator)
                    }
                    if let spacing = associated.spacing {
                        arrayPointer.pointee.append(spacing)
                    }
                    if !hidden { groupVisibleItemCount += 1 }
                }
            }
            let arrayPointer: UnsafeMutablePointer<[UIView]>
            if groupVisibleItemCount == 0 {
                arrayPointer = UnsafeMutablePointer<[UIView]>(&needHidden)
            } else {
                arrayPointer = UnsafeMutablePointer<[UIView]>(&needShown)
            }
            [topMarginView, topBorderView, topPaddingView, bottomPaddingView, bottomBorderView, bottomMarginView]
                .compactMap { $0 }
                .forEach { arrayPointer.pointee.append($0) }
            viewsNeedShown.append(contentsOf: needShown)
            viewsNeedHidden.append(contentsOf: needHidden)
        }

        for view in viewsNeedHidden where !view.isHidden { view.isHidden = true }
        for view in viewsNeedShown where view.isHidden { view.isHidden = false }
    }

}

extension ModuleContainerView {

    /// 无交互的 View
    private class NoInteractionView: UIView {

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            return nil
        }
    }

}
