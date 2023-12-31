//
//  GroupChatterSelectController.swift
//  LarkChat
//
//  Created by kkk on 2019/3/12.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkCore
import EENavigator
import LarkModel
import LKCommonsLogging

final class ChatChatterSelectViewController: BaseSettingController {
    private var table: ChatChatterController
    private var pickerToolBar = DefaultPickerToolBar()

    var onSelect: (([Chatter]) -> Void)?
    private var allowSelectNone: Bool

    init(viewModel: ChatterControllerVM,
         allowSelectNone: Bool) {
        self.allowSelectNone = allowSelectNone
        self.table = ChatChatterController(viewModel: viewModel, canSildeRelay: .init(value: false))
        super.init(nibName: nil, bundle: nil)

        self.addChild(table)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        pickerToolBar.setItems(pickerToolBar.toolbarItems(), animated: false)
        pickerToolBar.allowSelectNone = self.allowSelectNone
        pickerToolBar.updateSelectedItem(
            firstSelectedItems: [],
            secondSelectedItems: [],
            updateResultButton: true)

        pickerToolBar.selectedButtonTappedBlock = { [weak self] _ in self?.showSelectedDetail() }
        pickerToolBar.confirmButtonTappedBlock = { [weak self] _ in self?.confirmSelect() }
        self.pickerToolBar.isHidden = false
        self.view.addSubview(pickerToolBar)
        self.pickerToolBar.snp.makeConstraints {
            $0.height.equalTo(49)
            $0.left.right.equalToSuperview()
            if #available(iOS 11, *) {
                $0.bottom.equalTo(self.view.safeAreaLayoutGuide)
            } else {
                $0.bottom.equalToSuperview()
            }
        }

        self.view.addSubview(table.view)
        table.displayMode = .multiselect
        table.view.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
            maker.bottom.equalTo(pickerToolBar.snp.top)
        }

        self.view.bringSubviewToFront(pickerToolBar)

        title = titleString.isEmpty ? BundleI18n.LarkChatSetting.Lark_Legacy_TitleSelectMember : titleString

        bandingTableEvent()
    }
}

private extension ChatChatterSelectViewController {
    func showSelectedDetail() {
        let controller = ChatChatterSelectedDetailController(selectedItems: table.selectedItems)
        controller.onSure = { [weak self] (selectedItems, _) in
            self?.table.setDefaultSelectedItems(selectedItems)
            self?.pickerToolBar.updateSelectedItem(firstSelectedItems: selectedItems,
                                                   secondSelectedItems: [],
                                                   updateResultButton: true)
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    func confirmSelect() {
        navigationController?.popViewController(animated: true)
        onSelect?(table.selectedItems.compactMap { $0.itemUserInfo as? Chatter })
    }

    func bandingTableEvent() {
        table.onSelected = { [weak self] (_, items) in
            self?.pickerToolBar.updateSelectedItem(firstSelectedItems: items,
                                                  secondSelectedItems: [],
                                                  updateResultButton: true)
        }

        table.onDeselected = { [weak self] (_, items) in
            self?.pickerToolBar.updateSelectedItem(firstSelectedItems: items,
                                                  secondSelectedItems: [],
                                                  updateResultButton: true)
        }
    }
}
