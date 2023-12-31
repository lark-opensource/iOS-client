//
//  EMAControllerOCBridge.swift
//  EEMicroAppSDK
//
//  Created by kongkaikai on 2021/6/16.
//

import UIKit

/// public to show this class in EEMicroAppSDK-umbrella
@objc
public final class EMAControllerOCBridge: NSObject {
    @objc
    public class func textViewController(with text: String) -> UIViewController {
        EMATextViewController(text: text)
    }
}
