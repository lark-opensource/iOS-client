//
//  MentionResultView.swift
//  Lark
//
//  Created by Yuri on 2017/3/25.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import UniverseDesignEmpty
import UniverseDesignLoading
import UniverseDesignShadow
import LarkLocalizations

final class MentionLoadingView: UIView {
    let loadingView = UDLoading.presetSpin()
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.6)
        addSubview(loadingView)
        loadingView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MentionResultErrorView: UIView {
    
    private var label = UILabel()
    var errorString: String? {
        didSet {
            label.text = errorString
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 2
        label.text = BundleI18n.LarkMention.Lark_Mention_Mention_Mobile
        addSubview(label)
        label.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class MentionResultView: UIView {
    private let contentView = UIView()
    public private(set) lazy var tableView: UITableView = {
        UITableView(frame: .zero, style: .plain)
    }()
    private var errorView = MentionResultErrorView()
    private let loadingView = MentionLoadingView()
    var headerView: MentionResultHeaderView

    private let headerHeight: CGFloat = 46
    private let errorHeight: CGFloat = 54
    private let cellHeight: CGFloat = 56
    public private(set) var param: MentionUIParameters
    private var mentionTracker: MentionTraker
    
    public var didSwitchMulitSelectHandler: ((Bool) -> Void)?
    public var didSelectRowHandler: ((Int) -> Void)?
    public var didUpdateHeightHandler: ((CGFloat?) -> Void)?
    public var didSwitchGlobalCheckBoxHandler: ((Bool) -> Void)? {
        didSet {
            headerView.didSwitchGlobalCheckBoxHandler = didSwitchGlobalCheckBoxHandler
        }
    }
    
    public var isLoading: Bool = false {
        didSet {
            loadingView.isHidden = !isLoading
        }
    }
    
    public var error: String? {
        didSet {
            errorView.isHidden = error == nil
            tableView.isHidden = !errorView.isHidden
            headerView.isHidden = !errorView.isHidden
            errorView.errorString = error ?? ""
            if error?.isEmpty != oldValue?.isEmpty {
                didUpdateHeightHandler?(error == nil ? nil: errorView.bounds.height)
            }
        }
    }
    
    public var contentInsets: UIEdgeInsets = .zero {
        didSet {
            contentView.snp.remakeConstraints {
                $0.edges.equalTo(contentInsets)
            }
        }
    }
    
    public private(set) var items: [PickerOptionType] = []
    private var isSkeleton: Bool = false
    public func reloadTable(items: [PickerOptionType], isSkeleton: Bool) {
        self.isSkeleton = isSkeleton
        self.items = items
        tableView.reloadData()
        let height = headerHeight + CGFloat(items.count) * cellHeight
        didUpdateHeightHandler?(height)
    }

    public func hideHeaderView(isHidden: Bool = true) {
        self.headerView.isHidden = isHidden
        tableView.snp.remakeConstraints() {
            $0.leading.trailing.bottom.equalToSuperview()
            if isHidden {
                $0.top.equalToSuperview()
            } else {
                $0.top.equalTo(headerView.snp.bottom)
            }
        }
    }
    
    // tableView回滚到顶部
    public func updateTableScroll() {
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
    }
    
    public func reloadTableAtRows(items: [PickerOptionType], rows: [Int]) {
        self.items = items
        let indexPath = rows.compactMap { IndexPath(row: $0, section: 0) }
        tableView.reloadRows(at: indexPath, with: .none)
    }
    
    public init(parameters: MentionUIParameters, mentionTracker: MentionTraker) {
        self.param = parameters
        self.mentionTracker = mentionTracker
        self.headerView = MentionResultHeaderView(
            hasCheckBox: parameters.hasGlobalCheckBox,
            checkBoxSelected: parameters.globalCheckBoxSelected
        )
        super.init(frame: CGRect.zero)
        setupUI()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func onMultiSelectClick(btn: UIButton) {
        if btn.isSelected {
            didSwitchMulitSelectHandler?(!btn.isSelected)
        } else {
            btn.isSelected = !btn.isSelected
            didSwitchMulitSelectHandler?(btn.isSelected)
            mentionTracker.mentionTrakerPost(action: .typeChange, targer: "none")
        }
    }
    
    private func setupUI() {
        self.roundCorners(corners: [.topLeft, .topRight], radius: 12.0)
        self.backgroundColor = UIColor.ud.bgBody
        self.layer.ud.setShadow(type: .s3Up)
        addSubview(contentView)
        contentView.snp.makeConstraints {
           $0.edges.equalTo(UIEdgeInsets.zero)
        }

        setupHeader()
        setupTable(tableStyle: .plain)
        setupLoadingView()
        setupErrorView()
        headerView.multiBtn.addTarget(self, action: #selector(onMultiSelectClick(btn:)), for: .touchUpInside)
    }
    
    private func setupHeader() {
        headerView.didSwitchGlobalCheckBoxHandler = didSwitchGlobalCheckBoxHandler
        if let title = param.title, !title.isEmpty {
            headerView.titleLabel.text = param.title
        }
        headerView.multiBtn.isHidden = !param.needMultiSelect
        contentView.addSubview(headerView)
        headerView.snp.makeConstraints {
            $0.leading.top.trailing.equalToSuperview()
            $0.height.equalTo(headerHeight)
        }
    }

    fileprivate func setupTable(tableStyle: UITableView.Style) {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clear
        tableView.separatorColor = UIColor.clear
        tableView.rowHeight = cellHeight
        tableView.sectionIndexColor = UIColor.ud.textTitle
        tableView.lu.register(cellSelf: MentionItemCell.self)
        self.contentView.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalTo(headerView.snp.bottom)
        }

        tableView.contentInsetAdjustmentBehavior = .never
        self.tableView = tableView
    }

    fileprivate func setupLoadingView() {
        self.contentView.addSubview(loadingView)
        loadingView.snp.makeConstraints {
            $0.edges.equalTo(tableView)
        }
    }

    private func setupErrorView() {
        contentView.addSubview(errorView)
        errorView.snp.makeConstraints {
            $0.leading.bottom.trailing.equalToSuperview()
            $0.height.equalTo(errorHeight)
        }
        errorView.isHidden = true
    }

}

extension MentionResultView: UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MentionItemCell.self), for: indexPath)
        if let mentionCell = cell as? MentionItemCell {
            mentionCell.isSkeleton = isSkeleton
            mentionCell.item = items[indexPath.row]
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRowHandler?(indexPath.row)
        let item = items[indexPath.row]
        var isCheckSelected = false
        if let checkBox = headerView.checkBox, checkBox.isSelected {
            isCheckSelected = true
        }
        mentionTracker.mentionTrakerPost(action: .itemClick, targer: "none", hasCheckBox: headerView.hasCheckBox, isCheckSelected: isCheckSelected, listItemNumber: (indexPath.row + 1), item: item
            )
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        mentionTracker.mentionTrakerPost(action: .listSlide, targer: "none")
    }
}

extension UIView {

    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        layer.cornerRadius = radius
        layer.maskedCorners = CACornerMask(rawValue: corners.rawValue)
    }
}
