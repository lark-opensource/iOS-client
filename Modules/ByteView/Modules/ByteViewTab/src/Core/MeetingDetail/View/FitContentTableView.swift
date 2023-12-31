//
//  FitContentTableView.swift
//  MeetingDetail
//
//  Created by chenyizhuo on 2021/1/18.
//

import UIKit
import ByteViewUI

class FitContentTableView: BaseTableView {
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize { contentSize }
}
