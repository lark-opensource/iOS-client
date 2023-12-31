//
//  StateContainer.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/10.
//

import Foundation
import SKFoundation

// 创建一个唯一的 key 作为关联属性的索引
private var hiddenObservationKey: UInt8 = 0

// 扩展现有类型，并遵循关联属性协议
extension UIView {
    fileprivate var hiddenObservation: NSKeyValueObservation? {
        get {
            return objc_getAssociatedObject(self, &hiddenObservationKey) as? NSKeyValueObservation
        }
        set {
            objc_setAssociatedObject(self, &hiddenObservationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

class StateContainer: UIView {
    private var observation: NSKeyValueObservation?
    var hiddenChangedCallback: (() -> Void)?
    
    private lazy var backgroundView: UIControl = {
        let view = UIControl()
        view.addTarget(self, action: #selector(backgroundViewClicked), for: .touchDown)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func backgroundViewClicked() {
        DocsLogger.info("StateContainer.backgroundViewClicked, \(subviews.count)")
        self.isHidden = true    // 走到这里说明上层不处理，则直接隐藏
    }
    
    private func setup() {
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.isHidden = true    // 默认隐藏
    }
    
    override func didAddSubview(_ subview: UIView) {
        DocsLogger.info("StateContainer.didAddSubview,\(subview)")
        super.didAddSubview(subview)
        if subview == backgroundView {
            return
        }
        subview.hiddenObservation = subview.observe(\.isHidden, options: [.new, .old]) { [weak self] _, change in
            guard let newValue = change.newValue else {
                return
            }
            DocsLogger.info("StateContainer.subView hidden changed: \(newValue)")
            self?.updateSubviewsCount()
        }
        updateSubviewsCount()
    }
    
    override func willRemoveSubview(_ subview: UIView) {
        subview.hiddenObservation = nil
        super.willRemoveSubview(subview)
        updateSubviewsCount(willRemoveSubView: subview)
    }
    
    private func updateSubviewsCount(willRemoveSubView: UIView? = nil) {
        let hasVisilbleSubview = subviews.contains(where: { view in
            if view == self.backgroundView {
                return false
            }
            if view == willRemoveSubView {
                return false 
            }
            DocsLogger.info("StateContainer.updateSubviewsCount isHidden:\(view.isHidden) subviews.count:\(view.subviews.count)")
            return !view.isHidden && view.subviews.count > 0
        })
        DocsLogger.info("StateContainer.updateSubviewsCount:\(hasVisilbleSubview),\(subviews.count)")
        self.isHidden = !hasVisilbleSubview
        hiddenChangedCallback?()
    }
}
