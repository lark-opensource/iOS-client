//
//  Patch.swift
//  TangramComponent
//
//  Created by 袁平 on 2021/4/11.
//
import UIKit

protocol RenderTreeAbility: AnyObject {
    func createView() -> UIView?
    func draw(_ view: UIView)
    func updateView(_ view: UIView)
}

/// RenderTree节点不复用BaseVirtualNode，两个原因：
/// - RenderTree不需要Props，Style等信息
/// - VirtualTree到RenderTree会进行深拷贝，避免Props，Style的再次拷贝
struct RenderTreeNode {
    // 此处不能weak持有ability，否则在主线程patch时，VirtualNode可能被替换而释放了
    // RenderTree只会临时存在，不存在循环引用
    let ability: RenderTreeAbility
    let reflectingTag: Int?
    let componentKey: Int
    let isDirty: Bool
    var children: [RenderTreeNode] = []

    init(ability: RenderTreeAbility,
         reflectingTag: Int?,
         componentKey: Int,
         isDirty: Bool) {
        self.ability = ability
        self.reflectingTag = reflectingTag
        self.componentKey = componentKey
        self.isDirty = isDirty
    }
}

struct ViewTree {
    private let view: UIView
    // reflectingTag: [index]
    private(set) var viewTagMap: [Int: [Int]] = [:]
    var layerStashed: Bool = false

    init(view: UIView) {
        self.view = view
        buildViewTagMap()
    }

    /// https://caisanze.com/post/exchangesubview/
    /// 当sublayers和subviews的数量不同时，exchangeSubview和insertSubview会有歧义
    /// 此处先将多余的sublayers移除，若要新增sublayers，需要在RenderComponent的update里重新添加
    private mutating func buildViewTagMap() {
        var sublayers = view.layer.sublayers ?? []
        var viewIndex = 0
        while !sublayers.isEmpty {
            let layer = sublayers.removeFirst()
            if viewIndex < view.subviews.count, layer == view.subviews[viewIndex].layer {
                let tag = view.subviews[viewIndex].reflectingTag
                var indecies = viewTagMap[tag] ?? []
                indecies.append(viewIndex)
                viewTagMap[tag] = indecies
                viewIndex += 1
            } else {
                layerStashed = true
                layer.removeFromSuperlayer()
            }
        }

        assert(view.layer.sublayers?.count ?? 0 == view.subviews.count, "invalidate sublayers & subviews")
    }

    mutating func dequeueReusableIndex(_ tag: Int) -> Int? {
        if var indecies = viewTagMap[tag], let index = indecies.first {
            indecies.removeFirst()
            viewTagMap[tag] = indecies.isEmpty ? nil : indecies
            return index
        }
        return nil
    }

    mutating func exchangeSubview(at: Int, to: Int) {
        guard at < view.subviews.count, to < view.subviews.count else { return }
        let tag = view.subviews[to].reflectingTag
        if var indecies = viewTagMap[tag], !indecies.isEmpty {
            indecies[0] = at
            // 需要按从小到达顺序重排，因为默认更改的第一位（indecies[0] = at）
            viewTagMap[tag] = indecies.sorted(by: { l, r in return l < r })
        } else {
            assertionFailure("exchange subview with error index")
        }
        view.exchangeSubview(at: at, withSubviewAt: to)
    }

    mutating func insertSubview(subview: UIView, at: Int) {
        for key in viewTagMap.keys {
            if let indecies = viewTagMap[key] {
                viewTagMap[key] = indecies.map { $0 + 1 }
            }
        }
        view.insertSubview(subview, at: at)
    }
}

