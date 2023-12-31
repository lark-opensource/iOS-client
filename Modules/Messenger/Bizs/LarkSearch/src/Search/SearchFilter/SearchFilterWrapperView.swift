//
//  SearchFilterWrapperView.swift
//  LarkSearch
//
//  Created by SuPeng on 4/18/19.
//

import UIKit
import Foundation
import DateToolsSwift
import EENavigator
import LarkUIKit
import LKCommonsTracker
import LKCommonsLogging
import LarkSearchFilter
import LarkModel
import LarkSDKInterface

protocol SearchFilterWrapperViewDelegate: AnyObject {
    func filterWrapperView(_ view: SearchFilterWrapperView, didClick filterView: SearchFilterView)
    func filterWrapperView(_ view: SearchFilterWrapperView, didChange newFilter: [SearchFilter])
    func filterWrapperView(_ view: SearchFilterWrapperView, didChange newFilter: [SearchFilter], isFromClearButton: Bool)
}

extension SearchFilterWrapperViewDelegate {
    func filterWrapperView(_ view: SearchFilterWrapperView, didChange newFilter: [SearchFilter]) { }
    func filterWrapperView(_ view: SearchFilterWrapperView, didChange newFilter: [SearchFilter], isFromClearButton: Bool) { }
}

final class SearchFilterWrapperView: UIView {

    static let logger = Logger.log(SearchFilterWrapperView.self, category: "SearchFilterWrapperView")

    var currentFilters: [SearchFilter] { return fileterViews.map { $0.filter } }
    weak var delegate: SearchFilterWrapperViewDelegate?

    private let topBgView = UIView()
    private let titleLabel = UILabel()
    private let bottomBgView = UIView()
    private let stackView = UIStackView()
    private var fileterViews: [SearchFilterView] = []
    private let filterStackView = UIStackView()
    private let scrollview = UIScrollView()
    let resetButton = UIButton()

    init(title: String? = nil, filters: [SearchFilter]) {
        titleLabel.text = title

        super.init(frame: .zero)

        stackView.axis = .vertical
        addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let hasTitle = !(title ?? "").isEmpty
        stackView.addArrangedSubview(topBgView)
        topBgView.addSubview(titleLabel)
        if hasTitle {
            topBgView.isHidden = false
            topBgView.addSubview(resetButton)
            resetButton.snp.remakeConstraints { (make) in
                make.right.equalToSuperview().offset(-16)
                make.centerY.equalTo(titleLabel.snp.centerY)
            }
        } else {
            topBgView.isHidden = true
        }

        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(22)
            make.bottom.equalTo(-4)
        }

        stackView.addArrangedSubview(bottomBgView)
        bottomBgView.addSubview(scrollview)
        if !hasTitle {
            bottomBgView.addSubview(resetButton)
            resetButton.snp.remakeConstraints { (make) in
                make.centerY.equalTo(scrollview)
                make.right.equalToSuperview().offset(-16)
            }
        }

        filterStackView.axis = .horizontal
        filterStackView.spacing = 8
        filterStackView.distribution = .fill
        filterStackView.alignment = .fill
        set(filters: filters)

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
            if !hasTitle {
                make.right.equalTo(resetButton.snp.left).offset(-8)
            } else {
                make.right.equalTo(-16)
            }
            make.height.equalTo(filterContainerView.snp.height)
            make.centerY.equalToSuperview()
        }

        resetButton.setTitle(BundleI18n.LarkSearch.Lark_Search_ResetFilter, for: .normal)
        resetButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        resetButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        resetButton.setTitleColor(UIColor.ud.primaryContentLoading, for: .disabled)
        resetButton.addTarget(self, action: #selector(resetButtonDidClick), for: .touchUpInside)
        resetButton.isEnabled = !filters.allSatisfy({ $0.isEmpty })

        bottomBgView.snp.makeConstraints { (make) in
            make.height.equalTo(58)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func resetButtonDidClick() {
        SearchFilterWrapperView.logger.info("[LarkSearch] reset advance search filter")
        fileterViews.forEach { (filterView) in
            filterView.set(filter: filterView.filter.reset() )
        }
        filterDidChange(isFromClearButton: true)
    }

    func set(filters: [SearchFilter]) {
        fileterViews.forEach { (filterView) in
            filterStackView.removeArrangedSubview(filterView)
            filterView.removeFromSuperview()
        }
        fileterViews = filters.map { SearchFilterView(filter: $0) }
        fileterViews.forEach { (filterView) in
            filterView.delegate = self
            filterStackView.addArrangedSubview(filterView)
        }
    }

    func triggerDidChangeFilterCallBack() {
        filterDidChange()
        updateResetButtonEnable()
    }

    func updateResetButtonEnable() {
        resetButton.isEnabled = !currentFilters.allSatisfy({ $0.isEmpty })
    }

    private func filterDidChange(isFromClearButton: Bool = false) {
        delegate?.filterWrapperView(self, didChange: currentFilters)
        delegate?.filterWrapperView(self, didChange: currentFilters, isFromClearButton: isFromClearButton)
    }
}

extension SearchFilterWrapperView: SearchFilterViewDelegate {
    func filterViewDidClick(_ filterView: SearchFilterView) {
        if let info = filterView.filter.logInfo {
            SearchFilterWrapperView.logger.info("[LarkSearch] advance search update \(info.name) filter",
                                                additionalData: info.data)
        }
        delegate?.filterWrapperView(self, didClick: filterView)
    }
}

extension SearchFilter {
    var logInfo: (name: String, data: [String: String])? {
        switch self {
        case let .chat(mode: mode, picker: picker):
            return ("chat", ["mode": "\(mode)", "chats": "\(picker.map({ $0.chatId ?? "" }))"])
        case .date:
            return ("date", ["date": title ?? ""])
        case let .chatMemeber(mode: mode, picker: picker):
            return ("chatter", ["mode": "\(mode)", "chatters": "\(picker.map({ $0.chatterID }))"])
        case let .chatKeyWord(key):
            return ("keyword", ["keyword": key.lf.dataMasking])
        case let .chatType(types):
            return ("chat type", ["types": "\(types)"])
        case let.threadType(type):
            return ("thread type", ["type": "\(type)"])
        default:
            return nil
        }
    }
}
