//
//  ParticipantActionCell.swift
//  ByteView
//
//  Created by Tobb Huang on 2023/6/20.
//

import Foundation
import ByteViewCommon

struct ParticipantActionCellAppearance {
    let titleFontConfig: VCFontConfig
    let verticalOffset: CGFloat
    let horizontalOffset: CGFloat
    let backgroundViewInset: UIEdgeInsets
    let backgroundViewCornerRadius: CGFloat

    static let pan: ParticipantActionCellAppearance = .init(titleFontConfig: .body,
                                                            verticalOffset: 12,
                                                            horizontalOffset: 16,
                                                            backgroundViewInset: .zero,
                                                            backgroundViewCornerRadius: 0)

    static let popover: ParticipantActionCellAppearance = .init(titleFontConfig: .bodyAssist,
                                                                verticalOffset: 15,
                                                                horizontalOffset: 16,
                                                                backgroundViewInset: .init(top: 0, left: 4, bottom: 0, right: 4),
                                                                backgroundViewCornerRadius: 6)
}

class ParticipantActionCell: UITableViewCell {

    struct Layout {
        static let iconSize: CGFloat = 20
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var iconView: UIImageView = UIImageView()
    private lazy var bgView: UIView = {
        let bgView = UIView()
        bgView.backgroundColor = UIColor.ud.fillPressed
        return bgView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let customSelectedView = UIView()
        customSelectedView.addSubview(bgView)
        self.selectedBackgroundView = customSelectedView
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        self.clipsToBounds = true
        self.backgroundColor = .clear
        contentView.addSubview(titleLabel)
        contentView.addSubview(iconView)
    }

    func config(appearance: ParticipantActionCellAppearance, action: ParticipantAction) {
        iconView.image = action.icon
        iconView.isHidden = action.icon == nil
        iconView.snp.remakeConstraints { make in
            make.size.equalTo(Layout.iconSize)
            make.right.equalToSuperview().inset(appearance.horizontalOffset)
            make.centerY.equalToSuperview()
        }
        titleLabel.attributedText = NSAttributedString(string: action.title,
                                                       config: appearance.titleFontConfig,
                                                       lineBreakMode: .byTruncatingTail,
                                                       textColor: action.color)
        titleLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().inset(appearance.horizontalOffset)
            make.top.bottom.equalToSuperview().inset(appearance.verticalOffset)
            if iconView.isHidden {
                make.right.equalToSuperview().inset(appearance.horizontalOffset)
            } else {
                make.right.equalTo(iconView.snp.left).offset(-appearance.horizontalOffset)
            }
        }
        bgView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(appearance.backgroundViewInset)
        }
        bgView.layer.cornerRadius = appearance.backgroundViewCornerRadius
    }
}

class ParticipantActionLineCell: UITableViewCell {
    private lazy var lineDivider: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    var cellHeight: CGFloat = 1 {
        didSet {
            let inset = (cellHeight - 1) / 2
            lineDivider.snp.remakeConstraints { make in
                make.height.equalTo(1)
                make.left.right.equalToSuperview()
                make.top.bottom.equalToSuperview().inset(inset)
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.isUserInteractionEnabled = false
        self.backgroundColor = .clear
        contentView.addSubview(lineDivider)
        lineDivider.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
