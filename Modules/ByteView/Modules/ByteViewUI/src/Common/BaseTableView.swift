//
//  BaseTableView.swift
//  ByteViewUI
//
//  Created by chenyizhuo on 2021/9/23.
//

import UIKit

open class BaseTableView: UITableView {
    public override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        iOS15Fix()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func iOS15Fix() {
        if #available(iOS 15.0, *) {
            sectionHeaderTopPadding = 0
            /// https://bytetech.info/articles/7026626924147376135?searchId=20230817112853EA433B18E3D27FF033E0
            /// 防止 reload 闪动
            isPrefetchingEnabled = false
        }
    }
}

open class BaseGroupedTableView: BaseTableView {
    private let kTableCellCornerRadius: CGFloat = 10.0
    private let kTableContentMargin: CGFloat = 16.0

    public private(set) lazy var insetLayoutGuide: UILayoutGuide = {
        let guide = UILayoutGuide()
        guide.identifier = "insetLayoutGuide"
        return guide
    }()

    public init(frame: CGRect = .zero) {
        var style: UITableView.Style = .grouped
        if #available(iOS 13, *) {
            style = .insetGrouped
        }
        super.init(frame: frame, style: style)
        setupLayoutGuide()
    }

    private override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        setupLayoutGuide()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        if #available(iOS 13.0, *) {
            adjustTableElements()
        } else {
            adjustTableElements(includeCells: true)
        }
    }

    private func setupLayoutGuide() {
        addLayoutGuide(insetLayoutGuide)
        insetLayoutGuide.snp.makeConstraints { make in
            make.top.bottom.equalTo(self)
            make.leading.trailing.equalTo(self.safeAreaLayoutGuide).inset(kTableContentMargin)
        }
    }

    private func adjustTableElements(includeCells: Bool = false) {
        for subview in subviews {
            if includeCells, let cell = subview as? UITableViewCell {
                adjustCornerRadius(for: cell)
                adjustContentInsets(for: cell)
            } else if let view = subview as? UITableViewHeaderFooterView {
                adjustContentInsets(for: view)
            }
        }
    }

    private func adjustContentInsets(for view: UIView) {
        var newFrame = view.frame
        let safeAreaInsets = self.safeAreaInsets
        let leftInset = safeAreaInsets.left + kTableContentMargin
        let rightInset = safeAreaInsets.right + kTableContentMargin
        newFrame.origin.x = leftInset
        newFrame.size.width = frame.width - (leftInset + rightInset)
        view.layer.frame = newFrame
    }

    private func adjustCornerRadius(for cell: UITableViewCell) {
        guard let indexPath = indexPath(for: cell) else {
            return
        }
        let countOfRows = numberOfRows(inSection: indexPath.section)
        cell.clipsToBounds = true
        cell.layer.masksToBounds = true
        cell.layer.cornerRadius = kTableCellCornerRadius
        if countOfRows == 1 {
            cell.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner
            ]
        } else {
            switch indexPath.row {
            case 0:
                cell.layer.maskedCorners = [
                    .layerMinXMinYCorner,
                    .layerMaxXMinYCorner
                ]
            case countOfRows - 1:
                cell.layer.maskedCorners = [
                    .layerMinXMaxYCorner,
                    .layerMaxXMaxYCorner
                ]
            default:
                cell.layer.maskedCorners = []
            }
        }
    }
}
