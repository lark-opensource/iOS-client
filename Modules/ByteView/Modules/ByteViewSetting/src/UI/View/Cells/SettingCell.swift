//
//  SettingCell.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/2/28.
//

import Foundation
import ByteViewCommon
import UniverseDesignColor
import UniverseDesignToast
import ByteViewUI
import RichLabel

extension SettingCellType {
    static let settingCell = SettingCellType("settingCell", cellType: SettingCell.self)
}

enum SettingCellStyle {
    case insetCorner
    case blankPaper

    var titleStyleConfig: VCFontConfig {
        switch self {
        case .insetCorner:
            return .body
        case .blankPaper:
            return .r_16_24
        }
    }

    var subtitleStyleConfig: VCFontConfig {
        switch self {
        case .insetCorner:
            return .bodyAssist
        case .blankPaper:
            return .r_14_22
        }
    }
}

/// 所有setting cell的基类
class BaseSettingCell: UITableViewCell {
    private(set) var row: SettingDisplayRow?
    private(set) var indexPath: IndexPath = IndexPath(row: 0, section: 0)
    private var customBgColor: UIColor { .ud.bgFloat }

    private var selectedBgColor: UIColor {
        switch cellStyle {
        case .insetCorner:
            return .ud.fillHover
        case .blankPaper:
            return .ud.fillPressed
        }
    }

    private(set) var cellStyle: SettingCellStyle = .insetCorner {
        didSet {
            guard cellStyle != oldValue else { return }
            backgroundColor = customBgColor
            backgroundView?.backgroundColor = customBgColor
            selectedBackgroundView?.backgroundColor = selectedBgColor
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = customBgColor
        self.contentView.backgroundColor = .clear
        let backgroundView = UIView()
        backgroundView.backgroundColor = customBgColor
        self.backgroundView = backgroundView
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = selectedBgColor
        self.selectedBackgroundView = selectedBackgroundView
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// override point for subclass. Do not call directly
    func setupViews() { }

    func config(for row: SettingDisplayRow, indexPath: IndexPath) {
        self.row = row
        self.indexPath = indexPath
        self.cellStyle = row.cellStyle
    }
}

/// 常用的Cell基类，含title/subtitle label及left/right view
class SettingCell: BaseSettingCell {
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let subtitleAttributedLabel = LKLabel(frame: .zero)

    let leftView = UIView()
    let rightView = UIView()
    var adjustsTitleColorWhenDisabled = false

    private var subtitleTopOffset: CGFloat { cellStyle == .blankPaper ? 2 : 4 }

    var cellHeight: CGFloat { 52 }

    /// override point for subclass. Do not call directly
    override func setupViews() {
        super.setupViews()
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(subtitleAttributedLabel)
        contentView.addSubview(leftView)
        contentView.addSubview(rightView)
        titleLabel.numberOfLines = 0
        subtitleLabel.numberOfLines = 0
        subtitleAttributedLabel.numberOfLines = 0
        subtitleAttributedLabel.lineSpacing = 5.0
        subtitleAttributedLabel.backgroundColor = .clear
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        subtitleLabel.setContentHuggingPriority(.required, for: .vertical)
        subtitleAttributedLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        subtitleAttributedLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitleAttributedLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        subtitleAttributedLabel.setContentHuggingPriority(.required, for: .vertical)
        self.leftView.isHidden = true
        self.rightView.isHidden = true

        leftView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.height.width.equalTo(0).priority(1)
        }
        rightView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.height.width.equalTo(0).priority(1)
        }
    }

