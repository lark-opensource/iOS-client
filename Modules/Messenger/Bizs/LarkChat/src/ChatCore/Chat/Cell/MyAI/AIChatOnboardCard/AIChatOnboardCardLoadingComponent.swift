//
//  AIChatOnboardCardLoadingComponent.swift
//  LarkChat
//
//  Created by Zigeng on 2023/12/6.
//

import Foundation
import LarkMessageCore
import LarkMessageBase
import AsyncComponent
import EEFlexiable
import UniverseDesignLoading
import UniverseDesignColor
import UniverseDesignIcon

public class AIChatOnboardCardLoadingComponent<C: Context>: ASComponent<ASComponentProps, EmptyState, AIChatOnboardCardLoadingView, C> {
    var loadingView: AIChatOnboardCardLoadingView?
    public override var isSelfSizing: Bool {
        return true
    }

    public override var isComplex: Bool {
        return true
    }

    public override func create(_ rect: CGRect) -> AIChatOnboardCardLoadingView {
        let view = AIChatOnboardCardLoadingView(frame: rect)
        loadingView = view
        return view
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return CGSize(width: 100, height: 100)
    }

    public override func update(view: AIChatOnboardCardLoadingView) {
        super.update(view: view)
    }
}

final public class AIChatOnboardCardLoadingView: UIStackView {
    let loadingView = MyAILoadingView.createView()
    let loadingWarpper = UIView()
    public override init(frame: CGRect) {
        super.init(frame: frame)
        axis = .vertical
        alignment = .leading
        distribution = .equalSpacing
        spacing = 6.auto()
        loadingWarpper.backgroundColor = UDMessageColorTheme.imMessageBgBubblesGrey
        loadingWarpper.layer.cornerRadius = 8
        addArrangedSubview(loadingWarpper)
        loadingWarpper.snp.makeConstraints { make in
            make.width.equalTo(60)
            make.height.equalTo(UIFont.ud.title2.figmaHeight + 8 * 2 + 3)
        }

        loadingWarpper.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
