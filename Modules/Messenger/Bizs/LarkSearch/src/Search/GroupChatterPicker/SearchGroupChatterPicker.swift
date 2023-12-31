//
//  SearchGroupChatterPicker.swift
//  LarkSearch
//
//  Created by kongkaikai on 2019/5/8.
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
import LarkMessengerInterface

final class SearchGroupChatterPicker: BaseUIViewController {

    private var table: ChatChatterController

    private lazy var rightItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: BundleI18n.LarkSearch.Lark_Legacy_MenuMultiSelect,
                                   style: .plain,
                                   target: self,
                                   action: #selector(toggleViewSelectStatus))
        let tintColor = UIColor.ud.textTitle
        let font = UIFont.systemFont(ofSize: 16)
        item.setTitleTextAttributes([.font: font, .foregroundColor: tintColor], for: .normal)
        return item
    }()

    private lazy var leftCancelItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: BundleI18n.LarkSearch.Lark_Legacy_Cancel,
                                   style: .plain,
                                   target: self,
                                   action: #selector(cancelItemTapped))
        let font = UIFont.systemFont(ofSize: 16)
        item.setTitleTextAttributes([.font: font], for: .normal)
        return item
    }()

    private var isMultiSelect: Bool
    var onConfirmSelected: SearchGroupChatterPickerBody.SureCallBack?
    var onCancel: (() -> Void)?

    init(viewModel: ChatterControllerVM,
         forceMultiSelect: Bool) {
        // 由是否有默认选择的人决定初始状态是单选还是多选
        self.isMultiSelect = ((viewModel.defaultSelectedIds ?? []).isEmpty == false) || forceMultiSelect
        self.table = ChatChatterController(viewModel: viewModel, canSildeRelay: .init(value: self.isMultiSelect))
        super.init(nibName: nil, bundle: nil)

        table.displayMode = self.isMultiSelect ? .multiselect : .display
        self.addChild(table)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(table.view)
        table.view.snp.makeConstraints { (maker) in
            maker.top.bottom.left.right.equalToSuperview()
        }

        navigationItem.rightBarButtonItem = self.rightItem

        if isMultiSelect {
            self.rightItem.title = BundleI18n.LarkSearch.Lark_Legacy_Sure
            navigationItem.leftBarButtonItem = self.leftCancelItem
            let tintColor = UIColor.ud.primaryContentDefault
            let font = UIFont.systemFont(ofSize: 16, weight: .medium)
            rightItem.setTitleTextAttributes([.font: font, .foregroundColor: tintColor], for: .normal)
        } else {
            addCancelItem()
        }

        bandingTableEvent()
    }

    @objc
    private func toggleViewSelectStatus() {

        // 多选状态则是确定
        if isMultiSelect {
            onConfirmSelected?(self, table.selectedItems.compactMap { $0.itemUserInfo as? Chatter })
        } else {
            switchToMultiSelect()
            isMultiSelect.toggle()
        }
    }

    @objc
    private func cancelItemTapped() {
        switchToSingleSelect()
        isMultiSelect.toggle()
    }

    @objc
    override func closeBtnTapped() {
        onCancel?()
        super.closeBtnTapped()
    }
}

private extension SearchGroupChatterPicker {

    func switchToMultiSelect() {
        self.rightItem.title = BundleI18n.LarkSearch.Lark_Legacy_Sure
        let tintColor = UIColor.ud.primaryContentDefault
        let font = UIFont.systemFont(ofSize: 16, weight: .medium)
        rightItem.setTitleTextAttributes([.font: font, .foregroundColor: tintColor], for: .normal)
        navigationItem.leftBarButtonItem = self.leftCancelItem

        table.displayMode = .multiselect
    }

    func switchToSingleSelect() {
        self.rightItem.title = BundleI18n.LarkSearch.Lark_Legacy_MenuMultiSelect
        let tintColor = UIColor.ud.textTitle
        let font = UIFont.systemFont(ofSize: 16)
        rightItem.setTitleTextAttributes([.font: font, .foregroundColor: tintColor], for: .normal)
        addCancelItem()
        table.displayMode = .display
    }

    func bandingTableEvent() {
        table.onTap = { [weak self] (item) in
            guard let self = self else { return }

            guard let chatter = item.itemUserInfo as? Chatter else { return }
            self.onConfirmSelected?(self, [chatter])
        }
    }
}
