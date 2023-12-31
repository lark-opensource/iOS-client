//
//  BTOptionMorePanel.swift
//  SKBitable
//
//  Created by zoujie on 2021/10/19.
//  


import Foundation
import SKUIKit
import SnapKit
import SKBrowser
import SKResource
import EENavigator
import UniverseDesignIcon
import UniverseDesignColor
import UIKit

public protocol BTOptionMorePanelDelegate: AnyObject {
    func showConfirmActionPanel(model: BTCapsuleModel)
    func showEditorPanel(model: BTCapsuleModel)
}

public final class BTOptionMorePanel: SKPanelController {
    public weak var delegate: BTOptionMorePanelDelegate?

    private lazy var closeButton = UIButton().construct { it in
        it.setImage(UDIcon.closeSmallOutlined, withColorsForStates: [
            (UDColor.iconN1, .normal),
            (UDColor.iconN3, .highlighted),
            (UDColor.iconDisabled, .disabled)
        ])
        it.hitTestEdgeInsets = UIEdgeInsets(edges: -10)
        it.addTarget(self, action: #selector(didClickClose), for: .touchUpInside)
    }

    private var titleView: BTOptionItemView

    private lazy var headerView: BTOptionMenuHeaderView = {
        let view = BTOptionMenuHeaderView()
        view.backgroundColor = .clear
        view.setLeftView(closeButton)
        view.setTitleView(titleView)
        return view
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 6
        view.clipsToBounds = true

        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .fill
        view.spacing = 0
        return view
    }()

    private lazy var editorButton = OptionMenuButton().construct { it in
        it.setIcon(image: UDIcon.getIconByKey(.ccmRenameOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UDColor.iconN1))
        it.setTitleString(attributedText: NSAttributedString(string: BundleI18n.SKResource.Bitable_Common_ButtonEdit))
        it.addTarget(self, action: #selector(didClickEditor), for: .touchUpInside)
        it.layer.cornerRadius = 8
        it.backgroundColor = UDColor.bgFloatOverlay
    }

    private lazy var deleteButton = OptionMenuButton().construct { it in
        it.setIcon(image: UDIcon.getIconByKey(.deleteTrashOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UDColor.iconN1))
        it.setTitleString(attributedText: NSAttributedString(string: BundleI18n.SKResource.Bitable_Common_ButtonDelete))
        it.addTarget(self, action: #selector(didClickDelete), for: .touchUpInside)
        it.layer.cornerRadius = 8
        it.backgroundColor = UDColor.bgFloatOverlay
    }

    private var model: BTCapsuleModel


    public init(model: BTCapsuleModel) {
        self.model = model
        self.titleView = BTOptionItemView(model: model, labelEdges: UIEdgeInsets(top: 2,
                                                                                 left: 12,
                                                                                 bottom: 2,
                                                                                 right: 12))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func setupUI() {
        super.setupUI()

        containerView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(48)
        }

        containerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(16)
        }

        stackView.addArrangedSubview(editorButton)
        stackView.addArrangedSubview(deleteButton)

        editorButton.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(deleteButton.snp.top).offset(-16)
            make.height.equalTo(48)
        }

        deleteButton.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(editorButton.snp.bottom).offset(16)
            make.height.equalTo(48)
        }
    }

    @objc
    private func didClickClose() {
        self.dismiss(animated: true)
    }

    @objc
    private func didClickEditor() {
        let model = model
        self.dismiss(animated: true) { [weak self] in
            self?.delegate?.showEditorPanel(model: model)
        }
    }

    @objc
    private func didClickDelete() {
        self.dismiss(animated: true)
        delegate?.showConfirmActionPanel(model: model)
    }
}

private final class OptionMenuButton: UIButton {
    private let iconView = UIImageView()

    private let label = UILabel().construct { it in
        it.textColor = UDColor.textTitle
    }

    init() {
        super.init(frame: .zero)
        setUpUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUpUI() {
        addSubview(iconView)
        addSubview(label)

        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().offset(-14)
            make.right.equalTo(label.snp.left).offset(-12)
            make.width.height.equalTo(20)
        }

        label.snp.makeConstraints { make in
            make.centerY.equalTo(iconView)
            make.left.equalTo(iconView.snp.right).offset(-12)
        }
    }

    func setTitleString(attributedText: NSAttributedString) {
        label.attributedText = attributedText
    }

    func setIcon(image: UIImage) {
        self.iconView.image = image
    }
}

public final class BTOptionMenuHeaderView: UIView {
    private lazy var leftView: UIView = UIView()
    private lazy var rightView: UIView = UIView()

    private lazy var titleView = UIView()

    private lazy var bottomSeparator = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
    }

    public override init(frame: CGRect) {
        super.init(frame: .zero)
        // 背景颜色设置在 header 上是为了照顾 containerView 存在向上阴影的情形，在这个场景下 containerView 不能设置圆角，所以圆角只能设置在 header 上，那颜色也只能设置在 header 上
        // 如果把阴影放到 header 上也不是不行，但是外面可能需要显式将阴影去除，不太优雅
        // 如果业务方需要 header 有不同的颜色，可以在 init 之后单独设置 backgroundColor
        backgroundColor = UDColor.bgBody
        layer.cornerRadius = 12
        layer.maskedCorners = .top

        addSubview(leftView)
        addSubview(rightView)
        addSubview(titleView)
        addSubview(bottomSeparator)

        leftView.snp.makeConstraints { make in
            make.leading.equalTo(safeAreaLayoutGuide.snp.leading).inset(16)
            make.top.equalToSuperview().inset(14)
            make.height.equalTo(24)
            make.width.greaterThanOrEqualTo(24)
        }

        rightView.snp.makeConstraints { make in
            make.trailing.equalTo(safeAreaLayoutGuide.snp.trailing).inset(16)
            make.top.equalToSuperview().inset(14)
            make.height.equalTo(24)
            make.width.greaterThanOrEqualTo(24)
        }

        titleView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(leftView)
            make.height.greaterThanOrEqualTo(24)
            make.height.lessThanOrEqualTo(48)
            make.leading.greaterThanOrEqualTo(leftView.snp.trailing).offset(16)
            make.trailing.lessThanOrEqualTo(rightView.snp.trailing).inset(16)
        }

        bottomSeparator.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 48)
    }

    public var titleCenterY: ConstraintItem {
        titleView.snp.centerY
    }

    public func setTitleView(_ view: UIView) {
        titleView.addSubview(view)

        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public func setLeftView(_ view: UIView) {
        leftView.addSubview(view)

        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public func setRightView(_ view: UIView) {
        rightView.addSubview(view)

        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public func setLeftViewVisible(visible: Bool) {
        leftView.isHidden = !visible
        leftView.snp.updateConstraints { make in
            make.width.greaterThanOrEqualTo(visible ? 24 : 0)
        }
    }

    public func setRightViewVisible(visible: Bool) {
        rightView.isHidden = !visible
        rightView.snp.updateConstraints { make in
            make.width.greaterThanOrEqualTo(visible ? 24 : 0)
        }
    }

    public func setBottomSeparatorVisible(visible: Bool) {
        bottomSeparator.isHidden = !visible
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
