//
//  EmotionHeaderView.swift
//  LarkCore
//
//  Created by 李勇 on 2021/1/20.
//

import Foundation
import UIKit
import ByteWebImage

public struct EmotionHeaderModel {
    // 图标的key
    public let iconKey: String?
    // 标题的名字
    public let titleName: String
}

public final class EmotionHeaderView: UICollectionReusableView {
    private let icon = ByteImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        // self.backgroundColor = UIColor.orange

        self.addSubview(self.icon)
        self.addSubview(self.label)
        self.icon.backgroundColor = UIColor.clear
        self.icon.contentMode = .scaleToFill
        self.icon.isUserInteractionEnabled = false
        self.label.font = UIFont.systemFont(ofSize: 12)
        self.label.textColor = UIColor.ud.textCaption
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setData(model: EmotionHeaderModel, xOffset: CGFloat = 14) {
        var showIcon = false
        // 设置icon图标（可能会没有）
        if let iconKey = model.iconKey, !iconKey.isEmpty {
            showIcon = true
            self.icon.bt.setLarkImage(with: .default(key: iconKey), completion: { result in
                if case .failure(let error) = result {
                    print("icon加载失败：\(error)")
                }
            })
        }
        // 设置标题
        self.label.text = model.titleName
        var x: CGFloat = 0
        var y: CGFloat = 0
        let iconWidth: CGFloat = 18
        let iconHeight: CGFloat = 18
        if showIcon {
            self.icon.isHidden = false
            x = xOffset
            y = self.bounds.height - iconHeight
            self.icon.frame = CGRect(x: x, y: y, width: iconWidth, height: iconHeight)
            x += (iconWidth + 6)
            let labelWidth = self.bounds.width - 2 * xOffset - iconWidth - 6
            self.label.frame = CGRect(x: x, y: y, width: labelWidth, height: iconHeight)
        } else {
            self.icon.isHidden = true
            x = xOffset
            y = self.bounds.height - iconHeight
            let labelWidth = self.bounds.width - 2 * xOffset
            self.label.frame = CGRect(x: x, y: y, width: labelWidth, height: iconHeight)
        }
    }
}
