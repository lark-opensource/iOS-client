//
//  TemplateVC+NaviAndTab.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/4/23.
//

import AnimatedTabBar
import EENavigator
import Foundation
import LKCommonsLogging
import LarkUIKit
import RxRelay
import Swinject
import RxSwift
import LarkLocalizations
import LarkTab
import ByteWebImage
import UniverseDesignIcon
import LarkNavigation
import LarkBoxSetting

extension TemplateViewController: WPHomeChildVCProtocol {
    /// 更新门户信息
    func updateInitData(_ wrapper: WPHomeVCInitData) {
        inner_updateInitData(wrapper)
    }

    func onTabbarItemTap(_ isSameTab: Bool) {
        /// 点击Tab异步刷新数据
        if finishFirstDataRequest {
            Self.logger.info("user tap tab to refresh, start to dataProduce")
        }
    }

    /// 设置button
    func larkNaviBarV2(userDefinedButtonOf type: LarkNaviButtonTypeV2) -> UIButton? {
        let items = pageConfig.naviButtons
        switch type {
        case .first:
            return !items.isEmpty ? getIconButton(item: items[0]) : nil
        case .second:
            return items.count > 1 ? getIconButton(item: items[1]) : nil
        case .third:
            return items.count > 2 ? getIconButton(item: items[2]) : nil
        case .fourth:
            if items.count > 3 {
                return getIconButton(item: items[3])
            } else {
                return nil
            }
        @unknown default:
            return nil
        }
    }

    /// 导航栏的title
    var titleText: BehaviorRelay<String> {
        if pageConfig.showPageTitle {
            if isNaviBarLoading.value {
                // 加载中
                var str = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_Loading
                let removeSuffix = "..."
                if str.hasSuffix(removeSuffix) {
                    let index = str.index(str.endIndex, offsetBy: -removeSuffix.count)
                    str = String(str[..<index])
                }
                return BehaviorRelay(value: str)
            }
            let title = initData.name ?? BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_Title
            return BehaviorRelay(value: title)
        } else {
            return BehaviorRelay(value: "")
        }
    }

    /// 是否可以显示统一导航栏
    var isNaviBarEnabled: Bool {
        return isShowNaviBar
    }

    /// 是否在加载中
    var isNaviBarLoading: BehaviorRelay<Bool> {
        let value = (stateView.state == .loading)
        return BehaviorRelay(value: value)
    }
    
    var bizScene: LarkNaviBarBizScene? {
        // fg 控制是否显示小标题，bugfix 简单处理了。返回 nil 就不会显示小标题
        let isWorkflowOptimize = self.context.configService.fgValue(for: .workflowOptimize)
        return isWorkflowOptimize ? .workplace : nil
    }

    func topInsetDidChanged(height: CGFloat) {
        collectionViewTopConstraint?.update(offset: height)
    }

    /// 获取按钮
    private func getIconButton(item: HeaderNaviButton) -> UIButton? {
        if let innerIcon = InnerNaviIcon(rawValue: item.key) {
            switch innerIcon {
            case .appDirectory:
                // Ref doc: https://bytedance.feishu.cn/docx/N6iXdePmpo2X5dxmgVGcxIMbnQe?chatTab=1&useIframe=1&multiPage=1
                if BoxSetting.isBoxOff() { return nil }
                if let url = item.schema {
                    return getNativeNaviButton(
                        image: UDIcon.findAppOutlined,
                        handler: { [weak self] in self?.enterAppStore(url: url) }
                    )
                } else {
                    return nil
                }
            case .setting:
                return nil  //  字节模板化改造，不需要展示排期页面，直接在首页拖动排序了
            case .search:
               return getNativeNaviButton(
                    image: UDIcon.searchOutlineOutlined,
                    handler: { [weak self] in self?.enterSearch() }
               )
            }
        } else {
            if let iconUrl = item.iconUrl, let schema = item.schema {
                return getCostomNaviButton(iconUrl: iconUrl, schema: schema)
            } else {
                Self.logger.error("costom icon item miss iconUrl or schema, not display")
                return nil
            }
        }
    }

    /// 获取naviBar的原生button
    private func getNativeNaviButton(image: UIImage, handler: @escaping () -> Void) -> UIButton {
        let button = UIButton()
        let tintColor = (LarkNaviBar.viContentColor != nil) ? LarkNaviBar.buttonTintColor : UIColor.ud.iconN1
        button.setImage(image.ud.withTintColor(tintColor), for: .normal)
        button.rx.tap
            .subscribe(onNext: { _ in handler() })
            .disposed(by: disposeBag)
        return button
    }

    /// 获取naviBar 的自定义button
    private func getCostomNaviButton(iconUrl: String, schema: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.rx.tap.subscribe(onNext: { [weak self] in self?.enterCustomIcon(link: schema) }).disposed(by: disposeBag)
        // button.bt.setImage(with: URL(string: iconUrl), for: .normal)
        let tintColor = (LarkNaviBar.viContentColor != nil) ? LarkNaviBar.buttonTintColor : UIColor.ud.iconN1
        let iconView = WPMaskImageView()
        iconView.bt.setLarkImage(
            with: .avatar(key: iconUrl, entityID: "", params: .init(sizeType: .size(24))),
            completion: { result in
                var image: UIImage?
                if let img = try? result.get().image {
                    image = img.ud.withTintColor(tintColor)
                    iconView.image = image
                } else {
                    Self.logger.error("header icon image download failed")
                }
            }
        )
        button.addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return button
    }
}

/// 默认导航栏按钮类型
enum InnerNaviIcon: String {
    /// 应用目录
    case appDirectory = "AppDirectory"
    /// 设置
    case setting = "Setting"
    /// 搜索
    case search = "Search"

    /// 是否是内置型按钮
    static func isInnerIcon(key: String) -> Bool {
        return (key == Self.appDirectory.rawValue || key == Self.setting.rawValue || key == Self.search.rawValue)
    }
}

// MARK: navi点击事件
extension TemplateViewController {

    /// 进入自定义icon的link
    func enterCustomIcon(link: String) {
        Self.logger.info("enter custom icon", additionalData: ["link": link])
        openTriLink(url: link)

        context.tracker
            .start(.openplatform_workspace_main_page_click)
            .setClickValue(.self_defined)
            .setTargetView(.none)
            .setExposeUIType(.header)
            .setSubType(.native)
            .setValue(initData.id, for: .template_id)
            .post()
    }

    /// 进入大搜
    func enterSearch() {
        Self.logger.info("user tap search, entry to globalSearch")
        dependency.navigator.toMainSearch(from: self)

        context.tracker
            .start(.openplatform_workspace_main_page_click)
            .setClickValue(.search)
            .setTargetView(.none)
            .setExposeUIType(.header)
            .setSubType(.native)
            .setValue(initData.id, for: .template_id)
            .post()
    }

    /// 进入应用目录
    func enterAppStore(url: String) {
        Self.logger.info("user tap appStore", additionalData: ["url": url])
        context.tracker
            .start(.openplatform_ecosystem_workspace_mainpage_click)
            .setClickValue(.openplatform_application_get)
            .setTargetView(.openplatform_ecosystem_application_menu_view)
            .post()
        context.tracker
            .start(.openplatform_workspace_main_page_click)
            .setClickValue(.appdirectory)
            .setTargetView(.openplatform_ecosystem_application_menu_view)
            .setExposeUIType(.header)
            .setSubType(.native)
            .setValue(initData.id, for: .template_id)
            .post()
        openService.openAppLink(url, from: self)
    }
}
