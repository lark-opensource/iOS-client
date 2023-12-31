//
//  SmallDocsWidgetView.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/8/11.
//

import UIKit
import Foundation
import SwiftUI
import WidgetKit

@available(iOS 14.0, *)
public struct SmallDocsWidgetView: View {

    var selectedDoc: DocItem?
    var coverImage: UIImage?

    public init(item: DocItem?, image: UIImage? = nil) {
        self.selectedDoc = item
        self.coverImage = image
    }

    public var body: some View {
        Group {
            if let selectedDoc = selectedDoc {
                if selectedDoc.cover != nil, let image = coverImage {
                    docWithCover(selectedDoc, cover: image)
                } else {
                    docWithoutCover(selectedDoc)
                }
            } else {
                emptyView
            }
        }
        .widgetBackground(WidgetColor.background)
        .widgetURL(smallWidgetURL)
    }

    var emptyView: some View {
        VStack(spacing: 8) {
            Spacer()
            HStack {
                Spacer()
                Image("add_doc_icon")
                    .resizable()
                    .frame(width: 28, height: 28)
                Spacer()
            }
            Text(BundleI18n.LarkWidget.Lark_DocsWidget_TapAndHoldAddDocs_Button)
                .font(Font.system(size: 12))
                .foregroundColor(WidgetColor.secondaryText)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    func docWithCover(_ doc: DocItem, cover: UIImage) -> some View {
        GeometryReader { metric in
            VStack {
                Image(uiImage: cover)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .foregroundColor(doc.docType.themeColor)
                    .frame(width: metric.size.width, height: round(metric.size.height * 0.5))
                    .clipped()
                Text(doc.displayName)
                    .udFont(16, weight: .medium, lineHeight: 18)
                    .multilineTextAlignment(.leading)
                    .frame(width: metric.size.width - 32, alignment: .leading)
                Spacer()
            }
        }
    }

    func docWithoutCover(_ doc: DocItem) -> some View {
        GeometryReader { metric in
            ZStack {
                VStack {
                    Rectangle()
                        .frame(height: metric.size.height / 3)
                        .foregroundColor(doc.docType.themeColor)
                    Spacer()
                }
                VStack {
                    Spacer()
                        .frame(height: metric.size.height / 3 - 15)
                    HStack {
                        Image(doc.docType.iconNameFilled)
                            .resizable()
                            .frame(width: 24, height: 24)
                        Spacer()
                    }
                    Text(doc.displayName)
                        .udFont(16, weight: .medium, lineHeight: 18)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(WidgetColor.text)
                        .frame(width: metric.size.width - 32, alignment: .leading)
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
    }

    var smallWidgetURL: URL? {
        if let selectedDoc = selectedDoc, let docLink = selectedDoc.appLink {
            return WidgetTrackingTool.createURL(docLink, trackParams: [
                "click": "doc_click",
                "size": "s",
                "target": "ccm_docs_page_view"
            ])
        } else {
            return URL(string: WidgetLink.docsTab)
        }
    }
}

@available(iOS 14.0, *)
struct SmallDocsWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        SmallDocsWidgetView(item: nil)
    }
}
