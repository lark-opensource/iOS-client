// 
// Created by duanxiaochen.7 on 2019/11/4.
// Affiliated with SpaceKit.
// 
// Description: OnboardingTask describes a display task for an onboarding item.

import SKFoundation
import RxSwift

class OnboardingTask: Equatable {

    let id: OnboardingID

    weak var delegate: OnboardingDelegate?

    weak var dataSource: OnboardingDataSource?

    init(called id: OnboardingID, delegate: OnboardingDelegate, dataSource: OnboardingDataSource) {
        self.id = id
        self.delegate = delegate
        self.dataSource = dataSource
    }

    static func == (lhs: OnboardingTask, rhs: OnboardingTask) -> Bool {
        return lhs.id == rhs.id
    }

    func checkPreconditions() -> Bool {
        guard let delegate = delegate, let dataSource = dataSource else {
            DocsLogger.onboardingError("引导 \(id.rawValue) 未通过前置条件，没有提供代理和数据源")
            return false
        }
        if dataSource.onboardingShouldCheckDependencies(for: id) {
            for dependency in dataSource.onboardingDependencies(for: id) {
                guard OnboardingSynchronizer.shared.isFinished(dependency) else {
                    DocsLogger.onboardingError("引导 \(id.rawValue) 未通过前置条件，依赖 \(dependency.rawValue) 还没显示过呢")
                    delegate.onboardingDependenciesUnfinished(for: id)
                    return false
                }
            }
        }
        return true
    }
}



class OnboardingTextTask: OnboardingTask {}



class OnboardingFlowTask: OnboardingTask {

    weak var flowDataSource: OnboardingFlowDataSources!

    init(called id: OnboardingID, delegate: OnboardingDelegate, dataSource: OnboardingFlowDataSources) {
        self.flowDataSource = dataSource
        super.init(called: id, delegate: delegate, dataSource: dataSource)
    }
}



class OnboardingCardTask: OnboardingTask {

    weak var cardDataSource: OnboardingCardDataSources!

    init(called id: OnboardingID, delegate: OnboardingDelegate, dataSource: OnboardingCardDataSources) {
        self.cardDataSource = dataSource
        super.init(called: id, delegate: delegate, dataSource: dataSource)
    }

    override func checkPreconditions() -> Bool {
        guard super.checkPreconditions() else { return false }

        if cardDataSource.onboardingImage(for: id) == nil && cardDataSource.onboardingLottieView(for: id) == nil {
            DocsLogger.onboardingError("引导 \(id.rawValue) 未通过前置条件，没有提供卡片顶部的图片或动画")
            return false
        } else {
            return true
        }
    }
}
