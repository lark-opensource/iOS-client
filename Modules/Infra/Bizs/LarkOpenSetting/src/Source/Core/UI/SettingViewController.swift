//
//  SettingViewController.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/9.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkUIKit
import LarkFoundation
import EENavigator
import LKCommonsLogging
import LarkSettingUI

public typealias PatternPair = (moduleKey: String, createKey: String)

public enum SectionPattern {
    case wholeSection(pair: PatternPair)
    case section(header: PatternPair? = nil, footer: PatternPair? = nil, items: [PatternPair])
    case manySections(pair: PatternPair)
}

open class SettingViewController: BaseRxTableViewController {

    public let page: String // 仅用于打日志用
    public let context: ModuleContext

    var highlightKey: String?
    var highlightDate: DispatchTime?

    public init(name: String = "unknown", context: ModuleContext = ModuleContext()) {
        self.page = name
        self.context = context
        super.init(nibName: nil, bundle: nil)
        self.context.reload = { [weak self] in
            self?.reload()
        }
        self.context.reloadImmediately = { [weak self] in
            self?.reloadImmediately()
        }
        self.context.vc = self
        reloadSubject
            .debounce(.milliseconds(10), scheduler: ConcurrentMainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.reloadImmediately()
        }).disposed(by: disposeBag)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        SettingLoggerService.logger(.page(page)).info("life: deinit")
    }

    public var navTitle: String? {
        didSet {
            self.title = navTitle
        }
    }

    // 适用于页面在没有项时隐藏
    public func shouldShow() -> Bool {
        return !allModulesDict.isEmpty
    }

    // MARK: module
    private var allModulesDict = [String: BaseModule]()

    private var isFirstAppear = true

    public func registerModule(_ module: BaseModule, key: String) {
        if allModulesDict[key] != nil {
            SettingLoggerService.logger(.page(page)).warn("register: duplicate \(key)")
        }
        module.key = key
        allModulesDict[key] = module
        module.context = context
    }

    // MARK: generate views
    public var onRegisterDequeueViews: ((UITableView) -> Void)?

    override public func registerDequeueViews(for tableView: UITableView) {
        if let cb = self.onRegisterDequeueViews {
            SettingLoggerService.logger(.page(page)).info("tableView/registerDequeueViews")
            cb(tableView)
        }
        allModulesDict.forEach { key, module in
            if let cb = module.onRegisterDequeueViews {
                SettingLoggerService.logger(.module(key)).info("tableView/registerDequeueViews")
                cb(tableView)
            }
        }
    }

    private let reloadSubject = PublishRelay<Void>()

    public func reload(_ immediately: Bool = false) {
        if immediately {
            reloadImmediately()
        } else {
            sendReloadEvent()
        }
    }

    private func sendReloadEvent() {
        SettingLoggerService.logger(.page(page)).info("tableView/reload: send")
        self.reloadSubject.accept(())
    }

    private func reloadImmediately() {
        SettingLoggerService.logger(.page(page)).info("tableView/reload: real")
        self.sectionPropList.accept(self.createSections())
        self.jumpIfNeeded()
    }

    public var patternsProvider: (() -> [SectionPattern])?

    func createSections() -> [SectionProp] {
        let patterns: [SectionPattern] = self.patternsProvider?() ?? []
        return patterns.flatMap { p -> [SectionProp] in
            return self.createSectionProp(pattern: p, with: self.allModulesDict)
        }.map(highlightIfNeed)
    }

    func createSectionProp(pattern: SectionPattern, with modulesDict: [String: BaseModule]) -> [SectionProp] {
        switch pattern {
        case .wholeSection(let pair):
            if let prop = modulesDict[pair.moduleKey]?.createSectionProp(pair.createKey) {
                return [prop]
            }
            return []
        case .manySections(let pair):
            return modulesDict[pair.moduleKey]?.createSectionPropList(pair.createKey) ?? []
        case .section(let headerPair, let footerPair, let itemsPairs):
            var originHeader: HeaderFooterType?
            if let headerPair = headerPair {
                originHeader = modulesDict[headerPair.moduleKey]?.createHeaderProp(headerPair.createKey)
            }
            var originFooter: HeaderFooterType?
            if let footerPair = footerPair {
                originFooter = modulesDict[footerPair.moduleKey]?.createFooterProp(footerPair.createKey)
            }
            var cellProps: [CellProp] = []
            itemsPairs.forEach { moduleKey, createKey in
                if let items = modulesDict[moduleKey]?.createCellProps(createKey) {
                    cellProps.append(contentsOf: items)
                }
            }
            guard !cellProps.isEmpty else { return [] }
            let prop = SectionProp(items: cellProps, header: originHeader ?? .normal, footer: originFooter ?? .normal)
            return [prop]
        }
    }

    // MARK: 生命周期
    override open func viewDidLoad() {
        super.viewDidLoad()
        runState(.viewDidLoad)
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        runState(.viewWillAppear)

        if isFirstAppear {
            reloadImmediately() // 触发首次创建section
            isFirstAppear = false
        }
    }

    override open func viewDidAppear(_ animated: Bool) {
        runState(.viewDidAppear)
        super.viewDidAppear(animated)
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        runState(.viewWillDisappear)
    }

    override open func viewDidDisappear(_ animated: Bool) {
        runState(.viewDidDisappear)
        super.viewDidDisappear(animated)
    }

    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        runState(.viewWillLayoutSubviews)
    }

    override open func viewDidLayoutSubviews() {
        runState(.viewDidLayoutSubviews)
        super.viewDidLayoutSubviews()
    }

    private var lifeCircleActionDict = [LifeCircleState: () -> Void]()

    final public func removeStateListener(_ state: LifeCircleState) {
        lifeCircleActionDict[state] = nil
    }

    final public func addStateListener(_ state: LifeCircleState, action: @escaping () -> Void ) {
        if lifeCircleActionDict[state] != nil {
            SettingLoggerService.logger(.page(page)).warn("life: addStateListener: duplicate \(state)")
        }
        lifeCircleActionDict[state] = action
    }

    final private func onState(_ state: LifeCircleState) {
        lifeCircleActionDict[state]?()
    }

    final private func runState(_ state: LifeCircleState) {
        self.onState(state)
        SettingLoggerService.logger(.page(page)).info("life: \(state)")
        for module in allModulesDict.values {
            module.onState(state)
        }
    }
}

