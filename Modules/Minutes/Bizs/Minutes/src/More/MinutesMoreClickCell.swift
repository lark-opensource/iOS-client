//
//  MinutesMoreClickCell.swift
//  Minutes
//
//  Created by lvdaqian on 2021/2/23.
//

import Foundation
import UniverseDesignColor

struct MinutesMoreClickItem: MinutesMoreItem {
    let shouldDismiss: Bool = true

    let identifier = MinutesMoreClickCell.description()

    var icon: UIImage

    var title: String

    var height: CGFloat = 48

    var action: () -> Void

    func onSelect() {
        action()
    }

}

class MinutesMoreClickCell: UITableViewCell, MinutesMoreTableViewCell {

    private lazy var moreImageView: UIImageView = {
        let imageView: UIImageView = UIImageView(frame: CGRect.zero)
        return imageView
    }()

    private lazy var moreLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 17)
        return label
    }()

    private var item: MinutesMoreClickItem?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgFloat

        contentView.addSubview(moreImageView)
        moreImageView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(16)
            maker.centerY.equalToSuperview()
            maker.width.height.equalTo(20)
        }

        contentView.addSubview(moreLabel)
        moreLabel.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.left.equalTo(moreImageView.snp.right).offset(12)
            maker.right.lessThanOrEqualToSuperview().inset(16)
        }

        let selectedBackgroundView: UIView = UIView()
        selectedBackgroundView.backgroundColor = UIColor.ud.neutralColor12.withAlphaComponent(0.05)
        self.selectedBackgroundView = selectedBackgroundView
    }

    func onSelect() {
        self.item?.action()
    }

    func setupItem(_ item: MinutesMoreItem) {
        moreImageView.image = item.icon
        moreLabel.text = item.title
        self.item = item as? MinutesMoreClickItem
    }
}
