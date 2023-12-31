//
//  TreeTableViewCellV2.swift
//  SKWiki
//
//  Created by 邱沛 on 2021/3/23.
//
// swiftlint:disable file_length

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Lottie
import SKCommon
import SKUIKit
import SKResource
import SKFoundation
import UniverseDesignColor
import UniverseDesignIcon
import SpaceInterface
import SKWorkspace

class TreeHeaderView: UITableViewHeaderFooterView {
    private var node: TreeNode = .default
    private let bag = DisposeBag()
    private(set) var reuseBag = DisposeBag()
    private(set) lazy var titleButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(UDColor.textTitle, for: .normal)
        button.contentHorizontalAlignment = .left
        button.contentVerticalAlignment = .center
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.backgroundColor = .clear
        return button
    }()
    
    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    private(set) lazy var stateButton: UIButton = {
        let button = UIButton()
        button.adjustsImageWhenDisabled = false
        button.docs.addHighlight(with: .init(top: -4, left: -4, bottom: -4, right: -4), radius: 8)
        return button
    }()
    let nodeLoadingView: LOTAnimationView = {
        let loadingView = AnimationViews.wikiTreeNodeAnimation
        loadingView.isHidden = true
        loadingView.backgroundColor = .clear
        return loadingView
    }()
    private lazy var stateBoardView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var accessoryButton: UIButton = {
        let accessoryButton = UIButton()
        return accessoryButton
    }()
    
    private(set) lazy var segmentLine: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        view.isHidden = true
        return view
    }()

    let clickStateInput = PublishRelay<Void>()
    var clickStateSignal: Signal<Void> {
        clickStateInput.asSignal()
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
        docs.addStandardHover()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        //在横屏下contentView留有safeArea，没有撑满HeaderFooterView，会导致两侧有灰色块
        backgroundView = UIView().construct { it in
            it.backgroundColor = UDColor.bgBody
        }
        contentView.backgroundColor = UDColor.bgBody
        contentView.addSubview(stateBoardView)
        contentView.addSubview(titleButton)
        contentView.addSubview(segmentLine)
        titleButton.addSubview(stateButton)
        titleButton.addSubview(accessoryButton)
        stateBoardView.addSubview(titleLabel)
        stateBoardView.addSubview(nodeLoadingView)
        
        stateBoardView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
            make.top.bottom.equalToSuperview()
        }
        
        titleButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        segmentLine.snp.makeConstraints { (make) in
            make.left.right.equalTo(stateBoardView)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(4)
            make.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualTo(accessoryButton.snp.left).offset(-8)
        }

        accessoryButton.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.right.equalTo(stateBoardView.snp.right).inset(16)
        }
        
        stateButton.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(4)
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.width.height.equalTo(12)
        }
        
        nodeLoadingView.snp.makeConstraints { make in
            make.height.width.equalTo(14)
            make.center.equalTo(stateButton.snp.center)
        }

        stateButton.rx.tap.bind(to: clickStateInput).disposed(by: bag)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        reuseBag = DisposeBag()
    }
    
    func update(node: TreeNode) {
        reuseBag = DisposeBag()
        self.node = node
        nodeLoadingView.isHidden = true
        nodeLoadingView.stop()
        stateButton.isHidden = false
        stateButton.isEnabled = true
        titleButton.isEnabled = true
        if node.isSelected {
            stateBoardView.backgroundColor = UDColor.fillSelected
        } else {
            stateBoardView.backgroundColor = .clear
        }

        handleHomeChild()
        if !node.isEnabled {
            stateButton.isEnabled = false
            titleButton.isEnabled = false
            stateButton.setImage(stateButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
            stateButton.tintColor = UDColor.iconN3
            let text = NSAttributedString(string: node.title, attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                 .foregroundColor: UDColor.textDisabled])
            titleLabel.attributedText = text
        }

        setupAccessoryButton(item: node.accessoryItem)
    }
    
    private func handleHomeChild() {
        let topEdge: CGFloat = (50 - 24) / 2
        let leftEdge: CGFloat = 24
        stateButton.hitTestEdgeInsets = UIEdgeInsets(top: -topEdge, left: -24, bottom: -topEdge, right: 0)
        titleButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: leftEdge, bottom: 0, right: 0)
        let text = NSAttributedString(string: node.title, attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                       .foregroundColor: UDColor.textTitle])
        titleLabel.attributedText = text
        
        // icon状态
        stateButton.isHidden = false
        segmentLine.isHidden = false
        if node.isOpened {
            let icon = UDIcon.downBoldOutlined
            stateButton.setImage(icon.ud.withTintColor(UDColor.iconN2), for: .normal)
            segmentLine.isHidden = true
        } else {
            let icon = UDIcon.rightBoldOutlined
            stateButton.setImage(icon.ud.withTintColor(UDColor.iconN2), for: .normal)
            segmentLine.isHidden = false
        }
        
        if node.isSelected {
            segmentLine.isHidden = true
        }
    }

    private func setupAccessoryButton(item: TreeNodeAccessoryItem?) {
        guard let item = item else {
            accessoryButton.isHidden = true
            return
        }
        accessoryButton.isHidden = false
        accessoryButton.setImage(item.image(), for: .normal)
        accessoryButton.rx.tap.asSignal()
            .emit(onNext: { [weak self] in
                guard let self = self else { return }
                item.handler(self.accessoryButton)
            })
            .disposed(by: reuseBag)
    }
}

class TreeTableViewCell: SKCustomSlideTableViewCell {

    private(set) var reuseBag: DisposeBag {
        get { content.reuseBag }
        set { content.reuseBag = newValue }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        reuseBag = DisposeBag()
    }

    let content = TreeNodeView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _setupUI()
        self.containerView.docs.addStandardHover()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func _setupUI() {
        containerView.addSubview(content)
        content.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func updateModel(_ node: TreeNode, offset: CGFloat) {
        content.updateModel(node, offset: offset)
    }
    
    func updateLayout(offset: CGFloat) {
        content.updateLayout(offset: offset)
    }

    func autoLeftSwipe() {
        forceShowSlideActions()
    }
}

class TreeTableViewEmptyCell: UITableViewCell {
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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
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
                level: Int,
                offset: CGFloat) {
        self.level = level
        titleLabel.text = title
        let offsetSize = CGFloat(level * indentWidth + 16) + offset
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
