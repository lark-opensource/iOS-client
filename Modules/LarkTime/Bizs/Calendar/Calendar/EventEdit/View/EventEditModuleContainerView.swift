//
//  EventEditModuleContainerView.swift
//  Calendar
//
//  Created by 张威 on 2020/3/3.
//

import UIKit
import RxSwift
import RxCocoa

protocol EventEditModuleGroupType {
    var itemViews: [UIView] { get }
    var showTopLine: Bool { get }
    var topSeparatorInset: UIEdgeInsets { get }
    var showBottomLine: Bool { get }
    var bottomSeparatorInset: UIEdgeInsets { get }
    var showSeparatorLine: Bool { get }
    var separatorInset: UIEdgeInsets { get }
    var topMargin: CGFloat { get }
    var bottomMargin: CGFloat { get }
}

final class EventEditModuleContainerView: UIStackView {

    private enum EventEditGroupItemType {
        case topMargin
        case topBorder
        case item(relatedSeperator: UIView?)
        case bottomBorder
        case bottomMargin
    }

    private typealias TypeView = (type: EventEditGroupItemType, view: UIView)
    private var typeView2DMatrix = [[TypeView]]()
    private let disposeBag = DisposeBag()

    init(groups: [EventEditModuleGroupType]) {
        super.init(frame: .zero)

        axis = .vertical
        alignment = .center

        func makeMarginView(withHeight height: CGFloat) -> UIView {
            let view = UIView()
            self.addArrangedSubview(view)
            view.backgroundColor = UIColor.ud.bgFloat
            view.snp.makeConstraints {
                $0.height.equalTo(height)
                $0.left.right.equalToSuperview()
            }
            return view
        }

        func makeLineView(withInsets insets: UIEdgeInsets = .zero) -> UIView {
            let wrapperView = UIView()
            wrapperView.backgroundColor = .clear
            self.addArrangedSubview(wrapperView)
            wrapperView.snp.makeConstraints {
                $0.left.right.equalToSuperview()
            }

            let colorView = UIView()
            colorView.backgroundColor = UIColor.ud.lineDividerDefault
            wrapperView.addSubview(colorView)
            colorView.snp.makeConstraints {
                $0.height.equalTo(EventEditUIStyle.Layout.horizontalSeperatorHeight)
                $0.edges.equalToSuperview().inset(insets)
            }

            return wrapperView
        }

        var matrix2D = [[TypeView]]()
        for group in groups where !group.itemViews.isEmpty {
            var typeViews = [TypeView]()
            if group.topMargin > 0.01 {
                typeViews.append((type: .topMargin, view: makeMarginView(withHeight: group.topMargin)))
            }

            if group.showTopLine {
                typeViews.append((type: .topBorder, view: makeLineView(withInsets: group.topSeparatorInset)))
            }
            for itemView in group.itemViews {
                var seperator: UIView?
                if group.showSeparatorLine {
                    seperator = makeLineView(withInsets: group.separatorInset)
                }
                self.addArrangedSubview(itemView)
                itemView.snp.makeConstraints {
                    $0.left.right.equalToSuperview()
                }
                typeViews.append((type: .item(relatedSeperator: seperator), view: itemView))

                // adjust margin and seperator
                itemView.rx.observe(Bool.self, #keyPath(UIView.isHidden))
                    .distinctUntilChanged()
                    .bind { [weak self] _ in
                        self?.setNeedsUpdateMarginAndSeperator()
                    }
                    .disposed(by: disposeBag)
            }

            if group.showBottomLine {
                typeViews.append((type: .bottomBorder, view: makeLineView(withInsets: group.bottomSeparatorInset)))
            }

            if group.bottomMargin > 0.01 {
                typeViews.append((type: .bottomMargin, view: makeMarginView(withHeight: group.bottomMargin)))
            }
            matrix2D.append(typeViews)
        }
        typeView2DMatrix = matrix2D
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var willUpdateMarginAndSeperator = false
    private func setNeedsUpdateMarginAndSeperator() {
        guard !willUpdateMarginAndSeperator else { return }
        willUpdateMarginAndSeperator = true
        DispatchQueue.main.async {
            self.updateMarginAndSeperatorHidden()
            self.willUpdateMarginAndSeperator = false
        }
    }

    private func updateMarginAndSeperatorHidden() {
        var viewsNeedShown = [UIView]()
        var viewsNeedHidden = [UIView]()
        for groupTypeViews in typeView2DMatrix {
            var (topMarginView, topBorderView): (UIView?, UIView?) = (nil, nil)
            var (bottomMarginView, bottomBorderView): (UIView?, UIView?) = (nil, nil)
            var needShown = [UIView]()
            var needHidden = [UIView]()
            var groupVisibleItemCount = 0
            for typeView in groupTypeViews {
                switch typeView.type {
                case .topMargin: topMarginView = typeView.view
                case .topBorder: topBorderView = typeView.view
                case .bottomBorder: bottomBorderView = typeView.view
                case .bottomMargin: bottomMarginView = typeView.view
                case .item(let relatedSeperator):
                    let hidden = typeView.view.isHidden
                    let hideSeperator = hidden || groupVisibleItemCount == 0
                    if !hidden {
                        groupVisibleItemCount += 1
                    }
                    let arrayPointer: UnsafeMutablePointer<[UIView]> = hideSeperator ?
                        UnsafeMutablePointer(&needHidden) : UnsafeMutablePointer(&needShown)
                    if let seperator = relatedSeperator {
                        arrayPointer.pointee.append(seperator)
                    }
                }
            }
            let arrayPointer: UnsafeMutablePointer<[UIView]> = groupVisibleItemCount == 0 ?
                UnsafeMutablePointer(&needHidden) : UnsafeMutablePointer(&needShown)
            if let view = topBorderView {
                arrayPointer.pointee.append(view)
            }
            if let view = topMarginView {
                arrayPointer.pointee.append(view)
            }
            if let view = bottomBorderView {
                arrayPointer.pointee.append(view)
            }
            if let view = bottomMarginView {
                arrayPointer.pointee.append(view)
            }
            viewsNeedShown.append(contentsOf: needShown)
            viewsNeedHidden.append(contentsOf: needHidden)
        }

        viewsNeedHidden.forEach {
            if !$0.isHidden {
                $0.isHidden = true
            }
        }
        viewsNeedShown.forEach {
            if $0.isHidden {
                $0.isHidden = false
            }
        }
    }

}
