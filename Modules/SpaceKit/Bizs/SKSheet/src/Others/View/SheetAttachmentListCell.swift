//
// Created by duanxiaochen.7 on 2021/2/17.
// Affiliated with SKSheet.
//
// Description: Sheet 单元格附件列表的 table view cell

import SKFoundation
import SKUIKit
import SKResource
import SKCommon
import UniverseDesignColor

class SheetAttachmentListCell: UITableViewCell {

    private lazy var iconView = UIImageView(frame: .zero).construct { it in
        it.layer.cornerRadius = 12
        it.layer.masksToBounds = true
    }

    private lazy var titleLabel = UILabel(frame: .zero).construct { it in
        it.font = .systemFont(ofSize: 17)
        it.textColor = UDColor.textTitle
        it.textAlignment = .left
        it.numberOfLines = 0
        it.lineBreakMode = .byTruncatingMiddle
        it.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private lazy var sizeLabel = UILabel(frame: .zero).construct { it in
        it.font = .systemFont(ofSize: 17)
        it.textColor = UDColor.textCaption
        it.textAlignment = .right
        it.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
    }

    private lazy var bgView = UIView().construct { it in
        it.backgroundColor = UDColor.fillPressed
    }

    private lazy var separationLine = UIView(frame: .zero).construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectedBackgroundView = bgView
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.top.bottom.equalToSuperview().inset(12)
        }
        contentView.addSubview(sizeLabel)
        sizeLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
        contentView.addSubview(separationLine)
        separationLine.snp.makeConstraints { (make) in
            make.height.equalTo(0.5)
            make.leading.equalTo(16)
            make.bottom.trailing.equalToSuperview()
        }
        contentView.docs.addStandardHover()
    }

    func reloadInfo(_ info: SheetAttachmentInfo) {
        iconView.image = info.iconImage
        if info.type == .url {
            titleLabel.numberOfLines = 0
        } else {
            titleLabel.numberOfLines = 1
        }
        if info.type == .url || info.type == .cellPosition {
            let linkAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UDColor.textLinkNormal,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
            titleLabel.attributedText = NSAttributedString(string: info.name, attributes: linkAttributes)
        } else {
            titleLabel.attributedText = nil
            titleLabel.text = info.name
        }
        if info.shouldShowSize {
            sizeLabel.text = FileSizeHelper.memoryFormat(info.size)
        } else {
            sizeLabel.text = ""
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
