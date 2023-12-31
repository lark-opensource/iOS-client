//
//  SKTaggedLabelView.swift
//  SpaceKit
//
//  Created by kkk on 2021/07/22.
//

/// ****************************************************************************************
/// 这个文件是在做全量二进制时由: kongkaikai, kongkaikai@bytedance.com 移动代码内容到这里;
/// 有代码层疑问请优先联系原始作者；
///
/// 原始提交: 9c05e4e
/// 原始作者: qiupei，qiupei@bytedance.com
/// 原始文件: Bizs/SKBrowser/src/Controller/BrowserVC/BrowserViewController+Delegates.swift
///
/// 更新提交: 2ae66d4e9de01eca3933210e8ec0fc864c89c2a9
/// 更新作者: kongkaikai, kongkaikai@bytedance.com
/// 更新文件: 此文件
///
/// ****************************************************************************************

import SKFoundation
public protocol CommonGestureDelegateRepeaterProtocol: UIViewController {
    var naviPopGestureDelegate: UIGestureRecognizerDelegate? { get }
}

public final class CommonGestureDelegateRepeater: NSObject, UIGestureRecognizerDelegate {
    private weak var rawObject: CommonGestureDelegateRepeaterProtocol?

    private var naviPopGestureDelegate: UIGestureRecognizerDelegate? {
        guard rawObject?.naviPopGestureDelegate?.isEqual(self) == false else {
            DocsLogger.warning("rawObject?.naviPopGestureDelegate should not be self")
            return nil
        }
        return rawObject?.naviPopGestureDelegate
    }

    /// 用一个 Object 初始化该转发器
    /// - Parameter rawObject: 将协议转发出来的对象，Repeater不会强持有该对象
    public init(_ rawObject: CommonGestureDelegateRepeaterProtocol) {
        self.rawObject = rawObject
        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return naviPopGestureDelegate?.gestureRecognizerShouldBegin?(gestureRecognizer) ?? true
    }


    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return naviPopGestureDelegate?.gestureRecognizer?(gestureRecognizer,
                                                          shouldRecognizeSimultaneouslyWith: otherGestureRecognizer) ?? true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return naviPopGestureDelegate?.gestureRecognizer?(gestureRecognizer,
                                                          shouldRequireFailureOf: otherGestureRecognizer) ?? false

    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return naviPopGestureDelegate?.gestureRecognizer?(gestureRecognizer,
                                                          shouldBeRequiredToFailBy: otherGestureRecognizer) ?? false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldReceive touch: UITouch) -> Bool {
        return naviPopGestureDelegate?.gestureRecognizer?(gestureRecognizer, shouldReceive: touch) ?? true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldReceive press: UIPress) -> Bool {
        return naviPopGestureDelegate?.gestureRecognizer?(gestureRecognizer, shouldReceive: press) ?? true
    }

    @available(iOS 13.4, *)
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldReceive event: UIEvent) -> Bool {
        var canResponse = true
        if gestureRecognizer == rawObject?.navigationController?.interactivePopGestureRecognizer {
            if event.type == .scroll {
                canResponse = false
            }
        }
        return (naviPopGestureDelegate?.gestureRecognizer?(gestureRecognizer, shouldReceive: event) ?? true) && canResponse
    }
}
