//
//  TodoWidgetContentView.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/5/9.
//

import Foundation
import SwiftUI
import WidgetKit

@available(iOS 14.0, *)
public struct TodoWidgetContentView: View {

    var model: TodoWidgetModel

    @Environment(\.widgetFamily) var family

    public init(model: TodoWidgetModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallTodoWidgetView(model: model)
            case .systemMedium:
                MediumTodoWidgetView(model: model)
            case .systemLarge:
                LargeTodoWidgetView(model: model)
            default:
                LargeTodoWidgetView(model: model)
            }
        }
        .widgetBackground(WidgetColor.background)
        .widgetURL(todoTabURL)
    }

    var todoTabURL: URL? {
        return WidgetTrackingTool.createURL(model.todoTabLink, trackParams: [
            "click": "task_empty_area",
            "size": family.trackName,
            "target": "todo_center_task_list_view"
        ])
    }
}
