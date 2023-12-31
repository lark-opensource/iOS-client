//
//  OPMockAcquireFaceImage.swift
//  OPPlugin-Unit-Tests
//
//  Created by ByteDance on 2023/3/24.
//

import Foundation
import EEMicroAppSDK
import UniverseDesignIcon

final class OPMockAcquireFaceImage:NSObject, EMALiveFaceProtocol {
    func checkFaceLiveness(_ params: [AnyHashable : Any]!, shouldShow: (() -> Bool)!, block: (([AnyHashable : Any]?, [String : Any]?) -> Void)!) {
        
    }
    
    func checkOfflineFaceVerifyReady(_ callback: @escaping (Error?) -> Void) {
        
    }
    
    func prepareOfflineFaceVerify(callback: @escaping (Error?) -> Void) {
        
    }
    
    func startOfflineFaceVerify(_ params: [AnyHashable : Any], callback: @escaping (Error?) -> Void) {
        
    }
    
    func startFaceQualityDetect(withBeautyIntensity beautyIntensity: Int32, backCamera: Bool, faceAngleLimit: Int32, from fromViewController: UIViewController?, callback: @escaping (Error?, UIImage?, [AnyHashable : Any]?) -> Void) {
        let image = UDIcon.burnlifeHourOutlined
        callback(nil, image, nil)
    }
    
}
