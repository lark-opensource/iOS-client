//
//  WorkplaceMonitorable+Extension.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/8.
//

import Foundation
import ECOInfra

/// 符合 OPMointor 使用习惯的封装。
extension WorkplaceMonitorable {
    /// 工作台场景语法糖，可以设置一些 message 信息（非 error message）。
    @discardableResult func setWorkplaceMessage(_ message: String) -> WorkplaceMonitorable {
        return setValue(message, for: .wp_message)
    }

    @discardableResult func setErrorCode(_ code: Int) -> WorkplaceMonitorable {
        return setValue(code, for: .error_code)
    }

    @discardableResult func setErrorMessage(_ message: String) -> WorkplaceMonitorable {
        return setValue(message, for: .error_msg)
    }

    @discardableResult func setResultType(_ resultType: WorkplaceMonitorResultValue) -> WorkplaceMonitorable {
        return setValue(resultType.rawValue, for: .result_type)
    }

    @discardableResult func setResultTypeSuccess() -> WorkplaceMonitorable {
        return setResultType(.success)
    }

    @discardableResult func setResultTypeFail() -> WorkplaceMonitorable {
        return setResultType(.fail)
    }

    @discardableResult func setDuration(_ duration: Double) -> WorkplaceMonitorable {
        return setValue(duration, for: .duration)
    }
}