    // nolint: long_function
    override func config(for row: SettingDisplayRow, indexPath: IndexPath) {
        super.config(for: row, indexPath: indexPath)
        if row.showsLeftView, self.leftView.subviews.contains(where: { !$0.isHidden }) {
            self.leftView.isHidden = false
        } else {
            self.leftView.isHidden = true
        }
        if row.showsRightView, self.rightView.subviews.contains(where: { !$0.isHidden }) {
            self.rightView.isHidden = false
        } else {
            self.rightView.isHidden = true
        }
        if let lines = row.data["titleLines"] as? Int {
            titleLabel.numberOfLines = lines
        } else {
            titleLabel.numberOfLines = 0
        }
        titleLabel.textColor = adjustsTitleColorWhenDisabled && !row.isEnabled ? .ud.textDisabled : .ud.textTitle
        if let attributedTitle = row.attributedTitle?() {
            titleLabel.attributedText = attributedTitle
        } else {
            titleLabel.attributedText = NSAttributedString(string: row.title, config: cellStyle.titleStyleConfig, lineBreakMode: .byTruncatingTail)
        }
        if row.useLKLabel == true {
            subtitleLabel.isHidden = true
            if let subtitle = row.subtitle, !subtitle.isEmpty {
                let linkText = LinkTextParser.parsedLinkText(from: subtitle)
                let linkFont = VCFontConfig.bodyAssist.font
                for component in linkText.components {
                    var link = LKTextLink(range: component.range,
                                          type: .link,
                                          attributes: [.foregroundColor: UIColor.ud.primaryContentDefault,
                                                       .font: linkFont],
                                          activeAttributes: [.backgroundColor: UIColor.clear])

                    link.linkTapBlock = { (_, _) in
                        if let serviceTerms = row.serviceTerms, let url = URL(string: serviceTerms) {
                            UIApplication.shared.open(url)
                        }
                    }
                    subtitleAttributedLabel.addLKTextLink(link: link)
                }

                let foregroundColor = adjustsTitleColorWhenDisabled && !row.isEnabled ? UIColor.ud.textDisabled : UIColor.ud.textPlaceholder
                let attributedString = NSAttributedString(string: linkText.result,
                                                          attributes: [.font: linkFont,
                                                                       .foregroundColor: foregroundColor])
                subtitleAttributedLabel.attributedText = attributedString

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 5
                let height = attributedString.string.boundingRect(with: CGSize(width: CGFloat(self.contentView.bounds.width - 79), height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: linkFont, NSAttributedString.Key.paragraphStyle: paragraphStyle], context: nil).height

                subtitleAttributedLabel.snp.remakeConstraints { make in
                    if leftView.isHidden {
                        make.left.equalToSuperview().offset(16)
                    } else {
                        make.left.equalTo(leftView.snp.right).offset(12)
                    }
                    make.bottom.equalToSuperview().offset(-12)
                    if rightView.isHidden {
                        make.right.lessThanOrEqualToSuperview().offset(-16)
                    } else {
                        make.right.equalTo(rightView.snp.left).offset(-12)
                    }
                    make.height.equalTo(height)  // unable auto expand
                }
                subtitleAttributedLabel.isHidden = false
            } else {
                subtitleAttributedLabel.isHidden = true
            }

            titleLabel.snp.remakeConstraints { make in
                if leftView.isHidden {
                    make.left.equalToSuperview().offset(16)
                } else {
                    make.left.equalTo(leftView.snp.right).offset(12)
                }
                make.top.equalToSuperview().offset(12).priority(.high)
                if subtitleAttributedLabel.isHidden {
                    make.centerY.equalToSuperview()
                    make.bottom.equalToSuperview().offset(-12).priority(.high)
                    // 只有标题时，保证contentView's height >= 52
                    make.centerY.greaterThanOrEqualTo(contentView.snp.top).offset(cellHeight / 2)
                } else {
                    make.bottom.equalTo(subtitleAttributedLabel.snp.top).offset(-subtitleTopOffset)
                }
                if rightView.isHidden {
                    make.right.lessThanOrEqualToSuperview().offset(-16)
                } else {
                    make.right.lessThanOrEqualTo(rightView.snp.left).offset(-12)
                }
            }
        } else {
            subtitleAttributedLabel.isHidden = true

            if let subtitle = row.subtitle, !subtitle.isEmpty {
                if let lines = row.data["subtitleLines"] as? Int {
                    subtitleLabel.numberOfLines = lines
                } else {
                    subtitleLabel.numberOfLines = 0
                }
                subtitleLabel.textColor = adjustsTitleColorWhenDisabled && !row.isEnabled ? .ud.textDisabled : .ud.textPlaceholder

                subtitleLabel.attributedText = NSAttributedString(string: subtitle, config: cellStyle.subtitleStyleConfig, lineBreakMode: .byTruncatingTail)

                subtitleLabel.snp.remakeConstraints { make in
                    if leftView.isHidden {
                        make.left.equalToSuperview().offset(16)
                    } else {
                        make.left.equalTo(leftView.snp.right).offset(12)
                    }
                    make.bottom.equalToSuperview().offset(-12)
                    if rightView.isHidden {
                        make.right.lessThanOrEqualToSuperview().offset(-16)
                    } else {
                        make.right.equalTo(rightView.snp.left).offset(-12)
                    }
                }
                subtitleLabel.isHidden = false
            } else {
                subtitleLabel.isHidden = true
            }

            titleLabel.snp.remakeConstraints { make in
                if leftView.isHidden {
                    make.left.equalToSuperview().offset(16)
                } else {
                    make.left.equalTo(leftView.snp.right).offset(12)
                }
                make.top.equalToSuperview().offset(12).priority(.high)
                if subtitleLabel.isHidden {
                    make.centerY.equalToSuperview()
                    make.bottom.equalToSuperview().offset(-12).priority(.high)
                    // 只有标题时，保证contentView's height >= 52
                    make.centerY.greaterThanOrEqualTo(contentView.snp.top).offset(cellHeight / 2)
                } else {
                    make.bottom.equalTo(subtitleLabel.snp.top).offset(-subtitleTopOffset)
                }
                if rightView.isHidden {
                    make.right.lessThanOrEqualToSuperview().offset(-16)
                } else {
                    make.right.lessThanOrEqualTo(rightView.snp.left).offset(-12)
                }
            }
        }
    }
}

