//
//  ArrangementHeaderView.swift
//  Calendar
//
//  Created by harry zou on 2019/3/19.
//

import UIKit
import CalendarFoundation
import LarkUIKit
final class ArrangementHeaderView: UIView {
    enum Mode {
        case freeBusy
        case personalCard
    }

    private var mode: Mode
    private var currentHeight: CGFloat = ArrangementHeaderViewCell.timeLabelHideHeight
    private var cellWidth: CGFloat = 0

    private lazy var cellHeight: CGFloat = {
        switch mode {
        case .freeBusy:
            return ArrangementHeaderViewCell.timeLabelHideHeight
        case .personalCard:
            return PersonalCardHeaderviewCell.height
        }
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.bounces = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(ArrangementHeaderViewCell.self, forCellWithReuseIdentifier: "ArrangementHeaderViewCell")
        collectionView.register(PersonalCardHeaderviewCell.self, forCellWithReuseIdentifier: "PersonalCardHeaderviewCell")
        return collectionView
    }()

    private var model: ArrangementHeaderViewModelProtocol?
    var movedToLeft: ((String, IndexPath) -> Void)?
    private var leftMargin: CGFloat

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = currentHeight
        return size
    }

    init(leftMargin: CGFloat, mode: Mode) {
        self.mode = mode
        self.leftMargin = leftMargin
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        currentHeight = cellHeight
        self.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func relayoutForiPad(newWidth: CGFloat) {
        relayoutCell(newWidth: newWidth)
    }

    func horizontalScrollView() -> UIScrollView {
        return collectionView
    }

    func updateModel(model: ArrangementHeaderViewModelProtocol) {
        self.model = model
        collectionView.reloadData()
        if Display.pad {
            return
        }
        relayoutCell()
    }

    var shouldNameInMiddle = true
    var shouldTimeInOneLine = true

    func updateCellStyle(cellWidth: CGFloat) {
        shouldNameInMiddle = true
        self.model?.cellModels.forEach { item in
            /// 第一行 - 人名
            /// 第二行 - [私密] >>> [隐藏] >>> [时间] >>> [null]

            // 只显示名字的场景
            if item.timeString == nil && !item.hasNoPermission && !item.timeInfoHidden {
                if !ArrangementHeaderViewCell.shouldAlignTextInCenter(nameString: item.nameString) {
                    shouldNameInMiddle = false
                }
                return
            }

            if item.hasNoPermission {
                // 无权限，单行
                shouldNameInMiddle = ArrangementHeaderViewCell
                    .shouldAlignTextInCenter(nameString: item.nameString,
                                             timeString: "",
                                             weekdayString: BundleI18n.Calendar.Calendar_UnderUser_PrivateCalendarGreyStatus)
            } else if item.timeInfoHidden {
                // 隐藏时区，单行
                shouldNameInMiddle = ArrangementHeaderViewCell
                    .shouldAlignTextInCenter(nameString: item.nameString,
                                             timeString: "",
                                             weekdayString: I18n.Calendar_G_HideTimeZone)
            } else {
                // 显示时间，星期和时间一起显示
                guard let timeString = item.timeString, let weekString = item.weekString else { return }
                shouldNameInMiddle = false
                shouldTimeInOneLine = ArrangementHeaderViewCell
                    .shouldTimeInOneLine(time: timeString,
                                         week: weekString,
                                         cellWidth: cellWidth)

            }
        }
    }

    func firstCell() -> UIView? {
        let cells = collectionView.visibleCells
        if !cells.isEmpty {
            let cell = cells.reduce(cells[0]) {
                $0.frame.minX < $1.frame.minX ? $0 : $1
            }
            if let cell = cell as? ArrangementHeaderViewCell {
                return cell.getTimeLable()
            }
            return nil
        }
        return nil
    }

    private func relayoutCell(newWidth: CGFloat? = nil) {
        guard let model = self.model else { return }

        let width = calculateCellWidth(width: newWidth)
        updateCellStyle(cellWidth: width)

        var height: CGFloat = 0
        if mode == .freeBusy {
            if model.shouldShowTimeString || model.cellModels.contains { $0.hasNoPermission || $0.timeInfoHidden } {
                height = ArrangementHeaderViewCell.timeLabelShowedHeight
                if shouldTimeInOneLine {
                    height = ArrangementHeaderViewCell.timeLabelOneLineHeight
                }
            } else {
                height = ArrangementHeaderViewCell.timeLabelHideHeight
            }
        } else {
            height = currentHeight
        }

        if currentHeight != height || cellWidth != width {
            cellWidth = width
            currentHeight = height
            setUpLayout(with: cellWidth, for: collectionView, height: currentHeight)
            collectionView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
                make.height.equalTo(currentHeight)
            }
        }
    }

    private func setUpLayout(with cellWidth: CGFloat,
                             for collectionView: UICollectionView,
                             height: CGFloat) {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: cellWidth, height: height)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = layout
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ArrangementHeaderView: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model?.cellModels.count ?? 0
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        for index in collectionView.indexPathsForSelectedItems ?? [] {
            collectionView.deselectItem(at: index, animated: false)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let model = model,
            let cellModel = model.cellModels[safeIndex: indexPath.row] else {
            assertionFailureLog()
            return UICollectionViewCell()
        }
        var retCell: UICollectionViewCell
        switch mode {
        case .personalCard:
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PersonalCardHeaderviewCell", for: indexPath) as? PersonalCardHeaderviewCell {
                cell.update(with: cellModel)
                retCell = cell
            } else {
                let cell = PersonalCardHeaderviewCell()
                cell.update(with: cellModel)
                retCell = cell
            }
        case .freeBusy:
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ArrangementHeaderViewCell", for: indexPath) as? ArrangementHeaderViewCell {
                cell.update(with: cellModel, shouldNameInMiddle: shouldNameInMiddle, shouldTimeInOneLine: shouldTimeInOneLine, cellWidth: cellWidth)
                retCell = cell
            } else {
                let cell = ArrangementHeaderViewCell()
                cell.update(with: cellModel, shouldNameInMiddle: shouldNameInMiddle, shouldTimeInOneLine: shouldTimeInOneLine, cellWidth: cellWidth)
                retCell = cell
            }
        }
        return retCell
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if mode != .freeBusy {
            return false
        }

        if indexPath.row == 0 {
            return false
        }

        if let cell = collectionView.cellForItem(at: indexPath) {
            if cell.isSelected {
                collectionView.deselectItem(at: indexPath, animated: false)
                moveToLeft(collectionView, indexPath: indexPath)
                CalendarTracer.shareInstance.freeBusyTapToLeft()
                return false
            } else {
                CalendarTracer.shareInstance.calChangeFreebusyLocation(status: .showArrow)
                return true
            }
        }
        assertionFailureLog("cell呢？！")
        return false
    }

    func moveToLeft(_ collectionView: UICollectionView, indexPath: IndexPath) {
        CalendarTracer.shareInstance.calChangeFreebusyLocation(status: .moveToLeft)
        if let cellmodel = model?.cellModels.remove(at: indexPath.row) {
            model?.cellModels.insert(cellmodel, at: 0)
            movedToLeft?(cellmodel.calendarId, indexPath)
        }
        collectionView.moveItem(at: indexPath, to: IndexPath(row: 0, section: 0))
    }

    private func calculateCellWidth(width: CGFloat? = nil) -> CGFloat {
        let is12HourStyle = model?.is12HourStyle ?? false
        let count = model?.cellModels.count ?? 1
        var maxCellCntPerScreen = count >= 5 ? 5 : count
        if maxCellCntPerScreen <= 0 {
            maxCellCntPerScreen = 1
        }
        let cellWidth: CGFloat
        if let width = width {
            cellWidth = (width - leftMargin) / CGFloat(maxCellCntPerScreen)
        } else {
            cellWidth = (UIScreen.main.bounds.width - leftMargin) / CGFloat(maxCellCntPerScreen)
        }

        if is12HourStyle {
            return max(80, cellWidth)
        } else {
            return cellWidth
        }
    }

}
