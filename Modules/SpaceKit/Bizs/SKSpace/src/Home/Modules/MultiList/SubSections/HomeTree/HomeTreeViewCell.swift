//
//  HomeTreeViewCell.swift
//  SKSpace
//
//  Created by majie.7 on 2023/5/18.
//

import Foundation
import SKWorkspace
import RxSwift
import UniverseDesignColor
import UniverseDesignIcon
import SKUIKit


class HomeTreeViewCell: SKCustomSlideCollectionViewCell {

    private(set) var reuseBag: DisposeBag {
        get { content.reuseBag }
        set { content.reuseBag = newValue }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        reuseBag = DisposeBag()
        content.resuseHandler()
    }

    let content = NewTreeNodeView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func _setupUI() {
        
        containerView.addSubview(content)
        content.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func updateModel(_ node: TreeNode) {
        content.updateModel(node, offset: 0.0)
    }
    
    func configHomeHoverItem(provider: @escaping NewTreeNodeView.HomeHoverItemProvider) {
        content.configHoverItem(provider: provider)
    }
}

class HomeTreeViewEmptyCell: UICollectionViewCell {
    var indentWidth = 12
    var level = 1
    let titleLabel = UILabel()
    let segmentLine = UIView()
    let stateBoardView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.masksToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        titleLabel.textColor = UDColor.textCaption
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textAlignment = .left
        segmentLine.backgroundColor = UDColor.lineDividerDefault
        self.contentView.backgroundColor = UDColor.bgBody
        
        contentView.addSubview(stateBoardView)
        stateBoardView.addSubview(titleLabel)
        stateBoardView.addSubview(segmentLine)
        
        stateBoardView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        segmentLine.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.left).offset(-16)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    func update(title: String,
                level: Int) {
        self.level = level
        titleLabel.text = title
        let offsetSize = CGFloat(level * indentWidth + 16)
        titleLabel.snp.updateConstraints { (make) in
            make.left.equalToSuperview().offset(offsetSize)
        }
    }
    func updateLayout(offset: CGFloat) {
        let indentCGFloatWidth = CGFloat(level * indentWidth + 16)
        titleLabel.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(indentCGFloatWidth + offset)
        }
    }
}

class HomeTreeSpecialClickCell: UICollectionViewCell {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textCaption
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = .left
        return label
    }()
    
    lazy var button: HomeTreeHeaderCustomUIControl = {
        let button = HomeTreeHeaderCustomUIControl()
        button.backgroundColor = .clear
        button.layer.cornerRadius = 4
        button.docs.addHighlight(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), radius: 4)
        return button
    }()
    
    var reuseBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        reuseBag = DisposeBag()
    }
    
    private func setupUI() {
        contentView.backgroundColor = UDColor.bgBody
        contentView.addSubview(button)
        button.addSubview(titleLabel)
        
        button.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-4)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(6)
            make.right.equalToSuperview().offset(-6)
            make.centerY.equalToSuperview()
        }
    }
    
    func update(title: String) {
        titleLabel.text = title
    }
}


class HomeTreeHeaderView: UICollectionReusableView {
    private(set) var reuseBag = DisposeBag()

    override func prepareForReuse() {
        super.prepareForReuse()
        reuseBag = DisposeBag()
    }
    
    lazy var backgroundView: HomeTreeHeaderCustomUIControl = {
        let view = HomeTreeHeaderCustomUIControl()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 4
        view.docs.addStandardHighlight()
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = UDColor.textTitle
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    
    private lazy var clipButton: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.downBoldOutlined.ud.withTintColor(UDColor.iconN2)
        return view
    }()
    
    public lazy var createButton: NewTreeNodeCustomButton = {
        let button = NewTreeNodeCustomButton()
        button.isHidden = true
        button.adjustsImageWhenDisabled = false
        button.layer.cornerRadius = 4
        button.docs.addHighlight(with: .init(top: -4, left: -4, bottom: -4, right: -4), radius: 8)
        button.touchStateChangedHandler = { [weak button] isHighlight in
            button?.backgroundColor = isHighlight ? UDColor.N200 : .clear
        }
        return button
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody
        addSubview(backgroundView)
        backgroundView.addSubview(titleLabel)
        backgroundView.addSubview(clipButton)
        addSubview(createButton)
        
        backgroundView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.top.bottom.equalToSuperview().inset(8)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(6)
        }
        
        clipButton.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(6)
            make.right.equalToSuperview().inset(6)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
        }
        
        let addIcon = UDIcon.getIconByKey(.addOutlined, iconColor: UDColor.iconN2, size: CGSize(width: 20, height: 20))
        createButton.setImage(addIcon, for: .normal)
        createButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
    }
    
    func update(title: String) {
        titleLabel.text = title
    }
    
    func updateState(isExpand: Bool) {
        if isExpand {
            clipButton.image = UDIcon.downBoldOutlined.ud.withTintColor(UDColor.iconN2)
        } else {
            clipButton.image = UDIcon.rightBoldOutlined.ud.withTintColor(UDColor.iconN2)
        }
    }
}

class HomeTreeHeaderCustomUIControl: UIControl {
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.backgroundColor = UDColor.fillPressed
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.backgroundColor = .clear
                }
            }
        }
    }
}

class HomeTreeHeaderViewCell: UICollectionViewCell {
    private(set) var reuseBag = DisposeBag()

    override func prepareForReuse() {
        super.prepareForReuse()
        reuseBag = DisposeBag()
    }
    
    lazy var containerView: HomeTreeHeaderCustomUIControl = {
        let view = HomeTreeHeaderCustomUIControl()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 4
        view.docs.addStandardHighlight()
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = UDColor.textTitle
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    private lazy var clipButton: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.downBoldOutlined.ud.withTintColor(UDColor.iconN2)
        return view
    }()
    
    public lazy var createButton: NewTreeNodeCustomButton = {
        let button = NewTreeNodeCustomButton()
        button.isHidden = true
        button.adjustsImageWhenDisabled = false
        button.layer.cornerRadius = 4
        button.docs.addHighlight(with: .init(top: -4, left: -4, bottom: -4, right: -4), radius: 8)
        button.touchStateChangedHandler = { [weak button] isHighlight in
            button?.backgroundColor = isHighlight ? UDColor.N200 : .clear
        }
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(clipButton)
        addSubview(createButton)
        
        containerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.top.bottom.equalToSuperview().inset(8)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(6)
        }
        
        clipButton.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(6)
            make.right.equalToSuperview().inset(6)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
        }
        
        let addIcon = UDIcon.getIconByKey(.addOutlined, iconColor: UDColor.iconN2, size: CGSize(width: 20, height: 20))
        createButton.setImage(addIcon, for: .normal)
        createButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
    }
    
    func update(title: String) {
        titleLabel.text = title
    }
    
    func updateState(isExpand: Bool, scene: HomeTreeSectionScene) {
        clipButton.accessibilityIdentifier = "home.tree.\(scene).clip.button"
        clipButton.accessibilityLabel = "status: \(isExpand)"
        if isExpand {
            clipButton.image = UDIcon.downBoldOutlined.ud.withTintColor(UDColor.iconN2)
        } else {
            clipButton.image = UDIcon.rightBoldOutlined.ud.withTintColor(UDColor.iconN2)
        }
    }
}
