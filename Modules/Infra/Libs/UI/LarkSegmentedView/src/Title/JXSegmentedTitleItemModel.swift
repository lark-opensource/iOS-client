//
//  JXSegmentedTitleItemModel.swift
//  JXSegmentedView
//
//  Created by jiaxin on 2018/12/26.
//  Copyright © 2018 jiaxin. All rights reserved.
//

import Foundation
import UIKit

open class JXSegmentedTitleItemModel: JXSegmentedBaseItemModel {
    public var title: String?
    public var titleNumberOfLines: Int = 0
    public var titleNormalColor: UIColor = .black
    public var titleCurrentColor: UIColor = .black
    public var titleSelectedColor: UIColor = .red
    public var titleNormalFont: UIFont = UIFont.systemFont(ofSize: 15)
    public var titleSelectedFont: UIFont = UIFont.systemFont(ofSize: 15)
    public var isTitleZoomEnabled: Bool = false
    public var titleNormalZoomScale: CGFloat = 0
    public var titleCurrentZoomScale: CGFloat = 0
    public var titleSelectedZoomScale: CGFloat = 0
    public var isTitleStrokeWidthEnabled: Bool = false
    public var titleNormalStrokeWidth: CGFloat = 0
    public var titleCurrentStrokeWidth: CGFloat = 0
    public var titleSelectedStrokeWidth: CGFloat = 0
    public var isTitleMaskEnabled: Bool = false
    public var textWidth: CGFloat = 0
}
