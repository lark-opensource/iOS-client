//
//  InsetTableView.swift
//  FigmaKit
//
//  Created by Hayden Wang on 2021/8/29.
//

import Foundation
import UIKit

public final class InsetTableView: UITableView {

    private let kTableCellCornerRadius: CGFloat = 10.0
    private let kTableContentMargin: CGFloat = 16.0

    public lazy var insetLayoutGuide: UILayoutGuide = {
        let guide = UILayoutGuide()
        guide.identifier = "content-layout-guide"
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var keepDragShadowLightIfNeeded = false

    public override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        // Might handle KVO here.

        // 解决阴影过深 iOS12及以下
        guard keepDragShadowLightIfNeeded else { return }
        if #available(iOS 13, *) { } else {
            if isShadowView(subview) {
                subview.layer.opacity = 0.2
            }
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if #available(iOS 13, *) {} else {
            adjustTableElements()
        }

        // 解决阴影过深 针对iOS13
        guard keepDragShadowLightIfNeeded else { return }
        if #available(iOS 14, *) { } else if #available(iOS 13, *) {
            tableContentWrapper?.subviews
                .filter { isShadowView($0) }
                .forEach { $0.layer.opacity = 0.2 }
        }
    }

    private var tableContentWrapper: UIView? {
        return nil
        /* 去除私有 API
        guard #available(iOS 13, *) else {
            return nil
        }
        // swiftlint:disable all
        guard let classStr = EncodedKeys.uiTableViewWrapper, 
            let wrapperClass = NSClassFromString(classStr) else {
            return nil
        }
        // swiftlint:enable all
        return self.subviews.first(where: {
            $0.isMember(of: wrapperClass)
        })
         */
    }

    private func setupLayoutGuide() {
        addLayoutGuide(insetLayoutGuide)
        var guides = [
            insetLayoutGuide.topAnchor.constraint(equalTo: topAnchor),
            insetLayoutGuide.bottomAnchor.constraint(equalTo: topAnchor)]
        if #available(iOS 13, *), let tableWrapper = tableContentWrapper {
            guides.append(contentsOf: [
                insetLayoutGuide.leadingAnchor.constraint(equalTo: tableWrapper.leadingAnchor),
                insetLayoutGuide.trailingAnchor.constraint(equalTo: tableWrapper.trailingAnchor)
            ])
        } else {
            guides.append(contentsOf: [
                insetLayoutGuide.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
                insetLayoutGuide.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16)
            ])
        }
        NSLayoutConstraint.activate(guides)
    }

    private func adjustTableElements() {
        for subview in subviews {
            if let cell = subview as? UITableViewCell {
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

    public func tableContentViewWidth() -> CGFloat {
        if #available(iOS 13, *) {
            return self.frame.width - self.layoutMargins.left - self.layoutMargins.right
        } else {
            return self.frame.width - self.safeAreaInsets.left - 2 * kTableContentMargin - self.safeAreaInsets.right
        }
    }
}

extension InsetTableView {

    // swiftlint:disable all

    /* 去除私有 API
    enum EncodedKeys {
        /// UITableViewWrapperView
        static var uiTableViewWrapper: String? {
            "VUlUYWJsZVZpZXdXcmFwcGVyVmlldw==".base64Decoded()
        }
        /// UIShadowView
        static var uiShadowViewStr: String? {
            "VUlTaGFkb3dWaWV3".base64Decoded()
        }
    }

     */

    func isShadowView(_ view: UIView) -> Bool {
        return false
        /* 去除私有 API
        guard let classStr = EncodedKeys.uiShadowViewStr else { return false }
        return "\(type(of: view))" == classStr
         */
    }

    // swiftlint:enable all
}
