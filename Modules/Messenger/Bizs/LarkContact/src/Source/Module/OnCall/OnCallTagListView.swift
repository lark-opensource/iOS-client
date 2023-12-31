//
//  OnCallCollectionView.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/11/11.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import LarkSDKInterface

final class OnCallTagListView: UIView {
    weak var cellDelegate: OnCallTagDelegate?
    var dataSource: [OnCallTag] = []
    var cellDataSource: [OnCallTagView] = []

    var residueLineWidth: CGFloat!
    var superWidth: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)

        residueLineWidth = superWidth
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setDataSource(dataSource: [OnCallTag], superWidth: CGFloat) {
        self.superWidth = superWidth
        if dataSource.isEmpty {
            self.dataSource = dataSource
        } else {
            var allOncallTag = OnCallTag()
            allOncallTag.id = ""
            allOncallTag.name = BundleI18n.LarkContact.Lark_Legacy_All
            self.dataSource = [allOncallTag]
            self.dataSource.append(contentsOf: dataSource)
        }
        self.dataSource.enumerated().forEach { (index, tag) in
            initContentView(onCallTag: tag, isLastCell: index == dataSource.count - 1)
        }
        selectAllCell()
    }

    func selectAllCell() {
        cellDataSource.first?.label.textColor = UIColor.ud.primaryOnPrimaryFill
        cellDataSource.first?.label.color = UIColor.ud.colorfulBlue
    }

    func initContentView(onCallTag: OnCallTag, isLastCell: Bool) {
        let cell = OnCallTagView()
        cell.setContent(onCallTag: onCallTag, delegate: cellDelegate)
        let cellWidth = cell.sizeThatFits(.zero).width

        self.addSubview(cell)
        cell.snp.makeConstraints { (make) in
            make.height.equalTo(28)
            if let lastView = self.cellDataSource.last {
                if cellWidth >= superWidth {
                    make.top.equalTo(lastView.snp.bottom).offset(12)
                    make.width.left.right.equalToSuperview()
                    self.residueLineWidth = superWidth
                } else if cellWidth > residueLineWidth {
                    make.top.equalTo(lastView.snp.bottom).offset(12)
                    make.left.equalToSuperview()
                    self.residueLineWidth = superWidth - cellWidth
                } else {
                    make.top.equalTo(lastView.snp.top)
                    make.left.equalTo(lastView.snp.right).offset(12)
                    self.residueLineWidth -= cellWidth
                }
            } else {
                make.top.left.equalToSuperview()
                if cellWidth >= superWidth {
                    make.width.right.equalToSuperview()
                    self.residueLineWidth = superWidth
                } else {
                    self.residueLineWidth = superWidth - cellWidth
                }
            }
            if isLastCell {
                make.bottom.equalToSuperview()
            }
        }
        cellDataSource.append(cell)
    }

    func removeAllSelect() {
        self.cellDataSource.forEach { (cell) in
            cell.clearStatus()
        }
    }
}
