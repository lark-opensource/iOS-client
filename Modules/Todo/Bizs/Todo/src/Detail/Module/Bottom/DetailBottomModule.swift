//
//  DetailBottomModule.swift
//  Todo
//
//  Created by 张威 on 2021/3/8.
//

import RxSwift
import RxCocoa
import LarkUIKit

/// Detail - Bottom - Module

// nolint: magic number
final class DetailBottomModule: DetailBaseModule {
    private lazy var containerView = ContainerView()
    private let disposeBag = DisposeBag()

    private var submodules = [DetailBottomSubmodule]()

    private var rxBottomInset = BehaviorRelay<CGFloat>(value: 0)

    override func setup() {
        setupView()

        if context.scene.isForEditing {
            submodules = [DetailBottomCommentModule(resolver: userResolver, context: context)]
        } else if context.scene.isShowSendToChat {
            submodules = [DetailBottomSendToChatModule(resolver: userResolver, context: context)]
        }

        guard !submodules.isEmpty else {
            view.isHidden = true
            return
        }

        submodules.forEach { submodule in
            submodule.containerModule = self
            submodule.setup()
        }

        DispatchQueue.main.async {
            self.context.registerBottomInsetRelay(self.rxBottomInset, forKey: "bottom.module")
            self.setNeedsReload()
        }

    }

    func setNeedsReload() {
        containerView.items = submodules.map({ $0.bottomItems() }).flatMap({ $0 })
        view.isHidden = containerView.items.isEmpty
        rxBottomInset.accept(view.isHidden ? 0 : 80)
    }

    private func setupView() {
        view.backgroundColor = UIColor.ud.bgBody

        // container view
        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
            make.height.equalTo(36)
            make.trailing.leading.equalToSuperview()
        }
    }

}

extension DetailBottomModule {

    private class ContainerView: UIView {

        var items: [DetailBottomItem] = [] {
            didSet {
                oldValue.map(\.view).forEach { $0.removeFromSuperview() }
                items.map(\.view).forEach(addSubview(_:))
                setNeedsLayout()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            guard !items.isEmpty else { return }

            let paddding: CGFloat = 16
            let spacing: CGFloat = 12
            let contentHeight: CGFloat = 36

            var (totalDevideWidth, devideItemCount) = (bounds.width, 0)
            totalDevideWidth -= paddding * 2
            totalDevideWidth -= max(0, CGFloat(items.count - 1)) * spacing
            for item in items {
                switch item.widthMode {
                case .devide:
                    devideItemCount += 1
                case .fixed(let width):
                    totalDevideWidth -= width
                }
            }
            let devideWidth = floor(totalDevideWidth / CGFloat(max(1, devideItemCount)))

            var offsetX = paddding
            for item in items {
                switch item.widthMode {
                case .devide:
                    item.view.frame = CGRect(x: offsetX, y: 0, width: devideWidth, height: contentHeight)
                    offsetX += devideWidth
                case .fixed(let width):
                    item.view.frame = CGRect(x: offsetX, y: 0, width: width, height: contentHeight)
                    offsetX += width
                }
                item.view.frame.centerY = bounds.height / 2
                offsetX += spacing
            }
        }

    }

}
