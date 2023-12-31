//
//  MailSettingBaseCell.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/8/18.
//

import Foundation
import UniverseDesignIcon

/// 提供基础的 title ---- status ---- arrowImage UI
class MailSettingBaseCell: UITableViewCell {
    let titleLabel: UILabel = UILabel()
    let statusLabel: UILabel = UILabel()
    let arrowImageView = UIImageView()

    var item: MailSettingItemProtocol? {
        didSet {
            setCellInfo()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupViews()
    }

    func setupViews() {
        contentView.backgroundColor = UIColor.ud.bgFloat
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview().offset(-60)
            make.bottom.equalToSuperview().offset(-16)
        }

        arrowImageView.image = UDIcon.rightBoldOutlined.withRenderingMode(.alwaysTemplate)
        arrowImageView.tintColor = UIColor.ud.iconN3
        contentView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 12, height: 12))
            make.right.equalTo(-16)
        }

        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textColor = UIColor.ud.textPlaceholder
        contentView.addSubview(statusLabel)
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        statusLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(12)
            make.right.equalTo(arrowImageView.snp.left).offset(-7)
        }

        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didClickCell)))
    }
    
    func adjustLabelLayout() {
        // titleLabel中有多行文本时，intrinsicContentSize.width返回的宽度不符合预期，先设置为单行
        titleLabel.numberOfLines = 1
        titleLabel.sizeToFit()
        statusLabel.sizeToFit()
        let titleWidth = titleLabel.intrinsicContentSize.width
        let statusWidth = statusLabel.intrinsicContentSize.width
        let leftOffset: CGFloat = 16
        let rightOffset: CGFloat = 32
        let minDist: CGFloat = 12
        let minWidthOfCompress: CGFloat = 86 //statusLabel不允许被压缩至小于86
        let contentWidth: CGFloat = self.frame.width - leftOffset - rightOffset
        let totalWidth = titleWidth + statusWidth + minDist
        if totalWidth > contentWidth { // 需要压缩statuLabel or titelLabel 的宽度
            // statusLabel的最小宽度
            let minStatusWidth: CGFloat = min(statusWidth, minWidthOfCompress)
            var newTitleWidth = titleWidth
            var newStatusWidth = statusWidth
            if contentWidth - titleWidth - minDist > minWidthOfCompress {
                // 能够留给statusLabel的最大宽度大于86，直接取这个值
                newStatusWidth = contentWidth - titleWidth - minDist
            } else {
                // 不够86，statusLabel取其最小宽度
                newStatusWidth = minStatusWidth
            }
            newTitleWidth = contentWidth - newStatusWidth - minDist
            
            statusLabel.snp.remakeConstraints{ (make) in
                make.width.equalTo(newStatusWidth)
                make.right.equalTo(arrowImageView.snp.left).offset(-7)
                make.centerY.equalToSuperview()
            }

            titleLabel.snp.remakeConstraints{ (make) in
                make.top.equalToSuperview().offset(16)
                make.left.equalToSuperview().offset(16)
                make.bottom.equalToSuperview().offset(-16)
                make.width.equalTo(newTitleWidth)
            }
        } else {
            titleLabel.snp.remakeConstraints { (make) in
                make.top.equalToSuperview().offset(16)
                make.left.equalToSuperview().offset(16)
                make.bottom.equalToSuperview().offset(-16)
            }
            statusLabel.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.right.equalTo(arrowImageView.snp.left).offset(-7)
            }
        }
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        self.setNeedsLayout()
    }
    
    @objc
    func didClickCell() {

    }

    func setCellInfo() {
        fatalError("Subclass must override this method")
    }
}
