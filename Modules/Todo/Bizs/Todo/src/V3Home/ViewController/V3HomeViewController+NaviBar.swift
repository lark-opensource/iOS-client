//
//  V3HomeViewController+NaviBar.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/25.
//

import LarkUIKit
import EENavigator
import RxCocoa
import UniverseDesignIcon
import UniverseDesignActionPanel

// MARK: - NewHome Navi

extension V3HomeViewController: LarkNaviBarDataSource, LarkNaviBarAbility {

    var titleText: BehaviorRelay<String> { BehaviorRelay(value: I18N.Todo_Task_Tasks) }

    var isNaviBarEnabled: Bool { true }

    var isDrawerEnabled: Bool { true }

    // 是否禁用默认搜索按钮
    var isDefaultSearchButtonDisabled: Bool { !FeatureGating(resolver: userResolver).boolValue(for: .search) }

    func larkNaviBar(imageOfButtonOf type: LarkNaviButtonType) -> UIImage? {
        switch type {
        case .first:
            return UDIcon.settingOutlined.ud.withTintColor(UIColor.ud.iconN1)
        case .search:
            return nil
        default:
            return nil
        }
    }
}

extension V3HomeViewController: LarkNaviBarDelegate {

    func onButtonTapped(on button: UIButton, with type: LarkNaviButtonType) {
        switch type {
        case .first:
            showSettingVC(with: button)
        case .search:
            showSearchVC()
        default:
            V3Home.assertionFailure()
        }
    }

    private func showSearchVC() {
        V3Home.logger.info("show search vc")
        V3Home.Track.clickListSearch(with: context.store.state.container)
        routeDependency?.showMainSearchVC(from: self)
    }

    /// 设置页面
    private func showSettingVC(with button: UIButton) {
        let source = UDActionSheetSource(
            sourceView: button,
            sourceRect: CGRect(x: button.frame.width / 2, y: button.frame.height, width: 0, height: 0),
            arrowDirection: .unknown
        )
        let config = UDActionSheetUIConfig(popSource: source)
        let actionSheet = UDActionSheet(config: config)

        if FeatureGating(resolver: userResolver).boolValue(for: .helper) {
            actionSheet.addItem(
                UDActionSheetItem(
                    title: I18N.Todo_Common_HelpCenter,
                    titleColor: UIColor.ud.textTitle,
                    action: { [weak self] in
                        guard let self = self,
                              let urlStr = self.messengerDependency?.resourceAddrWithLanguage(key: Utils.ConfigKeys.helpCenter),
                              let url = URL(string: urlStr) else {
                            return
                        }
                        V3Home.Track.clickListHelp()
                        /// ipad 交互需要取消已选中的Cell
                        self.userResolver.navigator.showDetailOrPush(
                            url,
                            context: ["from": "todo"],
                            wrap: LkNavigationController.self,
                            from: self
                        )
                    }
                )
            )
        }

        actionSheet.addItem(
            UDActionSheetItem(
                title: I18N.Todo_Settings_Tooltip,
                titleColor: UIColor.ud.textTitle,
                action: { [weak self] in
                    guard let self = self else { return }
                    V3Home.Track.clickListSetting()
                    let vc = SettingViewController(resolver: self.userResolver)
                    self.userResolver.navigator.present(
                        vc,
                        wrap: LkNavigationController.self,
                        from: self,
                        prepare: { $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen }
                    )
                }
            )
        )

        actionSheet.setCancelItem(text: I18N.Todo_Common_Cancel)
        V3Home.Track.clickListMore()
        present(actionSheet, animated: true, completion: nil)
    }
}
