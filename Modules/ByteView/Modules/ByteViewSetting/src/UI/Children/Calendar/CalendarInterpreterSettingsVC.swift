//
//  CalendarInterpreterSettingsVC.swift
//  ByteView
//
//  Created by wulv on 2022/7/19.
//

import Foundation
import SnapKit
import ByteViewUI
import UniverseDesignToast

final class CalendarInterpreterSettingsVC: BaseViewController {

    /// 已选过的uid
    var selectedIds: [String]

    /// 本次选中的uid
    var currentSelectId: String?
    let callback: (String) -> Void
    let service: UserSettingManager
    init(service: UserSettingManager, selectedIds: [String], callback: @escaping (String) -> Void) {
        self.service = service
        self.selectedIds = selectedIds
        self.callback = callback
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = I18n.View_G_AddInterpreter

        let chatterPicker = service.ui.createChatterPicker(
            selectedIds: [], disabledIds: [], isMultiple: false, includeOuterTenant: true,
        selectHandler: { [weak self] in
            self?.didSelectChatter($0)
        }, deselectHandler: { [weak self] in
            self?.didDeselectChatter($0)
        }, shouldSelectHandler: nil)
        view.addSubview(chatterPicker)
        chatterPicker.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc func save() {
        if let currentSelectId = currentSelectId {
            callback(currentSelectId)
        }
        doBack()
    }

    func didSelectChatter(_ chatterID: String) {
        if !selectedIds.contains(chatterID) {
            currentSelectId = chatterID
            save()
        } else {
            UDToast.showTips(with: I18n.View_G_AlreadyInterpreter, on: self.view)
        }
    }

    func didDeselectChatter(_ chatterID: String) {
        if currentSelectId == chatterID {
            currentSelectId = nil
        }
    }
}
