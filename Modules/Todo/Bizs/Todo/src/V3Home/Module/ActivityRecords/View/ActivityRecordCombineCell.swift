//
//  ActivityRecordCombineCell.swift
//  Todo
//
//  Created by wangwanxin on 2023/3/29.
//

import Foundation
import UniverseDesignColor
import UniverseDesignFont

struct ActivityRecordCombineData {
    // 唯一id
    var guid: String
    var text: String?
    var textWidth: CGFloat?
    // 元数据
    var metaData: Rust.ActivityRecord?
    // 缓存高度
    var itemHeight: CGFloat?

    func preferredHeight(maxWidth: CGFloat) -> CGFloat {
        var height = ActivityRecordCombineCell.Config.topPadding + ActivityRecordCombineCell.Config.bottomPadding
        height += ActivityRecordCombineCell.Config.titleHeight
        return height
    }
}

final class ActivityRecordCombineCell: UICollectionViewCell {

    var viewData: ActivityRecordCombineData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            titleLabel.text = viewData.text
        }
    }

    private lazy var rightLine = UIView()
    private lazy var leftLine = UIView()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = Config.font
        label.textColor = UIColor.ud.textCaption
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBase
        addSubview(rightLine)
        addSubview(titleLabel)
        addSubview(leftLine)
        rightLine.backgroundColor = UIColor.ud.lineDividerDefault
        leftLine.backgroundColor = UIColor.ud.lineDividerDefault
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let centerY = Config.topPadding + Config.titleHeight * Config.halfRatio
        leftLine.frame = CGRect(
            x: 0,
            y: centerY,
            width: Config.leftWidth,
            height: Config.lineHeight
        )
        titleLabel.frame = CGRect(
            x: leftLine.frame.maxX + Config.padding,
            y: Config.topPadding,
            width: viewData?.textWidth ?? 0,
            height: Config.titleHeight
        )
        rightLine.frame = CGRect(
            x: titleLabel.frame.maxX + Config.padding,
            y: centerY,
            width: bounds.width - titleLabel.frame.maxX - Config.padding,
            height: Config.lineHeight
        )
    }

    struct Config {
        static let lineHeight: CGFloat = 1.0
        static let leftWidth: CGFloat = 8.0
        static let maxContentRatio: CGFloat = 0.7
        static let padding: CGFloat = 8.0
        static let topPadding: CGFloat = 14.0
        static let bottomPadding: CGFloat = 6.0
        static let titleHeight: CGFloat = 20.0
        static let halfRatio: CGFloat = 0.5
        static let font = UDFont.systemFont(ofSize: 14.0)
    }

}
