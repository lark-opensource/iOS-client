//
//  EMAPhotoAnimatedView.swift
//  EEMicroAppSDK
//
//  Created by bytedance on 2021/7/15.
//

import Foundation
import Kingfisher

@objcMembers
public final class EMAAnimationView: NSObject {
    public class func animationView() -> UIImageView {
        return AnimatedImageView()
    }
}

