//
//  MinutesServiceImp.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/11.
//

import Foundation
import MinutesInterface
import EENavigator
import MinutesFoundation
import MinutesNetwork
import LarkAccountInterface
import LarkGuide
import Minutes
import Swinject
import LarkContainer
//import ByteViewInterface
import LKCommonsLogging

/// Minutes 模块对外提供的接口
public final class MinutesServiceImp: MinutesService {

    public var tabURL: URL?
    static let logger = Logger.log(MinutesServiceImp.self, category: "Minutes")

    /// 初始化方法
    let userResolver: UserResolver
    var resolver: Resolver?
    
    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    /// 打开Minutes
    ///
    /// - Parameters:
    ///   - url: The URL of the minutes
    /// - Returns:
    ///   - Bool: whether the URL is an avalible URL of the minutes
    @discardableResult
    public func openMinutes(_ url: URL?) -> AnyObject? {
        guard let baseURL = url, Minutes.isMinutesURL(baseURL) else {
            return nil
        }

        if MinutesAudioRecorder.shared.minutes?.baseURL == baseURL {
            return MinutesAudioRecorder.shared.minutes
        } else {
            return Minutes(baseURL)
        }
    }

    public func setupMinutes() {
        do {
            let passportUserService = try userResolver.resolve(assert: LarkAccountInterface.PassportUserService.self)
            
            let passportService = try userResolver.resolve(assert: LarkAccountInterface.PassportService.self)
            passportService.register(interruptOperation: MinutesInterruptOperation(resolver: userResolver))

            let defaultAPI = try userResolver.resolve(assert: MinutesAPI.self)
            let guide = try userResolver.resolve(assert: NewGuideService.self)
            let dependency = try userResolver.resolve(assert: MinutesDependency.self)

            MinutesAPI.setup(defaultAPI)
        } catch {
            Self.logger.error("resolve error: \(error)")
        }
    }
}
