//
//  UIAppliction+Swizz.swift
//  SKCommon
//
//  Created by zengsenyuan on 2022/7/31.
//  


import SKFoundation


extension UIApplication {
    
    @objc
    public static func registDocsSwizz() {
        DispatchQueue.main.once {
            let originalSelector = #selector(sendEvent(_:))
            let swizzledSelector = #selector(doc_sendEvent(_:))
            doc_swizzling(
                forClass: UIApplication.self,
                originalSelector: originalSelector,
                swizzledSelector: swizzledSelector
            )
        }
    }
    
    @objc
    func doc_sendEvent(_ event: UIEvent) {
        NotificationCenter.default.post(name: Notification.Name.Docs.appliationSentEvent,
                                        object: nil,
                                        userInfo: ["event": event])
        self.doc_sendEvent(event)
    }
}

// MARK: - swizzling
func doc_swizzling(
    forClass: AnyClass,
    originalSelector: Selector,
    swizzledSelector: Selector) {
        
        guard let originalMethod = class_getInstanceMethod(forClass, originalSelector),
              let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector) else {
            return
        }
        if class_addMethod(
            forClass,
            originalSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        ) {
            class_replaceMethod(
                forClass,
                swizzledSelector,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod)
            )
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