// 同步剪枝后的VirtualTree到ViewTree
func applyPatchToView(_ root: RenderTreeNode, view: UIView) {
    assert(Thread.isMainThread, "applyPatchToView must be on main thread")
    guard root.reflectingTag == view.reflectingTag else {
        assertionFailure("View type not match RenderComponent: \(type(of: view))")
        return
    }
    var viewTree = ViewTree(view: view)
    let children = root.children
    for index in 0..<children.count {
        let child = children[index]
        if let tag = child.reflectingTag {
            let viewIndex = viewTree.dequeueReusableIndex(tag)
//            if index == viewIndex, index < view.subviews.count { // index相同，view被复用
//                view.subviews[index].isTCCreate = true
//            } else
            if let viewIndex = viewIndex, index != viewIndex { // view中有该child，但是位置不对
                viewTree.exchangeSubview(at: viewIndex, to: index)
//                view.subviews[index].isTCCreate = true
            } else if viewIndex == nil, let subview = child.ability.createView() { // view中没有该child：重新生成并插入
                // 只在view创建时标识该View由Component创建，根节点由外部传入，不需要标识isTCCreate
                subview.isTCCreate = true
                viewTree.insertSubview(subview: subview, at: index)
            }
        } else {
            assertionFailure("LayoutComponent can not patch to View")
        }
    }

    var i = children.count
    while i < view.subviews.count { // 移除多余Component创建的View
        if view.subviews[i].componentKey != nil {
            view.subviews[i].removeFromSuperview()
            continue
        }
        i += 1
    }

    // 复合View可能有自己的子元素，不能直接移除
//    if children.count < view.subviews.count { // 移除多于View
//        view.subviews[children.count...].forEach({ $0.removeFromSuperview() })
//    }

    // 以下情况会重新出发update
    //  - Props & Style changed
    //  - view componentKey改变：exchangeSubview等也可能会使View复用而变为Dirty，所以需要额外比较componentKey
    //  - layerStashed: 当view的subviews和sublayers不等时，ViewTree中会提前处理为相等，为避免歧义，需要业务方在update里重新增删layer
    // 需要在draw调用之前判断componentKey，因为draw里会同步componentKey
//    let needUpdate = root.isDirty || root.componentKey != view.componentKey || viewTree.layerStashed
    // 同步frame，componentKey等信息到View
    root.ability.draw(view)
    // needUpdate的判断有badcase，比如在SmartCard场景，SmartCard自己维护了一份LynxView的复用池，
    // 此时可能root.componentKey == view.componentKey，但view的subviews是需要更新的
//    if needUpdate {
//        root.ability.updateView(view)
//    }
    root.ability.updateView(view)

    // 自定义View等复合View可能会有自己的subviews，不能移除，所以对于复合View，subviews和children的数量不一定相等
//    assert(view.subviews.count == children.count, "VirtualTree not equal to ViewTree!")

    // darkmode或业务方可能会在updateView时插入subview，patch时只递归通过Component创建的view
    let subviews = view.subviews.filter({ $0.isTCCreate })
    // 当外部Component被释放时（比如VM更新被释放等正常情况），createView可能不成功，导致subviews和children数量不等
    if children.count != subviews.count {
        return
    }
    let count = children.count
    for i in 0..<count {
        // TODO: 此处有问题，因为上面会触发updateView，如果业务方在updateView中自己增加了view，那这里的index就对不上了
        applyPatchToView(children[i], view: subviews[i])
    }
}

private var _tcCreateKey = "_tcCreateKey"
private var _componentKey = "_componentKey"
private var _reflectingTagKey = "_reflectingTagKey"
private var _viewIdentifierKey = "_viewIdentifierKey"

// save Int as NONATOMIC: https://www.jianshu.com/p/d417e3038a04
extension UIView {
    var isTCCreate: Bool {
        get {
            return objc_getAssociatedObject(self, &_tcCreateKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &_tcCreateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // 对应component标识
    var componentKey: Int? {
        get {
            return objc_getAssociatedObject(self, &_componentKey) as? Int
        }
        set {
            objc_setAssociatedObject(self, &_componentKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // view类型标识
    var reflectingTag: Int {
        if let tag = objc_getAssociatedObject(self, &_reflectingTagKey) as? Int { return tag }
        let tag = ObjectIdentifier(type(of: self)).hashValue
        objc_setAssociatedObject(self, &_reflectingTagKey, tag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return tag
    }

    // view实例标识
    public var viewIdentifier: Int {
        if let identifier = objc_getAssociatedObject(self, &_viewIdentifierKey) as? Int { return identifier }
        let identifier = ObjectIdentifier(self).hashValue
        objc_setAssociatedObject(self, &_viewIdentifierKey, identifier, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return identifier
    }
}
