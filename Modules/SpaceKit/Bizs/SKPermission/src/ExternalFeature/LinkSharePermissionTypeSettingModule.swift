//
//  LinkSharePermissionTypeSettingModule.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/12/11.
//

import Foundation
import SKFoundation
import SKResource
import LarkContainer
import RxSwift
import LarkSettingUI
import LarkOpenSetting
import SKCommon
import UniverseDesignActionPanel
import UniverseDesignColor

extension LinkSharePermissionTypeStateModule {
    static let moduleProvider: ModuleProvider = { userResolver in
        do {
            let userSettings = try userResolver.resolve(assert: CCMUserSettings.self)
            guard let tenantName = userResolver.docs.user?.info?.tenantName else {
                DocsLogger.error("get tenant name failed in link share setting")
                return nil
            }
            return LinkSharePermissionTypeStateModule(userResolver: userResolver,
                                                      userSettings: userSettings,
                                                      tenantName: tenantName)
        } catch {
            DocsLogger.error("CCMUserSettings not found from userResolver", error: error)
            return nil
        }
    }
}

private extension CCMUserProperties.LinkSharePermissionType {
    func displayTitle(tenantName: String) -> String {
        switch self {
        case .close:
            BundleI18n.SKResource.LarkCCM_IM_SharingSuggestions_OnlyInvitedUserCanAccess_Radio_Mob
        case .tenantCanRead:
            BundleI18n.SKResource.LarkCCM_IM_SharingSuggestions_AnyoneWithLinkCanView_Radio_Mob(tenantName)
        }
    }
}

private typealias PermissionType = CCMUserProperties.LinkSharePermissionType

class LinkSharePermissionTypeStateModule: BaseModule {

    private var linkShareType: PermissionType
    private let userSettings: CCMUserSettings
    private let tenantName: String

    init(userResolver: UserResolver, userSettings: CCMUserSettings, tenantName: String) {
        self.userSettings = userSettings
        linkShareType = userSettings.userProperties?.linkSharePermissionType ?? .close
        self.tenantName = tenantName
        super.init(userResolver: userResolver)

        onRegisterDequeueViews = { tableView in
            tableView.register(LinkShareStateCell.self, forCellReuseIdentifier: LinkShareStateCell.reuseIdentifier)
        }

        userSettings.userPropertiesUpdated
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] properties in
                self?.linkShareType = properties.linkSharePermissionType
                self?.context?.reload()
            })
            .disposed(by: disposeBag)

        userSettings.fetchUserProperties()
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] properties in
                // 这里啥也不干也行，上面 updated 会包含这里的逻辑
                self?.linkShareType = properties.linkSharePermissionType
                self?.context?.reload()
            } onError: { error in
                DocsLogger.error("get common setting fail", error: error)
            }
            .disposed(by: disposeBag)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        let item = LinkShareStateCellProp(title: BundleI18n.SKResource.LarkCCM_IM_SharingSuggestions_DefaultPermissionOfNewDocs_Text_Mob,
                                          detail: linkShareType.displayTitle(tenantName: tenantName)) { [weak self] _ in
            guard let self, let controller = self.context?.vc else { return }
            let moduleKey = LinkSharePermissionTypeSettingModule.moduleKey
            let settingController = SettingViewController(name: moduleKey)
            settingController.patternsProvider = { return [
                .wholeSection(pair: PatternPair(moduleKey, ""))
            ]}
            let module = LinkSharePermissionTypeSettingModule(userResolver: self.userResolver,
                                                              userSettings: self.userSettings,
                                                              tenantName: self.tenantName)
            settingController.registerModule(module, key: moduleKey)
            settingController.navTitle = BundleI18n.SKResource.LarkCCM_IM_SharingSuggestions_DefaultPermissionOfNewDocs_Text_Mob
            self.userResolver.navigator.push(settingController, from: controller)
        }
        return SectionProp(items: [item])
    }

    private static func customLabel(text: String) -> UIView {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UDColor.textPlaceholder
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setFigmaText(text)
        return label
    }
}

class LinkSharePermissionTypeSettingModule: BaseModule {
    fileprivate static let moduleKey = "CCMLinkShareSetting"
    private var linkShareType: PermissionType
    private let userSettings: CCMUserSettings
    private let tenantName: String

    init(userResolver: UserResolver, userSettings: CCMUserSettings, tenantName: String) {
        self.userSettings = userSettings
        linkShareType = userSettings.userProperties?.linkSharePermissionType ?? .close
        self.tenantName = tenantName
        super.init(userResolver: userResolver)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        SectionProp(items: [
            createCellProp(for: .close),
            createCellProp(for: .tenantCanRead)
        ])
    }

    private func createCellProp(for permissionType: PermissionType) -> CellProp {
        let title = permissionType.displayTitle(tenantName: tenantName)
        return CheckboxNormalCellProp(title: title, isOn: linkShareType == permissionType) { [weak self] _ in
            self?.update(permissionType: permissionType)
        }
    }

    private func update(permissionType: PermissionType) {
        // 与当前设置一致，忽略操作
        guard permissionType != linkShareType else { return }
        let oldShareType = linkShareType
        linkShareType = permissionType
        context?.reload()

        var patch = CCMUserProperties.Patch()
        patch.linkSharePermissionType = permissionType
        userSettings.updateUserProperties(with: patch)
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self] error in
                DocsLogger.error("update userProperties for link share type fail", error: error)
                guard let self else { return }
                self.linkShareType = oldShareType
                self.context?.reload()
            })
            .disposed(by: disposeBag)
    }
}
