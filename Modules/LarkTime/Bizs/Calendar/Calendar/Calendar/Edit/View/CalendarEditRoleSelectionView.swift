//
//  CalendarEditRoleSelectionView.swift
//  Calendar
//
//  Created by Hongbin Liang on 3/29/23.
//

import Foundation
import UIKit
import UniverseDesignIcon

struct SelectionCellData {
    let canSelect: Bool
    let title: String
    let content: String
}

class CalendarEditRoleSelectionView: UIStackView {

    var onSelect: ((_ index: Int, _ shouldBlock: Bool) -> Void)?

    var selectedIndex: Int = -1 {
        didSet {
            guard oldValue != selectedIndex, !selectionContents[safeIndex: selectedIndex].isNil else { return }
            guard let to = selectionViewDic[selectedIndex] else { return }
            selectionViewDic[oldValue]?.isSelected = false
            to.isSelected = true
        }
    }

    static let UI = (cellHeight: 70, seperatorHeight: CGFloat(1.0 / UIScreen.main.scale))

    private let selectionContents: [SelectionCellData]
    private var selectionViewDic: [Int: SelectionCell] = [:]

    /// 权限选择面板
    /// - Parameters:
    ///   - contents: 各选项内容
    ///   - selectedIndex: 选中的值
    ///   - separatorFilled: 分割线是否通栏 default = false
    ///   - bgColor: 背景色，float 下颜色不同
    init(contents: [SelectionCellData], separatorFilled: Bool = false, bgColor: UIColor = .ud.panelBgColor) {
        self.selectionContents = contents
        super.init(frame: .zero)

        axis = .vertical
        backgroundColor = bgColor
        let contentsNum = contents.count
        contents.enumerated().forEach { index, content in
            let cell = SelectionCell()
            cell.setupWith(index: index, bgColor: bgColor, data: content)
            cell.itemTapped = { [weak self] index, canSelect in
                self?.onSelect?(index, !canSelect)
            }
            addArrangedSubview(cell)
            cell.snp.makeConstraints { make in
                make.height.equalTo(Self.UI.cellHeight)
            }
            selectionViewDic[index] = cell
            if index < contentsNum - 1 {
                let separator = UIView()
                separator.backgroundColor = .ud.lineDividerDefault
                let wrapper = UIView()
                wrapper.addSubview(separator)
                let leftInset = separatorFilled ? 0 : 16
                separator.snp.makeConstraints { make in
                    make.leading.equalToSuperview().inset(leftInset)
                    make.height.equalTo(Self.UI.seperatorHeight)
                    make.trailing.top.bottom.equalToSuperview()
                }
                addArrangedSubview(wrapper)
            }
        }

    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// 宽度自撑，高度外部设置，内容垂直居中
fileprivate class SelectionCell: EventBasicCellLikeView.BackgroundView {

    var itemTapped: ((_ index: Int, _ canSelect: Bool) -> Void)?
    var isSelected: Bool = false {
        didSet {
            guard oldValue != isSelected else { return }
            checkMark.isHidden = !isSelected
        }
    }

    private var canSelect = false

    private let titleLabel = UILabel.cd.textLabel()
    private let contentLabel = UILabel.cd.subTitleLabel()
    private let checkMark = UIImageView()

    private let authorityMask = UIView()

    func setupWith(index: Int, bgColor: UIColor, data: SelectionCellData) {
        self.tag = index
        canSelect = data.canSelect
        titleLabel.text = data.title
        contentLabel.text = data.content
        contentLabel.numberOfLines = 2
        checkMark.image = UDIcon.getIconByKey(.doneOutlined, iconColor: .ud.primaryContentDefault)

        addSubview(checkMark)
        checkMark.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 24, height: 24))
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }
        checkMark.isHidden = true

        let container = UIStackView(arrangedSubviews: [titleLabel, contentLabel])
        container.axis = .vertical
        container.alignment = .leading
        container.spacing = 4
        addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.trailing.equalTo(checkMark.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
        }

        authorityMask.alpha = 0.5
        authorityMask.backgroundColor = bgColor
        addSubview(authorityMask)
        authorityMask.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        authorityMask.isHidden = canSelect

        let highLightBgColor = canSelect ? UIColor.ud.fillPressed : bgColor
        backgroundColors = (bgColor, highLightBgColor)

        let tap = UITapGestureRecognizer(target: self, action: #selector(selectionTapped(_:)))
        addGestureRecognizer(tap)
    }

    @objc
    private func selectionTapped(_ tap: UITapGestureRecognizer) {
        guard let index = tap.view?.tag else { return }
        itemTapped?(index, canSelect)
    }
}
