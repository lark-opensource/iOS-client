//
//  SelectMenuCompactController.swift
//  LarkDynamic
//
//  Created by Songwen Ding on 2019/7/18.
//

import Foundation
import UIKit
import LarkUIKit
import UniverseDesignColor
import UniverseDesignPopover
import LarkFeatureGating

/// 用于显示更简易版本的select menu，支持在底部或者以popover两种形式进行显示，不会展示搜索框
public final class SelectMenuCompactController: UIViewController, UITableViewDelegate {

    public var selectConfirm: (([SelectMenuViewModel.Item]) -> Void)?
    
    private let viewModel: SelectMenuViewModel
    private var tapOutsideGesture: UITapGestureRecognizer?

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self.viewModel
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.rowHeight = 52
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.register(SelectMenuTableViewCell.self, forCellReuseIdentifier: "Cell")
        return tableView
    }()
    
    private lazy var navBar: UIView = {
        let container = UIView()
        container.backgroundColor = UIColor.ud.bgBody
        container.clipsToBounds = true
        container.layer.cornerRadius = 8
        container.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return container
    }()

    /// 显示popover形式时的视图宽度
    private let popoverWidth: CGFloat

    public init(items: [SelectMenuViewModel.Item], selectedValues: [String]? = nil, popoverWidth: CGFloat = 375.0, isMulti: Bool = false) {
        self.viewModel = SelectMenuViewModel(items: items, selectedValues: selectedValues, selectionStyle: .none, mode: .compact, isMulti: isMulti)
        self.popoverWidth = popoverWidth
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        var topConstraintItem = view.snp.top
        if viewModel.isMulti {
            setupNaviBar()
            topConstraintItem = navBar.snp.bottom
        }
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(topConstraintItem)
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var height = 52.0 * CGFloat(viewModel.allItems.count)
        let navBarHeight = viewModel.isMulti ? 56.0 : 0
        var originY = 0.0
        if let window = view.window {
            let maxHeight = window.bounds.height - navBarHeight - window.safeAreaInsets.top
            height = min(height + window.safeAreaInsets.bottom, maxHeight) + navBarHeight
            originY = window.bounds.height - height
        }
        if let popoverVC = popoverPresentationController,
           UIDevice.current.userInterfaceIdiom == .pad {
            preferredContentSize = CGSize(width: tableView.bounds.width, height: height)
            updateUIConstraints(arrowDirection: popoverVC.arrowDirection)
        } else {
            view.frame = CGRect(x: 0, y: originY, width: view.bounds.width, height: height)
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let indexPath = viewModel.firstSelectIndexPath {
            tableView.scrollToRow(at: indexPath,
                                  at: .middle,
                                  animated: true)
        }
        if !viewModel.isMulti && tapOutsideGesture == nil {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
            tapGesture.cancelsTouchesInView = false
            view.window?.addGestureRecognizer(tapGesture)
            tapOutsideGesture = tapGesture
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let tapOutsideGesture = tapOutsideGesture {
            view.window?.removeGestureRecognizer(tapOutsideGesture)
            self.tapOutsideGesture = nil
        }
    }

    @objc
    private func tapped(_ sender: UITapGestureRecognizer) {
        if !tableView.frame.contains(sender.location(in: view)) {
            dismiss(animated: true)
        }
    }
    
    private func setupNaviBar() {
        view.addSubview(navBar)
        navBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.text = BundleI18n.SelectMenu.Lark_Legacy_MsgCardSelect
        navBar.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        let closeBtn = UIButton()
        closeBtn.setImage(BundleResources.SelectMenu.navigation_close_outlined, for: .normal)
        closeBtn.addTarget(self, action: #selector(closeBtnTapped), for: .touchUpInside)
        navBar.addSubview(closeBtn)
        closeBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        let confirmBtn = UIButton()
        confirmBtn.setTitle(BundleI18n.SelectMenu.Lark_Legacy_Confirm, for: .normal)
        confirmBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        confirmBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        confirmBtn.addTarget(self, action: #selector(confirmBtnTapped), for: .touchUpInside)
        navBar.addSubview(confirmBtn)
        confirmBtn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    private func updateUIConstraints(arrowDirection: UIPopoverArrowDirection) {
        switch arrowDirection {
        case .up:
            if viewModel.isMulti {
                navBar.snp.remakeConstraints { make in
                    make.top.equalToSuperview().offset(12)
                    make.leading.trailing.equalToSuperview()
                    make.height.equalTo(56)
                }
            } else {
                tableView.snp.remakeConstraints { make in
                    make.top.equalToSuperview().offset(12)
                    make.leading.trailing.bottom.equalToSuperview()
                }
            }
        case .down:
            tableView.snp.updateConstraints { make in
                make.bottom.equalToSuperview().offset(-12)
            }
        default:
            break
        }
    }
    
    @objc
    private func closeBtnTapped() {
        dismiss(animated: true)
    }
    
    @objc
    private func confirmBtnTapped() {
        selectConfirm?(viewModel.selectedItems)
        dismiss(animated: true)
    }

    // MARK: - UITableViewDelegate

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let selectCell = tableView.cellForRow(at: indexPath) as? SelectMenuTableViewCell,
              let selectItem = viewModel.item(index: indexPath.row) else {
            return
        }
        
        if viewModel.isMulti {
            selectCell.isChosen = !selectCell.isChosen
            viewModel.selectItem(select: selectCell.isChosen, item: selectItem)
        } else {
            if let selectedIndex = viewModel.singlePreSelectIndex,
               selectedIndex != indexPath,
               let lastSelectCell = tableView.cellForRow(at: selectedIndex) as? SelectMenuTableViewCell {
                lastSelectCell.isChosen = false
            }
            selectCell.isChosen = true
            selectConfirm?([selectItem])
            dismiss(animated: true)
        }
    }
}
