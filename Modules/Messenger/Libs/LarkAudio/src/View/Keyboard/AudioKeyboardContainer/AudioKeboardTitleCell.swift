//
//  AudioKeboardTitleCell.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/5/31.
//

import UIKit
import Foundation
import UniverseDesignColor
import SnapKit

final class AudioKeboardTitleCell: UICollectionViewCell {

    private var titleLabel: UILabel = UILabel()
    private var lineView: UIView = UIView()
    private var isSelectedKeyboard: Bool = false
    private var showSelectedLine: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(titleLabel)
        self.titleLabel.font = UIFont.systemFont(ofSize: 14)
        self.titleLabel.textAlignment = .center
        titleLabel.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        contentView.addSubview(lineView)
        lineView.backgroundColor = UIColor.ud.N900
        lineView.layer.cornerRadius = 1.5
        lineView.layer.masksToBounds = true
        lineView.snp.makeConstraints { (maker) in
            maker.centerX.bottom.equalToSuperview()
            maker.width.equalTo(10)
            maker.height.equalTo(3)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, isSelectedKeyboard: Bool, showSelectedLine: Bool) {
        self.titleLabel.text = title
        self.isSelectedKeyboard = isSelectedKeyboard
        self.showSelectedLine = showSelectedLine
        self.updateTitleLabel()
    }

    private func updateTitleLabel() {
        if isSelectedKeyboard {
            self.titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
            self.titleLabel.textColor = UIColor.ud.textTitle
        } else {
            self.titleLabel.font = UIFont.systemFont(ofSize: 14)
            self.titleLabel.textColor = UIColor.ud.textPlaceholder
        }
        self.lineView.isHidden = !showSelectedLine
    }
}
