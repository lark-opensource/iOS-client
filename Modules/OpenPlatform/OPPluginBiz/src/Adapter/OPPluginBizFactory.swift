//
//  OPPluginBizFactory.swift
//  OPPluginBiz
//
//  Created by baojianjun on 2023/4/23.
//

import Foundation

public final class OPPluginBizFactory {
    public class func videoPlayer(model: BDPVideoViewModel, componentID: String) -> UIView & BDPVideoViewDelegate {
        return TMAVideoView(model: model, componentID: componentID)
    }
}
