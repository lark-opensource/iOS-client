//
//  EventEditFooterBarView.swift
//  Calendar
//
//  Created by Miao Cai on 2020/3/16.
//

import UIKit
import Foundation

protocol EventEditFooterBarItemViewDataType {
    // 已经废弃
    var icon: UIImage { get }
    var title: String { get }
    var titleColor: UIColor { get }
}

protocol EventEditFooterBarViewDataType {
    var items: [EventEditFooterBarItemViewDataType] { get }
    var isVisible: Bool { get }
}

final class EventEditFooterBarView: UIView, ViewDataConvertible {

    var viewData: EventEditFooterBarViewDataType? {
        didSet {
            isHidden = !(viewData?.isVisible ?? false)

            itemViews.forEach { $0.removeFromSuperview() }

            guard let items = viewData?.items, !items.isEmpty else { return }

            while itemViews.count < items.count {
                itemViews.append(EventEditFooterBarItemView())
            }

            for (index, item) in items.enumerated() {
                let itemView = itemViews[index]
                itemView.viewData = item
                itemView.clickHandler = { [weak self] in
                    self?.itemClickHandler?(index)
                }
                stackView.addArrangedSubview(itemView)
            }

            invalidateIntrinsicContentSize()
        }
    }

    var itemClickHandler: ((_ index: Int) -> Void)?

    private let edgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 12, right: 16)
    private let backgroundView = UIView()
    private let stackView = UIStackView()
    private var itemViews = [EventEditFooterBarItemView]()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundView.backgroundColor = UIColor.ud.bgFloat
        backgroundView.layer.cornerRadius = 10.0
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(edgeInsets)
        }

        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalTo(backgroundView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        guard let items = viewData?.items, !items.isEmpty else {
            return CGSize(width: Self.noIntrinsicMetric, height: 0)
        }
        return CGSize(width: Self.noIntrinsicMetric, height: 64)
    }

}

final class EventEditFooterBarItemView: UIView, ViewDataConvertible {

    var viewData: EventEditFooterBarItemViewDataType? {
        didSet {
            titleLabel.text = viewData?.title
            titleLabel.textColor = viewData?.titleColor
        }
    }

    var clickHandler: (() -> Void)?
    private var titleLabel: UILabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let container = UIView()
        container.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleClick))
        container.addGestureRecognizer(tapGesture)
        container.isExclusiveTouch = true
        addSubview(container)
        // MARK: 目前整个撑开了父容器
        container.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.isUserInteractionEnabled = false
        titleLabel.textAlignment = .center
        container.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.height.equalTo(22)
            $0.center.equalToSuperview()
        }
    }

    @objc
    private func handleClick() {
        clickHandler?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
