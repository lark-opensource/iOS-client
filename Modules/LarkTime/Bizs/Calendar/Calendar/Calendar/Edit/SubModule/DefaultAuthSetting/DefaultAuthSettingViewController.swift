//
//  DefaultAuthSettingViewController.swift
//  Calendar
//
//  Created by Hongbin Liang on 3/29/23.
//

import Foundation
import LarkUIKit
import RxSwift
import UniverseDesignToast

enum DefaultAuthFrom {
    case inner
    case external
}

class DefaultAuthSettingViewController: BaseUIViewController {

    var settingSelectedHandler: ((_ settingsChanged: DefaultAuthSetting) -> Void)?
    private var optionsPanel: CalendarEditRoleSelectionView
    private let viewModel: DefaultAuthSettingViewModel
    private let type: DefaultAuthFrom
    private let bag = DisposeBag()

    override var navigationBarStyle: NavigationBarStyle { .custom(.ud.bgBase) }

    init(of type: DefaultAuthFrom, viewModel: DefaultAuthSettingViewModel) {
        self.type = type
        self.viewModel = viewModel
        self.optionsPanel = .init(contents: viewModel.contents(of: type))
        super.init(nibName: nil, bundle: nil)
        title = I18n.Calendar_Share_SharingPermissions
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(optionsPanel)
        optionsPanel.layer.cornerRadius = 12
        optionsPanel.clipsToBounds = true
        optionsPanel.snp.makeConstraints({ make in
            make.top.equalTo(8)
            make.leading.trailing.equalToSuperview().inset(16)
        })

        // view -> model
        optionsPanel.onSelect = { [weak self] optionIndex, needBlock in
            guard let self = self else { return }
            if needBlock, let overCalendarRule = self.viewModel.predicateAuthOverRuleFromCalendar(authIndex: optionIndex) {
                // overReader 则走 calendar 兜底
                let tipStr = overCalendarRule ? I18n.Calendar_Share_ThisNoSetDefaultOption :
                I18n.Calendar_Share_MaxPermissionSetAs(MaxPermission: self.viewModel.externalTopAuthStr)
                UDToast.showTips(with: tipStr, on: self.view)
            } else {
                self.viewModel.updateSetting(of: self.type, with: optionIndex)
                self.settingSelectedHandler?(self.viewModel.rxShareAuthSettings.value)
                self.navigationController?.popViewController(animated: true)
            }
        }

        // model -> view
        let rxSelectedIndex = type == .inner ? viewModel.rxInnerSelectedIndex : viewModel.rxExternalSelectedIndex
        rxSelectedIndex
            .bind { [weak self] selectedIndex in
                guard let self = self, selectedIndex >= 0 else { return }
                self.optionsPanel.selectedIndex = selectedIndex
            }.disposed(by: bag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
