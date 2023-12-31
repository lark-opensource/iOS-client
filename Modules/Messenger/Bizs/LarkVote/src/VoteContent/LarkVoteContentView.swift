//
//  LarkVoteContentView.swift
//  LarkMessageCore
//
//  Created by bytedance on 2022/3/31.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignShadow

public final class LarkVoteContentProps {
    public var width: CGFloat = 0.0
    public var maxHeight: CGFloat = CGFloat.greatestFiniteMagnitude
    public var isClose: Bool = false
    public var isVoted: Bool = false
    public var voteTitle: String = ""
    public var voteTagInfos: [String] = []
    public var voteResultText: String = ""
    public var voteCellPropsList: [LarkVoteContentCellProps] = []
    public var cellDidClickEvent: ((Int) -> Void)?
    public var leftButtonTitle: String = ""
    public var leftButtonEnabled: Bool = false
    public var leftButtonClickEvent: (() -> Void)?
    public var rightButtonTitle: String = ""
    public var rightButtonEnabled: Bool = false
    public var rightButtonClickEvent: (() -> Void)?
    public var showMoreButtonTitle: String = ""
    public var showMoreButtonHidden: Bool = true
    public var showMoreButtonClickEvent: (() -> Void)?

    public init() {}
    public init(_ props: LarkVoteContentProps) {
        self.width = props.width
        self.maxHeight = props.maxHeight
        self.isClose = props.isClose
        self.isVoted = props.isVoted
        self.voteTitle = props.voteTitle
        self.voteTagInfos = props.voteTagInfos
        self.voteResultText = props.voteResultText
        self.cellDidClickEvent = props.cellDidClickEvent
        self.leftButtonTitle = props.leftButtonTitle
        self.leftButtonEnabled = props.leftButtonEnabled
        self.leftButtonClickEvent = props.leftButtonClickEvent
        self.rightButtonTitle = props.rightButtonTitle
        self.rightButtonEnabled = props.rightButtonEnabled
        self.rightButtonClickEvent = props.rightButtonClickEvent
        self.showMoreButtonTitle = props.showMoreButtonTitle
        self.showMoreButtonHidden = props.showMoreButtonHidden
        self.showMoreButtonClickEvent = props.showMoreButtonClickEvent
        self.voteCellPropsList = []
        for cell in props.voteCellPropsList {
            let cellProps = LarkVoteContentCellProps(cell)
            self.voteCellPropsList.append(cellProps)
        }
    }
}

public final class LarkVoteContentView: UIView, UITableViewDelegate, UITableViewDataSource {

    private enum Cons {
        // content
        static var contentPadding: CGFloat = 4
        // footer
        static var footerTopPadding: CGFloat = 0
        static var footerBottomPadding: CGFloat = 12
        static var footerItemSpacing: CGFloat = 16
        static var footerHorizontalPadding: CGFloat = 12
        static var resultLabelHeight: CGFloat = 18
        static var buttonHeight: CGFloat = 36
        static var resultFont: UIFont { return UIFont.ud.caption1 }
        static var buttonTitleFont: UIFont { return UIFont.ud.body0 }
        static var buttonBorderColor: UIColor = UIColor.ud.primaryPri500
        static var buttonBorderDisabledColor: UIColor = UIColor.ud.lineBorderComponent
        static var buttonTitleNormalColor: UIColor = UIColor.ud.primaryPri500
        static var buttonTitleDisabledColor: UIColor = UIColor.ud.textDisabled
        static var buttonTitleInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static var buttonSpacing: CGFloat = 12
    }

    private static let maxCellCount = 50
    private static let CellIdentifier = "LarkVoteContentCell"
    private var props: LarkVoteContentProps = LarkVoteContentProps()
    // 保存cell的高度
    private var cellHeightCache: [CGFloat] = [CGFloat](repeating: 0, count: maxCellCount)
    private var buttonGroupHeight: CGFloat = 0.0

