//
//  TreeNodeView.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/5/18.
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

public class TreeNodeView: UIView {

    public var reuseBag = DisposeBag()

    private let bag = DisposeBag()

    public lazy var titleButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(UDColor.textTitle, for: .normal)
        button.contentHorizontalAlignment = .left
        button.contentVerticalAlignment = .center
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        return button
    }()
    public lazy var stateButton: UIButton = {
        let button = UIButton()
        button.adjustsImageWhenDisabled = false
        button.docs.addHighlight(with: .init(top: -4, left: -4, bottom: -4, right: -4), radius: 8)
        return button
    }()
    private lazy var shortcutImageView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.wikiShortcutarrowColorful
        return view
    }()
    private let typeIcon = UIImageView()
    public lazy var segmentLine: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        view.isHidden = true
        return view
    }()

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

    public var node: TreeNode = .default

    var indentWidth = 12
    
    public var completeWidth: CGFloat {
        //左偏移： 节点level缩进 + icon缩进 + icon尺寸 + icon间距 + title间距
        var fontSize = UIFont.systemFont(ofSize: 16)
        if UserScopeNoChangeFG.WWJ.newSpaceTabEnable, node.isSelected {
            fontSize = .systemFont(ofSize: 16, weight: .medium)
        }
        let leftWidth = CGFloat((node.level + 1) * indentWidth + 24 + 24 + 24)
        let titleWidth: CGFloat = node.title.estimatedSingleLineUILabelWidth(in: fontSize)
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
        self.docs.addStandardHover()
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
        stateBoardView.addSubview(segmentLine)
        stateBoardView.addSubview(accessoryButton)
        
        stateBoardView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
            make.top.bottom.equalToSuperview()
        }
        stateButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(24)
            make.height.equalTo(24)
        }
        nodeLoadingView.snp.makeConstraints { (make) in
            make.height.width.equalTo(14)
            make.center.equalTo(stateButton.snp.center)
        }
        typeIcon.snp.makeConstraints { (make) in
            make.left.equalTo(stateButton.snp.right).offset(4)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        titleButton.snp.makeConstraints { (make) in
            make.left.equalTo(stateButton.snp.right).offset(4)
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().priority(.medium)
            titleAccessoryConstraint = make.right.equalTo(accessoryButton.snp.left).inset(-8).priority(.required).constraint
        }
        titleAccessoryConstraint?.deactivate()
        accessoryButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
            make.right.equalToSuperview().inset(16)
        }
        segmentLine.snp.makeConstraints { (make) in
            make.left.equalTo(stateButton.snp.left)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
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
        if node.isSelected {
            stateBoardView.backgroundColor = UDColor.fillSelected
        } else {
            stateBoardView.backgroundColor = .clear
        }

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
            make.width.equalTo(24)
            make.left.equalToSuperview().offset(indentCGFloatWidth + offset)
        }
        let topEdge: CGFloat = (50 - 24) / 2
        
        // 根节点无Icon
        let isRootNode = node.typeIcon == nil
        stateButton.hitTestEdgeInsets = UIEdgeInsets(top: -topEdge, left: -24 - CGFloat(node.level * indentWidth), bottom: -topEdge, right: 0)
        titleButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: isRootNode ? 0 : 24, bottom: 0, right: 0)
        titleButton.setTitle(node.title, for: .normal)
        // icon状态
        titleButton.setTitleColor(UDColor.textTitle, for: .normal)
        titleButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        if node.isSelected {
            if UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
                titleButton.setTitleColor(UDColor.primaryPri500, for: .normal)
                titleButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            }
            
            if !isRootNode {
                typeIcon.di.setDocsImage(iconInfo: node.iconInfo ?? "",
                                         token: node.objToken,
                                         type: node.typeIcon ?? .unknownDefaultType,
                                         shape: .SQUARE,
                                         container: ContainerInfo(isShortCut: node.isShortcut),
                                         userResolver: Container.shared.getCurrentUserResolver())
                typeIcon.image = typeIcon.image?.withRenderingMode(.alwaysOriginal)
            } else {
                typeIcon.di.clearDocsImage()
            }
            
            typeIcon.tintColor = UDColor.primaryPri500
            
            segmentLine.isHidden = true
            if node.isLeaf {
                stateButton.isEnabled = false
                stateButton.isHidden = true
            } else {
                stateButton.isEnabled = true
                stateButton.isHidden = false
                if !node.isOpened {
                    let icon = UDIcon.docs.iconWithPadding(.expandRightFilled,
                                                           iconSize: CGSize(width: 12, height: 12),
                                                           imageSize: CGSize(width: 24, height: 24))
                    stateButton.setImage(icon.ud.withTintColor(UDColor.iconN2), for: .normal)
                } else {
                    let icon = UDIcon.docs.iconWithPadding(.expandDownFilled,
                                                           iconSize: CGSize(width: 12, height: 12),
                                                           imageSize: CGSize(width: 24, height: 24))
                    stateButton.setImage(icon.ud.withTintColor(UDColor.iconN2), for: .normal)
                }
            }
        } else {
            if UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
                
                if !isRootNode {
                    typeIcon.di.setDocsImage(iconInfo: node.iconInfo ?? "",
                                             token: node.objToken,
                                             type: node.typeIcon ?? .unknownDefaultType,
                                             shape: .SQUARE,
                                             container: ContainerInfo(isShortCut: node.isShortcut),
                                             userResolver: Container.shared.getCurrentUserResolver())
                    
                } else {
                    typeIcon.di.clearDocsImage()
                }
                
            } else {
            
                if !isRootNode {
                    typeIcon.di.setDocsImage(iconInfo: node.iconInfo ?? "",
                                             token: node.objToken,
                                             type: node.typeIcon ?? .unknownDefaultType,
                                             shape: .OUTLINE,
                                             container: ContainerInfo(isShortCut: node.isShortcut),
                                             userResolver: Container.shared.getCurrentUserResolver())
                    
                } else {
                    typeIcon.di.clearDocsImage()
                }
                
                typeIcon.tintColor = UDColor.iconN2
         
            }
            
            segmentLine.isHidden = false
            if node.isLeaf {
                stateButton.isEnabled = false
                stateButton.isHidden = true
            } else {
                stateButton.isEnabled = true
                stateButton.isHidden = false
                if !node.isOpened {
                    let icon = UDIcon.docs.iconWithPadding(.expandRightFilled,
                                                           iconSize: CGSize(width: 12, height: 12),
                                                           imageSize: CGSize(width: 24, height: 24))
                    stateButton.setImage(icon.ud.withTintColor(UDColor.iconN2), for: .normal)
                } else {
                    let icon = UDIcon.docs.iconWithPadding(.expandDownFilled,
                                                           iconSize: CGSize(width: 12, height: 12),
                                                           imageSize: CGSize(width: 24, height: 24))
                    stateButton.setImage(icon.ud.withTintColor(UDColor.iconN2), for: .normal)
                }
            }
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
}
