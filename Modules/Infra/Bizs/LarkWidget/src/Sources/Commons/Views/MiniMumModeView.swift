//
//  MiniMumModeView.swift
//  Lark
//
//  Created by ZhangHongyun on 2021/5/11.
//

import Foundation
import SwiftUI
import WidgetKit

@available(iOS 14.0, *)
public struct MiniMumModeView: View {

    @Environment(\.widgetFamily) var family

    public init() {}

    public var body: some View {
        switch family {
        case .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge:
            VStack {
                Spacer()
                HStack(alignment: .center) {
                    Spacer()
                    AppIconView()
                    Text(BundleI18n.LarkWidget.Lark_ASL_SmartWidgetNoOtherEvents)
                        .font(.system(size: 14))
                        .foregroundColor(WidgetColor.secondaryText)
                    Spacer()
                }
                Spacer()
            }
            .widgetBackground(WidgetColor.background)
            .widgetURL(nil)
        case .accessoryRectangular:
            HStack(alignment: .center) {
                AppIconView()
                Text(BundleI18n.LarkWidget.Lark_ASL_SmartWidgetNoOtherEvents)
            }
        case .accessoryCircular:
            ZStack {
                if #available(iOSApplicationExtension 16.0, *) {
                    AccessoryWidgetBackground()
                }
                AppIconView()
            }
        case .accessoryInline:
            Text(BundleI18n.LarkWidget.Lark_ASL_SmartWidgetNoOtherEvents)
        }
    }
}
