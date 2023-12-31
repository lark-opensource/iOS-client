//
//  DetailSubTaskSkeletonView.swift
//  Todo
//
//  Created by baiyantao on 2022/8/15.
//

import Foundation
import UIKit
import SkeletonView

final class DetailSubTaskSkeletonView: UIView {
    private lazy var firstItem = SkeletonCell()
    private lazy var secondItem = SkeletonCell()
    private lazy var thirdItem = SkeletonCell()
    private lazy var forthItem = SkeletonCell()

    init() {
        super.init(frame: .zero)

        addSubview(firstItem)
        firstItem.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.height.equalTo(DetailSubTask.withTimeCellHeight)
        }
        addSubview(secondItem)
        secondItem.snp.makeConstraints {
            $0.top.equalTo(firstItem.snp.bottom)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(DetailSubTask.withTimeCellHeight)
        }
        addSubview(thirdItem)
        thirdItem.snp.makeConstraints {
            $0.top.equalTo(secondItem.snp.bottom)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(DetailSubTask.withTimeCellHeight)
        }
        addSubview(forthItem)
        forthItem.snp.makeConstraints {
            $0.top.equalTo(thirdItem.snp.bottom)
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(DetailSubTask.withTimeCellHeight)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

private final class SkeletonCell: UITableViewCell {

    private let gradient = SkeletonGradient(
        baseColor: UIColor.ud.bgFiller.withAlphaComponent(0.5),
        secondaryColor: UIColor.ud.bgFiller.withAlphaComponent(0.8)
    )

    private var isAnimating = false

    private let mockCheckbox = UIView()
    private let mockSummaryView = UIView()
    private let mockTimeView = UIView()
    private let mockAvator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody
        isSkeletonable = true

        mockCheckbox.frame = CGRect(x: 0, y: 12, width: 16, height: 16)
        mockCheckbox.layer.cornerRadius = 4
        mockCheckbox.clipsToBounds = true
        contentView.addSubview(mockCheckbox)
        mockCheckbox.isSkeletonable = true

        mockSummaryView.frame = CGRect(x: 28, y: 9, width: 247, height: 22)
        mockSummaryView.layer.cornerRadius = 4
        mockSummaryView.clipsToBounds = true
        contentView.addSubview(mockSummaryView)
        mockSummaryView.isSkeletonable = true

        mockTimeView.frame = CGRect(x: 28, y: 40, width: 200, height: 20)
        mockTimeView.layer.cornerRadius = 4
        mockTimeView.clipsToBounds = true
        contentView.addSubview(mockTimeView)
        mockTimeView.isSkeletonable = true

        mockAvator.frame = CGRect(x: 287, y: 8, width: 24, height: 24)
        mockAvator.layer.cornerRadius = 12
        mockAvator.clipsToBounds = true
        contentView.addSubview(mockAvator)
        mockAvator.isSkeletonable = true

        showAnimatedGradientSkeleton(usingGradient: gradient)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        mockSummaryView.frame.size.width = bounds.width - mockSummaryView.frame.left - 52
        mockTimeView.frame.size.width = mockSummaryView.frame.width - 47
        mockAvator.frame.origin.x = mockSummaryView.frame.maxX + 12
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
