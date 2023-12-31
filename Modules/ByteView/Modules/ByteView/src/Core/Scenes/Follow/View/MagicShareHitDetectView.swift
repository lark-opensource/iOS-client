//
//  MagicShareHitDetectView.swift
//  ByteView
//
//  Created by liurundong.henry on 2022/6/9.
//

import Foundation
import RxSwift

// 参考文档 https://bytedance.feishu.cn/docx/doxcntUrmt6PiM406QDfNNJwvqe
class MagicShareHitDetectView: UIView {

    var hitSubject = PublishSubject<Void>()

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if let event = event, hitView == self {
            if #available(iOS 13.4, *), event.type == .hover {
                return nil
            } else {
                hitSubject.onNext(Void())
                return nil
            }
        }
        return hitView
    }

}
