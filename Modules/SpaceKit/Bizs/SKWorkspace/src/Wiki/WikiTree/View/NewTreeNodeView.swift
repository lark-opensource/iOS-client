//
//  NewTreeNodeView.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/5/22.
//

import Foundation
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
import LarkDocsIcon
import LarkContainer
import LarkIcon

// 待后续Wiki目录树UI计划改造完成后与旧TreeNodeView合并
public class NewTreeNodeView: UIView {

    public var reuseBag = DisposeBag()

    private let bag = DisposeBag()
    
    // hover状态展示按钮
    public typealias HomeHoverItemProvider = (() -> [HomeHoverItem]?)
    private var hoverGesture: UIGestureRecognizer?
    private var hadAddHoverItem: Bool = false
    private var hoverItemProvider: HomeHoverItemProvider?
    
    private var isIpadSelected: Bool {
        return SKDisplay.pad && isMyWindowRegularSize() && node.isSelected
    }
    
    private let hoverColor = UIColor.docs.rgb("F4F4F4") & UIColor.docs.rgb("242424")
    private let selectedColor = UIColor.docs.rgb("EBF0FE") & UIColor.docs.rgb("232831")
    

    public lazy var titleButton: NewTreeNodeCustomButton = {
        let button = NewTreeNodeCustomButton()
        button.setTitleColor(UDColor.textTitle, for: .normal)
        button.contentHorizontalAlignment = .left
        button.contentVerticalAlignment = .center
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.touchStateChangedHandler = { [weak self] isHighlightd in
            guard let self else { return }
            if SKDisplay.pad, self.isMyWindowRegularSize() { return }
            if isHighlightd {
                self.stateBoardView.backgroundColor = self.hoverColor
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.stateBoardView.backgroundColor = .clear
                }
            }
        }
        return button
    }()
    public lazy var stateButton: UIButton = {
        let button = UIButton()
        button.adjustsImageWhenDisabled = false
        //button.docs.addHighlight(with: .init(top: -4, left: -4, bottom: -4, right: -4), radius: 8)
        return button
    }()
    private let typeIcon = UIImageView()

    public let nodeLoadingView: LOTAnimationView = {
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
    private var titleAccessoryConstraint: Constraint?
    
    private lazy var rightHoverView: HomeHoverRightView = {
        let view = HomeHoverRightView()
        view.isHidden = true
        return view
    }()

    public var node: TreeNode = .default

    var indentWidth = 12
    
    public var completeWidth: CGFloat {
        //左偏移： 节点level缩进 + icon缩进 + icon尺寸 + icon间距 + title间距
        let leftWidth = CGFloat((node.level + 1) * indentWidth + 24 + 24 + 24)
        let titleWidth: CGFloat = node.title.estimatedSingleLineUILabelWidth(in: UIFont.systemFont(ofSize: 14))
        // 右缩进：当展示 accessoryItem 时，按钮宽度 20 + 按钮右边距 16 + title 间距 8
        let rightPadding: CGFloat = node.accessoryItem == nil ? 0 : (20 + 16 + 8)
        return leftWidth + titleWidth + rightPadding
    }

    public let clickStateInput = PublishRelay<Void>()
    public var clickStateSignal: Signal<Void> {
        clickStateInput.asSignal()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        _setupUI()
        if #available(iOS 13.0, *) {
            setupHoverInterraction()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func _setupUI() {
        backgroundColor = UDColor.bgBody
        addSubview(stateBoardView)
        stateBoardView.addSubview(titleButton)
        stateBoardView.addSubview(stateButton)
        stateBoardView.addSubview(nodeLoadingView)
        stateBoardView.addSubview(typeIcon)
        stateBoardView.addSubview(accessoryButton)
        stateBoardView.addSubview(rightHoverView)
        
        stateBoardView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.top.bottom.equalToSuperview()
        }
        stateButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(16)
            make.height.equalTo(16)
        }
        nodeLoadingView.snp.makeConstraints { (make) in
            make.height.width.equalTo(14)
            make.center.equalTo(stateButton.snp.center)
        }
        typeIcon.snp.makeConstraints { (make) in
            make.left.equalTo(stateButton.snp.right).offset(2)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        titleButton.snp.makeConstraints { (make) in
            make.left.equalTo(stateButton.snp.right).offset(8)
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }
        titleAccessoryConstraint?.deactivate()
        accessoryButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
            make.right.equalToSuperview().inset(16)
        }
        rightHoverView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
        }

        stateButton.rx.tap.bind(to: clickStateInput).disposed(by: bag)
    }

    public func updateModel(_ node: TreeNode, offset: CGFloat) {
        self.node = node

        self.nodeLoadingView.isHidden = true
        self.nodeLoadingView.stop()
        self.stateButton.isHidden = false
        self.stateButton.isEnabled = true
        self.titleButton.isEnabled = true

        handleHomeChild(offset: offset)

        if !node.isEnabled {
            stateButton.isEnabled = false
            titleButton.isEnabled = false
            stateButton.setImage(stateButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
            stateButton.tintColor = UDColor.iconN3
            typeIcon.tintColor = UDColor.iconDisabled
            titleButton.setTitle(node.title, for: .normal)
            titleButton.setTitleColor(UDColor.textDisabled, for: .normal)
            titleButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        }

        setupAccessoryButton(item: node.accessoryItem)
    }
    
    public func updateLayout(offset: CGFloat) {
        let indentCGFloatWidth = CGFloat(node.level * indentWidth - indentWidth)
        stateButton.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(indentCGFloatWidth + offset)
        }
    }
    
    // 设置主页的子节点
    func handleHomeChild(offset: CGFloat) {
        // 缩进和UI
        let indentCGFloatWidth = CGFloat(node.level * indentWidth - indentWidth)
        stateButton.snp.updateConstraints { (make) in
            make.left.equalToSuperview().offset(indentCGFloatWidth + offset)
        }
        let topEdge: CGFloat = (50 - 24) / 2

  
        // 根节点无Icon
        let isRootNode = node.typeIcon == nil

        stateButton.hitTestEdgeInsets = UIEdgeInsets(top: -topEdge, left: -24 - CGFloat(node.level * indentWidth), bottom: -topEdge, right: 0)
        titleButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: isRootNode ? 0 : 24, bottom: 0, right: 0)
        titleButton.setTitle(node.title, for: .normal)
        
        // icon状态
        setupNodeIcon(isRootNode: isRootNode)
        
        // iPad上展示选中态
        if isIpadSelected {
            stateBoardView.backgroundColor = selectedColor
            titleButton.setTitleColor(UDColor.functionInfoContentDefault, for: .normal)
            titleButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        } else {
            stateBoardView.backgroundColor = .clear
            titleButton.setTitleColor(UDColor.textTitle, for: .normal)
            titleButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        }
        
        // 节点按钮展示
        if node.isLeaf {
            stateButton.isEnabled = false
            stateButton.isHidden = true
        } else {
            stateButton.isEnabled = true
            stateButton.isHidden = false
        }
        // 节点是否展开
        if !node.isOpened {
            let icon = UDIcon.docs.iconWithPadding(.expandRightFilled,
                                                   iconSize: CGSize(width: 10, height: 10),
                                                   imageSize: CGSize(width: 16, height: 16))
            stateButton.setImage(icon.ud.withTintColor(UDColor.iconN2), for: .normal)
        } else {
            let icon = UDIcon.docs.iconWithPadding(.expandDownFilled,
                                                   iconSize: CGSize(width: 10, height: 10),
                                                   imageSize: CGSize(width: 16, height: 16))
            stateButton.setImage(icon.ud.withTintColor(UDColor.iconN2), for: .normal)
        }
    }
    
    private func setupNodeIcon(isRootNode: Bool) {
        guard !isRootNode else {
            typeIcon.di.clearDocsImage()
            return
        }
        
        //取的反向fg
        if !UserScopeNoChangeFG.HZK.larkIconDisable {
            
            if UserScopeNoChangeFG.MJ.wikiSpaceCustomIconEnable,
               case let .wikiSpace(spaceId, _) = node.type,
               let iconInfo = DocsIconInfo.createDocsIconInfo(json: node.iconInfo ?? "") {
                typeIcon.di.clearDocsImage()
                
                var iconKey = iconInfo.key
                var iconExtend: LarkIconExtend
                if iconInfo.type == .word { //显示文字
                    iconKey = DocsIconInfo.getIconWord(spaceName: node.title)
                    let borderColor = DocsIconInfo.getIconColor(spaceId: spaceId)
                    let iconLayer = IconLayer(backgroundColor: UDColor.bgFloat,
                                              border: IconLayer.Border(borderWidth: 1.0, borderColor: borderColor))
                    iconExtend = LarkIconExtend(shape: .CORNERRADIUS(value: 11.0),
                                                layer: iconLayer,
                                                placeHolderImage: UDIcon.wikibookCircleColorful)
                } else if iconInfo.type == .unicode { //显示emoji配置
                    let iconLayer = IconLayer(backgroundColor: UDColor.bgFloat,
                                              border: IconLayer.Border(borderWidth: 1.0, borderColor: UDColor.lineDividerDefault))
                    iconExtend = LarkIconExtend(shape: .CORNERRADIUS(value: 11.0),
                                                layer: iconLayer,
                                                placeHolderImage: UDIcon.wikibookCircleColorful)
                } else { //其他类型正常显示
                    iconExtend = LarkIconExtend(placeHolderImage: UDIcon.wikibookCircleColorful)
                }
                
                typeIcon.li.setLarkIconImage(iconType: iconInfo.type,
                                             iconKey: iconKey,
                                             iconExtend: iconExtend,
                                             userResolver: Container.shared.getCurrentUserResolver())
                
            } else {
                typeIcon.li.clearLarkIconImage()
                typeIcon.di.setDocsImage(iconInfo: node.iconInfo ?? "",
                                         token: node.objToken,
                                         type: node.typeIcon ?? .unknownDefaultType,
                                         shape: .SQUARE,
                                         container: ContainerInfo(isShortCut: node.isShortcut,
                                                                  isWikiRoot: node.type.isWikiSpace,
                                                                  defaultCustomIcon: node.type.isWikiSpace ? UDIcon.wikiColorful : nil,
                                                                  wikiCustomIconEnable: UserScopeNoChangeFG.MJ.wikiSpaceCustomIconEnable),
                                         userResolver: Container.shared.getCurrentUserResolver())
            }
            
            return
        }
        
        //旧逻辑，后面larkIconDisable删掉，旧删除下面的代码，customIcon也要删除
        let iconView = WikiSpaceCustomIcon(frame: CGRect(origin: .zero, size: CGSize(width: 20, height: 20)))
        // 是知识库节点，且为单字icon时，使用手绘的单字icon
        if UserScopeNoChangeFG.MJ.wikiSpaceCustomIconEnable,
           case let .wikiSpace(spaceId, iconType) = node.type,
           iconType == .word {
            typeIcon.di.clearDocsImage()
            typeIcon.image = iconView.getImage(spaceName: node.title, spaceId: spaceId)
        } else {
            typeIcon.di.setDocsImage(iconInfo: node.iconInfo ?? "",
                                     token: node.objToken,
                                     type: node.typeIcon ?? .unknownDefaultType,
                                     shape: .SQUARE,
                                     container: ContainerInfo(isShortCut: node.isShortcut,
                                                              isWikiRoot: node.type.isWikiSpace,
                                                              defaultCustomIcon: node.type.isWikiSpace ? UDIcon.wikiColorful : nil,
                                                              wikiCustomIconEnable: UserScopeNoChangeFG.MJ.wikiSpaceCustomIconEnable),
                                     userResolver: Container.shared.getCurrentUserResolver())
        }
    }

    private func setupAccessoryButton(item: TreeNodeAccessoryItem?) {
        guard let item = item else {
            accessoryButton.isHidden = true
            titleAccessoryConstraint?.deactivate()
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
        titleAccessoryConstraint?.activate()
    }
    
    @available(iOS 13.0, *)
    private func setupHoverInterraction() {
        guard SKDisplay.pad else { return }
        
        let gesture = UIHoverGestureRecognizer()
        gesture.rx.event.subscribe(onNext: { [weak self] gesture in
            guard let self = self else { return }
            switch gesture.state {
            case .began:
                // hover手势触发时再构建item UI上屏
                if !self.hadAddHoverItem, let items = self.hoverItemProvider?(), !items.isEmpty {
                    self.rightHoverView.configItem(items: items, isSelected: self.isIpadSelected)
                    self.hadAddHoverItem = true
                }
                // ipad上选中节点时保持选中颜色不变
                if self.isIpadSelected {
                    self.stateBoardView.backgroundColor = self.selectedColor
                } else {
                    self.stateBoardView.backgroundColor = self.hoverColor
                }
                self.rightHoverView.isHidden = false
                self.rightHoverView.alpha = 1
            case .ended, .cancelled:
                if self.isIpadSelected {
                    self.stateBoardView.backgroundColor = self.selectedColor
                } else {
                    self.stateBoardView.backgroundColor = .clear
                }
                self.rightHoverView.isHidden = true
                self.rightHoverView.alpha = 0
            default:
                break
            }
        }).disposed(by: bag)
        hoverGesture = gesture
        addGestureRecognizer(gesture)
    }
    
    public func configHoverItem(provider: @escaping HomeHoverItemProvider) {
        self.hoverItemProvider = provider
    }
    
    public func removeHoverItems() {
        rightHoverView.removeConfigItems()
    }
    
    public func resuseHandler() {
        hadAddHoverItem = false
        hoverItemProvider = nil
        rightHoverView.isHidden = true
        removeHoverItems()
    }
}

