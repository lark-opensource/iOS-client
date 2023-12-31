//
//  SubtitleHistoryBehaviorCell.swift
//  ByteView
//
//  Created by kiri on 2020/6/11.
//

import UIKit

class SubtitleHistoryBehaviorCell: SubtitleHistoryCell {

    override var contentText: NSMutableAttributedString? {
        guard let vm = viewModel,
              let title = vm.behaviorDescText else {
            return nil
        }
        let text = NSMutableAttributedString(string: "(\(title))")
        text.setAttributes(normalTextAttributes,
                           range: NSRange(0 ..< text.length))
        return text
    }
}
