//
//  BitableRecommendCell.swift
//  SKBitable
//
//  Created by qianhongqiang on 2023/9/4.
//

import Foundation
import UIKit
import SKCommon
import LarkSetting
import SKFoundation

extension String {
    func getFitHeight(_ constrainedWidth: CGFloat, font: UIFont, lineHeght: CGFloat) -> CGFloat {
        let attStr = NSMutableAttributedString(string: self)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeght
        paragraphStyle.maximumLineHeight = lineHeght
        attStr.addAttributes([NSAttributedString.Key.font : font, NSAttributedString.Key.paragraphStyle : paragraphStyle], range: NSRange(location: 0, length: attStr.length))
        let height = attStr.boundingRect(with: CGSize(width: constrainedWidth, height: CGFloat(MAXFLOAT)), options: [.usesLineFragmentOrigin], context: nil).size.height
        
        return height
    }
    
    func buildAttributedString(_ font: UIFont, lineHeght: CGFloat) -> NSMutableAttributedString {
        let attStr = NSMutableAttributedString(string: self)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeght
        paragraphStyle.maximumLineHeight = lineHeght
        paragraphStyle.lineBreakMode = .byTruncatingTail
        attStr.addAttributes([NSAttributedString.Key.font : font, NSAttributedString.Key.paragraphStyle : paragraphStyle], range: NSRange(location: 0, length: attStr.length))
        return attStr
    }
}

public class RecommendConfig {
    public static let shared: RecommendConfig = RecommendConfig()
    
    public private(set) var recommenChunkSize: Int = 12
    // 首页分流接口的业务层超时,默认值200ms
    public private(set) var homeDiversionTimout: Int = 200
    // 数据上报时间间隔
    public private(set) var recommendViewReportInterval: Int = 1500
    
    init() {
        do {
            let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "ccm_base_recommend"))
            if let recommenChunkSize = settings["recommend_chunk_size"] as? Int {
                self.recommenChunkSize = recommenChunkSize
            }
            if let homeDiversionTimout = settings["home_diversion_timeout"] as? Int {
                self.homeDiversionTimout = homeDiversionTimout
            }
            if let recommendViewReportInterval = settings["recommend_view_report_interval_mills"] as? Int {
                self.recommendViewReportInterval = recommendViewReportInterval
            }
        } catch let error {
            DocsLogger.error("get settings ccm_base_recommend error", error: error)
        }
    }
}

// 埋点相关的格式化工具
extension Date {
    func formatToyyyyMMdd() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.string(from: self)
    }
    
    static func currentToyyyyMMdd() -> String {
        return self.init().formatToyyyyMMdd()
    }
}

class DocUrlParser {
    static func getEncryptedToken(from urlString:String?) -> String?{
        guard let urlString else {
            return nil
        }
        if let url = URL(string: urlString),
           let token = DocsUrlUtil.getFileToken(from: url) {
            return DocsTracker.encrypt(id: token)
        }
        return nil
    }
    
    static func geFileType(from urlString:String?) -> String?{
        guard let urlString else {
            return nil
        }
        if let url = URL(string: urlString),
           let type = DocsUrlUtil.getFileType(from: url) {
            return type.name
        }
        return nil
    }
}
