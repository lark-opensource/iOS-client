//
//  CalendarHostSettingsVC.swift
//  ByteView
//
//  Created by Tobb Huang on 2022/6/1.
//

import Foundation
import SnapKit
import ByteViewUI
import UniverseDesignToast

final class CalendarHostSettingsVC: BaseViewController {

    lazy var barSaveButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("\(I18n.View_G_ConfirmButton) (\(selectedIds.count))", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault.withAlphaComponent(0.5), for: .highlighted)
        button.addTarget(self, action: #selector(save), for: .touchUpInside)
        return button
    }()

    let service: UserSettingManager
    var selectedIds: [String] {
        didSet {
            barSaveButton.setTitle("\(I18n.View_G_ConfirmButton) (\(selectedIds.count))", for: .normal)
            barSaveButton.sizeToFit()
        }
    }

    let callback: ([String]) -> Void
    init(service: UserSettingManager, selectedIds: [String], callback: @escaping ([String]) -> Void) {
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
        self.title = I18n.View_G_AddHosts
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: barSaveButton)

        let userId = service.userId
        let chatterPicker = service.ui.createChatterPicker(selectedIds: selectedIds, disabledIds: [userId], isMultiple: true, includeOuterTenant: false, selectHandler: { [weak self] in
            self?.didSelectChatter($0)
        }, deselectHandler: { [weak self] in
            self?.didDeselectChatter($0)
        }, shouldSelectHandler: { [weak self] in
            guard let self = self else { return true }
            let shouldSelect = self.selectedIds.count < 10
            if !shouldSelect {
                if let window = self.view.window {
                    UDToast.showTips(with: I18n.View_G_AddTenHostsMax, on: window)
                }
            }
            return shouldSelect
        })
        self.view.addSubview(chatterPicker)
        chatterPicker.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc func save() {
        callback(selectedIds)
        self.dismiss(animated: true)
    }

    func didSelectChatter(_ chatterID: String) {
        if !selectedIds.contains(where: { $0 == chatterID }) {
            selectedIds.append(chatterID)
        }
    }

    func didDeselectChatter(_ chatterID: String) {
        selectedIds.removeAll(where: { $0 == chatterID })
    }
}
