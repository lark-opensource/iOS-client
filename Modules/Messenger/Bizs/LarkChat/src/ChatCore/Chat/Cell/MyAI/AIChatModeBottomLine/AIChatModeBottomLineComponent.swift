//
//  AIChatModeBottomLineComponent.swift
//  LarkChat
//
//  Created by ByteDance on 2023/6/20.
//

import Foundation
import LarkMessageCore
import LarkMessageBase
import AsyncComponent
import EEFlexiable
import UniverseDesignLoading

class AIChatModeBottomLineComponent: ASComponent<AIChatModeBottomLineComponent.Props, EmptyState, UIView, ChatContext> {
    final class Props: ASComponentProps {
        var showMoreBlock: (() -> Void)?
        var status: AIChatModeBottomLineCellViewModel.Status = .none
    }

    /// 内容固定高度42
    lazy var contentComponent: AIChatModeBottomLineContentComponent = {
        let props = AIChatModeBottomLineContentComponent.Props()
        props.showMoreBlock = self.props.showMoreBlock
        let style = ASComponentStyle()
        style.alignSelf = .center
        style.width = 100%
        style.height = CSSValue(float: 42)
        return AIChatModeBottomLineContentComponent(props: props, style: style)
    }()

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        self.contentComponent._style.display = (new.status == .none) ? .none : .flex
        let contentComponentProps = self.contentComponent.props
        contentComponentProps.showMoreBlock = new.showMoreBlock
        contentComponentProps.status = new.status
        self.contentComponent.props = contentComponentProps
        return true
    }

    public override func render() -> BaseVirtualNode {
        let maxCellWidth = (context?.maxCellWidth ?? UIScreen.main.bounds.width)
        style.width = CSSValue(cgfloat: maxCellWidth)
        return super.render()
    }

    public override init(props: AIChatModeBottomLineComponent.Props, style: ASComponentStyle, context: ChatContext? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents([contentComponent])
    }
}

class AIChatModeBottomLineContentComponent: ASComponent<AIChatModeBottomLineContentComponent.Props, EmptyState, AIChatModeBottomLineView, ChatContext> {
    final class Props: ASComponentProps {
        var showMoreBlock: (() -> Void)?
        var status: AIChatModeBottomLineCellViewModel.Status = .none
    }

    open override var isSelfSizing: Bool {
        return true
    }

    open override var isComplex: Bool {
        return true
    }

    override func update(view: AIChatModeBottomLineView) {
        super.update(view: view)
        view.showMoreBlock = self.props.showMoreBlock
        view.status = self.props.status
    }
}

class AIChatModeBottomLineView: UIView {
    var showMoreBlock: (() -> Void)?
    lazy var showMoreButton: UIButton = {
        let view = UIButton(frame: .zero)
        view.setTitle(BundleI18n.AI.MyAI_IM_ViewMoreMessages_Button, for: .normal)
        view.setTitleColor(UIColor.ud.textLinkNormal, for: .normal)
        view.setTitleColor(UIColor.ud.textLinkLoading, for: .disabled)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        view.addTarget(self, action: #selector(onShowMoreButtonTapped), for: .touchUpInside)
        return view
    }()

    lazy var loadingView: UDSpin = {
        var indicatorConfig = UDSpinIndicatorConfig(size: 16,
                                      color: UIColor.ud.textLinkLoading)
        return UDLoading.spin(
            config: .init(indicatorConfig: indicatorConfig, textLabelConfig: nil)
        )
    }()

    var status: AIChatModeBottomLineCellViewModel.Status = .none {
        didSet {
            guard status != oldValue else { return }
            switch status {
            case .hasMore:
                loadingView.isHidden = true
                showMoreButton.isHidden = false
                showMoreButton.isEnabled = true
            case .none:
                loadingView.isHidden = true
                showMoreButton.isHidden = true
            case .loading:
                loadingView.isHidden = false
                showMoreButton.isHidden = false
                showMoreButton.isEnabled = false
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .cyan
        addSubview(showMoreButton)
        showMoreButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.height.equalTo(42)
        }
        showMoreButton.isHidden = true
        addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.centerY.equalTo(showMoreButton)
            make.left.equalTo(showMoreButton.snp.right)
        }
        loadingView.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func onShowMoreButtonTapped() {
        self.showMoreBlock?()
    }
}
