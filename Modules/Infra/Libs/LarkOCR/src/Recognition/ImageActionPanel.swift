//
//  ImageActionPanel.swift
//  LarkOCR
//
//  Created by 李晨 on 2022/8/23.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LKCommonsLogging
import UniverseDesignButton
import UniverseDesignFont

public final class ImageActionPanel: UIView {
    public var actions: [ImageOCRAction] = []
    public var items: [ImageActionItem]
    public var wrapper: UIStackView = UIStackView()

    public init(actions: [ImageOCRAction]) {
        self.actions = actions
        self.items = actions.map({ action in
            return ImageActionItem(action: action)
        })
        super.init(frame: .zero)
        self.setupViews()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(actions: [ImageOCRAction]) {
        self.actions = actions
        self.items = actions.map({ action in
            return ImageActionItem(action: action)
        })
        self.wrapper.subviews.forEach { subView in
            subView.removeFromSuperview()
        }
        self.items.forEach { item in
            self.wrapper.addArrangedSubview(item)
        }
    }

    private func setupViews() {
        self.addSubview(wrapper)
        wrapper.axis = .horizontal
        wrapper.alignment = .center
        wrapper.distribution = .equalSpacing
        wrapper.spacing = 58
        wrapper.snp.makeConstraints { make in
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom).offset(-10)
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
        }

        self.items.forEach { item in
            self.wrapper.addArrangedSubview(item)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if self.bounds.width >= 500 {
            wrapper.spacing = 80
        } else {
            wrapper.spacing = 58
        }
    }
}

public final class ImageActionItem: UIView {
    static let logger = Logger.log(ImageActionItem.self, category: "LarkOCR")

    public var action: ImageOCRAction
    public var layoutView = UIView()
    public var imageView: UIImageView = UIImageView()
    public var titleView: UILabel = UILabel()
    var tapGesture = UITapGestureRecognizer()
    let disposeBag = DisposeBag()

    public init(action: ImageOCRAction) {
        self.action = action
        super.init(frame: .zero)

        self.addSubview(imageView)
        self.addSubview(titleView)
        self.addGestureRecognizer(self.tapGesture)

        self.setupViews()
    }

    private func setupViews() {
        self.addSubview(self.layoutView)
        self.layoutView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalTo(60)
        }
        self.imageView.image = action.icon
        self.imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(24)
            make.top.equalTo(5)
        }
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.isUserInteractionEnabled = false

        self.titleView.text = action.title
        self.titleView.textColor = action.titleColor
        self.titleView.font = UIFont.systemFont(ofSize: 10)
        self.titleView.numberOfLines = 2
        self.titleView.textAlignment = .center
        self.titleView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalTo(self.imageView.snp.bottom).offset(10)
        }

        self.tapGesture.rx.event.subscribe(onNext: { [weak self] (_) in
            Self.logger.info("click action item \(self?.action.title ?? "")")
            self?.action.handler()
        })
        .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
