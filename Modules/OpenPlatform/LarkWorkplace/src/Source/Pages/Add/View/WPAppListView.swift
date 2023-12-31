//
//  WPAppListView.swift
//  LarkWorkplace
//
//  Created by 李论 on 2020/6/21.
//

import UIKit
import LKCommonsLogging

/// 装在Cell里的那个pageView的包装类，真实的pageView是WPPageView
final class WPAppListView: UIView, WPPageViewDatasource, WPPageViewDelegate {
    static let logger = Logger.log(WPAppListView.self)

    func numberOfPagesInPageView(pageView: WPPageView) -> Int {
        return viewModel?.pageList?.count ?? 0
    }

    func pageview(pageView: WPPageView, pageIndex: Int) -> UIView {
        guard let viewModel = viewModel?.pageList?[pageIndex] else {
            Self.logger.error("page(\(pageIndex)) is empty, get pageview failed")
            return UIView()
        }
        Self.logger.debug("page(\(pageIndex)) is ready")
        return WPCategoryPageView(
            frame: pageView.bounds,
            viewModel: viewModel
        )
    }
    func dataReload(pageView: WPPageView, pageIndex: Int, content: UIView) {
        guard let viewModel = viewModel?.pageList?[pageIndex] else {
            Self.logger.error("viewModel(\(pageIndex)) is empty, can not reload")
            return
        }
        (content as? WPCategoryPageView)?.reloadData(model: viewModel)
    }

    func pageviewDidScrollTo(pageView: WPPageView, pageIndex: UInt) {
        viewModel?.switchToPageIndex(index: Int(pageIndex))
    }

    private lazy var appPageView: WPPageView = {
        let page = WPPageView(frame: self.bounds)
        page.datasource = self
        page.delegate = self
        return page
    }()

    var viewModel: AppCategoryViewModel? {
        didSet {
            reloadPageList()
        }
    }

    func reloadPageList() {
        appPageView.reloadData()
        if let selectedIndex = viewModel?.selectedIndex, selectedIndex < viewModel?.pageList?.count ?? 0 {
            appPageView.scrollToPage(pageIndex: selectedIndex)
        }
    }

    override func updateConstraints() {
        super.updateConstraints()
        appPageView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    init() {
        super.init(frame: .zero)
        setupPageView()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPageView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPageView() {
        backgroundColor = .clear
        addSubview(appPageView)
        setNeedsUpdateConstraints()
        appPageView.reloadData()
    }

    /// 刷新pageView布局
    func refreshPageLayout() {
        guard let selectedIndex = viewModel?.selectedIndex, selectedIndex < viewModel?.pageList?.count ?? 0 else {
            Self.logger.error("viewModel selectedIndex missed, can not refresh")
            return
        }
        self.appPageView.refreshPageViewLayout(selectedIndex: selectedIndex)
    }
}

final class WPAppListCell: UITableViewCell {
    static let cellIdentify = "cellIdentifier"
    /// 真正的内容视图（类似于一个pageView）
    private var _applistView: WPAppListView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.separatorInset = .zero
        self.contentView.backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setAppListView(applistView: WPAppListView?) {
        _applistView?.removeFromSuperview()
        _applistView = applistView
        setupAppListView()
    }

    func setupAppListView() {
        if let listView = _applistView {
            listView.removeFromSuperview()
            contentView.addSubview(listView)
            listView.snp.remakeConstraints { (make) in
                make.left.right.top.bottom.equalToSuperview()
            }
            setNeedsUpdateConstraints()
        }
    }
}
