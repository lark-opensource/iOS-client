//
//  WorkplaceTrackable+Home.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/20.
//

import Foundation

extension WorkplaceTrackable {
    /// 页面曝光上报
    func setForPageExpose(_ data: WPHomeVCInitData) -> WorkplaceTrackable {
        switch data {
        case .normal:
            setValue("old", for: .version)
        case .lowCode(let lowCode):
            setValue("new", for: .version)
            setValue(lowCode.id, for: .template_id)
        case .web(let web):
            setValue("h5", for: .version)
            setValue(web.id, for: .template_id)
            setValue(web.refAppId, for: .app_id)
        }

        return self
    }

    /// 页面停留时长上报
    func setPageStayDuration(_ data: WPHomeVCInitData, duration: Int) -> WorkplaceTrackable {
        guard duration > 0 else { return self }

        setValue("\(duration)", for: .duration)
        switch data {
        case .normal:
            setValue("old", for: .version)
        case .lowCode:
            setValue("new", for: .version)
        case .web(let web):
            setValue("h5", for: .version)
            setValue(web.refAppId, for: .app_id)
        }

        return self
    }
}
