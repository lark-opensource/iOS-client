//
//  DraggableTitleView.swift
//  SKCommon
//
//  Created by huayufan on 2021/5/19.
//  


import UIKit
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignShadow
import UniverseDesignIcon
import UniverseDesignMenu

public enum DraggableTitleViewType {
    case dragTopLine
    case closeButton
}

open class DraggableTitleView: UIView {

    public var closeButtonClickHandler: (() -> Void)?
    
    weak var delegate: DraggableTitleDelegate?

    /// 开启免打扰
    public var muteButtonClickHandler: ((Bool) -> Void)?
    
    /// 一键已读
    public var cleanButtonClickHandler: ((Bool) -> Void)?
    
    /// moreButton 展示的fg
    private var showMoreButton: Bool = false
    
    public let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        label.textColor = UDColor.textTitle
        return label
    }()

    private let topLine: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineBorderCard
        view.layer.cornerRadius = 2
        return view
    }()
    
    private let closeButton: UIButton = {
        let view = UIButton()
        view.setImage(UDIcon.closeOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        view.tintColor = UDColor.iconN1
        return view
    }()
    
    private let moreButton: UIButton = {
        let view = UIButton()
        view.setImage(UDIcon.getIconByKey(.moreOutlined, iconColor: UDColor.iconN1, size: CGSize(width: 20, height: 20)), for: .normal)
        view.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        return view
    }()

    private lazy var muteToggle: FeedMuteToggleView = {
        let view = FeedMuteToggleView()
        view.toggleAction = { [weak self] in
            let isMute = ($0 == .mute)
            self?.muteButtonClickHandler?(isMute)
        }
        view.isHidden = true
        return view
    }()

    var bottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    open var viewType: DraggableTitleViewType = .dragTopLine {
        didSet {
            updateLayout()
        }
    }
    
    public init(showMoreButton: Bool = false) {
        self.showMoreButton = showMoreButton
        super.init(frame: .zero)
        setupInit()
        updateLayout()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
        updateLayout()
    }    

    func setupInit() {
        backgroundColor = UDColor.bgBody
        topLine.docs.addStandardLift()
        addSubview(titleLabel)
        addSubview(topLine)
        addSubview(bottomLine)
        addSubview(closeButton)
        if showMoreButton {
            addSubview(moreButton)
            moreButton.addTarget(self, action: #selector(moreButtonClick), for: .touchUpInside)
        }
        closeButton.addTarget(self, action: #selector(closeButtonClick), for: .touchUpInside)
    }
    
    func setupLayout() {
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(26)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(24)
        }
        topLine.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(8)
            make.centerX.equalToSuperview()
            make.height.equalTo(4)
            make.width.equalTo(40)
        }
        bottomLine.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    func updateLayout() {
        titleLabel.snp.remakeConstraints { (make) in
            switch self.viewType {
            case .dragTopLine:
                make.top.equalToSuperview().offset(26)
                make.left.right.equalToSuperview().inset(16)
            case .closeButton:
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().inset(16 + 24 + 16)
                make.left.equalTo(closeButton.snp.right).offset(16)
            }
            make.height.equalTo(24)
        }
        switch viewType {
        case .dragTopLine:
            topLine.isHidden = false
            closeButton.isHidden = true
            topLine.snp.remakeConstraints { (make) in
                make.top.equalToSuperview().inset(8)
                make.centerX.equalToSuperview()
                make.height.equalTo(4)
                make.width.equalTo(40)
            }
        case .closeButton:
            topLine.isHidden = true
            closeButton.isHidden = false
            closeButton.snp.remakeConstraints { make in
                make.width.height.equalTo(24)
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(16)
            }
        }
        bottomLine.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        if moreButton.superview != nil {
            moreButton.snp.remakeConstraints { make in
                make.centerY.equalTo(titleLabel)
                make.width.height.equalTo(20)
                make.trailing.equalToSuperview().inset(12)
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func closeButtonClick() {
        self.closeButtonClickHandler?()
    }
    
    @objc
    private func moreButtonClick() {
        guard let dele = delegate else {
            DocsLogger.error("click card more button failed, DraggableTitleView.delegate is nil")
            return
        }
        dele.didClickMoreButton(sourceView: moreButton, operation: muteToggle.operation)
    }
}

extension DraggableTitleView {
    
    public func setTitle(_ title: String) {
        titleLabel.text = title
    }
    
    public func showDefaultShadowColor() {
        layer.cornerRadius = 8
        layer.ud.setShadow(type: .s4Up)
    }

    public func setMuteToggleClickable(_ clickable: Bool) {
        muteToggle.isUserInteractionEnabled = clickable
    }

    public func setMuteState(_ mute: Bool) {
        let operation: FeedMuteToggleView.Operation = mute ? .remind : .mute
        muteToggle.setOperation(operation)
    }

    public func setMuteToggleHidden(_ isHidden: Bool) {
        muteToggle.isHidden = isHidden
    }
    
    public func setMoreButtonHidden(_ isHidden: Bool) {
        moreButton.isHidden = isHidden
    }
}

public final class SKDraggableTitleView: UIStackView {
    
    // 设置 isHidden 来控制隐藏和可见
    public lazy var topLine: UIView = {
        let view = UIView()
        
        let line = UIView()
        line.backgroundColor = UDColor.lineBorderCard
        line.layer.cornerRadius = 2
        line.docs.addStandardLift()
        
        view.addSubview(line)
        line.snp.makeConstraints { make in
            make.bottom.centerX.equalToSuperview()
            make.height.equalTo(4)
            make.width.equalTo(40)
        }
        
        return view
    }()
        
    // 设置 isHidden 来控制隐藏和可见
    public lazy var leftButton: UIButton = {
        let view = UIButton()
        view.setImage(UDIcon.closeSmallOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        view.tintColor = UDColor.iconN1
        return view
    }()
    
    // 设置 isHidden 来控制隐藏和可见
    public lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.textColor = UDColor.textTitle
        view.font = .systemFont(ofSize: 17, weight: .medium)
        view.lineBreakMode = .byTruncatingTail
        return view
    }()
    
    // 设置 isHidden 来控制隐藏和可见
    public lazy var rightButton: UIButton = {
        let view = UIButton()
        view.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        view.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return view
    }()
    
    // 设置 isHidden 来控制隐藏和可见
    public lazy var bottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    public lazy var navigationBar: UIView = {
        let view = UIView()
        
        view.addSubview(leftButton)
        view.addSubview(titleLabel)
        view.addSubview(rightButton)
        
        leftButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        leftButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
        }
        
        rightButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        rightButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.greaterThanOrEqualTo(leftButton.snp.right).offset(16)
            make.right.lessThanOrEqualTo(rightButton.snp.left).offset(-16)
        }
        
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.axis = .vertical
        self.alignment = .center
        
        addArrangedSubview(topLine)
        addArrangedSubview(navigationBar)
        addArrangedSubview(bottomLine)
        
        topLine.snp.makeConstraints { (make) in
            make.height.equalTo(12)
        }
        
        navigationBar.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.width.equalToSuperview()
        }
        
        bottomLine.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.width.equalToSuperview()
        }
    }
}

// MARK: - DraggableTitleDelegate
protocol DraggableTitleDelegate: AnyObject {
    func didClickMoreButton(sourceView: UIView, operation: FeedMuteToggleView.Operation)
}
