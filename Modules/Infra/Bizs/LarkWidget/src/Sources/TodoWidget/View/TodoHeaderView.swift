//
//  TodoHeaderView.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/5/9.
//

import UIKit
import Foundation
import SwiftUI
import WidgetKit

@available(iOS 14.0, *)
struct TodoHeaderView: View {

    var model: TodoWidgetModel

    var todos: [TodoItem] {
        model.items
    }

    @Environment(\.widgetFamily) var family

    var body: some View {
        HStack(spacing: 8) {
            // 飞书 logo
            AppIconView()
            HStack(spacing: 3) {
                // 标题
                Text(headerText)
                    .font(.system(size: 15))
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                // 任务数
                if model.totalCount > 0 {
                    Text("(\(model.totalCount))")
                        .font(.system(size: 13))
                        .fontWeight(.medium)
                        .foregroundColor(Color(UIColor.systemBlue.withAlphaComponent(0.7)))
                }
            }
            .lineLimit(1)

            Spacer(minLength: 0)

            if family != .systemSmall, let url = createTodoURL {
                Link(destination: url) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 22, height: 22)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(family == .systemSmall ? .leading : .horizontal)
    }

    var headerText: String {
        switch family {
        case .systemSmall:
            return TodoTexts.textShortTitle
        default:
            return TodoTexts.textLongTitle
        }
    }

    var createTodoURL: URL? {
        return WidgetTrackingTool.createURL(model.todoNewLink, trackParams: [
            "click": "create_task",
            "size": family.trackName,
            "target": "todo_create_view"
        ])
    }
}
