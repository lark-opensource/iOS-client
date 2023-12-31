//
//  FeedFilterSortTableView.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/7/13.
//

import UIKit
import Foundation

final class FeedFilterSortTableView: UITableView {

    private let kTableCellCornerRadius: CGFloat = 10.0

    public init(frame: CGRect = .zero) {
        var style: UITableView.Style = .grouped
        if #available(iOS 13, *) {
            style = .insetGrouped
        }
        super.init(frame: frame, style: style)
    }

    private override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

     public override var alignmentRectInsets: UIEdgeInsets {
         var inset = super.alignmentRectInsets
         if #unavailable(iOS 13) {
             inset.left -= 16
             inset.right -= 16
         }
         return inset
     }

    public override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        // Might handle KVO here.

        if #unavailable(iOS 13) {
            if isShadowView(subview) {
                subview.layer.opacity = 0.2
            }
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if #unavailable(iOS 13) {
            adjustTableElements()
        }

        if #available(iOS 14, *) { } else if #available(iOS 13, *) {
            tableContentWrapper?.subviews
                .filter { isShadowView($0) }
                .forEach { $0.layer.opacity = 0.2 }
        }
    }

    var tableContentWrapper: UIView? {
        return nil
        /* 去除私有 API
        guard #available(iOS 13, *) else {
            return nil
        }
        guard let classStr = EncodedKeys.uiTableViewWrapper,
            let wrapperClass = NSClassFromString(classStr) else {
            return nil
        }
        return self.subviews.first(where: {
            $0.isMember(of: wrapperClass)
        })
         */
    }

    private func adjustTableElements() {
        for subview in subviews {
            if let cell = subview as? UITableViewCell {
                adjustCornerRadius(for: cell)
            }
        }
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

extension FeedFilterSortTableView {

    enum EncodedKeys {

        /* 去除私有 API
        /// UITableViewWrapperView
        static var uiTableViewWrapper: String? {
            if let data = Data(base64Encoded: "VUlUYWJsZVZpZXdXcmFwcGVyVmlldw==", options: .ignoreUnknownCharacters) {
                return String(data: data, encoding: .utf8)
            }
            return nil
        }
        /// UIShadowView
        static var uiShadowViewStr: String? {
            if let data = Data(base64Encoded: "VUlTaGFkb3dWaWV3", options: .ignoreUnknownCharacters) {
                return String(data: data, encoding: .utf8)
            }
            return nil
        }
         */
    }

    func isShadowView(_ view: UIView) -> Bool {
        return false
        /* 去除私有 API
        guard let classStr = EncodedKeys.uiShadowViewStr else { return false }
        return "\(type(of: view))" == classStr
         */
    }
}

protocol FeedFilterSectionHeaderProtocol: UIView {
    func setText(_ title: String, _ subTitle: String)
    func setTitleLabelLeadingOffset(_ offset: Double)
}

extension FeedFilterSectionHeaderProtocol {
    func setText(_ title: String, _ subTitle: String) {}
    func setTitleLabelLeadingOffset(_ offset: Double) {}
}

final class HeaderViewWithTitle: UITableViewHeaderFooterView, FeedFilterSectionHeaderProtocol {
    static let identifier = "HeaderViewWithTitle"
    let titleLabel = UILabel()
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textCaption
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(8)
            $0.bottom.equalTo(-6)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(_ title: String, _ subTitle: String) {
        titleLabel.text = title
    }

    func setTitleLabelLeadingOffset(_ offset: Double) {
        titleLabel.snp.updateConstraints {
            $0.leading.equalToSuperview().offset(offset)
        }
    }
}

final class FooterViewWithTitle: UITableViewHeaderFooterView {
    static let identifier = "FooterViewWithTitle"
    let titleLabel = UILabel()
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textPlaceholder
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(4)
            $0.bottom.equalTo(-8)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MultiTitleHeaderView: UITableViewHeaderFooterView, FeedFilterSectionHeaderProtocol {
    static let identifier = "MultiTitleHeaderView"

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        return label
    }()

    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 0
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.left.right.equalToSuperview().inset(16)
        }
        contentView.addSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.left.right.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(4)
        }
    }

    func setText(_ title: String, _ subTitle: String) {
        titleLabel.text = title
        subTitleLabel.text = subTitle
        subTitleLabel.snp.updateConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(subTitle.isEmpty ? 8 : 12)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
