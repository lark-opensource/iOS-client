//
//  LarkTimeLabel.swift
//  LarkListItem
//
//  Created by 姚启灏 on 2020/7/10.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

open class LarkTimeLabel: UIView {

    public private(set) var timeIcon: UIImageView = .init(image: nil)
    public private(set) var timeLabel: UILabel = .init()

    public var font: UIFont = UIFont.systemFont(ofSize: 12) {
        didSet { timeLabel.font = self.font }
    }

    public var textColor: UIColor = UIColor.ud.textPlaceholder {
        didSet { timeLabel.textColor = textColor }
    }

    private let iconSize = CGSize(width: 16, height: 16)
    private let spacing = CGFloat(4)
    public var timeString: String? {
        didSet {
            isHidden = (timeString ?? "").isEmpty
            timeLabel.text = timeString
            if isHidden {
                timeIcon.image = nil
                timeIcon.snp.updateConstraints { make in
                    make.size.equalTo(CGSize.zero)
                }
                timeLabel.snp.updateConstraints { make in
                    make.left.equalToSuperview()
                }
            } else {
                timeIcon.image = Resources.timeZone
                timeIcon.snp.updateConstraints { make in
                    make.size.equalTo(iconSize)
                }
                timeLabel.snp.updateConstraints { make in
                    make.left.equalToSuperview().offset(iconSize.width + spacing)
                }
            }
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = true
        isHidden = true

        timeIcon = UIImageView()
        timeIcon.image = Resources.timeZone
        timeIcon.isUserInteractionEnabled = false
        addSubview(timeIcon)
        timeIcon.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.size.equalTo(CGSize.zero)
        }

        timeLabel = UILabel()
        timeLabel.isUserInteractionEnabled = false
        timeLabel.font = font
        timeLabel.textColor = textColor
        addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.bottom.right.equalToSuperview()
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
