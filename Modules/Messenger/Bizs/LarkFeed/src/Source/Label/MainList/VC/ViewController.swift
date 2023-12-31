//
//  LabelMainListViewController.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/20.
//

import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import RustPB
import UIKit
import LarkOpenFeed
import LarkContainer

final class LabelMainListViewController: BaseUIViewController, UserResolverWrapper {
    var userResolver: UserResolver { vm.userResolver }
    private let disposeBag = DisposeBag()
    var context: LabelMainListContext?
    weak var delegate: FeedModuleVCDelegate?

    let vm: LabelMainListViewModel
    let viewAdapter: ViewAdapter
    let tableAdapter: LabelMainListTableAdapter
    let actionHandlerAdapter: LabelMainListActionHandlerAdapter
    let selectedAdapter: SelectedAdapter
    let otherAdapter: OtherAdapter

    let tableView = FeedTableView(frame: .zero, style: .plain)
    let tableFooter = LabelTableFooter(title: BundleI18n.LarkFeed.Lark_Core_CreateLabel_Button_PC)

    init(vm: LabelMainListViewModel) {
        self.vm = vm
        self.viewAdapter = ViewAdapter(vm: vm)
        self.tableAdapter = LabelMainListTableAdapter(vm: vm)
        self.actionHandlerAdapter = LabelMainListActionHandlerAdapter(vm: vm)
        self.selectedAdapter = SelectedAdapter(vm: vm)
        self.otherAdapter = OtherAdapter(vm: vm)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        otherAdapter.preloadDetail()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectIndexPath, animated: false)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.selectedAdapter.viewWillTransitionForPad(to: size, with: coordinator)
    }
}

extension LabelMainListViewController {
    func setup() {
        viewAdapter.setup(page: self)
        tableAdapter.setup(page: self)
        actionHandlerAdapter.setup(page: self)
        selectedAdapter.setup(page: self)
        otherAdapter.setup(page: self)
    }
}

extension LabelMainListViewController: FeedModuleVCInterface {

    func setContentOffset(_ offset: CGPoint, animated: Bool) {
        tableView.setContentOffset(offset, animated: animated)
    }

    func willActive() {
        vm.willActive()
        selectedAdapter.recoverSelectChat()
        otherAdapter.preloadDetail()
    }

    func willResignActive() {
        vm.willResignActive()
    }

    func willDestroy() {}

    func doubleClickTabbar() {
        self.delegate?.backFirstList()
    }
}
