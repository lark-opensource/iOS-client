//
//  RoomAudioSelectViewController.swift
//  ByteView
//
//  Created by kiri on 2023/3/16.
//

import Foundation
import UIKit
import UniverseDesignIcon
import ByteViewUI

protocol RoomAudioSelectViewControllerDelegate: AnyObject {
    func roomAudioSelectViewControllerDidAppear(_ vc: UIViewController)
    func roomAudioSelectViewControllerWillDisappear(_ vc: UIViewController)
}

final class RoomAudioSelectViewController: VMViewController<RoomAudioSelectViewModel> {
    private var isPopover = false

    private lazy var normalHeaderView = RoomAudioSelectHeaderView(isPopover: false, title: viewModel.title)
    private lazy var popoverHeaderView = RoomAudioSelectHeaderView(isPopover: true, title: viewModel.title)
    private var buttons: [RoomAudioSelectButton] = []
    private var sectionHeaderViews: [UIView] = []
    private var contentView = UIView()

    private var headerView: UIView {
        isPopover ? popoverHeaderView : normalHeaderView
    }

    weak var delegate: RoomAudioSelectViewControllerDelegate?

    override func setupViews() {
        super.setupViews()
        view.addSubview(contentView)
        var lastView: UIView?
        let lastSection = viewModel.availableItems.count - 1
        for (i, rows) in viewModel.availableItems.enumerated() {
            if i > 0 {
                let headerView = UIView()
                sectionHeaderViews.append(headerView)
                contentView.addSubview(headerView)
                headerView.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    if let lastView = lastView {
                        make.top.equalTo(lastView.snp.bottom)
                    }
                    make.height.equalTo(0)
                }
                lastView = headerView
            }
            let lastRow = rows.count - 1
            for (j, row) in rows.enumerated() {
                let button = RoomAudioSelectButton()
                button.indexPath = IndexPath(row: j, section: i)
                button.isLastSection = i == lastSection
                button.isLastRow = j == lastRow
                button.updateStyle(isPopover: isPopover)
                button.config(row)
                button.isExclusiveTouch = true
                button.addTarget(self, action: #selector(didSelectItem(_:)), for: .touchUpInside)
                buttons.append(button)
                contentView.addSubview(button)
                button.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    if let lastView = lastView {
                        make.top.equalTo(lastView.snp.bottom)
                    } else {
                        make.top.equalToSuperview()
                    }
                    if button.isLastRow && button.isLastSection {
                        make.bottom.equalToSuperview()
                    }
                }
                lastView = button
            }
        }
        updateStyle()
    }

    override func bindViewModel() {
        super.bindViewModel()
        viewModel.delegate = self
    }

    private var lastLayoutSubviewsSize: CGSize = .zero
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if lastLayoutSubviewsSize != self.view.frame.size {
            self.lastLayoutSubviewsSize = self.view.frame.size
            self.updateContentSize()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.roomAudioSelectViewControllerDidAppear(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.roomAudioSelectViewControllerWillDisappear(self)
    }

    private var ggHeight: CGFloat = 100
    private func updateStyle(from: String = #function) {
        guard isViewLoaded else { return }
        Logger.ui.info("updateStyle from \(from)")
        if isPopover {
            self.view.backgroundColor = .ud.bgFloat
            normalHeaderView.removeFromSuperview()
            self.view.addSubview(headerView)
            headerView.snp.remakeConstraints { make in
                make.left.top.right.equalToSuperview()
            }
            contentView.snp.remakeConstraints { make in
                make.top.equalTo(headerView.snp.bottom)
                make.left.equalToSuperview()
                make.right.equalToSuperview().priority(.high)
                make.bottom.equalToSuperview().inset(13).priority(.high)
                make.width.greaterThanOrEqualTo(280)
                make.width.lessThanOrEqualTo(360)
            }
            sectionHeaderViews.forEach { view in
                view.snp.updateConstraints { make in
                    make.height.equalTo(8)
                }
                let line = UIView()
                line.backgroundColor = .ud.lineDividerDefault
                view.addSubview(line)
                line.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.centerY.equalToSuperview()
                    make.height.equalTo(1 / view.vc.displayScale)
                }
            }
            buttons.forEach { btn in
                btn.updateStyle(isPopover: true)
                btn.snp.updateConstraints { make in
                    make.left.right.equalToSuperview().inset(4)
                    if btn.isLastRow && btn.isLastSection {
                        make.bottom.equalToSuperview().inset(4)
                    }
                }
            }
        } else {
            self.view.backgroundColor = .ud.bgFloatBase
            popoverHeaderView.removeFromSuperview()
            self.view.addSubview(normalHeaderView)
            headerView.snp.remakeConstraints { make in
                make.left.top.right.equalToSuperview()
            }
            contentView.snp.remakeConstraints { make in
                make.top.equalTo(headerView.snp.bottom)
                make.left.right.equalToSuperview().inset(16)
                make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16).priority(.high)
            }
            sectionHeaderViews.forEach { view in
                view.snp.updateConstraints { make in
                    make.height.equalTo(16)
                }
                view.subviews.forEach { $0.removeFromSuperview() }
            }
            buttons.forEach { btn in
                btn.updateStyle(isPopover: false)
                btn.snp.updateConstraints { make in
                    make.left.right.equalToSuperview()
                    if btn.isLastRow && btn.isLastSection {
                        make.bottom.equalToSuperview()
                    }
                }
            }
        }
    }

    private func updateContentSize() {
        if isPopover {
            let size = CGSize(width: contentView.frame.width, height: contentView.frame.maxY)
            if self.preferredContentSize != size {
                self.updateDynamicModalSize(size)
                self.logger.info("preferredContentSize changed to \(size)")
            }
        } else {
            let height = self.contentView.frame.maxY + 16
            if height != self.ggHeight {
                self.logger.info("ggHeight changed to \(height)")
                self.ggHeight = height
                self.panViewController?.updateBelowLayout()
            }
        }
    }

    @objc private func didSelectItem(_ sender: RoomAudioSelectButton) {
        guard let item = sender.currentModel?.item else { return }
        viewModel.handleSelectItem(item, from: self)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .allButUpsideDown
    }

    private var lastIsPopover = false
    func checkPopover(sourceView: UIView, sourceRect: CGRect) {
        if self.isPopover != self.lastIsPopover {
            self.lastIsPopover = self.isPopover
            /// popover changed, skip refresh
            return
        }
        guard self.isPopover, let popover = self.popoverPresentationController else {
            return
        }
        if popover.sourceView != sourceView {
            Logger.ui.info("repopover RoomAudioSelectViewController from \(sourceView)")
            popover.sourceView = sourceView
        }
        if popover.sourceRect != sourceRect {
            popover.sourceRect = sourceRect
            popover.containerView?.setNeedsLayout()
            popover.containerView?.layoutIfNeeded()
        }
    }
}

