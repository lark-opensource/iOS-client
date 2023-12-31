//
//  BaseRxTableViewController.swift
//  LarkMine
//
//  Created by panbinghua on 2021/12/21.
//

import Foundation
import UIKit
import SnapKit
import FigmaKit
import RxSwift
import RxCocoa
import RxDataSources
import UniverseDesignColor
import LarkUIKit
import LarkSettingUI

public struct SectionProp {
    public var items: [Item]
    public var header: HeaderFooterType
    public var footer: HeaderFooterType

    public init(items: [Item],
         header: HeaderFooterType = .normal,
         footer: HeaderFooterType = .normal) {
        self.header = header
        self.footer = footer
        self.items = items
    }
}

extension SectionProp: SectionModelType {
    public typealias Item = CellProp

    public init(original: Self, items: [Item]) { // 创建一个只有item不同、其他属性都同的sectionModel的初始化方法
        self = original
        self.items = items
    }
}

open class BaseRxTableViewController: BaseUIViewController, UITableViewDelegate {
    public let disposeBag = DisposeBag()

    // view
    public lazy var tableView: UITableView = {
        var tableView = InsetTableView(frame: .zero)
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 8))
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()

    public override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    open func registerDequeueViews(for tableView: UITableView) {
        // 由子类实现
    }

    private func registerDequeue(for tableView: UITableView) {
        // header footer
        tableView.register(UITableViewHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: "UITableViewHeaderFooterView")
        tableView.register(NormalHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: "NormalHeaderView")
        tableView.register(TitleHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: "TitleHeaderView")
        tableView.register(TitleFooterView.self,
                           forHeaderFooterViewReuseIdentifier: "TitleFooterView")
        // cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.register(TapCell.self, forCellReuseIdentifier: "TapCell")
        tableView.register(NormalCell.self, forCellReuseIdentifier: "NormalCell")
        tableView.register(SwitchNormalCell.self, forCellReuseIdentifier: "SwitchNormalCell")
        tableView.register(CheckboxNormalCell.self, forCellReuseIdentifier: "CheckboxNormalCell")
        tableView.register(ImageTitleCell.self, forCellReuseIdentifier: "ImageTitleCell")
        registerDequeueViews(for: tableView)
    }

    // view model

    /// 将观察序列绑定到这个对象上
    public var sectionPropList = BehaviorRelay<[SectionProp]>(value: [])

    public var dataSource = RxTableViewSectionedReloadDataSource<SectionProp>(
       configureCell: { _, tableView, indexPath, info in
           if let cell = tableView.dequeueReusableCell(withIdentifier: info.cellIdentifier,
                                                       for: indexPath) as? BaseCell {
               cell.update(info)
               return cell
           }
           return tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
       }
   )

    // life cycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        // view
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        registerDequeue(for: tableView)
        sectionPropList
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }

    // delegate
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? BaseCell else { return }
        let numberOfRow = tableView.numberOfRows(inSection: indexPath.section)
        let isLastRowInSection = indexPath.row == numberOfRow - 1
        cell.hideSeparatorLine(isLastRowInSection)
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section >= 0 && section < self.dataSource.sectionModels.count else {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
        }
        switch self.dataSource.sectionModels[section].header {
        case .custom(let viewProvider):
            return viewProvider()
        case .prop(let prop):
            if let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: prop.identifier)
                as? BaseHeaderFooterView {
                view.update(prop)
                return view
            }
        case .title(let text):
            if let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TitleHeaderView")
                as? TitleHeaderView {
                header.text = text
                return header
            }
        case .empty, .normal:
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: "NormalHeaderView")
        }
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section >= 0 && section < self.dataSource.sectionModels.count else {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
        }
        switch self.dataSource.sectionModels[section].footer {
        case .custom(let viewProvider):
            return viewProvider()
        case .prop(let prop):
            if let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: prop.identifier)
                as? BaseHeaderFooterView {
                view.update(prop)
                return view
            }
        case .title(let text):
            if let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TitleFooterView")
                as? TitleFooterView {
                footer.text = text
                return footer
            }
        case .empty, .normal:
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: "NormalHeaderView")
        }
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        guard indexPath.section >= 0 && indexPath.section < dataSource.sectionModels.count else { return }
        guard indexPath.row >= 0 && indexPath.row < dataSource.sectionModels[indexPath.section].items.count else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        if let prop = dataSource.sectionModels[indexPath.section].items[indexPath.row] as? CellClickable {
            prop.onClick?(cell)
        }
    }
}
