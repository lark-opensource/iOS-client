//
//  CalendarPickerItemView.swift
//  UniverseDesignDatePicker
//
//  Created by LiangHongbin on 2021/3/17.
//
import Foundation
import UIKit
class CalendarPickerItemView: UICollectionView {
    let style = (cellSpacing: CGFloat(20), leftPading: CGFloat(16), rightPading: CGFloat(15))

    let cellHeight: CGFloat
    override var frame: CGRect {
        didSet {
            guard window != nil, oldValue.size != frame.size else { return }
            guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
                return
            }
            let itemsWidthSum = frame.width - style.leftPading - style.rightPading - 6 * style.cellSpacing
            let itemWidth = floor(itemsWidthSum / 7 * 1000) / 1000
            layout.itemSize = CGSize(width: itemWidth, height: cellHeight)
        }
    }

    init(dayCellHeight: CGFloat) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 20
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: style.leftPading, bottom: 8, right: style.rightPading)
        cellHeight = dayCellHeight
        super.init(frame: .zero, collectionViewLayout: layout)
        backgroundColor = UDDatePickerTheme.wheelPickerBackgroundColor
        isScrollEnabled = false
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let fitHeight = contentSize.height
        frame.size = CGSize(width: frame.size.width, height: fitHeight)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
