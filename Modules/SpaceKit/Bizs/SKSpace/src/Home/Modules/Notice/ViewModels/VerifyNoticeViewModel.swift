//
//  VerifyNoticeViewModel.swift
//  SKSpace
//
//  Created by majie on 2021/9/23.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxRelay
import RxCocoa
import SKResource
import SwiftyJSON
import SKUIKit
import SKInfra
import LarkContainer

public final class VerifyNoticeViewModel: SpaceNoticeViewModel {
    typealias State = ComplaintState
    private var folderToken: String
    private var request: DocsRequest<JSON>?
    private var complaint = false
    private var isSingleContainer: Bool
    private var folderName: String?
    private var folderDescripte: String?
    private var disposeBag = DisposeBag()
    
    init(userResolver: UserResolver,
         token: String,
         isSingleContainer: Bool,
         bulletinManager: DocsBulletinManager,
         commonTrackParams: [String: String]) {
        self.folderToken = token
        self.isSingleContainer = isSingleContainer
        super.init(userResolver: userResolver, bulletinManager: bulletinManager, commonTrackParams: commonTrackParams)
        folderVerifyRefresh()
    }
    
    override func addNetworkUnreachableIfNeed() {
        var currentNotices = noticesRelay.value
        if currentNotices.contains(.networkUnreachable) { return }
        currentNotices.insert(.networkUnreachable, at: 0)
        noticesRelay.accept(currentNotices)
        folderVerifyShouldRemove()
    }
    
    override func removeNetworkUnreachableIfNeed() {
        var currentNotices = noticesRelay.value
        guard let unreachableIndex = currentNotices.firstIndex(of: .networkUnreachable) else {
            DocsLogger.info("space.notice.vm --- unreachable notice index not found when removing")
            return
        }
        currentNotices.remove(at: unreachableIndex)
        noticesRelay.accept(currentNotices)
        featchComplaintInfo()
    }
    
    public override func bannerRefresh() {
        folderVerifyRefresh()
    }
    
    /// 判断文件夹是否处于封禁状态
    public func folderIscomplaint(completion: @escaping ((Bool?) -> Void)) {
        let pramas = ["token": folderToken]
        request?.cancel()
        var apiPath = OpenAPI.APIPath.folderDetail
        if isSingleContainer {
            apiPath = OpenAPI.APIPath.childrenListV3
        }
        
        request = DocsRequest<JSON>(path: apiPath, params: pramas)
            .set(method: .GET)
            .start(result: { result, error in
                if let error = error {
                    DocsLogger.error("error \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                guard let json = result,
                      let complaintValue = json["data"]["entities"]["nodes"][self.folderToken]["extra"]["complaint"].bool else {
                    DocsLogger.error("request failed data invalide")
                    completion(nil)
                    return
                }
                completion(complaintValue)
            })
    }
    
    public func featchComplaintInfo() {
        guard complaint else { return }
        request?.cancel()
        var pramas: [String: Any] = [:]
        pramas = ["obj_type": 0, "obj_token": folderToken]  /// obj_type针对文件夹传0
        if UserScopeNoChangeFG.PLF.appealV2Enable {
            pramas["transit"] = true
        }
        request = DocsRequest<JSON>(path: OpenAPI.APIPath.getComplaintInfo, params: pramas)
            .set(method: .GET)
            .start(result: { [weak self] result, error in
                guard let self = self else { return }
                guard let json = result,
                      let code = DocsNetworkError(json["code"].int)?.code else {
                    DocsLogger.error("request failed data invalide")
                    return
                }
                let resultCode = json["data"]["result"].int
                switch code {
                case .success where resultCode == PermissionError.ComplaintResultCode.inProgress.rawValue:
                    /// 申诉中
                    self.folderVerifyShouldAdd(.verifying)
                case .success where resultCode == PermissionError.ComplaintResultCode.pass.rawValue:
                    /// 审核通过
                    self.folderVerifyShouldAdd(.machineVerify)
                case .success where resultCode == PermissionError.ComplaintResultCode.noPass.rawValue:
                    ///不通过
                    self.folderVerifyShouldAdd(.verifyFailed)
                case .appealEnable:
                    /// 允许申诉
                    self.folderVerifyShouldAdd(.machineVerify)
                case .appealing:
                    /// 申诉中
                    self.folderVerifyShouldAdd(.verifying)
                case .appealRejected:
                    /// 申诉被驳回
                    self.folderVerifyShouldAdd(.verifyFailed)
                case .notFound:
                    /// 未申诉
                    self.folderVerifyShouldAdd(.machineVerify)
                case .dailyLimit:
                    /// 当日到达上限
                    self.folderVerifyShouldAdd(.reachVerifyLimitOfDay)
                case .allLimit:
                    /// 申诉到达总上限
                    self.folderVerifyShouldAdd(.reachVerifyLimitOfAll)
                case .timeShort:
                    self.folderVerifyShouldAdd(.verifyFailed)
                default:
                    /// 兜底清空所有关于申诉的banner
                    self.folderVerifyShouldRemove()
                }
            })
    }
    
    public func folderVerifyRefresh() {
        folderIscomplaint(completion: { complaint in
            guard let complaintValue = complaint else {
                self.folderVerifyShouldRemove()
                return
            }
            self.complaint = complaintValue
            if complaintValue {
                self.featchComplaintInfo()
            } else {
                self.folderVerifyShouldRemove()
            }
        })
    }
    
    private func folderVerifyShouldAdd(_ type: State) {
        var currentNotice = noticesRelay.value
        for item in currentNotice {
            if case .folderVerify = item {
                if let index = currentNotice.firstIndex(of: item) {
                    currentNotice.remove(at: index)
                }
            }
        }
        let tips: NSAttributedString
        if UserScopeNoChangeFG.PLF.appealV2Enable {
            tips = NSAttributedString(string: type.folderAppealV2)
        } else {
            tips = NSAttributedString(string: type.detail)
        }
        currentNotice.append(.folderVerify(type: type, tips: tips, token: folderToken))
        noticesRelay.accept(currentNotice)
    }
    
    public func folderVerifyShouldRemove() {
        var currentNotice = noticesRelay.value
        for item in currentNotice {
            if case .folderVerify = item {
                if let index = currentNotice.firstIndex(of: item) {
                    currentNotice.remove(at: index)
                }
            }
        }
        noticesRelay.accept(currentNotice)
    }
}

extension VerifyNoticeViewModel {
    func shouldOpenVerifyURL(type: State) {
        if type == .machineVerify || type == .verifyFailed {
            let provider = SpaceFolderAppealInfoProvider(token: folderToken, isSingleContainer: isSingleContainer)
            let vc = SubmitAppealViewController(token: folderToken, objType: .folder, provider: provider)
            self.actionInput.accept(.push(viewController: vc))
        } else {
            let urlString = "https://applink.feishu.cn/TdSgr1y9"
            if let url = URL(string: urlString) {
                self.actionInput.accept(.openURL(url: url, context: nil))
            }
        }
    }

    func openURL(url: URL) {
        self.actionInput.accept(.openURL(url: url, context: nil))
    }
}
