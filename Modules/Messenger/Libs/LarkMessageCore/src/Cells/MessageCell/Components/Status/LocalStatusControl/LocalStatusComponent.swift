//
//  LocalStatusComponent.swift
//  LarkMessageCore
//
//  Created by Meng on 2019/4/2.
//

import UIKit
import Foundation
import AsyncComponent

/// 消息本地状态，loading，failed，normal
public final class LocalStatusComponent<C: Context>: ASComponent<LocalStatusComponent.Props, EmptyState, LocalStatusControl, C> {

    public final class Props: ASComponentProps {
        // swiftlint:disable nesting
        public typealias TapHandler = (LocalStatusControl, LocalStatusControl.Status) -> Void
        // swiftlint:enable nesting

        public var status: LocalStatusControl.Status = .normal

        public var tapHandler: TapHandler?

    }

    public override var isComplex: Bool {
        return true
    }

    public override func create(_ rect: CGRect) -> LocalStatusControl {
        let control = LocalStatusControl(frame: rect)
        control.hitTestEdgeInsets = UIEdgeInsets(top: -10.0, left: -10.0, bottom: -10.0, right: -10.0)
        control.onTapped = {
            self.props.tapHandler?($0, $0.status)
        }
        control.status = props.status
        return control
    }

    public override func update(view: LocalStatusControl) {
        super.update(view: view)
        view.status = props.status
        view.onTapped = {
            self.props.tapHandler?($0, $0.status)
        }
    }

}
