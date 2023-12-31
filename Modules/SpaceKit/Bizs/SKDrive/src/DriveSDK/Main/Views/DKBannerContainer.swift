//
//  DKBannerContainer.swift
//  SKDrive
//
//  Created by ByteDance on 2023/3/8.
//

import UIKit
import SKFoundation
import SnapKit

class DKBannerContainer: UIStackView {
    private var bannerMapper: NSMapTable<NSString, UIView>
    override init(frame: CGRect) {
        bannerMapper = NSMapTable<NSString, UIView>(keyOptions: .copyIn, valueOptions: .weakMemory)
        super.init(frame: frame)
    }
    
    required init(coder: NSCoder) {
        bannerMapper = NSMapTable<NSString, UIView>(keyOptions: .copyIn, valueOptions: .weakMemory)
        fatalError("init(coder:) has not been implemented")
    }
    
    func addBanner(banner: UIView, bannerID: String) {
        guard bannerMapper.object(forKey: bannerID as NSString) == nil else {
            DocsLogger.driveInfo("banner ID has already show \(bannerID)")
            spaceAssertionFailure("banner ID has already show")
            return
        }
        bannerMapper.setObject(banner, forKey: bannerID as NSString)
        self.addArrangedSubview(banner)
        banner.snp.makeConstraints { make in
            make.left.width.equalToSuperview()
        }
    }
    
    func removeBanner(with bannerID: String) {
        DocsLogger.driveInfo("remove banner \(bannerID)")
        if let banner = bannerMapper.object(forKey: bannerID as NSString) {
            self.removeArrangedSubview(banner)
            banner.removeFromSuperview()
            bannerMapper.removeObject(forKey: bannerID as NSString)
        } else {
            DocsLogger.driveInfo("banner with id \(bannerID) not found")
        }
    }
}