extension RoomAudioSelectViewController: RoomAudioSelectViewModelDelegate {
    func didChangeCallMeItem(_ cellModel: RoomAudioSelectCellModel) {
        self.buttons.first(where: { $0.currentModel?.item == .callMe })?.config(cellModel)
    }
}

extension RoomAudioSelectViewController: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
        if Display.pad {
            let isPopover = isRegular
            if isPopover != self.isPopover {
                self.lastIsPopover = self.isPopover
                self.isPopover = isPopover
                self.updateStyle()
            }
        }
    }
}

extension RoomAudioSelectViewController: PanChildViewControllerProtocol {
    func height(_ axis: RoadAxis, layout: RoadLayout) -> PanHeight {
        let bottomOffset: CGFloat = VCScene.safeAreaInsets.bottom > 0 ? 0 : 4
        /// 12是barView的高度。
        return .contentHeight(ggHeight + bottomOffset + 12)
    }

    func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth {
        if Display.phone, axis == .landscape {
            return .maxWidth(width: 420)
        }
        return .fullWidth
    }

    var backgroudColor: UIColor {
        .ud.bgFloatBase
    }
}

final class RoomAudioSelectHeaderView: UIView {
    let titleLabel = UILabel()
    init(isPopover: Bool, title: String) {
        super.init(frame: CGRect(x: 0, y: 0, width: 280, height: 32))

        titleLabel.numberOfLines = 0
        titleLabel.textColor = isPopover ? .ud.textPlaceholder : .ud.textCaption
        titleLabel.attributedText = NSAttributedString(string: title, config: .bodyAssist)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            if isPopover {
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 20, bottom: 4, right: 20))
            } else {
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 32, bottom: 4, right: 32))
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class RoomAudioSelectButton: UIButton {
    private let container = UIView()
    private let iconViewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.bgFiller
        view.layer.cornerRadius = 6
        return view
    }()
    private let iconView = UIImageView()
    var indexPath: IndexPath = IndexPath(row: 0, section: 0)
    var isLastSection = false
    var isFirstRow: Bool {
        indexPath.row == 0
    }
    var isLastRow = false
    private var isPopover = false

    override var isHighlighted: Bool {
        didSet {
            self.highlightBackgroundView.isHidden = !isHighlighted
            self.iconViewContainer.backgroundColor = isHighlighted ? .ud.bgFloat : .ud.bgFiller
        }
    }

    private let customTitleLabel: UILabel = {
        let label = UILabel()
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return label
    }()

    private lazy var customSubtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ud.textPlaceholder
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return label
    }()

    private lazy var customTitleStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [customTitleLabel, customSubtitleLabel])
        stackView.axis = .vertical
        stackView.spacing = 2
        return stackView
    }()

    private lazy var accessoryLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ud.textCaption
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var checkmarkView = UIImageView(image: UDIcon.getIconByKey(.doneOutlined, iconColor: .ud.primaryContentDefault, size: CGSize(width: 20, height: 20)))

    private lazy var highlightBackgroundView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .ud.fillHover
        view.layer.cornerRadius = 8
        view.isHidden = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
        vc.setBackgroundColor(.ud.bgFloat, for: .normal)
        vc.setBackgroundColor(.ud.bgFloat, for: .highlighted)
        container.isUserInteractionEnabled = false
        addSubview(highlightBackgroundView)
        addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconViewContainer.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.size.equalTo(20)
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private(set) var currentModel: RoomAudioSelectCellModel?
    // nolint: long_function
    func config(_ model: RoomAudioSelectCellModel) {
        self.currentModel = model
        var subviews: [UIView] = []
        var hasIcon = false
        var hasSubtitle = false
        var hasAccessoryText = false

        if let icon = model.icon {
            subviews.append(iconViewContainer)
            iconView.image = UDIcon.getIconByKey(icon, iconColor: .ud.iconN2, size: CGSize(width: 20, height: 20))
            hasIcon = true
        }

        subviews.append(customTitleStack)
        customTitleLabel.attributedText = NSAttributedString(string: model.title, config: .body, lineBreakMode: .byTruncatingTail)

        if let subtitle = model.subtitle, !subtitle.isEmpty {
            customSubtitleLabel.attributedText = NSAttributedString(string: subtitle, config: .bodyAssist, lineBreakMode: .byTruncatingTail)
            hasSubtitle = true
        }
        customSubtitleLabel.isHiddenInStackView = !hasSubtitle

        if let accessoryText = model.accessoryText, !accessoryText.isEmpty {
            subviews.append(accessoryLabel)
            accessoryLabel.attributedText = NSAttributedString(string: accessoryText, config: .bodyAssist)
            hasAccessoryText = true
        } else if model.isSelected {
            subviews.append(checkmarkView)
        }

        container.subviews.forEach { v in
            if !subviews.contains(v) {
                v.removeFromSuperview()
            }
        }
        subviews.forEach { v in
            if v.superview != container {
                container.addSubview(v)
            }
        }

        let rightView = hasAccessoryText ? accessoryLabel : model.isSelected ? checkmarkView : nil
        if hasIcon {
            iconViewContainer.snp.remakeConstraints { make in
                make.size.equalTo(40)
                make.left.equalToSuperview().inset(16)
                make.centerY.equalTo(customTitleStack)
            }
        }
        customTitleStack.snp.remakeConstraints { make in
            if hasIcon {
                make.left.equalTo(iconViewContainer.snp.right).offset(12)
            } else {
                make.left.equalToSuperview().inset(16)
            }
            if let rightView = rightView {
                make.right.equalTo(rightView.snp.left).offset(-4)
            } else {
                make.right.equalToSuperview().inset(16)
            }
            var topExtraInset: CGFloat = 0
            var bottomExtraInset: CGFloat = 0
            if !isPopover && !(isFirstRow && isLastRow) {
                topExtraInset = isFirstRow ? 4 : 0
                bottomExtraInset = isLastRow ? 4 : 0
            }
            if hasIcon {
                if hasSubtitle {
                    make.top.equalToSuperview().inset(10 + topExtraInset)
                    make.bottom.equalToSuperview().inset(10 + bottomExtraInset)
                } else {
                    make.top.equalToSuperview().inset(19 + topExtraInset)
                    make.bottom.equalToSuperview().inset(19 + bottomExtraInset)
                }
            } else {
                if isPopover {
                    make.top.equalToSuperview().inset(10 + topExtraInset)
                    make.bottom.equalToSuperview().inset(10 + bottomExtraInset)
                } else {
                    make.top.equalToSuperview().inset(14 + topExtraInset)
                    make.bottom.equalToSuperview().inset(14 + bottomExtraInset)
                }
            }
            if hasSubtitle {
                make.height.equalTo(44)
            } else {
                make.height.equalTo(22)
            }
        }

        if hasAccessoryText {
            accessoryLabel.snp.remakeConstraints { make in
                make.right.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
            }
        } else if model.isSelected {
            checkmarkView.snp.remakeConstraints { make in
                make.right.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(20)
            }
        }

        if isPopover {
            highlightBackgroundView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            switch(isFirstRow, isLastRow) {
            case (true, true):
                highlightBackgroundView.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }
            case (true, false):
                highlightBackgroundView.snp.remakeConstraints { make in
                    make.bottom.equalToSuperview()
                    make.top.left.right.equalToSuperview().inset(4)
                }
            case (false, true):
                highlightBackgroundView.snp.remakeConstraints { make in
                    make.top.equalToSuperview()
                    make.bottom.left.right.equalToSuperview().inset(4)
                }
            case (false, false):
                highlightBackgroundView.snp.remakeConstraints { make in
                    make.top.bottom.equalToSuperview()
                    make.left.right.equalToSuperview().inset(4)
                }
            }
        }
    }

    func updateStyle(isPopover: Bool) {
        self.isPopover = isPopover
        if isPopover {
            self.layer.cornerRadius = 0
            self.layer.masksToBounds = false
        } else {
            self.layer.cornerRadius = 10
            var mask: CACornerMask = []
            if self.isFirstRow {
                mask.formUnion([.layerMinXMinYCorner, .layerMaxXMinYCorner])
            }
            if self.isLastRow {
                mask.formUnion([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
            }
            self.layer.maskedCorners = mask
            self.layer.masksToBounds = true
        }
        if let currentModel = currentModel {
            config(currentModel)
        }
    }
}
