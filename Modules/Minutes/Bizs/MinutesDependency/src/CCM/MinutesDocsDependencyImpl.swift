//
//  MinutesDocsDependencyImpl.swift
//  MinutesMod
//
//  Created by Supeng on 2021/10/15.
//

import Foundation
import Minutes
import Swinject
import EENavigator
import LarkContainer
import SpaceInterface
import LarkDocsIcon
import RxSwift

public class MinutesDocsDependencyImpl: MinutesDocsDependency {
    private let userResolver: UserResolver

    let docsIconManager: DocsIconManager

    private lazy var disposeBag: DisposeBag = { DisposeBag() }()

    public init(resolver: UserResolver) throws {
        self.userResolver = resolver
        docsIconManager = try userResolver.resolve(assert: DocsIconManager.self)
    }

    // disable-lint: magic number
    public func openDocShareViewController(token: String,
                                    type: Int,
                                    isOwner: Bool,
                                    ownerID: String,
                                    ownerName: String,
                                    url: String,
                                    title: String,
                                    tenantID: String,
                                    needPopover: Bool? = nil,
                                    padPopDirection: UIPopoverArrowDirection? = nil,
                                    popoverSourceFrame: CGRect? = nil,
                                    sourceView: UIView? = nil,
                                    isInVideoConference: Bool,
                                    hostViewController: UIViewController) {
        var body = DocShareViewControllerBody(token: token,
                                              type: 28,
                                              isOwner: isOwner,
                                              ownerId: ownerID,
                                              ownerName: ownerName,
                                              url: url,
                                              title: title,
                                              tenantID: tenantID,
                                              needPopover: needPopover,
                                              padPopDirection: padPopDirection,
                                              popoverSourceFrame: popoverSourceFrame,
                                              sourceView: sourceView,
                                              isInVideoConference: isInVideoConference,
                                              hostViewController: hostViewController,
                                              scPasteImmunity: true)
        body.enableShareWithPassWord = false
        body.enableTransferOwner = !(MinutesAudioRecorder.shared.status != .idle)
        if let service = try? userResolver.resolve(assert: DocShareViewControllerDependency.self) {
           service.openDocShareViewController(body: body, from: hostViewController)
        }
    }
    // enable-lint: magic number

    
    public func getDocsIconImageAsync(url: String, finish: @escaping (UIImage) -> Void) {
        docsIconManager.getDocsIconImageAsync(iconInfo: "", url: url, shape: .OUTLINE).subscribe { image in
            finish(image)
        }.disposed(by: disposeBag)
    }
}
