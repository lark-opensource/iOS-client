//
//  SmallTodoWidgetView.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/5/9.
//

import UIKit
import Foundation
import SwiftUI
import WidgetKit

@available(iOS 14.0, *)
public struct SmallTodoWidgetView: View {

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
                            .frame(width: 40, height: 40)
                        Text(BundleI18n.LarkWidget.Lark_TasksWidget_TaskCenter_NoTasks_Short)
                            .udFont(12, lineHeight: 18)
                            .multilineTextAlignment(.center)
                            .foregroundColor(UDColor.textCaption)
                            .padding(.bottom, 20)
                    } else {
                        ForEach(0..<min(todos.count, 4), id: \.self) { index in
                            SmallTodoItemView(todo: todos[index],
                                              preferredMultiLines: todos.count <= 2)
                        }
                        Spacer()
                    }
                }
                .frame(height: metric.size.height - headerHeight - headerSpacing)
                .padding(.horizontal)
            }
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
struct SmallTodoItemView: View {

    var todo: TodoItem

    var preferredMultiLines: Bool

    var body: some View {
        contentView
    }

    private var contentView: some View {
        Label {
            Text(todo.title)
                .udFont(14, lineHeight: 20)
                .lineLimit(preferredMultiLines ? 2 : 1)
                .foregroundColor(UDColor.textTitle)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        } icon: {
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    todo.hasPermission ? .clear : WidgetColor.UD.N200,
                    strokeBorder: WidgetColor.UD.N400,
                    lineWidth: 1)
                .frame(width: 10, height: 10)
        }
    }
}

@available(iOS 14.0, *)
struct SmallTodoWidgetView_Previews: PreviewProvider {
    static var previews: some View {

        SmallTodoWidgetView(model: .emptyData)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
