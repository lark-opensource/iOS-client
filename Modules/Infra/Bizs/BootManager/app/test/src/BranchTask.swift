//
//  BranchTask.swift
//  BootManagerDevEEUnitTest
//
//  Created by KT on 2020/6/12.
//

import Foundation
@testable import BootManager

var shouldPrivacyCheckTask: Bool = false
class PrivacyCheckTask: BranchLaunchTask, Identifiable {
    static var identify: String = String(describing: PrivacyCheckTask.self)
    override func execute(_ context: BootContext) {
        if shouldPrivacyCheckTask {
            result.append(self.identify.checkout)
            self.branchCheckout()
        } else {
            result.append(self.identify)
        }
    }
}

var shouldFastLoginTask: Bool = false
class FastLoginTask: BranchLaunchTask, Identifiable {
    static var identify: String = String(describing: FastLoginTask.self)
    override func execute(_ context: BootContext) {
        if shouldFastLoginTask {
            result.append(self.identify.checkout)
            self.branchCheckout()
        } else {
            result.append(self.identify)
        }
    }
}

var shouldLaunchBlockRequestCheckTask: Bool = false
class LaunchBlockRequestCheckTask: BranchLaunchTask, Identifiable {
    static var identify: String = String(describing: LaunchBlockRequestCheckTask.self)
    override func execute(_ context: BootContext) {
        if shouldLaunchBlockRequestCheckTask {
            result.append(self.identify.checkout)
            self.branchCheckout()
        } else {
            result.append(self.identify)
        }
    }
}

var shouldGodoCreateTeam: Bool = false
var shouldGodoLogin: Bool = false
// Async/Branch
class LaunchGuideTask: AsyncLaunchTask, Identifiable {
    static var identify: String = String(describing: LaunchGuideTask.self)
    override func execute(_ context: BootContext) {
        if shouldGodoCreateTeam {
            result.append(self.identify.checkout)
            self.branchCheckout(.createTeamStage)
        } else if shouldGodoLogin {
            result.append(self.identify.checkout)
            self.branchCheckout(.loginStage)
        } else {
            result.append(self.identify)
        }
    }
}

class NewPrivacyCheckTask: BranchBootTask, Identifiable {
    static var identify: String = "PrivacyCheckTask"
    override func execute(_ context: BootContext) {
        if shouldPrivacyCheckTask {
            result.append(self.identify.checkout)
            self.flowCheckout(.privacyAlertFlow)
        } else {
            result.append(self.identify)
        }
    }
}

class NewFastLoginTask: BranchBootTask, Identifiable {
    static var identify: String = "FastLoginTask"
    override func execute(_ context: BootContext) {
        if shouldFastLoginTask {
            result.append(self.identify.checkout)
            self.flowCheckout(.launchGuideFlow)
        } else {
            result.append(self.identify)
        }
    }
}

class NewLaunchBlockRequestCheckTask: BranchBootTask, Identifiable {
    static var identify: String = "LaunchBlockRequestCheckTask"
    override func execute(_ context: BootContext) {
        if shouldLaunchBlockRequestCheckTask {
            result.append(self.identify.checkout)
            self.flowCheckout(.launchGuideLoginFlow)
        } else {
            result.append(self.identify)
        }
    }
}

// Async/Branch
class NewLaunchGuideTask: AsyncBootTask, Identifiable {
    static var identify: String = "LaunchGuideTask"
    override func execute(_ context: BootContext) {
        if shouldGodoCreateTeam {
            result.append(self.identify.checkout)
            self.flowCheckout(.createTeamFlow)
        } else if shouldGodoLogin {
            result.append(self.identify.checkout)
            self.flowCheckout(.loginFlow)
        } else {
            result.append(self.identify)
        }
    }
}
