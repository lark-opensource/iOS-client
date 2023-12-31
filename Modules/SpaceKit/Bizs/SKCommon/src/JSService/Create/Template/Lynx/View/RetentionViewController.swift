//
//  RetentionViewController.swift
//  SKCommon
//
//  Created by majie.7 on 2022/5/9.
//

import Foundation
import SKUIKit
import SKFoundation
import SKInfra

public final class RetentionViewController: LynxBaseViewController {
    
    public init(token: String, type: Int, statiscticParams: [String: Any]) {
        super.init(nibName: nil, bundle: nil)
        var params: [String: Any] = [
            "token": token,
            "type": type,
            "closeInsteadOfBack": SKDisplay.pad,
            //埋点参数
            "_module": statiscticParams["module"] ?? "",
            "sub_module": statiscticParams["sub_module"] ?? "",
            "file_id": statiscticParams["file_id"] ?? "",
            "file_type": statiscticParams["file_type"] ?? "",
            "sub_file_type": statiscticParams["sub_file_type"] ?? "",
            "container_id": statiscticParams["container_id"] ?? "",
            "container_type": statiscticParams["container_type"] ?? ""
        ]
        if let host = SettingConfig.retentionDomainConfig {
            params["host"] = host
        }
        initialProperties = params
        templateRelativePath = "pages/retention-label/template.js"
        
        //埋点上报
        DocsTracker.newLog(enumEvent: .retentionSettingView, parameters: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
