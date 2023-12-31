//
//  BlockDebugService.swift
//  OPBlock
//
//  Created by xiangyuanyuan on 2022/8/4.
//

import Foundation
import OPSDK
import OPFoundation
import OPBlockInterface

@objcMembers
public final class BlockDebugConfig: NSObject {
    
    public static let shared = BlockDebugConfig()
    
    private override init() {}
    
    public var openBlockDetailDebug = false
    
}

public final class BlockDebugService {
    
    private var debugData = BlockDebugData()
    
    public init() {}

    func getOpenBlockDetailDebug() -> Bool {
        return BlockDebugConfig.shared.openBlockDetailDebug
    }
    
    func setContainerContext(context: OPContainerContext) {
        self.debugData.containerContext = context
    }
    
    func setDarkMode(isSupportDarkMode: Bool?) {
        self.debugData.isSupportDarkMode = isSupportDarkMode
    }
    
    func setAppName(appName: String) {
        self.debugData.appName = appName
    }
    
    func setBlockVersion(blockVersion: String) {
        self.debugData.blockVersion = blockVersion
    }
    
    func setPackageUrl(packageUrl: String) {
        self.debugData.packageUrl = packageUrl
    }
    
    func setBlockType(blockType: String) {
        self.debugData.blockType = blockType
    }
    
    public func getBlockDetailInfo() -> [BlockDebugDetailInfo: String?] {
        let containerConfig = self.debugData.containerContext?.containerConfig as? OPBlockContainerConfigProtocol
        return [ .appName: self.debugData.appName,
                 .appId: self.debugData.containerContext?.applicationContext.appID,
                 .blockId: self.debugData.containerContext?.blockContext.uniqueID.blockID,
                 .blockTypeId: self.debugData.containerContext?.uniqueID.identifier,
                 .isSupportDarkMode: self.debugData.isSupportDarkMode ?? false ? "yes" : "no",
                 .blockVersion: self.debugData.blockVersion,
                 .packageUrl: self.debugData.packageUrl,
                 .blockType: self.debugData.blockType,
                 .host: containerConfig?.host]
    }
    
    @objc func showBlockDetail(_ gesture: UIGestureRecognizer) {
        guard let window = gesture.view!.window else {
            return
        }
        OPNavigatorHelper.push(BlockDebugListViewController(getBlockDetailInfo()), window: window)
    }
    
    func addDebugGesture(slot: UIView) {
        let blockDebugGesture = UITapGestureRecognizer(target: self, action: #selector(showBlockDetail(_:)))
        blockDebugGesture.numberOfTapsRequired = 5
        slot.addGestureRecognizer(blockDebugGesture)
    }
}

fileprivate struct BlockDebugData {
    var appName: String?
    var blockVersion: String?
    var packageUrl: String?
    var blockType: String?
    var containerContext: OPContainerContext?
    var isSupportDarkMode: Bool?
}
