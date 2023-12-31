//
//  SelectLanguageTableViewCell.swift
//  SKCommon
//
//  Created by LiZeChuang on 2020/7/2.
//

import Foundation
import LarkUIKit
import RxSwift
import SKCommon
import UniverseDesignColor
import UniverseDesignCheckBox

public final class SelectLanguageTableViewCell: SKGroupTableViewCell {
    private let disposeBag: DisposeBag = DisposeBag()
    private lazy var titleLabel: UILabel = UILabel()
    private lazy var checkBox: UDCheckBox = UDCheckBox(boxType: .list, config: .init(style: .circle), tapCallBack: { _ in })
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        self.containerView.backgroundColor = UIColor.ud.bgFloat
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.textAlignment = .left
        self.titleLabel.textColor = UDColor.textTitle
        self.titleLabel.backgroundColor = .clear
        self.containerView.addSubview(self.titleLabel)
        self.containerView.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(16)
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }

        self.checkBox.isHidden = true
        self.checkBox.isUserInteractionEnabled = false
        self.containerView.addSubview(self.checkBox)
        self.checkBox.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
            make.size.equalTo(18)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(title: String, isSelected: Bool) {
        self.titleLabel.text = title
        self.checkBox.isSelected = isSelected
        self.checkBox.isHidden = !isSelected
    }

    // The default is N1000
    public func setTitleLabelColor(_ color: UIColor) {
        self.titleLabel.textColor = color
    }
}
