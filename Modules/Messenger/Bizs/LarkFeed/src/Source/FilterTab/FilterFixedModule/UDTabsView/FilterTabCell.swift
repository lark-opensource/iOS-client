//
//  FilterTabCell.swift
//  LarkFeed
//
//  Created by 姚启灏 on 2020/12/21.
//

import Foundation
import UIKit
import UniverseDesignTabs
import UniverseDesignIcon

final class FilterTabCell: UDTabsTitleCell {
    private var longPressGes: UILongPressGestureRecognizer?
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: Resources.filter_setting)
        imageView.backgroundColor = UIColor.ud.bgBody
        imageView.contentMode = .center
        return imageView
    }()

    var longPressCallBack: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let longPressGes = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(gesture:)))
        longPressGes.minimumPressDuration = 0.5
        longPressGes.numberOfTouchesRequired = 1
        self.addGestureRecognizer(longPressGes)
        self.longPressGes = longPressGes

        self.contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func longPressed(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            self.longPressCallBack?()
        }
    }

    override func reloadData(itemModel: UDTabsBaseItemModel, selectedType: UDTabsViewItemSelectedType) {
        super.reloadData(itemModel: itemModel, selectedType: selectedType)
        if let titleModel = itemModel as? UDTabsTitleItemModel, titleModel.title == FiltersModel.filterSettingTitle {
            imageView.isHidden = false
        } else {
            imageView.isHidden = true
        }
    }
}
