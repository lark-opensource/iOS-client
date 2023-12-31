//
//  MenuItemImageModel.swift
//  LarkUIKitDemo
//
//  Created by 刘洋 on 2021/1/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

/// 给LarkMenu的Item提供图片，可以提供多种场景下的图片
public final class MenuItemImageModel: NSObject, MenuItemImageModelProtocol {

    /// iPhone从下往上滑出的面板中正常状态下的图片
    private let normalForIPhonePanel: UIImage

    /// iPhone从下往上滑出的面板中按压状态下的图片
    private let pressForIPhonePanel: UIImage

    /// iPhone从下往上滑出的面板中禁用状态下的图片
    private let disableForIPhonePanel: UIImage

    /// iPad上Popover弹出的面板中正常状态下的图片
    private let normalForIPadPopover: UIImage

    /// iPad上Popover弹出的面板中按压状态下的图片
    private let pressForIPadPopover: UIImage

    /// iPad上Popover弹出的面板中鼠标悬浮状态下的图片
    private let hoverForIPadPopover: UIImage

    /// iPad上Popover弹出的面板中禁用状态下的图片
    private let disableForIPadPopover: UIImage

    /// iPhone上主导航菜单栏的面板中正常状态下的图片
    private let normalForIPhoneLark: UIImage

    /// iPhone上主导航菜单栏的面板中按压状态下的图片
    private let pressForIPhoneLark: UIImage

    /// iPhone上主导航菜单栏的面板中禁用状态下的图片
    private let disableForIPhoneLark: UIImage

    private let renderMode: UIImage.RenderingMode

    /// 根据每种状态初始化图片模型
    /// - Parameters:
    ///   - normalForIPhonePanel: iPhone从下往上滑出的面板中正常状态下的图片
    ///   - pressForIPhonePanel: iPhone从下往上滑出的面板中按压状态下的图片
    ///   - disableForIPhonePanel: iPhone从下往上滑出的面板中禁用状态下的图片
    ///   - normalForIPadPopover: iPad上Popover弹出的面板中正常状态下的图片
    ///   - pressForIPadPopover: iPad上Popover弹出的面板中按压状态下的图片
    ///   - hoverForIPadPopover: iPad上Popover弹出的面板中鼠标悬浮状态下的图片
    ///   - disableForIPadPopover: iPad上Popover弹出的面板中禁用状态下的图片
    ///   - normalForIPhoneLark: iPhone上主导航菜单栏的面板中正常状态下的图片
    ///   - pressForIPhoneLark: iPhone上主导航菜单栏的面板中按压状态下的图片
    ///   - disableForIPhoneLark: iPhone上主导航菜单栏的面板中禁用状态下的图片
    @objc
    public init(normalForIPhonePanel: UIImage,
         pressForIPhonePanel: UIImage,
         disableForIPhonePanel: UIImage,
         normalForIPadPopover: UIImage,
         pressForIPadPopover: UIImage,
         hoverForIPadPopover: UIImage,
         disableForIPadPopover: UIImage,
         normalForIPhoneLark: UIImage,
         pressForIPhoneLark: UIImage,
         disableForIPhoneLark: UIImage,
         renderMode: UIImage.RenderingMode) {
        self.normalForIPhonePanel = normalForIPhonePanel
        self.pressForIPhonePanel = pressForIPhonePanel
        self.disableForIPhonePanel = disableForIPhonePanel
        self.normalForIPadPopover = normalForIPadPopover
        self.pressForIPadPopover = pressForIPadPopover
        self.hoverForIPadPopover = hoverForIPadPopover
        self.disableForIPadPopover = disableForIPadPopover
        self.normalForIPhoneLark = normalForIPhoneLark
        self.pressForIPhoneLark = pressForIPhoneLark
        self.disableForIPhoneLark = disableForIPhoneLark
        self.renderMode = renderMode
        super.init()
    }

    /// 使用iPhone上主导航菜单栏的面板中正常状态下的图片初始化图片模型，渲染模式为alwaysTemplate
    /// - Parameter normalForIPhoneLark: iPhone上主导航菜单栏的面板中正常状态下的图片
    @objc
    public convenience init(normalForIPhoneLark: UIImage) {
        self.init(normalForIPhonePanel: normalForIPhoneLark,
                  pressForIPhonePanel: normalForIPhoneLark,
                  disableForIPhonePanel: normalForIPhoneLark,
                  normalForIPadPopover: normalForIPhoneLark,
                  pressForIPadPopover: normalForIPhoneLark,
                  hoverForIPadPopover: normalForIPhoneLark,
                  disableForIPadPopover: normalForIPhoneLark,
                  normalForIPhoneLark: normalForIPhoneLark,
                  pressForIPhoneLark: normalForIPhoneLark,
                  disableForIPhoneLark: normalForIPhoneLark,
                  renderMode: .alwaysTemplate)
    }

    /// 使用iPhone上主导航菜单栏的面板中正常状态下的图片初始化图片模型
    /// - Parameters:
    ///   - normalForIPhoneLark: iPhone上主导航菜单栏的面板中正常状态下的图片
    ///   - renderMode: 自定义图片的渲染模式
    @objc
    public convenience init(normalForIPhoneLark: UIImage, renderMode: UIImage.RenderingMode) {
        self.init(normalForIPhonePanel: normalForIPhoneLark,
                  pressForIPhonePanel: normalForIPhoneLark,
                  disableForIPhonePanel: normalForIPhoneLark,
                  normalForIPadPopover: normalForIPhoneLark,
                  pressForIPadPopover: normalForIPhoneLark,
                  hoverForIPadPopover: normalForIPhoneLark,
                  disableForIPadPopover: normalForIPhoneLark,
                  normalForIPhoneLark: normalForIPhoneLark,
                  pressForIPhoneLark: normalForIPhoneLark,
                  disableForIPhoneLark: normalForIPhoneLark,
                  renderMode: renderMode)
    }

