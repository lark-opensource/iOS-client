//
//  StatusCheckHelper.swift
//  SmartWidgetExtension
//
//  Created by kongkaikai on 2022/11/11.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import SwiftUI
import WidgetKit
import LarkWidget

enum StatusCheckHelper {
    @inline(__always)
    @ViewBuilder private static func view(isMinimumMode: Bool, isLogin: Bool, @ViewBuilder mainView: () -> some View) -> some View {
        if isMinimumMode {
            MiniMumModeView()
        } else {
            if isLogin {
                mainView()
            } else {
                LoginWidgetView()
            }
        }
    }

    @inline(__always)
    static func view(with info: WidgetAuthInfo, @ViewBuilder mainView: () -> some View) -> some View {
        view(isMinimumMode: info.isMinimumMode, isLogin: info.isLogin, mainView: mainView)
    }

    @inline(__always)
    static func view(with model: TodayWidgetModel, @ViewBuilder mainView: () -> some View) -> some View {
        view(isMinimumMode: model.isMinimumMode, isLogin: model.isLogin, mainView: mainView)
    }
}

extension WidgetConfiguration {

    func contentMarginsDisabledIfAvailable() -> some WidgetConfiguration {
        #if compiler(>=5.9)
        // Xcode 15
        if #available(iOSApplicationExtension 17.0, *) {
            return self.contentMarginsDisabled()
        } else {
            return self
        }
        #else
        return self
        #endif
    }
}
