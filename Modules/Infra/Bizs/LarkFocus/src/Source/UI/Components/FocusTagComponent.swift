//
//  FocusTagComponent.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/12/28.
//

import Foundation
import UIKit
import AsyncComponent
import LarkFocusInterface

public final class FocusTagComponent<C: AsyncComponent.Context>: ASComponent<FocusTagComponent.Props, EmptyState, FocusTagWrapper, C> {

    public final class Props: ASComponentProps {
        public var style: FocusTagView.LayoutStyle = .compact
        public var focusStatus: ChatterFocusStatus?
        public var preferredSingleIconSize: CGFloat?
    }

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
    }

    public override var isComplex: Bool {
        return true
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        if let status = props.focusStatus {
            return FocusTagView.getContentSize(
                with: status,
                style: props.style,
                preferredSingleIconSize: props.preferredSingleIconSize
            )
        } else {
            return .zero
        }
    }

    public override func create(_ rect: CGRect) -> FocusTagWrapper {
        if let preferredSingleIconSize = props.preferredSingleIconSize {
            let view = FocusTagWrapper(preferredSingleIconSize: preferredSingleIconSize)
            view.tagView.style = props.style
            return view
        } else {
            let view = FocusTagWrapper(frame: rect)
            view.tagView.style = props.style
            return view
        }
    }

    public override func update(view: FocusTagWrapper) {
        super.update(view: view)
        view.tagView.style = props.style
        if let status = props.focusStatus {
            view.tagView.config(with: status)
        }
    }
}

/// FocusTagView 改为 UIStackView 子类之后，包装成 ASComponent 会出现布局问题，所以此处做一层封装
public final class FocusTagWrapper: UIView {

    public var tagView: FocusTagView

    public init(preferredSingleIconSize: CGFloat) {
        tagView = FocusTagView(preferredSingleIconSize: preferredSingleIconSize)
        super.init(frame: .zero)
        addSubview(tagView)
        tagView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public override init(frame: CGRect) {
        tagView = FocusTagView()
        super.init(frame: .zero)
        addSubview(tagView)
        tagView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