protocol SettingRowUpdatable: AnyObject {
    func reloadRow(for item: SettingDisplayItem, shouldReloadSection: Bool)
    func reloadSection(_ section: Int)
    func scrollToRow(for item: SettingDisplayItem, at position: UITableView.ScrollPosition, animated: Bool)
}

struct SettingRowActionContext {
    let source: SettingPageId
    let service: UserSettingManager
    let row: SettingDisplayRow
    let indexPath: IndexPath
    weak var from: UIViewController?
    weak var updator: SettingRowUpdatable?
    /// newValue
    let isOn: Bool
    var anchorView: UIView?

    /// reload一下可以把状态刷回去
    func reloadRow() {
        updator?.reloadRow(for: row.item, shouldReloadSection: false)
    }

    func push(_ viewController: UIViewController) {
        Util.runInMainThread {
            from?.navigationController?.pushViewController(viewController, animated: true)
        }
    }

    func push(url: URL) {
        Util.runInMainThread {
            if let from = from {
                service.ui.push(url: url, from: from)
            }
        }
    }

    func showToast(_ message: String) {
        Util.runInMainThread {
            guard !message.isEmpty, let from = from else { return }
            UDToast.showTips(with: message, on: from.view)
        }
    }
}

extension UITableView {
    func registerSettingCell(_ cellType: SettingCellType) {
        self.register(cellType.cellType, forCellReuseIdentifier: cellType.reuseIdentifier)
    }
    func registerSettingHeaderView(_ headerViewType: SettingDisplayHeaderType) {
        self.register(headerViewType.headerViewType, forHeaderFooterViewReuseIdentifier: headerViewType.reuseIdentifier)
    }
    func registerSettingFooterView(_ footerViewType: SettingDisplayFooterType) {
        self.register(footerViewType.footerViewType, forHeaderFooterViewReuseIdentifier: footerViewType.reuseIdentifier)
    }
}
