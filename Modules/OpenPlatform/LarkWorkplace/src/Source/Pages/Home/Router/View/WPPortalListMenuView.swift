//
//  WPPortalListMenu.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/12/20.
//

import Foundation
import UIKit
import UniverseDesignColor

protocol WPPortalListMenuViewDelegate: AnyObject {

    /// 当点击背景遮罩时，回调 item 为 nil
    func menuView(_ menuView: WPPortalListMenuView, didSelectItem item: WPPortal?)
    
    /// 自动切换门户时调用
    /// path：applink 处理 Web 工作台时，跳转到的特定子页面
    func menuView(_ menuView: WPPortalListMenuView, didChangeItem item: WPPortal?, path: String?, queryItems: [URLQueryItem]?)
}

private enum Const {
    static let cellID = "WPPortalListMenuViewCell"

    static let cellH: CGFloat = 48.0
    static let iPadCellH: CGFloat = 56.0

    static let tableBottomMarginH: CGFloat = 4.0
}

final class WPPortalListMenuView: UIView {

    // MARK: - public vars

    enum DisplayMode {
        case normal
        case popover
    }

    var displayMode: DisplayMode = .normal

    private(set) var portalList: [WPPortal] = []

    weak var delegate: WPPortalListMenuViewDelegate?
    
    // 自动切换门户，目前仅通过applink打开指定门户
    func selectPortal(
        _ portal: WPPortal,
        path: String? = nil,
        queryItems: [URLQueryItem]?
    ) {
        guard let index = portalList.firstIndex(of: portal) else {
            assertionFailure("WPPortalListMenuView: cannot find select portal")
            return
        }
        selectedIndex = index
        delegate?.menuView(self, didChangeItem: portal, path: path, queryItems: queryItems)
        // 修改选中态
        self.tableView.reloadData()
    }

    // MARK: - private vars

    private lazy var bgView: UIView = {
        let vi = UIView()
        vi.backgroundColor = UIColor.ud.bgMask
        let tap = UITapGestureRecognizer(target: self, action: #selector(onBackgroundTap(_:)))
        vi.addGestureRecognizer(tap)
        return vi
    }()

    private lazy var tableContainerView: UIView = {
        let container = UIView()
        container.backgroundColor = UIColor.ud.bgBody
        return container
    }()

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.separatorStyle = .none
        table.separatorColor = .clear
        table.showsVerticalScrollIndicator = false
        table.backgroundColor = UIColor.ud.bgBody
        table.delegate = self
        table.dataSource = self
        table.register(WPPortalListMenuCell.self, forCellReuseIdentifier: Const.cellID)
        return table
    }()

    private var selectedIndex: Int = 0

    private var cellHeight: CGFloat {
        switch displayMode {
        case .normal:
            return Const.cellH
        case .popover:
            return Const.iPadCellH
        }
    }

    // MARK: - life cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        subviewsInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - public funcs

    /// 更新数据
    /// - Parameters:
    ///   - list: 门户列表
    ///   - selectedIndex: 被选择index
    func updateData(_ list: [WPPortal], selectedIndex: Int) {
        self.portalList = list
        self.selectedIndex = selectedIndex

        let height: CGFloat
        let containerHeight: CGFloat

        if list.count <= 10 {
            height = cellHeight * CGFloat(list.count)
            containerHeight = height
        } else {
            height = cellHeight * 6.5
            containerHeight = height + Const.tableBottomMarginH
        }

        tableContainerView.snp.updateConstraints { make in
            make.height.equalTo(containerHeight)
        }

        tableView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }

        tableView.reloadData()
    }

    // MARK: - private funcs

    private func subviewsInit() {
        addSubview(bgView)
        addSubview(tableContainerView)
        tableContainerView.addSubview(tableView)

        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableContainerView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(0)
        }

        tableView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(0)
        }
    }

    @objc
    func onBackgroundTap(_ sender: UITapGestureRecognizer) {
        delegate?.menuView(self, didSelectItem: nil)
    }
}

final class WPPortalListMenuCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        styleInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func styleInit() {
        backgroundColor = UIColor.ud.bgBody
        // 使用 ud token 初始化 font
        // swiftlint:disable init_font_with_token
        textLabel?.font = UIFont.systemFont(ofSize: 16.0)
        // swiftlint:disable init_font_with_token
        textLabel?.textColor = UIColor.ud.textTitle
        textLabel?.backgroundColor = UIColor.clear
        textLabel?.textAlignment = .left
        textLabel?.numberOfLines = 1
        textLabel?.lineBreakMode = .byTruncatingTail
    }
}

extension WPPortalListMenuView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        portalList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Const.cellID, for: indexPath)
        if indexPath.row < portalList.count {
            cell.textLabel?.text = portalList[indexPath.row].title
        }
        cell.backgroundColor = (indexPath.row == selectedIndex ? UIColor.ud.bgFiller : UIColor.ud.bgBody)

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        cellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < portalList.count else {
            assertionFailure()
            return
        }
        selectedIndex = indexPath.row
        let item = portalList[indexPath.row]
        delegate?.menuView(self, didSelectItem: item)
    }
}
