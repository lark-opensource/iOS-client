//
//  EditorInterface.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/8/10.
//

import UIKit
import Foundation
import RxSwift

/// 新旧imageEditVC遵守的协议
public protocol EditViewController: UIViewController {
    /// vc没有dismiss，需要外部调用vc.exit()退出界面
    func exit()
    /// 埋点的Observable
    var editEventObservable: Observable<ImageEditEvent> { get }
    /// 需要外部赋值的ImageEditViewControllerDelegate
    var delegate: ImageEditViewControllerDelegate? { get set }
}

/// 图片编辑需要外部实现的协议
public protocol ImageEditViewControllerDelegate: AnyObject {
    /// vc没有dismiss，需要外部调用vc.exit()退出界面
    func closeButtonDidClicked(vc: EditViewController)
    /// vc没有dismiss，需要外部调用vc.exit()退出界面
    func finishButtonDidClicked(vc: EditViewController, editImage: UIImage)
}

/// 埋点
public struct ImageEditEvent {
    /// 埋点事件名称
    public let event: String
    /// 埋点参数
    public let params: [String: Any]?

    init(event: String, params: [String: Any]? = nil) {
        self.event = event
        self.params = params
    }
}
