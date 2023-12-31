//
//  NewShareContent.swift
//  ByteView
//
//  Created by huangshun on 2020/4/17.
//

import Foundation

class NewShareContentItem: RowPresentable {

    var title: String

    var image: UIImage

    var showBeta: Bool

    init(
        title: String,
        image: UIImage,
        showBeta: Bool = false,
        action: @escaping RowAction
    ) {
        self.title = title
        self.image = image
        self.showBeta = showBeta
        super.init(action)
    }

    override var type: RowPresentableCell.Type {
        return NewShareContentTableCell.self
    }

    override var height: CGFloat {
        return 72.0
    }

}

class NewShareContentTableCell: RowPresentableCell {

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(frame: .zero)
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.textColor = UIColor.ud.textTitle
        return titleLabel
    }()

    private lazy var titleImageView: UIImageView = {
        let titleImageView = UIImageView(frame: .zero)
        return titleImageView
    }()

    private lazy var betaView: UIView = {
        let label = PaddingLabel()
        label.font = .systemFont(ofSize: 12.0)
        label.textColor = UIColor.ud.textCaption
        label.attributedText = NSAttributedString(string: "Beta", config: .tinyAssist)
        label.backgroundColor = UIColor.ud.udtokenTagNeutralBgNormal
        label.textInsets = UIEdgeInsets(top: 0.0, left: 4.0, bottom: 0.0, right: 4.0)
        label.layer.cornerRadius = 2.0
        label.clipsToBounds = true
        label.isHidden = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var bottomLine: UIImageView = {
        let line = UIImageView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.clear
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = UIColor.ud.fillHover
        self.selectedBackgroundView = selectedBackgroundView
        contentView.addSubview(titleImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(betaView)
        contentView.addSubview(bottomLine)

        titleImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(48)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(titleImageView.snp.right).offset(12)
        }
        betaView.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.right).offset(12.0)
            make.centerY.equalTo(titleLabel)
            make.height.equalTo(18.0)
        }
        bottomLine.snp.makeConstraints { maker in
            maker.height.equalTo(1.0 / self.vc.displayScale)
            maker.left.equalTo(titleLabel)
            maker.right.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configRowPresentable(_ presentable: RowPresentable) {

        guard let presentable = presentable as? NewShareContentItem
            else { return }

        titleLabel.text = presentable.title
        titleImageView.image = presentable.image
        betaView.isHidden = !presentable.showBeta
    }

}
