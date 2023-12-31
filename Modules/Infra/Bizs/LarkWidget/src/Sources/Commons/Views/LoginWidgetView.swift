//
//  LoginWidgetView.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/3/8.
//

import Foundation
import SwiftUI
import WidgetKit

@available(iOS 14.0, *)
public struct LoginWidgetView: View {

    @Environment(\.widgetFamily) var family

    public init() {}

    public var body: some View {
        switch family {
        case .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge:
            ZStack {
                // 背景
                VStack {
                    if family == .systemSmall {
                        Image("login_bg_image_small")
                            .resizable()
                            .aspectRatio(1.43, contentMode: .fit)
                    } else {
                        Image("login_bg_image_medium")
                            .resizable()
                            .aspectRatio(2.5, contentMode: .fit)
                    }
                    Spacer(minLength: 0)
                }
                .widgetBackground(LinearGradient(
                    colors: [Color("loginBgTop"), Color("loginBgBottom")],
                    startPoint: UnitPoint(x: 0, y: 0),
                    endPoint: UnitPoint(x: 0, y: 1))
                )

                // Logo
                VStack {
                    HStack {
                        Spacer()
                        AppIconView()
                    }
                    Spacer()
                }
                .padding(.all, 12)

                // 登录界面
                VStack(alignment: .center) {
                    Text(BundleI18n.LarkWidget.Lark_Core_LogInDesc)
                        .font(.system(size: 12))
                        .foregroundColor(WidgetColor.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 8)
            }
        case .accessoryRectangular:
            Text(BundleI18n.LarkWidget.Lark_Core_LogInDesc)
        case .accessoryCircular:
            ZStack {
                if #available(iOSApplicationExtension 16.0, *) {
                    AccessoryWidgetBackground()
                }
                AppIconView()
            }
        case .accessoryInline:
            Text(BundleI18n.LarkWidget.Lark_Core_LogInDesc)
        }
    }
}

@available(iOS 14.0, *)
struct SmallLoginWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        LoginWidgetView()
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

@available(iOS 14.0, *)
struct MediumLoginWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        LoginWidgetView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
