//
//  UserGuideService.swift
//  SpaceKit
//
//  Created by 段晓琛 on 2019/5/23.
//

import SKCommon
import SKFoundation

private let undefined = "mobile_illegal_onboarding_item"

public final class UserGuideService: BaseJSService {}

extension UserGuideService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.userGuide]
    }

    public func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info("UserGuideService \(params.description) \(serviceName)")
        guard let bvc = registeredVC as? BrowserViewController else {
            DocsLogger.onboardingError("不在 BrowserViewController 里不能显示前端触发的引导")
            return
        }
        guard !bvc.isInVideoConference else {
            DocsLogger.onboardingInfo("VC Follow 时不能显示引导")
            return
        }
        if bvc.forceFull {
            return
        }
        guard let action = params["action"] as? String else {
            DocsLogger.onboardingError("最关键的引导 key 没给")
            model?.jsEngine.callFunction(DocsJSCallBack.notifyGuideFinish,
                                         params: ["action": undefined,
                                                  "status": "failed"], completion: nil)
            return
        }
        guard let id = OnboardingID(rawValue: action) else {
            DocsLogger.onboardingError("我不能播放 \(action)!!")
            model?.jsEngine.callFunction(DocsJSCallBack.notifyGuideFinish,
                                         params: ["action": action,
                                                  "status": "failed"], completion: nil)
            return
        }
        if let currentIndex = params["currentIndex"] as? Int,
            let totalCount = params["totalCount"] as? Int {
            bvc.onboardingIndexes[id] = "\(currentIndex)/\(totalCount)"
            DocsLogger.onboardingDebug("前端设置 \(id) 的页码为 \(currentIndex)/\(totalCount)")
        }
        if let position = params["position"] as? [String: Any],
           let x = position["x"] as? CGFloat, let y = position["y"] as? CGFloat {
            DocsLogger.onboardingDebug("前端传过来的相对于 webview 左上角坐标：x: \(x), y: \(y)")
            //将前端传过来的坐标转换为 BrowserViewController.view 坐标
            let point = ui?.editorView.convert(CGPoint(x: x, y: y), to: bvc.view) ?? CGPoint(x: x, y: y)
            
            if let width = position["width"] as? CGFloat, let height = position["height"] as? CGFloat {
                let targetRect = CGRect(x: point.x, y: point.y, width: width, height: height)
                bvc.onboardingTargetRects[id] = targetRect
                DocsLogger.onboardingDebug("前端设置 \(id) 指向 \(targetRect)")
            } else {
                let targetRect = CGRect(x: point.x, y: point.y, width: 0, height: 0)
                bvc.onboardingTargetRects[id] = targetRect
                DocsLogger.onboardingDebug("前端设置 \(id) 指向 \(targetRect)")
            }
        }
        if let isLast = params["isLast"] as? Bool {
            bvc.onboardingIsLast[id] = isLast
            DocsLogger.onboardingDebug("前端设置 \(id) \(isLast ? "" : "不")是最后一个引导")
        }
        if let nextID = params["nextID"] as? String,
            let next = OnboardingID(rawValue: nextID) {
            bvc.onboardingNextIDs[id] = next
            DocsLogger.onboardingDebug("前端设置 \(id) 的 nextID 为 \(next)")
        }
        if let shouldCheckDependencies = params["shouldCheckDependencies"] as? Bool {
            bvc.onboardingShouldCheckDependenciesMap[id] = shouldCheckDependencies
            DocsLogger.onboardingDebug("前端设置 \(id) \(shouldCheckDependencies) 检查依赖")
        }

        bvc.showOnboarding(id: id)
    }
}
