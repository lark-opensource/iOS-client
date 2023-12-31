//
//  EmotionSettingTableViewSortCell.swift
//  AudioSessionScenario
//
//  Created by huangjianming on 2019/8/6.
//

import Foundation
import UIKit
import RxSwift

final class EmotionSettingTableViewSortCell: EmotionShopViewBaseTableViewCell {
    var disposeBag = DisposeBag()
    public lazy var deleteButton: UIButton = {
        let deleteButton = UIButton()
        deleteButton.setImage(Resources.emotionDeleteIcon, for: .normal)
        return deleteButton
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupSubviews() {
        super.setupSubviews()
        self.contentView.addSubview(self.deleteButton)
        self.backgroundColor = UIColor.ud.bgBody

        self.deleteButton.snp.makeConstraints { (make) in
            make.right.equalTo(-8)
            make.width.height.equalTo(40)
            make.centerY.equalToSuperview()
        }
    }

    override func prepareForReuse() {
       super.prepareForReuse()
       self.disposeBag = DisposeBag()
   }
}
