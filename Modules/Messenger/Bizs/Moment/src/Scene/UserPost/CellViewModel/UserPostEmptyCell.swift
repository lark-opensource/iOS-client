//
//  UserPostEmptyCell.swift
//  Moment
//
//  Created by liluobin on 2021/3/12.
//

import Foundation
import UIKit
import SnapKit
import LarkButton
import UniverseDesignEmpty

final class UserPostEmptyCell: UITableViewCell {
    static let identifier = "UserPostEmptyCell"
    var emptyBtnCallBack: (() -> Void)?
    var title: String = ""
    var emptyBtnStyle: (String, TypeButton.Style?)?
    var emptyType: UDEmptyType = .defaultPage
    let emptyView = MomentsEmptyView(frame: .zero)
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        self.contentView.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func updateUI() {
        self.backgroundColor = UIColor.clear
        var primaryButtonConfig: (String?, (UIButton) -> Void)?
        if let emptyBtnStyle = emptyBtnStyle {
            primaryButtonConfig = (emptyBtnStyle.0, { [weak self] _ in
                self?.emptyBtnCallBack?()
            })
        }
        self.emptyView.update(description: title, type: emptyType, primaryButtonConfig: primaryButtonConfig)
    }
}
