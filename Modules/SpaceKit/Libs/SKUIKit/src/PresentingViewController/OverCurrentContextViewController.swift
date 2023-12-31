//
//  OverCurrentContextViewController.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/2/1.
//

import Foundation

// 当modalPresentationStyle方式为.overCurrentContext时请使用此类
// Remark: 当此方式present时，原vc不会收到lifeCycle消息，viewWillAppear:, viewDidAppear:, viewWillDisappear: viewDidDisappear:
// 但存在vc需要接受此事件的case，故通过发通知方式告知dismiss
// BTW: 自行将modalPresentationStyle设置为.custom并实现transitioningDelegate的方法更优，但是成本较大

open class OverCurrentContextViewController: UIViewController {
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalPresentationStyle = .overCurrentContext
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
