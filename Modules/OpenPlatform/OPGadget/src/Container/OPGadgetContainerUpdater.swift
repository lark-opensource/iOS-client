//
//  OPGadgetContainerUpdater.swift
//  OPGadget
//
//  Created by yinyuan on 2020/12/17.
//

import Foundation
import OPSDK
import LKCommonsLogging
import LarkOPInterface
import TTMicroApp

private let logger = Logger.oplog(OPGadgetContainerUpdater.self, category: "OPGadgetContainerUpdater")

protocol OPGadgetContainerUpdaterDelegate: AnyObject {
    
    func reloadFromUpdater()
    
}

class OPGadgetContainerUpdater {
    
    private let containerContext: OPContainerContext
    
    weak var delegate: OPGadgetContainerUpdaterDelegate?
    
    required init(containerContext: OPContainerContext) {
        self.containerContext = containerContext
    }
}

extension OPGadgetContainerUpdater: OPContainerUpdaterProtocol {
    
    func applyUpdateIfNeeded(_ beforeReloadBlock: (()->Void)?) -> Bool {
        
        logger.info("applyUpdateIfNeed \(containerContext.uniqueID)")
        
        // TODO: common 要改成传入模式，不要使用单例
        guard let common = BDPCommonManager.shared()?.getCommonWith(containerContext.uniqueID) else {
            logger.warn("common is nil")
            return false
        }
        
        guard let updateModel = BDPAppLoadManager.shareService().getUpdateInfo(with: containerContext.uniqueID) else {
            logger.warn("updateModel is nil")
            return false
        }
        
        guard let currentModel = common.model else {
            logger.warn("currentModel is nil")
            return false
        }
        
        if !updateModel.isNewerThanAppModel(currentModel) {
            logger.warn("!updateModel.isNewerThanAppModel")
            return false
        }
        
        // 一致性改造, Android和PC不会检查是否有包,这边进行对齐
        if !OPSDKFeatureGating.packageAPIUnifiedEnable() {
            if !BDPAppLoadManager.shareService().hasPackageDownloaded(updateModel.pkgName, for: containerContext.uniqueID) {
                logger.warn("!hasPackageDownloaded")
                return false
            }
        }
        //判断一下时间戳有没有过期
        if let context = BDPTaskManager.shared().getTaskWith(common.uniqueID)?.context,
           !context.shouldSendOnUpdateReadyEventOrApplyUpdate(with: common.uniqueID) {
            logger.warn("runtime shouldSendOnUpdateReadyEventOrApplyUpdateWith check fail, timestamp is not expired");
            return false
        }
        // TODO: launchFrom
        BDPAppManagerTrackEvent.asyncLoadApplyEnd(with: containerContext.uniqueID, launchFrom: "TODO", latestVersion: updateModel.version, currentVersion: currentModel.version)
        
        guard let delegate = delegate else {
            logger.warn("delegate is nil")
            return false
        }
        //每次成功ApplyUpdate导致更新之后，需要更新本地时间戳
        BDPTaskManager.shared().getTaskWith(common.uniqueID)?.context?.updateTimestampAfterApplyUpdateSuccess(with: common.uniqueID);
        // 重启
        if OPSDKFeatureGating.enableApplyUpdateImprove() {
            beforeReloadBlock?()
        }
        delegate.reloadFromUpdater()
        return true
    }
    
}
