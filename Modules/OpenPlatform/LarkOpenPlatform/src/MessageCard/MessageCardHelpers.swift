//
//  MessageCardHelpers.swift
//  LarkOpenPlatform
//
//  Created by zhangjie.alonso on 2022/10/13.
//

import Foundation
import RustPB
import LarkModel
import NewLarkDynamic
import LarkFeatureGating

extension  CardContent.CardHeader {

    public func getTitle() -> String? {
        if !LarkFeatureGating.shared.getFeatureBoolValue(for: FeatureGatingKey.messageCardHeaderUseNew) {
            return self.hasTitle ? self.title : nil
        }
        if self.hasMainTitle{
            return self.mainTitle
        }
        if self.hasTitle {
            return self.title
        }
        cardlog.info("get cardHeader title: nil")
        return nil
    }

    public func isEmptyTitle() -> Bool {

        if let title = self.getTitle() {
            return title.isEmpty
        }
        return true
}

}
