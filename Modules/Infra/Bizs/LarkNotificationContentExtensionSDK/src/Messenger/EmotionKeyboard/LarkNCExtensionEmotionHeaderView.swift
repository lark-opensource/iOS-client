//
//  LarkNCExtensionEmotionHeaderView.swift
//  LarkNotificationContentExtension
//
//  Created by yaoqihao on 2022/4/20.
//

import Foundation
import UIKit

public final class LarkNCExtensionEmotionHeaderView: UICollectionReusableView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        //self.backgroundColor = UIColor.orange

        self.addSubview(self.label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setData(title: String, xOffset: CGFloat = 14) {
        // 设置标题
        self.label.text = title
        self.label.font = UIFont.systemFont(ofSize: 12)
        self.label.textColor = UIColor(named: "emoji_section_color", in: BundleConfig.LarkNotificationContentExtensionSDKBundle, compatibleWith: nil)
        var x: CGFloat = 0;
        var y: CGFloat = 0;
        let iconHeight: CGFloat = 18
        x = xOffset
        y = self.bounds.height - iconHeight
        let labelWidth = self.bounds.width - 2 * xOffset
        self.label.frame = CGRect(x: x, y: y, width: labelWidth, height: iconHeight)
    }
}
