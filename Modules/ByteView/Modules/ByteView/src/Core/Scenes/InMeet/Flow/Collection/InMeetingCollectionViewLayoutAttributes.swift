//
//  InMeetingCollectionViewLayoutAttributes.swift
//  ByteView
//
//  Created by Prontera on 2020/11/4.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewRtcBridge

class InMeetingCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
    enum Style {
        case fill
        case half
        case quarter
        case singleRow

        // 新样式
        case fillSquare
        case newHalf
        case third
        case sixth
        case singleRowSquare
    }
    var style: Style = .fill
    var viewCount = 1

    var styleConfig: ParticipantViewStyleConfig = .squareGrid
    var multiResSubscribeConfig: MultiResSubscribeConfig = .invalidDefault

    override init() {
        super.init()
        self.frame = CGRect(x: -10000, y: -10000, width: 1, height: 1)
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let attri = object as? InMeetingCollectionViewLayoutAttributes else {
            return false
        }
        if self === attri {
            return true
        }
        return self.style == attri.style &&
                self.viewCount == attri.viewCount &&
                self.styleConfig == attri.styleConfig &&
                self.multiResSubscribeConfig == attri.multiResSubscribeConfig &&
                super.isEqual(attri)
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone)
        guard let copy = copy as? InMeetingCollectionViewLayoutAttributes else { return copy }
        copy.style = self.style
        copy.viewCount = self.viewCount
        copy.styleConfig = self.styleConfig
        copy.multiResSubscribeConfig = self.multiResSubscribeConfig
        return copy
    }
}