    public init(_ props: LarkVoteContentProps) {
        super.init(frame: .zero)
        setupUI()
        updateUI(props)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if !maskShadowLayer.frame.equalTo(bottomMaskView.bounds) {
            maskShadowLayer.colors = [UIColor.ud.bgFloat.withAlphaComponent(0).cgColor, UIColor.ud.bgFloat.withAlphaComponent(1).cgColor]
            maskShadowLayer.frame = bottomMaskView.bounds
        }
    }

    // contentHeight
    private var contentHeight: CGFloat {
        var totalHeight: CGFloat = 0
        let count = self.props.voteCellPropsList.count
        for index in 0 ..< count {
            totalHeight += cellHeightCache[index]
        }
        return totalHeight
    }

    private lazy var contentTableView: UITableView = UITableView()

    private lazy var footerContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Cons.footerItemSpacing
        stackView.distribution = .fill
        return stackView
    }()

    private lazy var voteResultLabel: UILabel = {
        let label = UILabel()
        label.font = Cons.resultFont
        label.textColor = UIColor.ud.textTitle
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = Cons.buttonSpacing
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()

    private lazy var leftButton: UIButton = {
        let button = makeCustomButton()
        return button
    }()

    private lazy var rightButton: UIButton = {
        let button = makeCustomButton()
        return button
    }()

    private func makeCustomButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitleColor(Cons.buttonTitleNormalColor, for: .normal)
        button.setTitleColor(Cons.buttonTitleDisabledColor, for: .disabled)
        button.titleLabel?.font = Cons.buttonTitleFont
        button.layer.cornerRadius = 6
        button.layer.borderWidth = 1
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.layer.ud.setBorderColor(Cons.buttonBorderColor)
        return button
    }

    private lazy var maskShadowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.locations = [0, 1]
        layer.startPoint = CGPoint(x: 0.0, y: 0.0)
        layer.endPoint = CGPoint(x: 0.0, y: 1.0)
        return layer
    }()

    // 折叠蒙层
    private lazy var bottomMaskView: UIView = UIView()

    // 展示更多按钮
    private lazy var showMoreButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.ud.bgBody
        button.layer.cornerRadius = 18
        button.layer.ud.setShadow(type: UDShadowType.s2Down)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.addTarget(self, action: #selector(showMoreButtonDidClick), for: .touchUpInside)
        return button
    }()

    private func updateContentFrame(oldProps: LarkVoteContentProps, newProps: LarkVoteContentProps) {
        guard newProps.voteCellPropsList.count <= LarkVoteContentView.maxCellCount else {
            return
        }
        var totalCellHeight = 0.0
        for idx in 0 ..< newProps.voteCellPropsList.count {
            var needUpdateCellHeight = false
            if idx >= oldProps.voteCellPropsList.count {
                needUpdateCellHeight = true
            } else {
                let oldCellProps = oldProps.voteCellPropsList[idx]
                let newCellProps = newProps.voteCellPropsList[idx]
                needUpdateCellHeight = (oldCellProps.itemTitle != newCellProps.itemTitle)
                || (oldCellProps.showResult != newCellProps.showResult)
                || (oldCellProps.avatarKeyList.isEmpty != newCellProps.avatarKeyList.isEmpty)
                || (oldProps.width != newProps.width)
            }
            // 计算并保存高度结果
            if needUpdateCellHeight {
                let height = LarkVoteContentCell.calculateCellHeight(cellProps: props.voteCellPropsList[idx], cellWidth: props.width)
                self.cellHeightCache[idx] = height
            }
            totalCellHeight += self.cellHeightCache[idx]
        }
        contentTableView.frame = CGRect(x: 0, y: 0, width: newProps.width, height: totalCellHeight)
    }

    private func updateFooterFrame(oldProps: LarkVoteContentProps, newProps: LarkVoteContentProps) {
        // 按钮标题发生变化可能引起按钮排列方式改变
        let voteResultH = newProps.voteResultText.isEmpty ? 0.0 : Cons.resultLabelHeight
        let voteResultW = newProps.width - 2 * Cons.footerHorizontalPadding
        voteResultLabel.frame = CGRect(x: 0, y: 0, width: voteResultW, height: voteResultH)

        // 更新按钮布局
        if (oldProps.leftButtonTitle != newProps.leftButtonTitle)
            || (oldProps.rightButtonTitle != newProps.rightButtonTitle)
            || (oldProps.width != newProps.width) {
            buttonGroupHeight = LarkVoteContentView.calcuateButtonHeight(props: self.props, width: self.props.width)
            buttonStackView.axis = self.buttonGroupHeight <= Cons.buttonHeight ? NSLayoutConstraint.Axis.horizontal : NSLayoutConstraint.Axis.vertical
        }
        let spacingHeight = voteResultH != 0.0 && self.buttonGroupHeight != 0.0 ? Cons.footerItemSpacing : 0.0
        // footer frame
        let footerContainerX = Cons.footerHorizontalPadding
        let footerContainerY = self.contentTableView.frame.maxY + Cons.footerTopPadding
        let footerContainerW = self.props.width - 2 * Cons.footerHorizontalPadding
        let footerContainerH = self.buttonGroupHeight + voteResultH + spacingHeight
        self.footerContainer.frame = CGRect(x: footerContainerX, y: footerContainerY, width: footerContainerW, height: footerContainerH)
    }

    public func updateUI(_ props: LarkVoteContentProps) {
        let oldProps = self.props
        self.props = LarkVoteContentProps(props)
        let newProps = self.props
        // update frame
        updateContentFrame(oldProps: oldProps, newProps: newProps)
        updateFooterFrame(oldProps: oldProps, newProps: newProps)
        voteResultLabel.text = newProps.voteResultText
        voteResultLabel.isHidden = !(props.isClose || props.isVoted)
        // button
        leftButton.isHidden = props.leftButtonTitle.isEmpty
        leftButton.isEnabled = props.leftButtonEnabled
        leftButton.layer.ud.setBorderColor(props.leftButtonEnabled ? Cons.buttonBorderColor : Cons.buttonBorderDisabledColor)
        let letButtonStatus = leftButton.isEnabled ? UIControl.State.normal : UIControl.State.disabled
        leftButton.setTitle(props.leftButtonTitle, for: letButtonStatus)
        rightButton.isHidden = props.rightButtonTitle.isEmpty
        rightButton.isEnabled = props.rightButtonEnabled
        rightButton.layer.ud.setBorderColor(props.rightButtonEnabled ? Cons.buttonBorderColor : Cons.buttonBorderDisabledColor)
        let rightButtonStatus = rightButton.isEnabled ? UIControl.State.normal : UIControl.State.disabled
        rightButton.setTitle(props.rightButtonTitle, for: rightButtonStatus)
        buttonStackView.isHidden = leftButton.isHidden && rightButton.isHidden
        showMoreButton.setTitle(props.showMoreButtonTitle, for: .normal)
        bottomMaskView.isHidden = props.showMoreButtonHidden
        self.contentTableView.reloadData()
    }

    // MARK: setupUI
    private func setupUI() {
        self.clipsToBounds = true
        addSubview(contentTableView)
        addSubview(footerContainer)
        contentTableView.register(LarkVoteContentCell.self, forCellReuseIdentifier: LarkVoteContentView.CellIdentifier)
        contentTableView.backgroundColor = UIColor.ud.bgFloat
        contentTableView.isScrollEnabled = false
        contentTableView.dataSource = self
        contentTableView.delegate = self
        contentTableView.separatorStyle = .none
        // footer
        footerContainer.addArrangedSubview(voteResultLabel)
        footerContainer.addArrangedSubview(buttonStackView)
        leftButton.addTarget(self, action: #selector(leftButtonDidClick), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(rightButtonDidClick), for: .touchUpInside)
        buttonStackView.addArrangedSubview(leftButton)
        buttonStackView.addArrangedSubview(rightButton)
        // mask
        setupMaskViewUI()
    }

    private func setupMaskViewUI() {
        bottomMaskView.layer.addSublayer(self.maskShadowLayer)
        bottomMaskView.addSubview(showMoreButton)
        addSubview(bottomMaskView)
        showMoreButton.snp.makeConstraints { make in
            make.height.equalTo(36)
            make.width.equalTo(142)
            make.bottom.equalTo(-36)
            make.centerX.equalToSuperview()
        }
        bottomMaskView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(72)
        }
    }

    @objc
    private func leftButtonDidClick() {
        if let block = props.leftButtonClickEvent {
            block()
        }
    }

    @objc
    private func rightButtonDidClick() {
        if let block = props.rightButtonClickEvent {
            block()
        }
    }

    @objc
    private func showMoreButtonDidClick() {
        if let block = props.showMoreButtonClickEvent {
            block()
        }
    }

    // MARK: TableView Delegate
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if props.showMoreButtonHidden {
            return props.voteCellPropsList.count
        } else {
            var totalHeight = 0.0
            let contentMaxHeight = props.maxHeight - footerContainer.frame.height
            for (index, cellHeight) in cellHeightCache.enumerated() {
                totalHeight += cellHeight
                if totalHeight >= props.maxHeight {
                    return index + 1
                }
            }
            return props.voteCellPropsList.count
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < self.props.voteCellPropsList.count else {
            return UITableViewCell()
        }
        if let cell = tableView.dequeueReusableCell(withIdentifier: LarkVoteContentView.CellIdentifier, for: indexPath) as? LarkVoteContentCell {
            var cellProps = self.props.voteCellPropsList[indexPath.row]
            cell.updateItem(cellProps, cellWidth: props.width)
            return cell
        }
        return UITableViewCell()
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < self.props.voteCellPropsList.count else { return 0.0 }
        let height = self.cellHeightCache[indexPath.row]
        return height
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        let cellProps = self.props.voteCellPropsList[indexPath.row]
        if let block = props.cellDidClickEvent {
            block(cellProps.identifier)
        }
    }

    // MARK: 计算整体高度
    public static func calculateContentHeight(props: LarkVoteContentProps) -> CGFloat {

        let width = props.width
        // content
        var contentHeight = Cons.contentPadding
        for cellProps in props.voteCellPropsList {
            var cellHeight = LarkVoteContentCell.calculateCellHeight(cellProps: cellProps, cellWidth: width)
            contentHeight += cellHeight
        }

        // footer
        let voteResultHeight = props.voteResultText.isEmpty ? 0.0 : Cons.resultLabelHeight
        let buttonHeight = Self.calcuateButtonHeight(props: props, width: width)
        let spacingHeight = (voteResultHeight != 0.0 && buttonHeight != 0.0) ? Cons.footerItemSpacing : 0.0
        let footerHeight = Cons.footerTopPadding + Cons.footerBottomPadding + voteResultHeight + spacingHeight + buttonHeight
        return contentHeight + footerHeight
    }

    // 计算Button高度,长度过长时分两行显示
    private static func calcuateButtonHeight(props: LarkVoteContentProps, width: CGFloat) -> CGFloat {
        if props.leftButtonTitle.isEmpty && props.rightButtonTitle.isEmpty {
            return 0.0
        } else if props.leftButtonTitle.isEmpty || props.rightButtonTitle.isEmpty {
            return Cons.buttonHeight
        }
        var totalHeight = 0.0
        var buttonWidth = (width - 2 * Cons.footerHorizontalPadding - Cons.buttonSpacing) / 2
        var buttonTitleMaxWidth = buttonWidth - Cons.buttonTitleInset.left - Cons.buttonTitleInset.right
        let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        var leftButtonTitleWidth = LarkVoteUtils.calculateLabelSize(text: props.leftButtonTitle, font: Cons.buttonTitleFont, size: size).width
        var rightButtonTitleWidth = LarkVoteUtils.calculateLabelSize(text: props.rightButtonTitle, font: Cons.buttonTitleFont, size: size).width
        if leftButtonTitleWidth > buttonTitleMaxWidth || rightButtonTitleWidth > buttonTitleMaxWidth {
            totalHeight = 2 * Cons.buttonHeight + Cons.buttonSpacing
        } else {
            totalHeight = Cons.buttonHeight
        }
        return totalHeight
    }
}