public class NewTreeNodeCustomButton: UIButton {
    
    public var touchStateChangedHandler: ((Bool) -> Void)?
    
    public override var isHighlighted: Bool {
        didSet {
            touchStateChangedHandler?(isHighlighted)
        }
    }
}


//MARK: Hover时的浮起的 新建 和 more面板按钮View

public class HomeHoverRightView: UIView {
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 8
        view.backgroundColor = .clear
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 8)
        return view
    }()
    
    private var disposeBag = DisposeBag()
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(24)
        }
    }
    
    func configItem(items: [HomeHoverItem], isSelected: Bool) {
        // 每次config时先移除掉旧的item，防止复用时添加多个
        removeConfigItems()
        let selectedColor = UIColor.docs.rgb("EBF0FE") & UIColor.docs.rgb("232831")
        let hoverColor = UIColor.docs.rgb("F4F4F4") & UIColor.docs.rgb("242424")
        if isSelected {
            stackView.backgroundColor = selectedColor
        } else {
            stackView.backgroundColor = hoverColor
        }
        
        items.forEach { item in
            let button = UIButton()
            button.setImage(item.icon.ud.withTintColor(UDColor.iconN2), for: .normal)
            button.layer.cornerRadius = 4
            button.docs.addStandardHighlight()
            button.rx.tap
                .subscribe(onNext: { [weak button] _ in
                    guard let button else { return }
                    item.handler(item, button)
                })
                .disposed(by: disposeBag)
            
            stackView.addArrangedSubview(button)
            button.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.width.height.equalTo(20)
            }
        }
    }
    
    func removeConfigItems() {
        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
    }
}

