//
//  SettingViewModel.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/3/1.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI
import UniverseDesignToast

protocol SettingViewModelDelegate: SettingRowUpdatable, AnyObject {
    func requireUpdateSections()
}

class BaseSettingViewModel: UserSettingListener {
    var logger: Logger = .setting
    var pageId: SettingPageId = .unknown
    let service: UserSettingManager
    var title: String = ""
    @RwAtomic
    private(set) var sections: [SettingDisplaySection] = []
    weak var delegate: SettingViewModelDelegate?
    weak var hostViewController: UIViewController?
    var httpClient: HttpClient { service.httpClient }
    var userId: String { service.userId }
    final var observedSettingChanges: Set<UserSettingChangeType> = []
    final var supportedCellTypes: Set<SettingCellType> = [.switchCell, .checkboxCell, .gotoCell, .checkmarkCell, .longGotoCell]
    /// 需要默认自动跳转的 cell
    var autoJumpCell: SettingDisplayItem? { nil }
    final var supportedHeaderTypes: Set<SettingDisplayHeaderType> = [.emptyHeader, .titleHeader, .titleAndRedirectDescriptionHeader]
    final var supportedFooterTypes: Set<SettingDisplayFooterType> = [.emptyFooter, .descriptionFooter, .redirectDescriptionFooter]

    init(service: UserSettingManager) {
        self.service = service
        self.setup()
        self.buildSections()

        if !observedSettingChanges.isEmpty {
            service.addListener(self, for: observedSettingChanges)
        }
    }

    /// for override，初始化一些配置（事件监听，配置刷新等），外部不应该调用
    func setup() {}
    /// for override
    func buildSections(builder: SettingSectionBuilder) {}
    /// for override
    func trackPageAppear() {}

    final func buildSections() {
        let builder = SettingSectionBuilder()
        buildSections(builder: builder)
        self.sections = builder.build()
    }

    func updateRow(for item: SettingDisplayItem, newValue: SettingDisplayRow) {
        _sections.update { sections in
            if let indexPath = sections.findIndexPath(for: item) {
                sections.updateRow(newValue, at: indexPath)
            }
        }
    }

    /// ViewController是否能够旋转
    var supportsRotate: Bool { false }

    func didChangeUserSetting(_ setting: UserSettingManager, _ data: UserSettingChange) {
        reloadData()
    }

    func reloadData() {
        buildSections()
        delegate?.requireUpdateSections()
    }

    func showToast(_ text: String) {
        Util.runInMainThread { [weak self] in
            if let from = self?.hostViewController {
                UDToast.showTips(with: text, on: from.view)
            }
        }
    }
}

class SettingViewModel<Context>: BaseSettingViewModel {
    @RwAtomic
    var context: Context
    init(service: UserSettingManager, context: Context) {
        self.context = context
        super.init(service: service)
    }
}
