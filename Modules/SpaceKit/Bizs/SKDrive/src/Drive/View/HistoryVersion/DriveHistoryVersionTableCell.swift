//
//  DriveHistoryVersionTableCell.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/4/12.
//

import UIKit
import UniverseDesignColor

protocol DriveHistoryTableCellPresenter {
    var userName: String { get }
    var timeStamp: String { get }
    var recordWords: String { get }
    var iconImage: UIImage? { get }
    var fileName: String { get }
    var tagString: String? { get }
    var showDeletedStyle: Bool { get }
    var canSelected: Bool { get }
    var hideFileContainer: Bool { get }
}

class DriveHistoryVersionTableCell: UITableViewCell {

    static let cellHeight: CGFloat = 108.0
    static let cellHideFileHeight: CGFloat = 79.0

    private lazy var userNameLabel: UILabel = {
        let nameLabel = UILabel(frame: .zero)
        nameLabel.textColor = UIColor.ud.N900
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        contentView.addSubview(nameLabel)
        return nameLabel
    }()

    private lazy var timeStampLabel: UILabel = {
        let timeStampLabel = UILabel(frame: .zero)
        timeStampLabel.textColor = UIColor.ud.N500
        timeStampLabel.font = UIFont.systemFont(ofSize: 12)
        contentView.addSubview(timeStampLabel)
        return timeStampLabel
    }()

    private lazy var operateDecLabel: UILabel = {
        let operateDecLabel = UILabel(frame: .zero)
        operateDecLabel.textColor = UIColor.ud.N600
        operateDecLabel.font = UIFont.systemFont(ofSize: 14)
        contentView.addSubview(operateDecLabel)
        return operateDecLabel
    }()

    private lazy var fileContainer: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        contentView.addSubview(view)
        return view
    }()

    private lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.layer.cornerRadius = 10
        iconView.layer.masksToBounds = true
        iconView.contentMode = .scaleAspectFill
        fileContainer.addSubview(iconView)
        return iconView
    }()

    private lazy var fileNameLabel: UILabel = {
        let nameLabel = UILabel(frame: .zero)
        nameLabel.textColor = UIColor.ud.N900
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        fileContainer.addSubview(nameLabel)
        return nameLabel
    }()

    private lazy var tagLabel: DriveMarginLabel = {
        let tagLabel = DriveMarginLabel(frame: .zero)
        tagLabel.isHidden = true
        tagLabel.layer.cornerRadius = 2.0
        tagLabel.clipsToBounds = true
        tagLabel.textColor = UIColor.ud.N600
        tagLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        tagLabel.margin = UIEdgeInsets(top: 1, left: 4, bottom: 1, right: 4)
        tagLabel.backgroundColor = UIColor.ud.N100
        fileContainer.addSubview(tagLabel)
        return tagLabel
    }()

    private var fileNameLabelFont: UIFont {
        return UIFont.systemFont(ofSize: 14, weight: .medium)
    }

    private var fileNameLabelColor: UIColor {
        return UIColor.ud.N900
    }

    private var deletedFileNameLabelColor: UIColor {
        return UIColor.ud.N400
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.backgroundColor = UDColor.bgBody

        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.ud.N200
        selectedBackgroundView = bgColorView

        timeStampLabel.snp.makeConstraints { (make) in
            make.right.equalTo(-24)
            make.top.equalTo(23)
        }

        userNameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(24)
            make.centerY.equalTo(timeStampLabel.snp.centerY)
            make.right.lessThanOrEqualTo(timeStampLabel.snp.left)
        }

        operateDecLabel.snp.makeConstraints { (make) in
            make.left.equalTo(userNameLabel.snp.left)
            make.top.equalTo(userNameLabel.snp.bottom).offset(6)
            make.right.lessThanOrEqualToSuperview().offset(-24)
        }

        fileContainer.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(operateDecLabel.snp.bottom).offset(6)
        }

        iconView.snp.makeConstraints { (make) in
            make.left.equalTo(userNameLabel.snp.left)
            make.width.height.equalTo(20)
            make.top.equalToSuperview()
        }

        fileNameLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(iconView.snp.centerY)
            make.left.equalTo(iconView.snp.right).offset(8)
            make.right.lessThanOrEqualToSuperview().offset(-74)
        }

        tagLabel.snp.makeConstraints { (make) in
            make.left.equalTo(fileNameLabel.snp.right).offset(8)
            make.centerY.equalTo(iconView.snp.centerY)
        }

        let dividingLine = UIView()
        dividingLine.backgroundColor = UIColor.ud.N300
        contentView.addSubview(dividingLine)
        dividingLine.snp.makeConstraints { (make) in
            make.left.equalTo(24)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
}

extension DriveHistoryVersionTableCell {

    func render(presenter: DriveHistoryTableCellPresenter) {
        selectionStyle = presenter.canSelected ? .default : .none
        userNameLabel.text = presenter.userName
        timeStampLabel.text = presenter.timeStamp
        operateDecLabel.text = presenter.recordWords
        iconView.image = presenter.iconImage
        fileContainer.isHidden = presenter.hideFileContainer
        if presenter.showDeletedStyle {
            let color = deletedFileNameLabelColor
            let attributedText = NSMutableAttributedString(string: presenter.fileName,
                                                           attributes: [NSAttributedString.Key.font: fileNameLabelFont,
                                                                        NSAttributedString.Key.foregroundColor: color,
                                                                        NSAttributedString.Key.strikethroughStyle: 2,
                                                                        NSAttributedString.Key.strikethroughColor: color])
            fileNameLabel.attributedText = attributedText
            tagLabel.text = presenter.tagString
            tagLabel.isHidden = false
        } else {
            let attributedText = NSMutableAttributedString(string: presenter.fileName,
                                                           attributes: [NSAttributedString.Key.font: fileNameLabelFont,
                                                                        NSAttributedString.Key.foregroundColor: fileNameLabelColor])
            fileNameLabel.attributedText = attributedText
            tagLabel.isHidden = true
        }
    }
}
