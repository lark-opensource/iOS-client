//
//  LastReadTipView.swift
//  Moment
//
//  Created by liluobin on 2023/9/20.
//

import UIKit
import SnapKit

class LastReadTipView: UIView {

    var tapCallBack: (() -> Void)?

    private static var text: String {
        return BundleI18n.Moment.Moments_LeftOffHere_NoButton_Toast + " " +
        BundleI18n.Moment.Moments_LeftOffHere_TapRefresh_Mobile_Button
    }
    private static let font = UIFont.systemFont(ofSize: 14, weight: .medium)
    private static let space: CGFloat = 12
    private let bgView = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        bgView.backgroundColor = UIColor.ud.bgBodyOverlay
        self.addSubview(bgView)
        bgView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        bgView.layer.cornerRadius = 17
        bgView.layer.masksToBounds = true

        let label = UILabel()
        label.text = Self.text
        label.font = Self.font
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textLinkNormal
        label.backgroundColor = UIColor.clear
        label.isUserInteractionEnabled = true
        label.textAlignment = .center
        bgView.addSubview(label)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        label.addGestureRecognizer(tap)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Self.space * 2)
            make.right.equalToSuperview().offset(-Self.space * 2)
            make.bottom.equalToSuperview().offset(-7)
            make.top.equalToSuperview().offset(7)
            make.height.greaterThanOrEqualTo(20)
        }

        let leftLine = UIView()
        leftLine.backgroundColor = UIColor.ud.lineDividerDefault
        self.addSubview(leftLine)
        leftLine.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.right.equalTo(bgView.snp.left).offset(-Self.space)
            make.left.equalToSuperview().offset(Self.space)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(Self.space)
        }

        let rightLine = UIView()
        rightLine.backgroundColor = UIColor.ud.lineDividerDefault
        self.addSubview(rightLine)
        rightLine.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.right.equalToSuperview().offset(-Self.space)
            make.left.equalTo(bgView.snp.right).offset(Self.space)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(Self.space)
        }
    }

    @objc
    func tap() {
        self.tapCallBack?()
    }

    static func heightForSize(_ size: CGSize) -> CGFloat {
        let minLineWith = self.space * 6 + 2 * Self.space * 2
        let width: CGFloat = size.width - minLineWith
        let labelHeight = MomentsDataConverter.heightForString(self.text, onWidth: width, font: self.font)
        return max(34, labelHeight + 14)
    }
}
