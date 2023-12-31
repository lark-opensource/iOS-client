//
//  MoreViewNormalCell.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/9/12.
//

import Foundation
import UIKit
import RxSwift
import UniverseDesignColor
import UniverseDesignBadge
import UniverseDesignSwitch
import UniverseDesignIcon
import SKUIKit
import SKFoundation
import SKResource

public class MoreViewV2NormalCell: UITableViewCell {
    fileprivate let disposeBag: DisposeBag = DisposeBag()

    private lazy var iconImageView = UIImageView()

    fileprivate lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 2
        label.backgroundColor = .clear // 按压效果随背景
        label.textColor = UDColor.textTitle
        return label
    }()

    private(set) lazy var seperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private lazy var redpointView: UDBadge = {
        let view = nameLabel.addBadge(.dot, anchor: .topRight,
                                      offset: .init(width: 8, height: 0))
        return view
    }()
    
    // 红点新的样式，一个icon提示
    private lazy var tipView: OnBoardingLabelView = {
        let view = OnBoardingLabelView(frame: .zero)
        view.useDefaultTip()
        return view
    }()
    
    private lazy var arrowView: UIImageView = {
        let view = UIImageView()
        view.image = BundleResources.SKResource.Common.Icon.icon_right_outlined
        return view
    }()

    fileprivate lazy var containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.backgroundColor = UDColor.bgFloat
        view.layer.cornerRadius = 8
        return view
    }()

    var roundingCorners: CACornerMask {
        get {
            containerView.layer.maskedCorners
        }
        set {
            containerView.layer.maskedCorners = newValue
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
        }
        containerView.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)

        containerView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        containerView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconImageView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().inset(12)
        }
        containerView.addSubview(seperatorView)
        seperatorView.snp.makeConstraints { (make) in
            make.left.equalTo(iconImageView.snp.left)
            make.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        containerView.addSubview(tipView)
        tipView.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel.snp.right).offset(4)
            make.centerY.equalToSuperview()
        }
        containerView.addSubview(arrowView)
        arrowView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.right.equalTo(20)
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        containerView.backgroundColor = UDColor.bgFloat
        seperatorView.isHidden = false
        iconImageView.tintColor = UDColor.iconN1
        nameLabel.textColor = UDColor.textTitle
    }

    func showRedPoint(_ isShow: Bool) {
        nameLabel.badge?.removeFromSuperview()
        redpointView = nameLabel.addBadge(.dot, anchor: .topRight,
                                          offset: .init(width: 8, height: 0))
        redpointView.isHidden = !isShow
    }
    
    func showSubPageArrow(_ isShow: Bool) {
        arrowView.isHidden = !isShow
    }
    
    func showOnBoardingView(_ isShow: Bool) {
        tipView.isHidden = !isShow
    }

    func update(title: String, image: UIImage) {
        nameLabel.text = title
        iconImageView.image = image.withRenderingMode(.alwaysTemplate)
    }

    func update(isHighlighted: Bool) {
        let color = isHighlighted ? UDColor.fillPressed : UDColor.bgFloat
        containerView.backgroundColor = color
    }

    func update(isEnabled: Bool) {
        iconImageView.tintColor = isEnabled ? UDColor.iconN1 : UDColor.iconDisabled
        nameLabel.textColor = isEnabled ? UDColor.textTitle : UDColor.textDisabled
    }
}

public final class MoreViewV2SwitchCell: MoreViewV2NormalCell {
    private class MoreViewV2SwitchLayout {
        static var switchHeight: CGFloat = 30
        static let switchWidth: CGFloat = 50
    }
    lazy var switchView: UDSwitch = {
        let switchView = UDSwitch()
        switchView.behaviourType = .waitCallback
        //默认为选中
        switchView.setOn(true, animated: false)
        switchView.valueWillChanged = { [weak self] value in
            guard let self = self else {
                return
            }
            self.switchViewValueWillChanged(on: value)
        }
        return switchView
    }()
    typealias SwitchOnClosure = (Bool) -> Void
    var switchOnClosure: SwitchOnClosure?

    var needLoading: Bool = true {
        didSet {
            switchView.stopAnimating()
            switchView.behaviourType = needLoading ? .waitCallback : .normal
        }
    }
    
    func switchViewValueWillChanged(on: Bool) {
        DocsLogger.info("UDSwitch valueWillChanged: \(on)")
        switchOnClosure?(on)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    private func setupUI() {
        containerView.addSubview(switchView)
        switchView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
            make.width.equalTo(MoreViewV2SwitchLayout.switchWidth)
            make.height.equalTo(MoreViewV2SwitchLayout.switchHeight)
        }
        nameLabel.snp.makeConstraints { make in
            make.right.lessThanOrEqualTo(switchView.snp.left).inset(12)
        }
    }

    func setCurrentSwitchValue(_ value: Bool) {
        switchView.isEnabled = true
        switchView.setOn(value, animated: true)
    }

    // 带 switch 的 cell 不响应 highlight
    // 对齐安卓，还是要响应的，尽管点击 cell 区域没有作用
//    override func update(isHighlighted: Bool) {}
}


public class MoreViewV2RightLabelCell: MoreViewV2NormalCell {

    lazy var rightLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.backgroundColor = .clear // 按压效果随背景
        label.textColor = UDColor.textCaption
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    private func setupUI() {
        containerView.addSubview(rightLabel)
        rightLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        rightLabel.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel.snp.right).offset(5)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
        }
    }
    func update(rightTitle: String) {
        rightLabel.text = rightTitle
    }
}

public final class MoreViewV2RightIndicatorCell: MoreViewV2RightLabelCell {

    private var indicatorImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    private func setupUI() {
        containerView.addSubview(indicatorImageView)
        rightLabel.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
        }
        indicatorImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
            make.right.equalTo(rightLabel.snp.left).offset(-4)
        }
    }

    func update(rightTitle: String, rightIndicator: UIImage?) {
        rightLabel.text = rightTitle
        indicatorImageView.image = rightIndicator
    }
}

public final class MoreViewV2RightButtonCell: MoreViewV2NormalCell {
    
    public enum Style {
        case right
        case left
    }
    
    lazy var rightButton: UIButton = {
        let label = UIButton()
        label.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        label.setTitleColor(UDColor.textCaption, for: .normal)
        label.backgroundColor = .clear // 按压效果随背景
        label.addTarget(self, action: #selector(clickAction), for: .touchUpInside)
        return label
    }()
    

    typealias ClickOnClosure = (MoreViewV2RightButtonCell.Style) -> Void
    
    var switchOnClosure: ClickOnClosure?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    private func setupUI() {
        containerView.addSubview(rightButton)
        rightButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        rightButton.snp.makeConstraints { make in
            make.left.equalTo(nameLabel.snp.right).offset(5)
            make.width.equalTo(60)
            make.bottom.top.equalToSuperview()
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }
    }

  func update(rightTitle: String) {
      rightButton.setTitle(rightTitle, for: .normal)
  }
    
    
    func updateRightLabel(isEnabled: Bool) {
        rightButton.setTitleColor(isEnabled ? UIColor.ud.primaryContentDefault : UDColor.textDisabled, for: .normal)
    }

  /// 点击按钮的触发方法
    @objc
    func clickAction() {
        self.clickRightView()
    }
    
    func clickRightView() {
        switchOnClosure?(.right)
    }
}
