//  Created by Songwen Ding on 2018/8/2.

import Foundation

public struct DocsTimeline {
    var startTime = CFAbsoluteTimeGetCurrent()
    public func totalDuration() -> CFAbsoluteTime {
        return (CFAbsoluteTimeGetCurrent() - self.startTime)
    }
    public init() {
        
    }
}
