//
//  HeaderTagWrapper.swift
//  TangramUIComponent
//
//  Created by 袁平 on 2021/7/8.
//

import UIKit
import Foundation
import LarkTag

public final class HeaderTagWrapper: UIView {
    private let headerTag: TangramHeaderConfig.HeaderTag

    public static func sizeToFit(headerTag: TangramHeaderConfig.HeaderTag, size: CGSize) -> CGSize {
        if let tag = headerTag.tagType {
            return TagWrapperView.sizeToFit(tagType: tag, containerSize: size)
        } else if let tag = headerTag.tag {
            let tagInfo = TagInfo(text: tag, textColor: headerTag.textColor, backgroundColor: headerTag.backgroundColor)
            return TagListView.layout(size: size, tagInfos: [tagInfo], font: headerTag.font, numberOfLines: 0).0
        }
        return .zero
    }

    public init(headerTag: TangramHeaderConfig.HeaderTag, frame: CGRect) {
        self.headerTag = headerTag
        super.init(frame: frame)
        setupViews()
    }

    private func setupViews() {
        if let tag = headerTag.tagType {
            let tagWrapper = TagWrapperView()
            tagWrapper.setTags([tag])
            tagWrapper.frame.origin = .zero
            tagWrapper.layoutIfNeeded()
            addSubview(tagWrapper)
        } else if let text = headerTag.tag {
            let tagInfo = TagInfo(text: text, textColor: headerTag.textColor, backgroundColor: headerTag.backgroundColor)
            let tagLabel = TagListView.tagView(tagInfo: tagInfo, font: headerTag.font, fixSize: self.bounds.size)
            tagLabel.sizeToFit()
            addSubview(tagLabel)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
