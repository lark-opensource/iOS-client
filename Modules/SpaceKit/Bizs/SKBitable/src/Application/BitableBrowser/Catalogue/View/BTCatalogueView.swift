//
//  BTCatalogueView.swift
//  SKSheet
//
//  Created by huayufan on 2021/3/22.
//  


import UIKit
import SKUIKit
import SnapKit
import RxSwift
import RxCocoa
import SKFoundation

protocol BTCatalogueViewDelegate: AnyObject {
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
}

final class BTCatalogueView: UIView {
    
    enum State {
        case reload([[BitableCatalogueData]], autoAdjust: Bool)
        case reloadPartial([[BitableCatalogueData]], [IndexPath])
        case add([[BitableCatalogueData]], [IndexPath])
        case delete([[BitableCatalogueData]], [IndexPath])
    }

    // 列表滑动、其他 cell 开始侧滑时，需要把前一个 cell 的侧滑菜单收起
    private let slideMutexHelper = SKSlideableTableViewCell.MutexHelper()

    fileprivate var eventSubject = PublishSubject<BTCatalogueViewController.Event>()
    
    fileprivate var items: [[BitableCatalogueData]] = []
    
    private(set) var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        #if canImport(ShazamKit)
        if #available(iOS 15.0, *) {
            view.fillerRowHeight = 0
            view.sectionHeaderTopPadding = 0
        }
        #endif
        view.register(BTCatalogueCell.self, forCellReuseIdentifier: BTCatalogueCell.reuseIdentifier)
        view.register(BTCatalogueGroupCell.self, forCellReuseIdentifier: BTCatalogueGroupCell.reuseIdentifier)
        view.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 40 - 6, right: 0)
        view.rowHeight = 48
        view.sectionHeaderHeight = 6
        view.sectionFooterHeight = 6
        view.separatorStyle = .none
        view.backgroundColor = .clear
        return view
    }()
    
    weak var catalogueViewDelegate: BTCatalogueViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
        setupLayout()
    }
    
    func setupInit() {
        tableView.construct {
            $0.delegate = self
            $0.dataSource = self
        }
        addSubview(tableView)
    }
    
    private func setupLayout() {
        addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - tableView delegate dataSource

extension BTCatalogueView: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < items.count else { return 0 }
        return items[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < items.count,
              indexPath.row < items[indexPath.section].count else {
                  return UITableViewCell()
              }
        let item = items[indexPath.section][indexPath.row]
        var cell: BTCatalogueBaseCell?
        if item.catalogueType == .node {
            cell = tableView.dequeueReusableCell(withIdentifier: BTCatalogueCell.reuseIdentifier, for: indexPath) as? BTCatalogueCell
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: BTCatalogueGroupCell.reuseIdentifier, for: indexPath) as? BTCatalogueGroupCell
        }
        guard let tableViewCell = cell else {
            return UITableViewCell()
        }
        tableViewCell.update(data: item)

        let isSectionFirstItem = indexPath.row == 0
        let isSectionLastItem = indexPath.row == items[indexPath.section].count - 1
        var corners: CACornerMask = []
        if isSectionFirstItem {
            corners.insert(.top)
        }
        if isSectionLastItem {
            corners.insert(.bottom)
            tableViewCell.lineView.isHidden = true
        } else {
            tableViewCell.lineView.isHidden = false
        }
        tableViewCell.update(roundCorners: corners)
        tableViewCell.setClickAction { [weak self] in
            guard let self = self else { return }
            self.tableView(self.tableView, didSelectRowAt: indexPath)
        }

        tableViewCell.addHandler = { [weak self] (sourceView: Weak<UIView>) in
            self?.eventSubject.onNext(.slide(indexPath, .add, sourceView))
        }
        tableViewCell.moreHandler = { [weak self] (sourceView: Weak<UIView>) in
            self?.eventSubject.onNext(.slide(indexPath, .more, sourceView))
        }
        return tableViewCell
    }

    private func swipeActionsForRowAt(indexPath: IndexPath) -> [SKSlidableTableViewCellItem]? {
        guard indexPath.section < items.count, indexPath.row < items[indexPath.section].count else {
            DocsLogger.btInfo("BTCatalogue: swipe action out of range")
            return []
        }
        let item = items[indexPath.section][indexPath.row]
        var slideAction: [BTCatalogueContextualAction.ActionType] = []
        if item.editable {
            slideAction = item.slideActions
        }
        let actions = slideAction.compactMap { (type) -> SKSlidableTableViewCellItem? in
            guard type != .add else { return nil } // 新建按钮从侧滑菜单移至 cell 内容上
            return BTCatalogueContextualAction.slideItem(type) { [weak self] _, _ in
                guard let self = self else { return }
                self.slideMutexHelper.didClickSlideMenuAction()
                self.eventSubject.onNext(.slide(indexPath, type, nil))
            }
        }
        return actions.reversed()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        eventSubject.onNext(.choose(indexPath))
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        slideMutexHelper.tableViewDidScroll()
        
        catalogueViewDelegate?.scrollViewDidScroll(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        catalogueViewDelegate?.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
    }
}

// MARK: - binder

extension Reactive where Base: BTCatalogueView {
    
    var state: Binder<BTCatalogueView.State> {
        return Binder(base) { (target, data) in
            switch data {
            case let.reload(res, autoAdjust):
                DocsLogger.btInfo("BTCatalogue: reload autoAdjust:\(autoAdjust)")
                target.items = res
                target.tableView.reloadData()
                target.tableView.layoutIfNeeded()
                if autoAdjust {
                    for (section, sectionItems) in res.enumerated() {
                        guard let row = sectionItems.firstIndex(where: {
                            if $0.catalogueType == .node {
                               return $0.isSelected
                            } else {
                                return $0.isSelected && !$0.canExpand
                            }
                        }) else { continue }
                        // 放到下个循环处理，否则一些场景不生效
                        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) { [weak target] in
                            guard let tg = target else {
                                return
                            }
                            if section < tg.items.count,
                               row < tg.items[section].count { // 防止越界
                                tg.tableView.scrollToRow(at: IndexPath(row: row, section: section), at: .middle, animated: false)
                            }
                        }
                        break
                    }
                }
                
            case let.reloadPartial(res, indexPaths):
                DocsLogger.btInfo("BTCatalogue: reloadPartial \(indexPaths)")
                target.items = res
                target.tableView.reloadRows(at: indexPaths, with: .none)
            case let .add(res, indexPaths):
                DocsLogger.btInfo("BTCatalogue: add \(indexPaths)")
                target.items = res
                target.tableView.performBatchUpdates({
                    target.tableView.insertRows(at: indexPaths, with: .top)
                }, completion: { _ in
                    target.tableView.reloadData()
                })
            case let .delete(res, indexPaths):
                DocsLogger.btInfo("BTCatalogue: delete \(indexPaths)")
                target.items = res
                target.tableView.performBatchUpdates({
                    target.tableView.deleteRows(at: indexPaths, with: .top)
                }, completion: { _ in
                    target.tableView.reloadData()
                })
            }
           
        }
    }
}


// MARK: - event

extension BTCatalogueView {
    
    var eventDrive: Driver<BTCatalogueViewController.Event> {
        return eventSubject.asDriver(onErrorJustReturn: .none)
    }
    
}