// 跳转高亮相关
extension SettingViewController: FragmentLocate {
    public func customLocate(by fragment: String, with context: [String: Any], animated: Bool) {
        SettingLoggerService.logger(.page(page)).info("highlight/onFragment: \(fragment)")
        if let body = context[ContextKeys.body] as? HighlightableBody, let highlight = body.highlight {
            self.update(highlight: highlight)
            self.reload()
        }
    }

    public func update(highlight: String?) {
        highlightKey = highlight
        guard let key = highlight, !key.isEmpty else {
            SettingLoggerService.logger(.page(page)).info("highlight/key empty")
            return
        }
        SettingLoggerService.logger(.page(page)).info("highlight/key: \(key)")
    }

    func jumpIfNeeded() {
        guard let id = highlightKey, !id.isEmpty else { return }
        guard let indexPath = findIndexPath(id: id) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            guard indexPath.section < self.tableView.numberOfSections  else {
                SettingLoggerService.logger(.page(self.page)).info("tableView/indexPath: \(indexPath) section out of range: \(self.tableView.numberOfSections)")
                return
            }
            guard indexPath.row < self.tableView.numberOfRows(inSection: indexPath.section) else {
                SettingLoggerService.logger(.page(self.page)).info("tableView/indexPath: \(indexPath) row out of range: \(self.tableView.numberOfRows(inSection: indexPath.section))")
                return
            }
            self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    }

    func findIndexPath(id: String) -> IndexPath? {
        for (i, section) in self.sectionPropList.value.enumerated() {
            for (j, item) in section.items.enumerated() {
                if let itemId = item.id, itemId == id {
                    return IndexPath(row: j, section: i)
                }
            }
        }
        return nil
    }

    func highlightIfNeed(section: SectionProp) -> SectionProp {
        let items = section.items.map(highlightIfNeed)
        return SectionProp(items: items, header: section.header, footer: section.footer)
    }

    func highlightIfNeed(prop: CellProp) -> CellProp {
        guard let id = prop.id, let key = highlightKey, id == key else { return prop }
        let res = prop
        if let due = highlightDate {
            if DispatchTime.now() >= due { // 超过高亮时间，删除key
                highlightKey = nil
                highlightDate = nil
                res.isHighlight = false
            } else { // 高亮时间内，继续高亮
                res.isHighlight = true
            }
        } else { // 时间还未设置：高亮，并更新时间
            res.isHighlight = true
            let highlightDuration: Double = 1 // 高亮1秒
            let updateTime = highlightDuration + 0.1 // 保险起见0.1秒后才刷新
            highlightDate = DispatchTime.now() + highlightDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + updateTime) { [weak self] in
                self?.reload()
            }
        }
        return res
    }
}

public enum LifeCircleState: String, CustomStringConvertible {
    case viewDidLoad
    case viewWillAppear
    case viewDidAppear
    case viewWillLayoutSubviews
    case viewDidLayoutSubviews
    case viewWillDisappear
    case viewDidDisappear

    public var description: String {
        return self.rawValue
    }
}
