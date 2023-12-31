//
//  DepartmentTestListController.swift
//  Passport
//
//  Created by Miaoqi Wang on 2021/4/23.
//

import Foundation
import LarkRustClient
import LarkContainer
import RustPB
import RxSwift
import LarkAccountInterface
import EENavigator
import RoundedHUD

typealias FetchDataAction = (@escaping ([[Item]]) -> Void) -> Void

/// 暂时没用 后期有需求可以使用
class FetchMoreListViewController: ListViewController {

    var fetching: Bool = false
    let fetchAction: FetchDataAction

    init(fetchAction: @escaping FetchDataAction, items: [[Item]]) {
        self.fetchAction = fetchAction
        super.init(items: items)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.bounds.height > scrollView.contentSize.height && !fetching {
            fetching = true
            fetchAction { newData in
                DispatchQueue.main.async {
                    self.items = newData
                    self.table.reloadData()
                    self.fetching = false
                }
            }
        }
    }
}

/// 组织架构分页逻辑 https://bytedance.feishu.cn/docs/doccnuGGkO1Hiwd7reEsFa2lKcf
class DepartmentTestListController: ListViewController {
    @Provider var rustService: RustService
    let disposeBag = DisposeBag()

    init() {
        super.init(items: [])

        self.items = [
            [
                Item(title: "Unfold Department", subtitle: "PC only", action: {
                    self.fetchUnfoldDepartment(offset: 0, count: 50) { (items) in
                        Navigator.shared.push(ListViewController(items: items), from: self)

                        let testPaging = false // 打开验证分页拉取： 连续打开两个页面 第二个页面是 "下一页"的数据
                        if testPaging {
                            self.fetchUnfoldDepartment(offset: 50, count: 50) { (items) in
                                Navigator.shared.push(ListViewController(items: items), from: self)
                            }
                        }
                    }
                }),
                Item(title: "Get Department", subtitle: "GetDepartmentCombineChat", action: {
                    self.openDepartment(id: nil)
                })
            ]
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fetchUnfoldDepartment(offset: Int, count: Int, complete: @escaping ([[Item]]) -> Void) {
        var req = Contact_V1_GetUnfoldDepartmentCombineChatRequest()
        req.chatID = AccountServiceAdapter.shared.currentChatterId
        req.offset = Int32(offset)
        req.count = Int32(count)
        req.subDepartmentPaging = true
        let hud = RoundedHUD.showLoading(on: self.view)
        Self.logger.info("fetch department offset: \(offset) count: \(count)")
        self.rustService.sendAsyncRequest(req)
            .observeOn(MainScheduler.instance)
            .subscribe { (resp: Contact_V1_GetUnfoldDepartmentCombineChatResponse) in
                hud.remove()
                var departItems: [[Item]] = []
                resp.departmentStructure.forEach { (department) in
                    Self.logger.info("department name: \(department.department.name) id: \(department.department.id) sub count: \(department.subDepartments.count) chatter count: \(department.chatters.count)")
                    if department.subDepartments.count == 0 {
                        departItems.append([
                            Item(title: "Empty Department")
                        ])
                    } else {
                        let subDepartmentItems = department.subDepartments.map { (sub) -> Item in
                            Item(title: sub.name, subtitle: sub.id) {
                                self.openDepartment(id: sub.id)
                            }
                        }
                        let chatterItems = department.chatters.map({ Item(title: $0.name, subtitle: $0.id) })

                        let items = [Item(title: "Department: \(subDepartmentItems.count) Chatter: \(chatterItems.count)")]
                            + subDepartmentItems
                            + chatterItems
                        departItems.append(items)
                    }
                }
                complete(departItems)
            } onError: { (error) in
                hud.showFailure(with: error.localizedDescription, on: self.view)
                Self.logger.error("get unfold department combine chat failed", error: error)
            }.disposed(by: self.disposeBag)
    }

    func openDepartment(id: String?) {
        var req = Contact_V1_GetDepartmentCombineChatRequest()
        req.chatID = AccountServiceAdapter.shared.currentChatterId
        if let id = id {
            req.departmentID = id
        } else {
            req.departmentID = "0"
        }
        req.offset = 0
        req.count = 30
        req.chatterOffset = 0
        req.chatterCount = 30
        req.subDepartmentPaging = true
        let hud = RoundedHUD.showLoading(on: self.view)
        self.rustService.sendAsyncRequest(req)
            .observeOn(MainScheduler.instance)
            .subscribe { (resp: Contact_V1_GetDepartmentCombineChatResponse) in
                hud.remove()
                Navigator.shared.push(
                    DepartmentListViewController(
                        structure: resp.departmentStructure
                    ),
                    from: self)
            } onError: { (error) in
                hud.showFailure(with: error.localizedDescription, on: self.view)
                Self.logger.error("get department failed", error: error)
            }.disposed(by: self.disposeBag)
    }
}

class DepartmentListViewController: ListViewController {
    @Provider var rustService: RustService
    let disposeBag = DisposeBag()

    let departmentStructure: Contact_V1_DepartmentStructure

    init(structure: Contact_V1_DepartmentStructure) {
        self.departmentStructure = structure
        super.init(items: [])
        self.title = structure.department.name
        let departmentItems = structure.subDepartments.map({ (sub) -> Item in
            Item(title: sub.name, subtitle: sub.id) {
                let countStep = 40
                self.openDepartment(id: sub.id, offset: 0, count: countStep, chatterOffset: 0, chatterCount: 0) { resp in
                    Navigator.shared.push(DepartmentListViewController(structure: resp), from: self)

                    // 分页拉取逻辑(可参考messenger 这里简单实现验证接口)：
                    // - 先拉Department 如果department数量小于 countstep 则尾部会有chatter 同时hasMoreDepartment == false， 否则都是department，下一页继续拉 department
                    // - department 和 chatter offset 独立，所以拉完department前 chatter count == 0

                    
                    let testPaging = false // 打开验证分页拉取： 连续打开两个页面 第二个页面是 "下一页"的数据
                    if testPaging {
                        let chatterOffset: Int
                        let chatterCount: Int
                        let offset: Int
                        let count: Int
                        if resp.hasMoreDepartment_p {
                            offset = countStep
                            count = countStep
                            chatterOffset = 0
                            chatterCount = 0
                        } else {
                            offset = 0
                            count = 0
                            chatterOffset = countStep - resp.subDepartments.count
                            chatterCount = countStep
                        }
                        self.openDepartment(
                            id: sub.id,
                            offset: offset,
                            count: count,
                            chatterOffset: chatterOffset,
                            chatterCount: chatterCount
                        ) { resp in
                            Navigator.shared.push(DepartmentListViewController(structure: resp), from: self)
                        }
                    }
                }
            }
        })

        let chatterItems = structure.chatters.map({ Item(title: $0.id, subtitle: "Chatter") })

        self.items = [
            [Item(title: "Department: \(departmentItems.count)")] + departmentItems,
            [Item(title: "Chatter: \(chatterItems.count)")] + chatterItems
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func openDepartment(id: String?, offset: Int, count: Int, chatterOffset: Int, chatterCount: Int, complete: @escaping (Contact_V1_DepartmentStructure) -> Void) {

        var req = Contact_V1_GetDepartmentCombineChatRequest()
        req.chatID = AccountServiceAdapter.shared.currentChatterId
        if let id = id {
            req.departmentID = id
        }
        req.offset = Int32(offset)
        req.count = Int32(count)
        req.chatterOffset = Int32(chatterOffset)
        req.chatterCount = Int32(chatterCount)
        let hud = RoundedHUD.showLoading(on: self.view)
        self.rustService.sendAsyncRequest(req)
            .observeOn(MainScheduler.instance)
            .subscribe { (resp: Contact_V1_GetDepartmentCombineChatResponse) in
                hud.remove()
                complete(resp.departmentStructure)
            } onError: { (error) in
                hud.showFailure(with: error.localizedDescription, on: self.view)
                Self.logger.error("get department failed", error: error)
            }.disposed(by: self.disposeBag)
    }
}
