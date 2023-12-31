//
//  DetailBottomSubModule.swift
//  Todo
//
//  Created by 张威 on 2021/3/9.
//

struct DetailBottomItem {
    enum WidthMode {
        case devide             // 均分
        case fixed(CGFloat)     // 固定值
    }

    var view: UIView
    var widthMode: WidthMode = .devide
}

class DetailBottomSubmodule: DetailBaseModule {

    /// will set before `setup`
    weak var containerModule: DetailBottomModule?

    func bottomItems() -> [DetailBottomItem] {
        fatalError("needs override")
    }

}
