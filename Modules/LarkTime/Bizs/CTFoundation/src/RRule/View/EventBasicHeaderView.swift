//
//  EventBasicHeaderView.swift
//  Calendar
//
//  Created by Miao Cai on 2020/3/27.
//

import UIKit

final class EventBasicHeaderView: UIView {

    static let desiredHeight: CGFloat = 71

    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle
            let shouldHidden = !(subtitle?.isEmpty ?? false)
            subtitleLabel.isHidden = shouldHidden
            subtitleLabel.snp.updateConstraints {
                $0.height.equalTo(shouldHidden ? 0 : 18)
                $0.top.equalTo(titleLabel.snp.bottom).offset(shouldHidden ? 0 : 1)
            }
        }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textColor = RRule.UIStyle.Color.normalText
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private lazy var bottomLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgBody
        let centerView = UIView()
        addSubview(centerView)
        centerView.snp.makeConstraints {
            $0.centerY.equalToSuperview().offset(-0.25)
            $0.left.right.equalToSuperview()
        }

        centerView.addSubview(titleLabel)
        centerView.addSubview(subtitleLabel)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.height.equalTo(31)
            $0.left.lessThanOrEqualToSuperview().offset(16)
            $0.width.equalToSuperview().offset(-32)
        }

        subtitleLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom)
            $0.height.equalTo(0)
            $0.left.right.equalTo(titleLabel)
        }

        addSubview(bottomLineView)
        bottomLineView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(RRule.UIStyle.Layout.horizontalSeperatorHeight)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: Self.desiredHeight)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: Self.desiredHeight)
    }
}
