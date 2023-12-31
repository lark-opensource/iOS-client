//
//  MessageTranslateFeedBackNavigationController.swift
//  LarkChat
//
//  Created by bytedance on 2020/9/11.
//

import Foundation
import UIKit
import LarkUIKit

final class MessageTranslateFeedbackNavigationController: LKBaseNavigationController {

    /// 转场方式
    private let transition: MessageTranslateFeedbackTransition

    override init(rootViewController: UIViewController) {
        self.transition = MessageTranslateFeedbackTransition(backgroundColor: UIColor.ud.bgMask)
        super.init(rootViewController: rootViewController)
        transitioningDelegate = transition
        modalPresentationStyle = .custom
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.transition = MessageTranslateFeedbackTransition(backgroundColor: UIColor.ud.bgMask)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        transitioningDelegate = transition
        modalPresentationStyle = .custom
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }
}
