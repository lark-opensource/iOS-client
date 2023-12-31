//
//  CCMDocsPickerProxy.swift
//  CCMMod
//
//  Created by liujinwei on 2023/6/16.
//  


import Foundation
import LarkModel
import SpaceInterface

class CCMDocsSearchPlaceHolderTopView: UIView {
    let proxy: CCMDocsPickerProxy
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 0)
    }

    init(proxy: CCMDocsPickerProxy) {
        self.proxy = proxy
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CCMDocsPickerProxy: SearchPickerDelegate {
    weak var delegate: DocsPickerDelegate?
    
    init(delegate: DocsPickerDelegate) {
        self.delegate = delegate
    }

    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        return delegate?.pickerDidFinish(pickerVc: pickerVc, items: items) ?? true
    }
    
    func pickerDidCancel(pickerVc: SearchPickerControllerType) -> Bool {
        delegate?.pickerDidCancel()
        return true
    }

    func pickerDidDismiss(pickerVc: SearchPickerControllerType) {
        delegate?.pickerDidCancel()
    }
}
