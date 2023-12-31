//
//  MediumTodoWidgetView.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/5/9.
//

import UIKit
import Foundation
import SwiftUI
import WidgetKit
import LarkTimeFormatUtils

@available(iOS 14.0, *)
public struct MediumTodoWidgetView: View {

    var model: TodoWidgetModel

    var todos: [TodoItem] {
        model.items
    }

    public init(model: TodoWidgetModel) {
        self.model = model
    }

    public var body: some View {
        GeometryReader { metric in
            VStack {
                TodoHeaderView(model: model)
                    .frame(height: headerHeight)

                Spacer()
                    .frame(height: headerSpacing)

                VStack(spacing: getLineSpacing(withContentHeight: metric.size.height)) {
                    if todos.isEmpty {
                        Image("todo_empty_image")
                            .resizable()
                            .frame(width: 50, height: 50)
                        Text(BundleI18n.LarkWidget.Lark_TasksWidget_TaskCenter_NoTasks)
                            .udFont(12, lineHeight: 18)
                            .multilineTextAlignment(.center)
                            .foregroundColor(UDColor.textCaption)
                            .padding(.bottom, 10)
                    } else {
                        ForEach(0..<min(todos.count, 4), id: \.self) { index in
                            MediumTodoItemView(todo: todos[index], is24Hour: model.is24Hour)
                        }
                        Spacer()
                    }
                }
                .frame(height: metric.size.height - headerHeight - headerSpacing)
                .padding(.horizontal)
            }
            .widgetBackground(WidgetColor.background)
        }
    }

    private var maxNumberOfItems: Int {
        return 4
    }

    private var headerHeight: CGFloat {
        return 40
    }

    private var headerSpacing: CGFloat {
        return 3
    }

    private func getLineSpacing(withContentHeight height: CGFloat) -> CGFloat {
        return (height - headerHeight - headerSpacing) / CGFloat(maxNumberOfItems) - 20
    }
}

@available(iOS 14.0, *)
struct MediumTodoItemView: View {

    var todo: TodoItem

    var is24Hour: Bool

    var body: some View {
        if let url = todoDetailURL {
            Link(destination: url) {
                contentView
            }
        } else {
            contentView
        }
    }

    private var contentView: some View {
        Label {
            Text(todo.title)
                .foregroundColor(UDColor.textTitle)
                .font(.system(size: 14))
                .lineLimit(1)
                .frame(height: 20)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(0.8)
            Spacer()
                .layoutPriority(0.5)
            if let dueDate = todo.dueDate {
                Text(TodoTexts.textShortFormattedDueTime(todo))
                    .udFont(12)
                    .lineLimit(1)
                    .foregroundColor(timeColor)
                    .fixedSize(horizontal: true, vertical: true)
                    .minimumScaleFactor(0.8)
                    .layoutPriority(1.0)
            }
        } icon: {
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    todo.hasPermission ? .clear : WidgetColor.UD.N200,
                    strokeBorder: WidgetColor.UD.N400,
                    lineWidth: 1)
                .frame(width: 10, height: 10)
        }
    }

    private var timeColor: Color {
        guard let dueDate = todo.dueDate else {
            return UDColor.textTitle
        }
        if todo.isAllDay {
            if dueDate.isToday {
                return UDColor.B600
            } else if dueDate.isInPast {
                return UDColor.R600
            } else {
                return UDColor.textPlaceholder
            }
        } else {
            if dueDate.isInPast {
                return UDColor.R600
            } else if dueDate.isToday {
                return UDColor.B600
            } else {
                return UDColor.textPlaceholder
            }
        }
    }

    var todoDetailURL: URL? {
        return WidgetTrackingTool.createURL(todo.appLink, trackParams: [
            "click": "task_click",
            "size": "m",
            "target": "todo_task_detail_view"
        ])
    }
}

@available(iOS 14.0, *)
struct MediumTodoWidgetView_Previews: PreviewProvider {
    static var previews: some View {

        MediumTodoWidgetView(model: .emptyData)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
