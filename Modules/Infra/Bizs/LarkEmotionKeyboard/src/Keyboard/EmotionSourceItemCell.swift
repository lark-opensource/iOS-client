//
//  EmotionSourceItemCell.swift
//  LarkUIKit
//
//  Created by 李晨 on 2019/8/13.
//

import UIKit
import Foundation

open class EmotionSourceItemCell: UICollectionViewCell {
    public var sourceIcon: UIImageView = UIImageView()
    public var index: Int = -1

    var cellDidSelectedColor = UIColor.clear

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.layer.cornerRadius = 6
        self.contentView.layer.masksToBounds = true
        let sourceIcon = UIImageView()
        sourceIcon.contentMode = .scaleAspectFit
        sourceIcon.isUserInteractionEnabled = false
        self.contentView.addSubview(sourceIcon)
        sourceIcon.snp.makeConstraints({ make in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        })
        self.sourceIcon = sourceIcon
    }

    var shouldSelected: Bool = false {
        didSet {
            if self.shouldSelected {
                self.contentView.backgroundColor = cellDidSelectedColor
            } else {
                self.contentView.backgroundColor = UIColor.clear
            }
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class EmotionItemCell: UICollectionViewCell {
    private weak var emotionView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(emotionView: UIView) {
        if emotionView == self.emotionView &&
            emotionView.superview == self.contentView {
            return
        }
        if self.emotionView?.superview == self.contentView {
            self.emotionView?.removeFromSuperview()
        }
        self.emotionView = emotionView
        self.contentView.addSubview(emotionView)
        emotionView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }
}
