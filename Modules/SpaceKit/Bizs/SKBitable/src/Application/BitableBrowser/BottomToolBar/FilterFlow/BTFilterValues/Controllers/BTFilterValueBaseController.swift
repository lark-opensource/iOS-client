//
//  BTFilterValueBaseController.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/1.
//  


import Foundation

protocol BTFilterValueControllerDelegate: AnyObject {
    // 取消
    func valueControllerDidCancel()
    // 完成
    func valueControllerDidDone(result: [AnyHashable])
    func valueSelected(_ value: Any, selected: Bool)
    func search(_ keywords: String)
}

extension BTFilterValueControllerDelegate {
    // 取消
    func valueControllerDidCancel() {}
    // 完成
    func valueControllerDidDone(result: [AnyHashable]) {}
    // value 发生变化
    func valueSelected(_ value: Any, selected: Bool) {}
    // 搜索
    func search(_ keywords: String) {}
}

class BTFilterValueBaseController: BTDraggableViewController {
    
    enum CancelType {
        case close(isByClickMask: Bool)
        case back
    }
    
    typealias FinishWithValueHandler = ((_ value: [AnyHashable]) -> Void)
    typealias CancelHandler = ((_ cancelType: CancelType) -> Void)
    
    var didChangeValueWhenDismiss: (() -> Void)?
    
    var didFinishWithValues: FinishWithValueHandler?
    
    var didCancel: CancelHandler?
    weak var delegate: BTFilterValueControllerDelegate?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        if self.navigationController?.modalPresentationStyle == .formSheet || popoverOn { return }
        let contenViewHeight = min(initViewHeight + view.safeAreaInsets.bottom, maxViewHeight)
        containerView.snp.updateConstraints { make in
            make.height.equalTo(contenViewHeight)
        }
    }
    
    override func didClickBackPage() {
        self.delegate?.valueControllerDidCancel()
        self.navigationController?.popViewController(animated: true)
        self.didCancel?(.back)
        self.dismissBlock?()
        self.handleValueChangeWhenDismiss()
    }
    
    override func didClickClose() {
        self.delegate?.valueControllerDidCancel()
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.didCancel?(.close(isByClickMask: false))
            self.handleValueChangeWhenDismiss()
        }
    }

    override func didClickDoneButton() {
        self.delegate?.valueControllerDidDone(result: self.getValuesWhenFinish())
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.didFinishWithValues?(self.getValuesWhenFinish())
            self.handleValueChangeWhenDismiss()
        }
    }

    override func didClickMask() {
        self.delegate?.valueControllerDidCancel()
        self.dismiss(animated: true) {
            self.didCancel?(.close(isByClickMask: true))
            self.handleValueChangeWhenDismiss()
        }
    }
    
    // MARK: - 给子类实现
    func getValuesWhenFinish() -> [AnyHashable] {
        fatalError("need handle by subVC")
    }
    
    func isValueChange() -> Bool {
        fatalError("need handle by subVC")
    }
    
    private func handleValueChangeWhenDismiss() {
        if isValueChange() {
            self.didChangeValueWhenDismiss?()
        }
    }
}
