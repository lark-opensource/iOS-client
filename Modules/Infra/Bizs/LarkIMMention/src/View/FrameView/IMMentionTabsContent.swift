//
//  IMMentionTabsContant.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/21.
//

import UIKit
import Foundation
import UniverseDesignTabs
import CoreGraphics

// mention内各列表内容
final class IMMentionTabsContent: UIView, UDTabsListContainerViewDelegate {
    private let headerIdentifier = "headerIdentifier"
    
    var contentView = UIView()
    var tableView = UITableView()
    var errorView = IMMentionErrorView()
    
    var result = IMMentionReuslt(sections: [])
    var nameIndex: [String]?
    // 第几节开始变成索引
    var nameIndexForm: Int = 0
    // 索引映射
    var nameDict: [Int: Int] = [:]
    // 显示列表底部隐私信息
    var isShowPrivacyFooter: Bool = false {
        didSet {
            isShowPrivacyFooter ? showFootView() : hiddenFootView()
        }
    }
    var isSkeleton: Bool = true
    var isMultiSelect: Bool = false
    
    var didSelectRowHandler: ((Int) -> Void)?
    var didSelectItemHandler: ((IMMentionOptionType) -> Void)?
    var didEndEditing: (() -> Void)?
    var paneloffsetY: CGFloat = UIScreen.main.bounds.height
    var didChangeHeightHandler: ((CGFloat, UIGestureRecognizer.State) -> Void)?
    var error: String? {
        didSet {
            errorView.isHidden = error == nil
            tableView.isHidden = !errorView.isHidden
            errorView.errorString = error ?? ""
        }
    }
    
    init() {
        super.init(frame: CGRect.zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
    
    private func setup() {
        addSubview(contentView)
        contentView.snp.makeConstraints{
            $0.top.bottom.leading.trailing.equalToSuperview()
        }
        
        setupTableView()
        setupErrorView()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clear
        tableView.separatorColor = UIColor.clear
        tableView.sectionIndexColor = UIColor.ud.textTitle
        tableView.rowHeight = 68
        tableView.lu.register(cellSelf: IMMentionItemCell.self)
        tableView.register(IMMentionSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: headerIdentifier)
        if self.traitCollection.horizontalSizeClass != .regular {
            let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(pan:)))
            gesture.delegate = self
            tableView.addGestureRecognizer(gesture)
        }
        contentView.addSubview(tableView)
        let tipsLabel = UILabel()
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func setupErrorView() {
        contentView.addSubview(errorView)
        errorView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }
        errorView.isHidden = true
    }
    
    func listView() -> UIView {
        return self
    }
    
    func reloadTable(result: IMMentionReuslt, isSkeleton: Bool = true, nameIndex: [String]? = nil, nameIndexForm: Int = 0, nameDict:[Int: Int] = [:], isMultiSelect: Bool = false) {
        self.isSkeleton = isSkeleton
        self.isMultiSelect = isMultiSelect
        self.nameIndexForm = nameIndexForm
        self.result = result
        self.nameIndex = nameIndex
        self.nameDict = nameDict
        tableView.reloadData()
    }
    
    func reloadTableAtRows(result: IMMentionReuslt, indexPath: [IndexPath]) {
        self.result = result
        UIView.performWithoutAnimation {
            tableView.reloadRows(at: indexPath, with: .none)
        }
    }
    
    // tableView回滚到顶部
    func updateTableScroll() {
        tableView.setContentOffset(.zero, animated: false)
    }
    
    func hiddenFootView() {
        tableView.tableFooterView = nil
    }
    
    func showFootView() {
        let footView = IMMentionTableFooterView(title: BundleI18n.LarkIMMention.Lark_Group_HugeGroup_MemberList_Bottom)
        footView.frame = CGRect(x: 0, y: 0, width: 0.1, height: 56)
        tableView.tableFooterView = footView
    }
    
    @objc func handlePan(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            paneloffsetY = tableView.contentOffset.y
        case .changed:
            let changeY = pan.translation(in: self.tableView).y - paneloffsetY
            if changeY > 0, tableView.contentOffset.y == 0 {
                didChangeHeightHandler?(changeY, pan.state)
            }
        case .ended:
            let changeY = pan.translation(in: self.tableView).y - paneloffsetY
            didChangeHeightHandler?(changeY, pan.state)
            // 重制为默认值
            paneloffsetY = UIScreen.main.bounds.height
        default:
            break
        }
    }
}

extension IMMentionTabsContent: UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return result.sections.count
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let title = result.sections[section].title, !title.isEmpty else {
            return 0
        }
        return 30
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerIdentifier) as? IMMentionSectionHeaderView else {
            return nil
        }
        guard let title = result.sections[section].title, !title.isEmpty else { return nil }
        headerView.contentView.backgroundColor = title.count == 1 ? UIColor.ud.bgBody : UIColor.ud.bgBase
        headerView.title = title
        return headerView
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard result.sections[section].isShowFooter else { return 0 }
        return 56
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard result.sections[section].isShowFooter else { return nil }
        return IMMentionSectionFooterView(title: BundleI18n.LarkIMMention.Lark_Chat_AtChatMemberNoResults)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return result.sections[section].items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: IMMentionItemCell.self), for: indexPath)
        if let mentionCell = cell as? IMMentionItemCell {
            let item = result.sections[indexPath.section].items[indexPath.row]
            mentionCell.node = MentionItemNode(item: item, isMultiSelected: isMultiSelect, isSkeleton: isSkeleton)
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectItemHandler?(result.sections[indexPath.section].items[indexPath.row])
        didEndEditing?()
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        didEndEditing?()
    }
    
    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.nameIndex
    }
    
    public func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return nameDict[index] ?? 0
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffsetY = self.tableView.contentOffset.y
        let panelOffsetY = tableView.panGestureRecognizer.translation(in: self.tableView).y
        if contentOffsetY <= 0 {
            self.tableView.contentOffset.y = 0
        }
        if panelOffsetY > self.paneloffsetY, contentOffsetY >= 0 {
            self.tableView.contentOffset.y = 0
        }
    }
    
}

extension IMMentionTabsContent: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
