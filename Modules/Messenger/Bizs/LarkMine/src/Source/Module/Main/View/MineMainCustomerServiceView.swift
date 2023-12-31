//
//  MineMainCustomerServiceView.swift
//  LarkMine
//
//  Created by 姚启灏 on 2019/2/25.
//

import UIKit
import Foundation
import LarkUIKit
import LarkCore
import LarkModel
import LarkSDKInterface

protocol MineMainCustomerServiceViewRouter: AnyObject {
    func openCustomServiceChatById(id: String, phoneNumber: String, reportLocation: Bool)
}

final class MineMainCustomerServiceView: UIView {
    weak var router: MineMainCustomerServiceViewRouter?

    private var oncalls: [Oncall] = []
    private var cellDataSource: [MineMainCustomerServiceCell] = []

    private var residueLineWidth: CGFloat!
    private var wrapperViewWidth: CGFloat!

    private var wrapperView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let wrapperView = UIView()
        self.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.wrapperView = wrapperView
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setOncalls(oncalls: [Oncall]) {
        self.oncalls = oncalls

        wrapperView?.setNeedsLayout()
        wrapperView?.layoutIfNeeded()
        wrapperViewWidth = wrapperView?.frame.width ?? 0
        residueLineWidth = wrapperView?.frame.width ?? 0

        oncalls.enumerated().forEach { (index, oncall) in
            buildCell(oncall: oncall, isLastCell: index == oncalls.count - 1)
        }
        UIView.performWithoutAnimation {
            if oncalls.isEmpty {
                wrapperView?.snp.updateConstraints {
                    $0.edges.equalToSuperview()
                }
            } else {
                wrapperView?.snp.updateConstraints {
                    $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 16, bottom: 20, right: 16))
                }
            }
        }
    }

    private func buildCell(oncall: Oncall, isLastCell: Bool) {
        let cell = MineMainCustomerServiceCell()
        cell.set(oncall: oncall)
        cell.delegate = self
        wrapperView?.addSubview(cell)

        let cellWidth = cell.sizeThatFits(.zero).width

        cell.snp.makeConstraints { (make) in
            if let lastView = self.cellDataSource.last {
                if cellWidth >= wrapperViewWidth {
                    make.top.equalTo(lastView.snp.bottom).offset(12)
                    make.width.left.right.equalToSuperview()
                    self.residueLineWidth = wrapperViewWidth
                } else if cellWidth > residueLineWidth {
                    make.top.equalTo(lastView.snp.bottom).offset(12)
                    make.left.equalToSuperview()
                    self.residueLineWidth = wrapperViewWidth - cellWidth
                } else {
                    make.top.equalTo(lastView.snp.top)
                    make.left.equalTo(lastView.snp.right).offset(12)
                    self.residueLineWidth -= cellWidth
                }
            } else {
                make.top.left.equalToSuperview()
                if cellWidth >= wrapperViewWidth {
                    make.width.right.equalToSuperview()
                    self.residueLineWidth = wrapperViewWidth
                } else {
                    self.residueLineWidth = wrapperViewWidth - cellWidth
                }
            }
            if isLastCell {
                make.bottom.equalToSuperview()
            }
        }

        cellDataSource.append(cell)
    }
}

extension MineMainCustomerServiceView: MineMainCustomerServiceCellDelegate {
    func didSelected(oncall: Oncall) {
        self.router?.openCustomServiceChatById(id: oncall.id, phoneNumber: oncall.phoneNumber, reportLocation: oncall.reportLocation)
        SettingTracker.Main.Click.Sos()
    }
}
