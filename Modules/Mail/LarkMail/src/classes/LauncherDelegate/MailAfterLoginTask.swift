//
//  MailAfterLoginStageTask.swift
//  LarkMail
//
//  Created by tefeng liu on 2020/7/7.
//

import Foundation
import BootManager
import RunloopTools
import LarkPerf
import LarkContainer
import MailSDK
import LarkAccountInterface
import LarkFeatureGating
import LKCommonsLogging
import LKLoadable
import AppContainer
import LarkStorage
import RxSwift
import LarkSetting


class SetupMailTask: UserFlowBootTask, Identifiable {
    static var identify: TaskIdentify = "SetupMailTask"
    let disposeBag = DisposeBag()

    override var scope: Set<BizScope> {
        return [.mail]
    }

    @ScopedProvider private var service: LarkMailService?
    @ScopedProvider private var featureGatingService: FeatureGatingService?
    let logger = Logger.log(SetupMailTask.self, category: "Module.Mail")

    override class var compatibleMode: Bool { MailUserScope.userScopeCompatibleMode }

    override func execute(_ context: BootContext) {
        let isFastLogin = context.isFastLogin
        if isFastLogin { AppStartupMonitor.shared.start(key: .mailSDK) }

        if isFastLogin { AppStartupMonitor.shared.end(key: .mailSDK) }

        DispatchQueue.global(qos: .utility).async { [weak self] in
            // setting配置更新
            CommonSettingProvider.shared.fetchSetting()
            self?.registerSandboxMigration()
        }
    }

    func registerSandboxMigration() {
        let msgBiz: MailBiz = .msgList
        let sendBiz: MailBiz = .sendPage
        if let accountID = MailSettingManagerInterface.getCachedCurrentAccount(fetchNet: false)?.mailAccountID {
            let mSpace: MSpace = .account(id: accountID)
            let domain = Domains.Business.mail.child(mSpace.isolationId)
            self.registerSandboxMigrationInMsgListBiz(domain: domain.child(msgBiz.isolationId))
            self.registerSandboxMigrationInSendPageBiz(domain: domain.child(sendBiz.isolationId))
        } else {
            MailSettingManagerInterface.getCurrentAccount().subscribe { [weak self] (account) in
                guard let `self` = self else { return }
                let mSpace: MSpace = .account(id: account.mailAccountID)
                let domain = Domains.Business.mail.child(mSpace.isolationId)
                self.registerSandboxMigrationInMsgListBiz(domain: domain.child(msgBiz.isolationId))
                self.registerSandboxMigrationInSendPageBiz(domain: domain.child(sendBiz.isolationId))
            } onError: { [weak self] (err) in
                self?.logger.error("setting error: \(err)")
            }.disposed(by: self.disposeBag)
        }
    }

    func registerSandboxMigrationInSendPageBiz(domain: Domain) {
        SBMigrationRegistry.registerMigration(forDomain: domain) { space in
            guard case .global = space else { return [:] }
            return [
                .library: .whole(
                    fromRoot: AbsPath.library + "MailSDK/Attachment",
                    strategy: .moveOrDrop(allows: [.background, .intialization])
                ),
                .cache: .whole(
                    fromRoot: AbsPath.cache + "attachment",
                    strategy: .moveOrDrop(allows: [.background, .intialization])
                )
            ]
        }
    }

    func registerSandboxMigrationInMsgListBiz(domain: Domain) {
        SBMigrationRegistry.registerMigration(forDomain: domain) { space in
            guard case .global = space else { return [:] }
            return [
                .cache: .whole(
                    fromRoot: AbsPath.cache + "readmail/image",
                    strategy: .moveOrDrop(allows: [.background, .intialization])
                )
            ]
        }
    }
}
