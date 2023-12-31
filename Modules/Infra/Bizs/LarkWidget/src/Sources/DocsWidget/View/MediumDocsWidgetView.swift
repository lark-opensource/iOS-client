//
//  MediumDocsWidgetView.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/8/11.
//

import UIKit
import Foundation
import SwiftUI
import WidgetKit

@available(iOS 14.0, *)
public struct MediumDocsWidgetView: View {

    var model: MediumDocsWidgetModel

    var docItems: [DocItem] {
        return model.docItems
    }

    public init(model: MediumDocsWidgetModel) {
        self.model = model
    }

    public var body: some View {
        GeometryReader { metric in
            VStack {
                MediumDocsHeaderView(headerText: model.listType.name)
                    .frame(height: headerHeight)

                Spacer()
                    .frame(height: headerSpacing)

                if docItems.isEmpty {
                    VStack(spacing: 6) {
                        Image("docs_empty_image")
                            .resizable()
                            .frame(width: 68, height: 68)
                        Text(BundleI18n.LarkWidget.Lark_DocsWidget_NoDocs_EmptyState)
                            .font(.system(size: 12))
                            .foregroundColor(UDColor.textCaption)
                            .padding(.bottom, 10)
                    }
                } else {
                    VStack(spacing: getLineSpacing(withContentHeight: metric.size.height)) {
                        ForEach(0..<min(docItems.count, maxNumberOfItems), id: \.self) { index in
                            MediumDocItemView(doc: docItems[index])
                        }
                        Spacer()
                    }
                    .frame(height: metric.size.height - headerHeight - headerSpacing)
                    .padding(.horizontal)
                }
            }
        }
        .widgetBackground(WidgetColor.background)
        .widgetURL(docsTabURL)
    }

    private var maxNumberOfItems: Int {
        return 3
    }

    private var headerHeight: CGFloat {
        return 40
    }

    private var headerSpacing: CGFloat {
        return 10
    }

    private func getLineSpacing(withContentHeight height: CGFloat) -> CGFloat {
        return (height - headerHeight - headerSpacing) / CGFloat(maxNumberOfItems) - 20
    }

    @Environment(\.widgetFamily) var family

    var docsTabURL: URL? {
        return URL(string: WidgetLink.docsTab)
        /* 这里暂时没有要求埋点
        return WidgetTrackingTool.createURL(AppLink.docsTab, trackParams: [
            "size": family.trackName
        ])
         */
    }
}

@available(iOS 14.0, *)
struct MediumDocsWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        MediumDocsWidgetView(model: .defaultData)
    }
}

// MARK: - Header View

@available(iOS 14.0, *)
struct MediumDocsHeaderView: View {

    var headerText: String

    var body: some View {
        HStack(spacing: 8) {
            // 飞书 logo
            AppIconView()
            // 标题
            Text(headerText)
                .font(.system(size: 15))
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
    }
}

// MARK: - Item View

@available(iOS 14.0, *)
struct MediumDocItemView: View {

    var doc: DocItem

    var body: some View {
        if let url = docDetailURL {
            Link(destination: url) {
                contentView
            }
        } else {
            contentView
        }
    }

    private var contentView: some View {
        Label {
            Text(doc.displayName)
                .foregroundColor(WidgetColor.text)
                .font(.system(size: 14))
                .lineLimit(1)
                .frame(height: 20)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        } icon: {
            Image(doc.docType.iconNameFilled)
                .resizable()
                .frame(width: 20, height: 20)
        }
    }

    var docDetailURL: URL? {
        guard let linkURL = doc.appLink else { return nil }
        return WidgetTrackingTool.createURL(linkURL, trackParams: [
            "click": "doc_click",
            "size": "m",
            "target": "ccm_docs_page_view"
        ])
    }
}
