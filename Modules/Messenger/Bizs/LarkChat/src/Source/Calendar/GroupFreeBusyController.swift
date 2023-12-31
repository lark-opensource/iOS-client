//
//  GroupFreeBusyController.swift
//  LarkChat
//
//  Created by zoujiayi on 2019/7/30.
//

import UIKit
import Foundation

import LarkUIKit
import RxSwift
import RxCocoa
import LarkCore
import EENavigator
import LarkModel
import LKCommonsLogging

final class GroupFreeBusyController: BaseUIViewController {
    private var disposeBag = DisposeBag()

    private var table: GroupFreeBusyChatterController
    private let chatId: String
    private let selectedCallBack: ([String]) -> Void
    private let originalSelectedCount: Int
    private var confirmButton: LKBarButtonItem!

    init(viewModel: GroupFreeBusyChatterControllerVM) {
        self.chatId = viewModel.chatId
        self.selectedCallBack = viewModel.selectCallBack
        self.originalSelectedCount = viewModel.defaultSelectedIds?.count ?? 0
        self.table = GroupFreeBusyChatterController(viewModel: viewModel)

        super.init(nibName: nil, bundle: nil)
        self.addChild(table)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(table.view)
        table.view.snp.remakeConstraints { (maker) in
            maker.top.left.right.bottom.equalToSuperview()
        }
        table.displayMode = .multiselect

        title = BundleI18n.Calendar.Calendar_ChatFindTime_ChooseMember

        addBackItem()
        confirmButton = addConfirmItem()

        bandingTableEvent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
}

private extension GroupFreeBusyController {
    func addConfirmItem() -> LKBarButtonItem {
        let barItem = LKBarButtonItem(image: nil, title: "\(BundleI18n.LarkChat.Lark_Legacy_Sure)(\(originalSelectedCount))")
        barItem.button.rx.tap.asDriver()
            .drive(onNext: { [weak self] _ in self?.confirmSelect() })
            .disposed(by: disposeBag)
        self.navigationItem.rightBarButtonItem = barItem
        return barItem
    }

    func confirmSelect() {
        let chatters = table.selectedItems.compactMap { $0.itemUserInfo as? Chatter }
        let chatterIds = chatters.map { $0.id }
        self.navigationController?.popViewController(animated: true)
        selectedCallBack(chatterIds)
    }

    func bandingTableEvent() {

        table.onSelected = { [weak self] (_, items) in
            self?.confirmButton.setBtnColor(color: UIColor.ud.colorfulBlue)
            self?.confirmButton.resetTitle(title: "\(BundleI18n.LarkChat.Lark_Legacy_Sure)(\(items.count))")
            self?.confirmButton.isEnabled = true
        }

        table.onDeselected = { [weak self] (_, items) in
            self?.confirmButton.resetTitle(title: "\(BundleI18n.LarkChat.Lark_Legacy_Sure)(\(items.count))")
        }

        table.onClickSearch = { ChatTracker.trackFindMemberClick() }
    }
}
