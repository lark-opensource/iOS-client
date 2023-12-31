//
//  IntentHandler+DocsWidget.swift
//  IntentsExtension
//
//  Created by Hayden Wang on 2022/8/17.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Intents
import LarkHTTP
import LarkWidget
import LarkExtensionServices

extension IntentHandler: SmallDocsConfigurationIntentHandling {
    func provideSelectedDocItemOptionsCollection(for intent: SmallDocsConfigurationIntent, with completion: @escaping (INObjectCollection<INDocItem>?, Error?) -> Void) {
        DocsWidgetNetworking.requestDocsList(ofType: .recent, nums: 50) { docItems, error in
            if let docItems = docItems {
                let items = docItems.map({ $0.toINDocItem() })
                completion(INObjectCollection(items: items), nil)
            } else if let error = error {
                completion(nil, error)
            } else {
                completion(nil, nil)
            }
        }
    }
}

extension DocItem {

    func toINDocItem() -> INDocItem {
        let inDoc = INDocItem(identifier: token, display: displayName)
        inDoc.token = token
        inDoc.title = title
        inDoc.type = NSNumber(value: type)
        inDoc.url = url
        if let subType = extra?.wikiSubtype {
            inDoc.subType = NSNumber(value: subType)
        }
        if #available(iOS 15, *) {
            inDoc.displayImage = INImage(named: typeIconName)
        } else if let imageData = UIImage(named: typeIconName)?.pngData() {
            inDoc.displayImage = INImage(imageData: imageData)
        }
        inDoc.subtitleString = lastOpenTimeDesc
        return inDoc
    }
}
