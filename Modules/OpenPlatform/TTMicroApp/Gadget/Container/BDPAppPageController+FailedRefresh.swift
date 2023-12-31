//
//  BDPAppPageController+FailedRefresh.swift
//  TTMicroApp
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import LarkUIKit
import UniverseDesignEmpty
import SnapKit
import OPFoundation
import UniverseDesignColor
import LarkFeatureGating

private var failedRetryViewStoreKey: Void? = nil

extension BDPAppPageController {

    @objc public class FailedRefreshWrapperView: UIView {
        var retryAction: (()->Void)

        /// 提示文字水平方向上距离左右两侧的距离
        private static let tipInfoHorizontalMargin: CGFloat = 20

        /// 提示文字的大小
        private static let tipInfoFontSize: CGFloat = 15


        init(tipInfo: String, retryAction: @escaping ()->Void) {
            self.retryAction = retryAction
            super.init(frame: .zero)
            self.backgroundColor = UDOCColor.bgBase
            // 创建EmptyView
            let emptyConfig = UDEmptyConfig(
                description: UDEmptyConfig.Description(
                    descriptionText: tipInfo,
                    font: .systemFont(ofSize: Self.tipInfoFontSize),
                    textAlignment: .left
                ),
                type: .loadingFailure,
                labelHandler: retryAction,
                primaryButtonConfig: (BDPI18n.retry, { [weak self] (_) in
                    guard let self = self else { return }
                    retryAction()
                })
            )
            
            let emptyView = UDEmpty(config: emptyConfig)
            // 添加到视图层级中去
            addSubview(emptyView)
            emptyView.snp.makeConstraints { maker in
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview().offset(-Self.tipInfoHorizontalMargin)
                maker.leading.equalToSuperview().offset(Self.tipInfoHorizontalMargin)
            }
            // 添加全局轻触(单击)手势
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(receiveTargetAction))
            addGestureRecognizer(tapGesture)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc func receiveTargetAction() {
            retryAction()
        }
    }

    /// AppPage重载过多次发生错误时出现的View
    /// show: 是否显示View，false代表将view从视图层级中一走，true代表将view添加到视图层级中
    /// tipText: 提示用户的文案
    @objc public func updateCrashOverloadView(show: Bool, tipText: String = "") {
        if show {
            // 创建FailedRefreshWrapperView
            let failedRefreshView = FailedRefreshWrapperView(tipInfo: tipText) { [weak self] in
                guard let self = self else {
                    return
                }

                self.updateCrashOverloadView(show: false)
                self.appPage?.reloadAndRefreshTerminateState()
            }
            // 添加到视图层级中去, 这里再一些情况下出现了 crash，做一下保护 http://t.wtturl.cn/eG6oW67/
            if let view = OPUnsafeObject(view), let failedRefreshView = OPUnsafeObject(failedRefreshView) {
                view.addSubview(failedRefreshView)
                failedRefreshView.snp.makeConstraints { maker in
                    maker.top.bottom.trailing.leading.equalToSuperview()
                }
            }
            /// 在failedRefreshView上显示小程序的toolBarView，方便用户在小程序加载失败时打开菜单或者直接退出小程序
            if let toolBarView = self.toolBarView as BDPToolBarView? {
                toolBarView.moreButton.tintColor = UIColor.ud.iconN1
                toolBarView.closeButton.tintColor = UIColor.ud.iconN1
            }
            self.failedRefreshViewIsOn = true

        } else {
            // 如果show为false，则去掉提示的View
            for emptyView in view.subviews where emptyView is FailedRefreshWrapperView {
                emptyView.removeFromSuperview()
            }
        }
    }
}
