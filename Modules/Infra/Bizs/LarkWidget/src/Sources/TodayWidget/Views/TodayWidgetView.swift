//
//  TodayWidgetView.swift
//  Lark
//
//  Created by ZhangHongyun on 2020/11/22.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import SwiftUI
import WidgetKit

@available(iOS 14.0, *)
public struct TodayWidgetView: View {

    var timelineEntry: TodayWidgetModel

    public init(_ entry: TodayWidgetModel) {
        self.timelineEntry = entry
    }

    public var body: some View {
        GeometryReader { metrics in
            VStack(alignment: .leading, spacing: 0) {
                if let url = URL(string: timelineEntry.event.appLink) {
                    Link(destination: url) {
                        scheduleCard
                            .frame(height: metrics.size.height * 0.55)
                            .widgetBackground(WidgetColor.background)
                    }
                } else {
                    scheduleCard
                        .frame(height: metrics.size.height * 0.55)
                        .widgetBackground(WidgetColor.background)
                }
                actionList
                    .frame(height: metrics.size.height * 0.45)
            }
        }
    }

    /// 日程卡片
    var scheduleCard: some View {
        if timelineEntry.hasEvent {
            return AnyView(HStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 2)
                    .frame(width: 4)
                    .padding([.top, .bottom], timelineEntry.event.description.isEmpty ? 27 : 20)
                    .padding(.leading, 16)
                    .foregroundColor(Color.yellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text(timelineEntry.event.name)
                        .font(.system(size: 14))
                        .foregroundColor(WidgetColor.text)
                        .bold()
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)

                    Text(timelineEntry.event.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(WidgetColor.text)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    if !timelineEntry.event.description.isEmpty {
                        Text(timelineEntry.event.description)
                            .font(.system(size: 12))
                            .multilineTextAlignment(.leading)
                            .foregroundColor(WidgetColor.secondaryText)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 16)
            }
                .padding(.trailing, 0))
        } else {
            return AnyView(HStack(alignment: .center) {
                Spacer()
                AppIconView()
                Text(BundleI18n.LarkWidget.Lark_ASL_SmartWidgetNoOtherEvents)
                    .font(.system(size: 14))
                    .foregroundColor(WidgetColor.secondaryText)
                Spacer()
            })
        }
    }

    /// Action List
    var actionList: some View {
        var actions: [TodayWidgetAction] = timelineEntry.actions

        if actions.count > 3 {
            actions = Array(actions[0...3])
        } else if actions.count < 3 {
            actions = TodayWidgetAction.defaultActions
        }
        return VStack {
            Spacer(minLength: 15)
            HStack(alignment: .center) {
                Spacer()
                    .frame(width: 30)
                ForEach(actions.indices) { index in
                    let action = actions[index]
                    Link(destination: URL(string: action.appLink)!) {
                        VStack(alignment: .center) {
                            Image(action.iconUrl)
                            Text(action.name)
                                .font(.system(size: 12))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .frame(height: 14, alignment: .center)
                        }
                        .padding(.bottom, 16)
                        .frame(width: 66, height: 62)
                    }
                    if index != actions.count - 1 {
                        Spacer()
                    }
                }
                Spacer()
                    .frame(width: 30)
            }
        }
        .background(WidgetColor.secondaryBackground)
    }
}

@available(iOS 14.0, *)
struct TodayWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TodayWidgetView(.noEventModel)
                .previewLayout(.fixed(width: 320, height: 160))
                .environment(\.colorScheme, .light)
            TodayWidgetView(.noEventModel)
                .previewLayout(.fixed(width: 320, height: 160))
                .environment(\.colorScheme, .dark)
        }
    }
}
