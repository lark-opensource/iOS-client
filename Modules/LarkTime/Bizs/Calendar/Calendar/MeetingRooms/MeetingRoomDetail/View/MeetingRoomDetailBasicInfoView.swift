//
//  MeetingRoomDetailBasicInfoView.swift
//  Calendar
//
//  Created by Lianghongbin on 2021/1/15.
//

import UIKit
import Foundation

typealias CellData = (type: MeetingRoomDetailCellView.MeetingRoomDetailCellType, content: [String])

protocol BasicInfoViewDataType {
    var cellsData: [CellData] { get }
}

// 两种组合方式 「基本信息」「预定信息」
final class MeetingRoomDetailBasicInfoView: UIView, ViewDataConvertible {
    var viewData: BasicInfoViewDataType? {
        didSet {
            guard let cellsData = viewData?.cellsData, !cellsData.isEmpty else { return }
            subviews.forEach { (subview) in subview.removeFromSuperview() }
            var cellsShowed = [MeetingRoomDetailCellView]()
            cellsData.forEach { (cellData) in
                switch cellData.type {
                case .capcity:
                    capacityCell.cellData = cellData
                    cellsShowed.append(capacityCell)
                case .equipments:
                    equipmentsCell.cellData = cellData
                    cellsShowed.append(equipmentsCell)
                case .resourceStrategy:
                    resourceStrategyCell.cellData = cellData
                    cellsShowed.append(resourceStrategyCell)
                case .remarks:
                    remarksCell.cellData = cellData
                    cellsShowed.append(remarksCell)
                case .picture:
                    pictureCell.cellData = cellData
                    cellsShowed.append(pictureCell)
                case .booker:
                    bookerCell.cellData = cellData
                    cellsShowed.append(bookerCell)
                case .scheduledTime:
                    scheduledTimeCell.cellData = cellData
                    cellsShowed.append(scheduledTimeCell)
                case .cantUse:
                    cantReserveCell.cellData = cellData
                    cellsShowed.append(cantReserveCell)
                case .creator:
                    createrCell.cellData = cellData
                    cellsShowed.append(createrCell)
                }
            }
            updateSubviews(subviews: cellsShowed)
        }
    }

    // statusContent
    lazy var scheduledTimeCell = MeetingRoomDetailCellView()
    lazy var bookerCell = MeetingRoomDetailCellView()

    // statusContent & basicInfo
    lazy var resourceStrategyCell = MeetingRoomDetailCellView()
    lazy var cantReserveCell = MeetingRoomDetailCellView()

    // basicInfo
    lazy var capacityCell = MeetingRoomDetailCellView()
    lazy var equipmentsCell = MeetingRoomDetailCellView()
    lazy var remarksCell = MeetingRoomDetailCellView()
    lazy var pictureCell = MeetingRoomDetailCellView()
    lazy var createrCell = MeetingRoomDetailCellView()

    private func updateSubviews(subviews: [UIView]) {
        subviews.enumerated().forEach { (index, cell) in
            addSubview(cell)
            cell.snp.makeConstraints {
                $0.left.right.equalToSuperview()
                // 纵向约束
                if index == 0 {
                    $0.top.equalToSuperview().offset(15)
                } else {
                    $0.top.equalTo(subviews[index - 1].snp.bottom)
                }
                if index == subviews.count - 1 {
                    $0.bottom.equalToSuperview().offset(-15)
                }
            }
        }
    }
}
