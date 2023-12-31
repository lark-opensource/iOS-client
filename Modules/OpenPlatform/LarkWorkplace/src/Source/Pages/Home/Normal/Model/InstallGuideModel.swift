//
//  InstallGuideModel.swift
//  LarkWorkplace
//
//  Created by tujinqiu on 2020/3/13.
//

import UIKit
import LKCommonsLogging
import EENavigator
import SwiftyJSON
import LarkNavigator

enum InstallGuideAppLevel: String {
    case high
    case normal
}

// 权限内容
struct InstallGuideAppScope {
    let desc: String? // 权限描述
    let level: InstallGuideAppLevel // 权限级别

    init(json: JSON) {
        self.desc = json["desc"].string
        if let level = json["level"].string {
            self.level = InstallGuideAppLevel(rawValue: level) ?? .normal
        } else {
            self.level = .normal
        }
    }

    init(newScope: GuideAppScope) {
        self.desc = newScope.desc
        if let level = newScope.getLevel() {
            self.level = InstallGuideAppLevel(rawValue: level.rawValue) ?? .normal
        } else {
            self.level = .normal
        }
    }
}

struct InstallGuideApp {
    let appId: String?
    let iconKey: String?
    let name: String?
    let description: String?
    let scopes: [InstallGuideAppScope]?
    let applinkStoreUrl: String? // 跳转到应用商店的链接
    let privacyPolicyUrl: String? // 跳转到隐私协议的链接
    let clauseUrl: String? // 跳转到用户协议的链接

    init(json: JSON) {
        self.appId = json["appId"].string
        self.iconKey = json["iconKey"].string
        self.name = json["name"].string
        self.description = json["description"].string
        if let array = json["scopes"].array {
            self.scopes = array.map({ (json) -> InstallGuideAppScope in
                return InstallGuideAppScope(json: json)
            })
        } else {
            self.scopes = nil
        }
        self.applinkStoreUrl = json["applinkStoreUrl"].string
        self.privacyPolicyUrl = json["privacyPolicyUrl"].string
        self.clauseUrl = json["clauseUrl"].string
    }

    /// 适配新的数据结构
    init(app: OperationApp) {
        self.appId = app.appId
        self.iconKey = app.icon.key
        self.name = app.name
        self.description = app.description
        if let appScopes = app.scopes {
            self.scopes = appScopes.map({ (scope) -> InstallGuideAppScope in
                return InstallGuideAppScope(newScope: scope)
            })
        } else {
            self.scopes = nil
        }
        self.applinkStoreUrl = app.mobileAppstoreUrl
        self.privacyPolicyUrl = app.privacyPolicyUrl
        self.clauseUrl = app.clauseUrl
    }
}

struct InstallGuide {
    let apps: [InstallGuideApp]?
    let isAdmin: Bool

    init(json: JSON) {
        if let apps = json["apps"].array {
            self.apps = apps.map({ (json) -> InstallGuideApp in
                return InstallGuideApp(json: json)
            })
        } else {
            self.apps = nil
        }
        self.isAdmin = json["isAdmin"].boolValue
    }
}

final class InstallGuideAppViewModel {
    static let logger = Logger.log(InstallGuideAppViewModel.self)

    let app: InstallGuideApp
    var isSelected: Bool = false
    private let navigator: UserNavigator

    init(app: InstallGuideApp, navigator: UserNavigator) {
        self.app = app
        self.navigator = navigator
    }

    /// 适配新的数据结构
    convenience init(newApp: OperationApp, navigator: UserNavigator) {
        self.init(app: InstallGuideApp(app: newApp), navigator: navigator)
    }

    func gotoDetail() {
        guard let applinkStoreUrl = app.applinkStoreUrl,
            let url = URL(string: applinkStoreUrl)?.lf.toHttpUrl(),
            let fromVC = navigator.mainSceneWindow?.fromViewController else { return }
        InstallGuideAppViewModel.logger.info("open appStore detail: \(url)")
        navigator.push(url, context: ["from": "appcenter"], from: fromVC, animated: true, completion: nil)
    }

    func gotoPrivacy() {
        guard let privacyPolicyUrl = app.privacyPolicyUrl,
            let url = URL(string: privacyPolicyUrl)?.lf.toHttpUrl(),
            let fromVC = navigator.mainSceneWindow?.fromViewController else { return }
        InstallGuideAppViewModel.logger.info("Open the privacy protocol:\(url)")
        navigator.push(url, context: ["from": "appcenter"], from: fromVC, animated: true, completion: nil)
    }

    func gotoUserClause() {
        guard let clauseUrl = app.clauseUrl,
            let url = URL(string: clauseUrl)?.lf.toHttpUrl(),
            let fromVC = navigator.mainSceneWindow?.fromViewController else { return }
        InstallGuideAppViewModel.logger.info("Open the user protocol:\(url)")
        navigator.push(url, context: ["from": "appcenter"], from: fromVC, animated: true, completion: nil)
    }

    // 抽取普通权限
    lazy var basicScopes: [InstallGuideAppScope] = {
        app.scopes?.filter({ $0.level == .normal }) ?? []
    }()

    // 抽取用户权限
    lazy var advancedScopes: [InstallGuideAppScope] = {
        app.scopes?.filter({ $0.level == .high }) ?? []
    }()
}

protocol InstallGuideViewModelDelegate: AnyObject {
    // 跳转到权限条款页面
    func gotoClausePage(viewModel: InstallGuideViewModel)
}

final class InstallGuideViewModel {
    let onboardingApps: [InstallGuideAppViewModel]
    let isAdmin: Bool
    let hasSafeArea: Bool // iphoneX有刘海的和没有刘海的布局不一样
    weak var delegate: InstallGuideViewModelDelegate?

    init(model: InstallGuide, hasSafeArea: Bool, navigator: UserNavigator) {
        if let apps = model.apps {
            self.onboardingApps = apps.map({ (app) -> InstallGuideAppViewModel in
                return InstallGuideAppViewModel(app: app, navigator: navigator)
            })
        } else {
            self.onboardingApps = []
        }
        self.isAdmin = model.isAdmin
        self.hasSafeArea = hasSafeArea
    }

    init(apps: [OperationApp], isAdmin: Bool, hasSafeArea: Bool, navigator: UserNavigator) {
        self.onboardingApps = apps.map({ (app) -> InstallGuideAppViewModel in
            return InstallGuideAppViewModel(newApp: app, navigator: navigator)
        })
        self.isAdmin = isAdmin
        self.hasSafeArea = hasSafeArea
    }

    func gotoClausePage() {
        InstallGuideAppViewModel.logger.info("open clause page")
        delegate?.gotoClausePage(viewModel: self)
    }
}
