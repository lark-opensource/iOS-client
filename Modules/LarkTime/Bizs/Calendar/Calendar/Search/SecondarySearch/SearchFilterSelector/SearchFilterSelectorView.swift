//
//  SearchFilterSelectorView.swift
//  CalendarInChat
//
//  Created by zoujiayi on 2019/8/9.
//

import UIKit
import Foundation

protocol SearchFilterSelectorCellContext {
    func getView() -> UIView
    func getMaxWidth() -> CGFloat
    func setText(_ text: String)
    func reset()
    func set(avatars: [Avatar])
    var isActive: Bool { get set }
}

final class SearchFilterSelectorView: UIView {
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width, height: 58)
    }

    var currentFilters: [SearchFilterSelectorCellContext]
    private let filterStackView = UIStackView()
    private let scrollview = UIScrollView()

    init(filters: [SearchFilterSelectorCellContext]) {
        currentFilters = filters
        super.init(frame: .zero)

        addSubview(scrollview)

        filterStackView.axis = .horizontal
        filterStackView.spacing = 8
        filterStackView.distribution = .fill
        filterStackView.alignment = .fill
        currentFilters.forEach { (filterItem) in
            filterStackView.addArrangedSubview(filterItem.getView())
        }
        let filterContainerView = UIView()
        filterContainerView.addSubview(filterStackView)
        filterStackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        scrollview.addSubview(filterContainerView)
        filterContainerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        scrollview.showsHorizontalScrollIndicator = false
        scrollview.showsVerticalScrollIndicator = false
        scrollview.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalToSuperview().offset(-8)
            make.height.equalTo(filterContainerView.snp.height)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(filters: [SearchFilterSelectorCellContext]) {
        currentFilters.forEach { (filter) in
            filter.getView().removeFromSuperview()
        }
        currentFilters = filters
        currentFilters.forEach { (filterItem) in
            filterStackView.addArrangedSubview(filterItem.getView())
        }
        filterDidChange()
    }

    private func filterDidChange() {
    }
}
