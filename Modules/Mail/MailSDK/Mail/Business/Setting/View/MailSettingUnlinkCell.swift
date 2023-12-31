//
//  MailSettingUnlinkCell.swift
//  MailSDK
//
//  Created by tanghaojin on 2020/7/6.
//

import UIKit
import RxSwift
import LarkInteraction

class MailSettingUnlinkCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    var item: MailSettingItemProtocol? {
        didSet {
            setCellInfo()
        }
    }
    private let unlinkLabel: UILabel = UILabel()

    let disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupViews()
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: PointerStyle(
                    effect: .hover()
                )
            )
            self.addLKInteraction(pointer)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        contentView.backgroundColor = UIColor.ud.bgFloat
        contentView.addSubview(unlinkLabel)
        unlinkLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        unlinkLabel.textColor = UIColor.ud.functionDangerContentDefault
        unlinkLabel.numberOfLines = 0
        unlinkLabel.sizeToFit()
        unlinkLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)

        }
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(unbindCellClick)))
    }

    func setCellInfo() {
        if let currItem = item as? MailSettingUnlinkModel {
            unlinkLabel.text = currItem.title
        }
    }
}

extension MailSettingUnlinkCell {
    @objc
    func unbindCellClick() {
        if let currItem = item as? MailSettingUnlinkModel, let handler = currItem.unbindHandler {
            handler()
        }
    }
}