    /// 使用iPhone从下往上滑出的面板中正常状态下的图片和iPhone上主导航菜单栏的面板中正常状态下的图片初始化图片模型，渲染模式为alwaysTemplate
    /// - Parameters:
    ///   - normalForIPhonePanel: iPhone从下往上滑出的面板中正常状态下的图片
    ///   - normalForIPadPopover: iPhone上主导航菜单栏的面板中正常状态下的图片
    @objc
    public convenience init(normalForIPhonePanel: UIImage, normalForIPadPopover: UIImage) {
        self.init(normalForIPhonePanel: normalForIPhonePanel,
                  pressForIPhonePanel: normalForIPhonePanel,
                  disableForIPhonePanel: normalForIPhonePanel,
                  normalForIPadPopover: normalForIPadPopover,
                  pressForIPadPopover: normalForIPadPopover,
                  hoverForIPadPopover: normalForIPadPopover,
                  disableForIPadPopover: normalForIPadPopover,
                  normalForIPhoneLark: normalForIPhonePanel,
                  pressForIPhoneLark: normalForIPadPopover,
                  disableForIPhoneLark: normalForIPhonePanel,
                  renderMode: .alwaysTemplate)
    }

    /// 使用iPhone从下往上滑出的面板中正常状态下的图片和iPhone上主导航菜单栏的面板中正常状态下的图片初始化图片模型
    /// - Parameters:
    ///   - normalForIPhonePanel: iPhone从下往上滑出的面板中正常状态下的图片
    ///   - normalForIPadPopover: iPhone上主导航菜单栏的面板中正常状态下的图片
    ///   - renderMode: 自定义图片的渲染模式
    @objc
    public convenience init(normalForIPhonePanel: UIImage, normalForIPadPopover: UIImage, renderMode: UIImage.RenderingMode) {
        self.init(normalForIPhonePanel: normalForIPhonePanel,
                  pressForIPhonePanel: normalForIPhonePanel,
                  disableForIPhonePanel: normalForIPhonePanel,
                  normalForIPadPopover: normalForIPadPopover,
                  pressForIPadPopover: normalForIPadPopover,
                  hoverForIPadPopover: normalForIPadPopover,
                  disableForIPadPopover: normalForIPadPopover,
                  normalForIPhoneLark: normalForIPhonePanel,
                  pressForIPhoneLark: normalForIPadPopover,
                  disableForIPhoneLark: normalForIPhonePanel,
                  renderMode: renderMode)
    }

    /// 使用iPhone从下往上滑出的面板中正常状态下的图片和iPhone上主导航菜单栏的面板中正常状态下的图片初始化图片模型
    /// - Parameters:
    ///   - normalForIPhonePanel: iPhone从下往上滑出的面板中正常状态下的图片
    ///   - normalForIPadPopover: iPhone上主导航菜单栏的面板中正常状态下的图片
    ///   - renderMode: 自定义图片的渲染模式
    @objc
    public convenience init(normalForIPhonePanel: UIImage, disableForIPhonePanel: UIImage, normalForIPadPopover: UIImage, renderMode: UIImage.RenderingMode) {
        self.init(normalForIPhonePanel: normalForIPhonePanel,
                  pressForIPhonePanel: normalForIPhonePanel,
                  disableForIPhonePanel: disableForIPhonePanel,
                  normalForIPadPopover: normalForIPadPopover,
                  pressForIPadPopover: normalForIPadPopover,
                  hoverForIPadPopover: normalForIPadPopover,
                  disableForIPadPopover: disableForIPhonePanel,
                  normalForIPhoneLark: normalForIPhonePanel,
                  pressForIPhoneLark: normalForIPadPopover,
                  disableForIPhoneLark: disableForIPhonePanel,
                  renderMode: renderMode)
    }

    public func image(for location: MenuPanelType, status: UIControl.State) -> UIImage {
        switch (location, status) {
        case (.iPhonePanel, .normal):
            return self.normalForIPhonePanel.withRenderingMode(self.renderMode)
        case (.iPhonePanel, .disabled):
            return self.disableForIPhonePanel.withRenderingMode(self.renderMode)
        case (.iPhonePanel, _):
            return self.normalForIPhonePanel.withRenderingMode(self.renderMode)
        case (.iPadPopover, .normal):
            return self.normalForIPadPopover.withRenderingMode(self.renderMode)
        case (.iPadPopover, .selected):
            return self.pressForIPadPopover.withRenderingMode(self.renderMode)
        case (.iPadPopover, .focused):
            return self.hoverForIPadPopover.withRenderingMode(self.renderMode)
        case (.iPadPopover, .disabled):
            return self.disableForIPadPopover.withRenderingMode(self.renderMode)
        case (.iPadPopover, _):
            return self.normalForIPadPopover.withRenderingMode(self.renderMode)
        case (.iPhoneLark, .normal):
            return self.normalForIPhoneLark.withRenderingMode(self.renderMode)
        case (.iPhoneLark, .disabled):
            return self.disableForIPhoneLark.withRenderingMode(self.renderMode)
        case (.iPhoneLark, _):
            return normalForIPhoneLark.withRenderingMode(self.renderMode)
        }
    }
}
