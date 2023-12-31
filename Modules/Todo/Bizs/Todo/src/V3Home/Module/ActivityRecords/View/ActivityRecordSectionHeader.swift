//
//  ActivityRecordSectionHeader.swift
//  Todo
//
//  Created by wangwanxin on 2023/3/28.
//

import Foundation
import UniverseDesignColor

struct ActivityRecordSectionHeaderData {
    var text: AttrText?
    var height: CGFloat?
    var textHeight: CGFloat?
    var topSpace: CGFloat?
}

final class ActivityRecordSectionHeader: UICollectionReusableView {

    var viewData: ActivityRecordSectionHeaderData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            label.attributedText = viewData.text
        }
    }

    private lazy var containerView = UIView()
    private lazy var label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(containerView)
        containerView.backgroundColor = UIColor.ud.bgBase
        containerView.addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame = bounds
        label.frame = CGRect(
            x: 0,
            y: viewData?.topSpace ?? 0,
            width: bounds.width,
            height: viewData?.textHeight ?? 0
        )
    }

    struct Config {
        static let textHeight: CGFloat = 24.0
        static let topSpace: CGFloat = 16.0
        static let bottomSpace: CGFloat = 8.0
    }
}
