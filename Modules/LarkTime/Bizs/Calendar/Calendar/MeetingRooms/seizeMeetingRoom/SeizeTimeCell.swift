//
//  SeizeTimeCell.swift
//  Calendar
//
//  Created by harry zou on 2019/4/16.
//

import UniverseDesignIcon
import UIKit
import CalendarFoundation
final class SeizeTimeCell: UIView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.cd.regularFont(ofSize: 16)
        label.numberOfLines = 1
        return label
    }()

    var border = UIView()

    let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.timeOutlined).renderColor(with: .n3).withRenderingMode(.alwaysOriginal))

    let seizeableTag = TagViewProvider.seizeable()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layout(imageView: imageView)
        layout(titleView: titleLabel, leadingView: imageView)
        layout(tag: seizeableTag, leadingView: titleLabel)
        border = addBottomBorder(inset: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), lineHeight: 1)
    }

    func layout(imageView: UIImageView) {
        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
            make.leading.equalToSuperview().offset(16)
        }
    }

    func layout(titleView: UILabel, leadingView: UIView) {
        addSubview(titleView)
        titleView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
            make.leading.equalTo(leadingView.snp.trailing).offset(12)
        }
    }

    func layout(tag: UIView, leadingView: UIView) {
        addSubview(tag)
        tag.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(leadingView.snp.trailing).offset(6)
            make.trailing.lessThanOrEqualToSuperview().offset(-12)
        }
    }

    func update(title: String) {
        titleLabel.text = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTag(isHidden: Bool) {
        seizeableTag.isHidden = isHidden
    }

    func showAlldayBorder() {
        border.removeFromSuperview()
        border = addBottomBorder(inset: UIEdgeInsets(top: 0, left: 44, bottom: 0, right: 0), lineHeight: 1)
    }
}
