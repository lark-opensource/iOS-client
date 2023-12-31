//
//  FilterPanelViewController.swift
//  Todo
//
//  Created by baiyantao on 2022/8/23.
//

import Foundation
import UIKit
import AnimatedTabBar

final class FilterPanelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var dismissHandler: ((FilterPanelViewModel.Field?) -> Void)?

    // dependencies
    private let viewModel: FilterPanelViewModel
    private let topOffset: CGFloat

    // views
    private lazy var naviCoverView = initNaviConverView()
    private lazy var whiteGapView = initWhiteGapView()
    private lazy var maskView = initMaskView()
    private lazy var tableView = initTableView()

    // internal state
    private var isPopover: Bool { modalPresentationStyle == .popover }

    init(viewModel: FilterPanelViewModel, topOffset: CGFloat) {
        self.viewModel = viewModel
        self.topOffset = topOffset
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    func alongsideAppearTransition() {
        guard !isPopover else { return }
        maskView.backgroundColor = UIColor.ud.bgMask
        tableView.snp.updateConstraints {
            $0.bottom.equalTo(maskView.snp.top).offset(viewModel.contentHeight())
        }
        view.layoutIfNeeded()
    }

    func alongsideDisappearTransition() {
        guard !isPopover else { return }
        maskView.backgroundColor = .clear
        whiteGapView.snp.updateConstraints {
            $0.height.equalTo(0)
        }
        tableView.snp.updateConstraints {
            $0.bottom.equalTo(maskView.snp.top)
        }
        view.layoutIfNeeded()
    }

    private func setupView() {
        if isPopover {
            preferredContentSize = CGSize(width: 375, height: viewModel.contentHeight())
        } else {
            transitioningDelegate = self
        }
        view.backgroundColor = isPopover ? UIColor.ud.N00 : .clear
        view.addSubview(naviCoverView)
        naviCoverView.snp.makeConstraints {
            $0.top.trailing.leading.equalToSuperview()
            $0.height.equalTo(isPopover ? 0 : topOffset)
        }
        view.addSubview(maskView)
        maskView.snp.makeConstraints {
            $0.bottom.trailing.leading.equalToSuperview()
            $0.top.equalTo(naviCoverView.snp.bottom)
        }
        maskView.addSubview(whiteGapView)
        whiteGapView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(isPopover ? 0 : 20)
        }
        maskView.addSubview(tableView)
        tableView.snp.makeConstraints {
            if isPopover {
                $0.top.bottom.equalToSuperview()
            } else {
                $0.bottom.equalTo(maskView.snp.top)
                $0.height.equalTo(viewModel.contentHeight())
            }
            $0.leading.trailing.equalToSuperview()
        }

        // 分屏时 dismiss 掉自己
        NotificationCenter.default.addObserver(
            self, selector: #selector(doDismiss),
            name: AnimatedTabBarController.styleChangeNotification, object: nil
        )
    }

    private func initNaviConverView() -> UIButton {
        let button = UIButton()
        button.backgroundColor = .clear
        button.clipsToBounds = false
        button.addTarget(self, action: #selector(doDismiss), for: .touchUpInside)
        return button
    }

    private func initWhiteGapView() -> UIControl {
        let view = UIControl()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }

    private func initMaskView() -> UIButton {
        let button = UIButton()
        button.backgroundColor = .clear
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(doDismiss), for: .touchUpInside)
        return button
    }

    private func initTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.separatorInset = .init(top: 0, left: 16, bottom: 0, right: 0)
        tableView.alwaysBounceVertical = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.ctf.register(cellType: FilterPanelCell.self)
        return tableView
    }

    @objc
    private func doDismiss() {
        dismissSelf()
    }

    private func dismissSelf(field: FilterPanelViewModel.Field? = nil) {
        dismissHandler?(field)
        dismiss(animated: true, completion: nil)
    }

    // MARK: - UITableView

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfItems()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.ctf.dequeueReusableCell(FilterPanelCell.self, for: indexPath),
              let info = viewModel.cellInfo(indexPath: indexPath) else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        cell.viewData = info
        cell.clickHandler = { [weak self] field in
            FilterTab.logger.info("panel do select field: \(field?.logInfo ?? "")")
            self?.dismissSelf(field: field)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        48
    }
}

// MARK: - Transitioning

extension FilterPanelViewController: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController, source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return Transitioning(.show)
    }
    func animationController(forDismissed dismissed: UIViewController )
        -> UIViewControllerAnimatedTransitioning? {
        return Transitioning(.dismiss)
    }
}

private class Transitioning: NSObject, UIViewControllerAnimatedTransitioning {
    enum Style {
        case show
        case dismiss
    }
    let style: Style
    init(_ style: Style) {
        self.style = style
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch style {
        case .show: doShow(using: transitionContext)
        case .dismiss: doDismiss(using: transitionContext)
        }
    }

    private func doShow(using transitionContext: UIViewControllerContextTransitioning) {
        guard let vc = transitionContext.viewController(forKey: .to) as? FilterPanelViewController else {
            return
        }
        transitionContext.containerView.addSubview(vc.view)
        vc.view.layoutIfNeeded()
        doAnimation(using: transitionContext) {
            vc.alongsideAppearTransition()
        }
    }

    private func doDismiss(using transitionContext: UIViewControllerContextTransitioning) {
        guard let vc = transitionContext.viewController(forKey: .from) as? FilterPanelViewController else {
            return
        }
        doAnimation(using: transitionContext) {
            vc.alongsideDisappearTransition()
        }
    }

    private func doAnimation(
        using transitionContext: UIViewControllerContextTransitioning,
        animations: @escaping () -> Void
    ) {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.77,
            initialSpringVelocity: 0.5,
            options: [.allowUserInteraction],
            animations: animations
        ) { _ in
            transitionContext.completeTransition(true)
        }
    }
}
