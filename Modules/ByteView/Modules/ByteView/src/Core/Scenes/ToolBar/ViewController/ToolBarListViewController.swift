//
//  ToolBarListViewController.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/8.
//

import UIKit
import ByteViewUI

protocol ToolBarListViewControllerDelegate: AnyObject {
    func toolbarListViewControllerDidDismiss()
}

class ToolBarListViewController: VMViewController<ToolBarViewModel>, UITableViewDelegate, UITableViewDataSource {
    private static let cellHeight: CGFloat = 50
    private static let minWidth: CGFloat = 136
    private static let maxWidth: CGFloat = 375
    private static let footerHeight: CGFloat = 7

    weak var delegate: ToolBarListViewControllerDelegate?
    private var items: [[ToolBarItem]] = Array(repeating: [], count: ToolBarConfiguration.padMoreItems.count)

    private lazy var tableView: UITableView = {
        let view = BaseTableView(frame: .zero)
        view.layer.masksToBounds = true
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = true
        view.register(cellType: ToolBarListCell.self)
        view.separatorStyle = .none
        view.bounces = false
        return view
    }()

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.toolbarListViewControllerDidDismiss()
    }

    override func setupViews() {
        super.setupViews()
        view.backgroundColor = UIColor.ud.bgFloat
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.bottom.equalTo(view.safeAreaLayoutGuide).inset(4)
            make.left.right.equalTo(view.safeAreaLayoutGuide)
        }
    }

    override func bindViewModel() {
        super.bindViewModel()
        viewModel.addListener(self)
        updateToolbarItems()
    }

    override func viewLayoutContextDidChanged() {
        UIView.performWithoutAnimation {
            self.updateToolbarItems()
        }
    }

    private var listWidth: CGFloat {
        let maxItemWidth = items.flatMap { $0 }.map { item in
            let title: String
            if let participantItem = item as? ToolBarParticipantsItem {
                title = participantItem.listTitle
            } else {
                title = item.title
            }
            let titleWidth = CGFloat(ceil(ToolBarTitleWidthCache.titleWidth(title,
                                                                            fontSize: ToolBarListCell.titleFontSize,
                                                                            fontWeight: ToolBarListCell.titleFontWeight)))
            // left spacing + right spacing + icon width + icon-title spacing
            let spacing: CGFloat = 16 * 2 + 20 + 12
            let badgeWidth: CGFloat
            switch item.badgeType {
            case .dot:
                badgeWidth = 6
            case .text(let text):
                badgeWidth = CGFloat(ceil(ToolBarTitleWidthCache.titleWidth(text,
                                                                            fontSize: ToolBarListCell.textBadgeFontSize,
                                                                            fontWeight: ToolBarListCell.textBadgeFontWeight) + 8))
            case .none:
                badgeWidth = 0
            }
            let badgeTitleSpacing: CGFloat = badgeWidth == 0 ? 0 : 6
            return titleWidth + spacing + badgeWidth + badgeTitleSpacing
        }.max() ?? 0
        return min(max(maxItemWidth, Self.minWidth), Self.maxWidth)
    }

    func updateContainerSize() {
        UIView.performWithoutAnimation {
            let counts = items.map { $0.count }
            let itemsCount = counts.reduce(0, +)
            var totalHeight = CGFloat(itemsCount) * Self.cellHeight + 8
            for i in 0..<counts.count - 1 {
                if counts[i] > 0 && counts[i + 1] > 0 {
                    totalHeight += Self.footerHeight
                }
            }
            updateDynamicModalSize(CGSize(width: listWidth + 8, height: totalHeight))
        }
    }

    private func updateToolbarItems() {
        let itemTypes = viewModel.padMoreItems
        var hasItem = false
        var deletions: [IndexPath] = []
        var moves: [(from: IndexPath, to: IndexPath)] = []
        var insertions: [IndexPath] = []

        assert(itemTypes.count == items.count)
        for i in 0..<itemTypes.count {
            let newItems = itemTypes[i].map { viewModel.factory.item(for: $0) }
            if !newItems.isEmpty {
                hasItem = true
            }

            let itemsInSection = items[safeAccess: i] ?? []
            if let diff = DiffUtils.computeBatchAction(origin: itemsInSection.map { $0.itemType }, target: itemTypes[i], maxChangeCnt: 40), !diff.isEmpty {
                deletions.append(contentsOf: diff.deletions.map { IndexPath(row: $0, section: i) })
                moves.append(contentsOf: diff.moves.map { (from: IndexPath(row: $0.from, section: i), to: IndexPath(row: $0.to, section: i)) })
                insertions.append(contentsOf: diff.insertions.map { IndexPath(row: $0, section: i) })
            }
        }

        if !hasItem {
            dismiss(animated: false)
            return
        }

        UIView.performWithoutAnimation {
            tableView.performBatchUpdates({
                self.items = itemTypes.map { $0.map { viewModel.factory.item(for: $0) } }
                if !deletions.isEmpty {
                    self.tableView.deleteItemsAtIndexPaths(deletions, animationStyle: .none)
                }
                for move in moves {
                    self.tableView.moveItemAtIndexPath(move.from, to: move.to)
                }
                if !insertions.isEmpty {
                    self.tableView.insertItemsAtIndexPaths(insertions, animationStyle: .none)
                }
            }, completion: { [weak self] _ in
                guard let self = self else { return }
                self.updateContainerSize()
            })
        }
    }

    private func shouldShowFooter(in section: Int) -> Bool {
        guard section < items.count - 1 && tableView.numberOfRows(inSection: section) > 0 else { return false }
        if tableView.numberOfRows(inSection: section + 1) > 0 {
            return true
        } else if section + 2 < items.count && tableView.numberOfRows(inSection: section + 2) > 0 {
            return true
        }
        return false
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withType: ToolBarListCell.self, for: indexPath)
        cell.bind(item: items[indexPath.section][indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Self.cellHeight
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        shouldShowFooter(in: section) ? Self.footerHeight : 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard shouldShowFooter(in: section) else { return nil }
        let view = UIView()
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        view.addSubview(line)
        line.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
        return view
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss(animated: true)
        items[indexPath.section][indexPath.row].clickAction()
    }
}

extension ToolBarListViewController: ToolBarViewModelDelegate {
    func toolbarItemDidChange(_ item: ToolBarItem) {
        let oldIsShowing = items.flatMap { $0 }.contains { $0.itemType == item.itemType }
        let newIsShowing = item.actualPadLocation == .more
        if newIsShowing != oldIsShowing {
            updateToolbarItems()
        }
    }
}
