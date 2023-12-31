//
//  UDThemeSettingView.swift
//  UDCCatalog
//
//  Created by bytedance on 2021/3/28.
//  Copyright © 2021 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignTheme

class UDThemeSettingView: UIView {

    private lazy var exampleViews: [UIView] = [messageView, chatView]

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.bounces = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    private lazy var bottomView: UIView = {
        let view = UIView()
        return view
    }()

    lazy var messageView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.alwaysBounceVertical = false
        return tableView
    }()

    lazy var chatView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.alwaysBounceVertical = false
        return tableView
    }()

    lazy var pageIndicator: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.hidesForSinglePage = true
        pageControl.pageIndicatorTintColor = UIColor.ud.N300
        pageControl.currentPageIndicatorTintColor = Cons.themeTintColor
        return pageControl
    }()

    lazy var darkModeControl: UISegmentedControl = {
        let items = ["system", "light", "dark"]
        let control = UISegmentedControl(items: items)
        return control
    }()

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        addSubview(scrollView)
        addSubview(bottomView)
        addSubview(pageIndicator)
        for exampleView in exampleViews {
            scrollView.addSubview(exampleView)
        }
        bottomView.addSubview(darkModeControl)
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomView.snp.top)
        }
        bottomView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
        }
        darkModeControl.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-20)
        }
        pageIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(bottomView.snp.top).offset(-10)
        }
    }

    private func setupAppearance() {
        scrollView.delegate = self
        pageIndicator.addTarget(self, action: #selector(didTapPageControl(_:)), for: .valueChanged)
        pageIndicator.numberOfPages = exampleViews.count

        backgroundColor = UIColor.ud.bgBody
        chatView.backgroundColor = .clear
        messageView.backgroundColor = .clear
        bottomView.backgroundColor = UIColor.ud.bgFloat
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.contentSize = CGSize(
            width: self.bounds.width * CGFloat(exampleViews.count),
            height: scrollView.bounds.height
        )
        for (i, view) in exampleViews.enumerated() {
            view.frame = CGRect(
                x: self.bounds.width * CGFloat(i),
                y: 0,
                width: self.bounds.width,
                height: scrollView.bounds.height
            )
        }
    }
}

extension UDThemeSettingView: UIScrollViewDelegate {

    @objc
    private func didTapPageControl(_ sender: UIPageControl) {
        let page = CGFloat(sender.currentPage)
        scrollView.setContentOffset(CGPoint(x: frame.width * page, y: 0), animated: true)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / frame.width)
        pageIndicator.currentPage = page
    }
}

extension UDThemeSettingView {

    enum Cons {
        static var bottomPanelHeight: CGFloat {
            UIApplication.safeAreaInsets.bottom + 100
        }

        static var themeTintColor: UIColor {
            return .systemBlue
        }
    }

}

extension UIApplication {

    static var safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
        }
        return UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
    }
}
