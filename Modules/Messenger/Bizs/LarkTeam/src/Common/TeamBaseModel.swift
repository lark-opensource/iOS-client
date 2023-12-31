//
//  TeamBaseModel.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/5.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa

protocol TeamBaseViewModel {
    var name: String { get }
    var title: String { get }
    // Todo: xiaruzhen，rightItem收敛成一个
    var leftItemInfo: (String?) { get }
    var rightItemInfo: (Bool, String) { get }
    var rightItemEnableRelay: BehaviorRelay<Bool> { get }
    var rightItemColorStyleRelay: BehaviorRelay<Bool> { get }
    var fromVC: UIViewController? { get set }
    var targetVC: TeamBaseViewControllerAbility? { get set }
    var reloadData: Driver<Void> { get }
    var items: TeamSectionDatasource { get }

    func viewDidLoadTask()
    func viewWillAppearTask()
    func viewWillDisappearTask()
    func closeItemClick()
    func rightItemClick()
    func backItemTapped()
}

extension TeamBaseViewModel {
    func closeItemClick() {
        self.targetVC?.dismiss(animated: true, completion: nil)
    }
    func rightItemClick() {}
    func backItemTapped() {}
    var rightItemColorStyleRelay: BehaviorRelay<Bool> {
        return BehaviorRelay<Bool>(value: true)
    }
    var leftItemInfo: String? {
        return nil
    }

    func viewWillAppearTask() {}
    func viewWillDisappearTask() {}
}

struct TeamConfig {
    static let inputMaxLength = 60
    static let descriptionInputMaxLength = 200
    static let chatDescInputMaxLength = 100 // 群描述限制输入字符
    static let teamMemberPageCount = 30 // 团队成员列表，每页拉取的成员数量
}

public enum TeamCellSeparaterStyle {
    /// 将会根据 Cell 位置自动设置分割线
    case auto
    /// 没有分割线
    case none
    /// 并非是50%, 而是前面有一段留白
    case half
    /// 和Cell一样宽
    case full
}

protocol TeamCellProtocol {
    /// 填充方法
    /// Parameter item: 对应的Item
    var item: TeamCellViewModelProtocol? { get set }

    func updateAvailableMaxWidth(_ width: CGFloat)
    func cellForRowTask()
}

public protocol TeamCellViewModelProtocol {
    var cellIdentifier: String { get }
    /// 对应Cell的分割线样式
    var style: TeamCellSeparaterStyle { get set }
    /// 对应的标识符
    var type: TeamCellType { get }
}

protocol TeamItemStyleFormat {
    func style(for item: TeamCellViewModelProtocol, at index: Int, total: Int) -> TeamCellSeparaterStyle
}

extension TeamItemStyleFormat {
    func style(for item: TeamCellViewModelProtocol, at index: Int, total: Int) -> TeamCellSeparaterStyle {
        if _fastPath(item.style == .auto) {
            if _slowPath(index == total - 1) {
                return .full
            }
            return .half
        } else {
            return item.style
        }
    }
}

typealias TeamSectionDatasource = [TeamSectionModel]

struct TeamSectionModel {
    var headerTitle: String?
    var footerTitle: String?
    var items: [TeamCellViewModelProtocol]

    @inline(__always)
    var numberOfRows: Int { items.count }

    @inline(__always)
    func item(at row: Int) -> TeamCellViewModelProtocol? {
        _fastPath(row < numberOfRows) ? items[row] : nil
    }
}

public enum TeamCellType: Int {
    case member
    case teamInfo
    case groupMode
    case chooseBindGroup
    case messageNotification
    case permissionConfig
    case leaveTeam
    case disbandTeam
    case `input`
    case `default`
    case teamEvent
}

extension Array where Iterator.Element == TeamSectionModel {
    @inline(__always)
    var numberOfSections: Int { count }

    @inline(__always)
    func section(at index: Int) -> TeamSectionModel? {
        _fastPath(index < numberOfSections) ? self[index] : nil
    }

    @inline(__always)
    func sectionHeader(at index: Int) -> String? {
        section(at: index)?.headerTitle
    }

    @inline(__always)
    func sectionFooter(at index: Int) -> String? {
        section(at: index)?.footerTitle
    }

    @inline(__always)
    func numberOfRows(in section: Int) -> Int {
        self.section(at: section)?.numberOfRows ?? 0
    }

    func item(at indexPath: IndexPath) -> TeamCellViewModelProtocol? {
        if let section = self.section(at: indexPath.section), var item = section.item(at: indexPath.row) {
            item.style = style(for: item, at: indexPath.row, total: section.numberOfRows)
            return item
        }

        return nil
    }
}

extension Array: TeamItemStyleFormat where Iterator.Element == TeamSectionModel {}
