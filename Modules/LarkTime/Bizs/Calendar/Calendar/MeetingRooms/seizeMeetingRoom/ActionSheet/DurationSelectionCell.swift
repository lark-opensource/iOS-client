//
//  DurationSelctionCell
//  Calendar
//
//  Created by harry zou on 2019/4/18.
//

import UIKit
import CalendarFoundation
import UniverseDesignIcon

final class DurationSelctionCell: UITableViewCell {
    let selectedImageView = UIImageView(image: UDIcon.getIconByKey(.listCheckColorful,
                                                                   renderingMode: .alwaysOriginal,
                                                                   size: CGSize(width: 16, height: 16)))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        contentView.addSubview(timeLabel)
        contentView.addSubview(selectedImageView)
        timeLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(17)
        }
        selectedImageView.isHidden = true
        contentView.addSubview(selectedImageView)
        selectedImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-15)
        }
        addBottomBorder()
        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.regularFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    func update(timeString: String) {
        timeLabel.text = timeString
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            selectedImageView.isHidden = false
        } else {
            selectedImageView.isHidden = true
        }
        // Configure the view for the selected state
    }

}
