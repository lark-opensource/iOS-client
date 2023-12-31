//
//  ShowTipCell.swift
//  LarkSearch
//
//  Created by chenyanjie on 2023/8/29.
//

import Foundation
import UIKit
import LarkCore

class ShowTipCell: UITableViewCell {
    private let errorView = SearchErrorInfoView()
    private let bgView = UIView()
    var viewModel: SearchCellViewModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        bgView.backgroundColor = UIColor.clear
        bgView.layer.cornerRadius = 8
        bgView.clipsToBounds = true
        contentView.addSubview(bgView)
        bgView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        bgView.addSubview(errorView)
        errorView.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        })
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateView(model: SearchTipViewModel, btnTappedAction: (() -> Void)?) {
        if let errorInfo = model.errorInfo {
            errorView.updateView(errorInfo: errorInfo, isNeedShowIcon: false, btnTappedAction: btnTappedAction)
        }

        self.viewModel = model
        if needShowDividerStyle() {
            updateToPadStyle()
        } else {
            updateToMobobileStyle()
        }
    }

    private func needShowDividerStyle() -> Bool {
        if let support = viewModel?.supprtPadStyle() {
            return support
        }
        return false
    }

    private func updateToPadStyle() {
        self.backgroundColor = UIColor.ud.bgBase
        bgView.backgroundColor = UIColor.ud.bgBody
    }

    private func updateToMobobileStyle() {
        self.backgroundColor = UIColor.ud.bgBody
        bgView.backgroundColor = UIColor.clear
    }
}
