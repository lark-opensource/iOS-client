//
//  PassthroungView.swift
//  Todo
//
//  Created by 张威 on 2021/3/6.
//

class PassthroungView: UIView {

    // 返回 true 则处理
    typealias EventFilter = (CGPoint, UIEvent?) -> Bool

    var eventFilter: EventFilter?

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return eventFilter?(point, event) ?? false
    }
}
