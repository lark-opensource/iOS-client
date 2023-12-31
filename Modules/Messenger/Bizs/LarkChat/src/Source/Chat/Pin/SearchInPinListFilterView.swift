//
//  SearchInPinListFilterView.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/16.
//

import UIKit
import Foundation
import LarkSearchFilter
import LarkModel
import LarkSDKInterface

protocol SearchInPinListFilterViewDelegate: AnyObject {
    func inPinListFilterView(_ view: SearchInPinListFilterView, didClick filterView: SearchFilterView)
    func inPinListFilterView(_ view: SearchInPinListFilterView, didChange newFilter: [SearchFilter])
}

final class SearchInPinListFilterView: UIView {
    weak var delegate: SearchInPinListFilterViewDelegate?
    private let filters: [SearchFilter] = [.chatter(mode: .unlimited, picker: [], recommends: [], fromType: .user, isRecommendResultSelected: false),
                                           .chat(mode: .unlimited, picker: []),
                                           .date(date: nil, source: .message)]
    private var fileterViews: [SearchFilterView]
    private let filterStackView = UIStackView()
    private let resetButton = UIButton()
    var currentFilters: [SearchFilter] { return fileterViews.map { $0.filter } }
    override init(frame: CGRect) {
        fileterViews = filters.map { SearchFilterView(filter: $0) }

        super.init(frame: frame)

        self.addSubview(resetButton)

        filterStackView.axis = .horizontal
        filterStackView.spacing = 10
        filterStackView.distribution = .fill
        filterStackView.alignment = .fill
        fileterViews.forEach { (filterView) in
            filterView.delegate = self
            filterStackView.addArrangedSubview(filterView)
        }
        self.addSubview(filterStackView)
        filterStackView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualTo(resetButton.snp.left).offset(-15)
        }

        resetButton.setTitle(BundleI18n.LarkChat.Lark_Search_ResetFilter, for: .normal)
        resetButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        resetButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        resetButton.setTitleColor(UIColor.ud.primaryContentLoading,
                                  for: .disabled)
        resetButton.addTarget(self, action: #selector(resetButtonDidClick), for: .touchUpInside)
        resetButton.isEnabled = !filters.allSatisfy({ $0.isEmpty })
        resetButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func resetButtonDidClick() {
        fileterViews.forEach { (filterView) in
            filterView.set(filter: filterView.filter.reset() )
        }
        resetButton.isEnabled = false
        filterDidChange()
    }

    private func filterDidChange() {
        resetButton.isEnabled = !currentFilters.allSatisfy({ $0.isEmpty })
        delegate?.inPinListFilterView(self, didChange: currentFilters)
    }
}

extension SearchInPinListFilterView: SearchFilterViewDelegate {
    func filterViewDidClick(_ filterView: SearchFilterView) {
        delegate?.inPinListFilterView(self, didClick: filterView)
    }
}
