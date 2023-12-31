//
//  LargeTodoWidgetView.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/5/9.
//

import UIKit
import Foundation
import SwiftUI
import WidgetKit
import LarkLocalizations
import LarkTimeFormatUtils

@available(iOS 14.0, *)
public struct LargeTodoWidgetView: View {

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
                //
                TodoHeaderView(model: model)
                    .frame(height: headerHeight)

                Spacer()
                    .frame(height: headerSpacing)

                VStack(spacing: getLineSpacing(withContentHeight: metric.size.height)) {
                    if todos.isEmpty {
                        Image("todo_empty_image")
                            .resizable()
                            .frame(width: 100, height: 100)
                        Text(BundleI18n.LarkWidget.Lark_TasksWidget_TaskCenter_NoTasks)
                            .udFont(12, lineHeight: 18)
                            .multilineTextAlignment(.center)
                            .foregroundColor(UDColor.textCaption)
                            .padding(.bottom, 20)
                    } else {
                        ForEach(0..<getNumberOfItemsToDisplay(withContentHeight: metric.size.height), id: \.self) { index in
                            LargeTodoItemView(todo: todos[index], is24Hour: model.is24Hour)
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

    private var preferredNumberOfItems: Int {
        return 5
    }

    private var headerHeight: CGFloat {
        return 50
    }

    private var headerSpacing: CGFloat {
        return 3
    }

    private var bottomMargin: CGFloat {
        return 10
    }

    /// 计算 todo item 间距（满尺寸 todo 最多放 5 个）
    /// - Parameter height: 组件的高度（根据设备尺寸有所不同）
    private func getLineSpacing(withContentHeight height: CGFloat) -> CGFloat {
        // 40 是带有截止日期的 todo item 高度
        return round((height - headerHeight - headerSpacing - bottomMargin) / CGFloat(preferredNumberOfItems) - 40 - 2)
    }

    /// 计算大号组件实际能够摆放的 todo 数量
    /// - Parameter height: 组件的高度（根据设备尺寸有所不同）
    private func getNumberOfItemsToDisplay(withContentHeight height: CGFloat) -> Int {
        let itemSpacing = getLineSpacing(withContentHeight: height)
        var count: Int = 0
        var remainingHeight: CGFloat = height - headerHeight - headerSpacing - bottomMargin + itemSpacing
        for todo in todos {
            if todo.dueDate != nil {
                remainingHeight -= (40 + itemSpacing)
            } else {
                remainingHeight -= (20 + itemSpacing)
            }
            if remainingHeight >= 0 {
                count += 1
            } else {
                break
            }
        }
        return min(todos.count, count)
    }
}

@available(iOS 14.0, *)
struct LargeTodoItemView: View {

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
            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .foregroundColor(UDColor.textTitle)
                    .udFont(14, lineHeight: 20)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: 21, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let dueDate = todo.dueDate {
                    Text(TodoTexts.textLongFormattedDueTime(todo, is24Hour: is24Hour))
                        .udFont(12, lineHeight: 18)
                        .lineLimit(1)
                        .foregroundColor(timeColor)
                        .frame(maxWidth: .infinity, maxHeight: 19, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
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
        // 全天任务的 dueDate 会设定为早上 8 点，所以判断顺序和其他任务不同
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
            "size": "l",
            "target": "todo_task_detail_view"
        ])
    }
}

@available(iOS 14.0, *)
struct LargeTodoWidgetView_Previews: PreviewProvider {
    static var previews: some View {

        LargeTodoWidgetView(model: .emptyData)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
