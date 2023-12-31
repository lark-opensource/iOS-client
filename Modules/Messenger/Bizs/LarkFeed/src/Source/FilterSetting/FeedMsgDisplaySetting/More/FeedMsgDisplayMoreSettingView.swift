//
//  FeedMsgDisplayMoreSettingView.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/29.
//

import UIKit
import Foundation
import LarkUIKit

protocol FeedSubFilterCellItem {
    var cellIdentifier: String { get }
    var isLastRow: Bool { get set }
    var indexPath: IndexPath? { get set }
}

struct FeedSubFilterCellModel: FeedSubFilterCellItem {
    var cellIdentifier: String = "FeedSubFilterCell"
    var title: String
    var subTitle: String?
    var item: FeedMsgDisplayFilterItem
    var isLastRow: Bool
    var indexPath: IndexPath?
    var showEditBtn: Bool
    var tapHandler: ((Int) -> Void)?

    init(title: String,
         subTitle: String?,
         item: FeedMsgDisplayFilterItem,
         isLastRow: Bool = false,
         indexPath: IndexPath? = nil,
         showEditBtn: Bool = false,
         tapHandler: ((Int) -> Void)? = nil) {
        self.title = title
        self.subTitle = subTitle
        self.item = item
        self.isLastRow = isLastRow
        self.indexPath = indexPath
        self.showEditBtn = showEditBtn
        self.tapHandler = tapHandler
    }
}

final class FeedSubFilterCell: BaseTableViewCell {
    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .left
        label.numberOfLines = 1
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private lazy var editBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(Resources.feed_right_arrow, for: .normal)
        button.isHidden = true
        button.isUserInteractionEnabled = false
        return button
    }()

    var bottomSeperator: UIView?

    var item: FeedSubFilterCellItem? {
        didSet {
            setCellInfo()
        }
    }

    var topOffSet: Float = 5

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        selectionStyle = .none
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().inset(50)
        }

        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(topOffSet)
            make.left.equalTo(self.titleLabel.snp.left)
            make.right.equalToSuperview().inset(50)
            make.bottom.equalToSuperview().inset(12)
        }

        contentView.addSubview(editBtn)
        editBtn.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(17)
            make.width.height.equalTo(20)
        }

        bottomSeperator = lu.addBottomBorder(leading: 16)
        self.lu.addTapGestureRecognizer(action: #selector(tapAction), target: self)
    }

    func setCellInfo() {
        guard let currItem = self.item as? FeedSubFilterCellModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = currItem.title
        editBtn.isHidden = !currItem.showEditBtn
        bottomSeperator?.isHidden = currItem.isLastRow
        let subTitle = currItem.subTitle ?? ""
        subtitleLabel.text = subTitle
        topOffSet = subTitle.isEmpty ? 0 : 5
        subtitleLabel.snp.updateConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(topOffSet)
        }
    }

    @objc
    func tapAction() {
        guard let currItem = self.item as? FeedSubFilterCellModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        guard let index = currItem.indexPath?.row else { return }
        currItem.tapHandler?(index)
    }
}
