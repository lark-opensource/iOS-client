//
//  Double+CT.swift
//  SpaceKit
//
//  Created by 邱沛 on 2018/10/28.
//

import Foundation

extension Double {
    //scientificDemarcationLen表示多少位以上转科学计数法
    public func toScientificString(with scientificDemarcationLen: Int) -> String? {
        let stringFormatter = NumberFormatter()
        stringFormatter.usesSignificantDigits = true
        //默认最大有效数字
        stringFormatter.maximumSignificantDigits = 15
        stringFormatter.maximumIntegerDigits = 310
        guard let stringValue = stringFormatter.string(from: NSNumber(value: self)) else { return nil }
        let intSegment = stringValue.split(separator: ".")

        if String(intSegment[0]).count > scientificDemarcationLen {
            let formatter = NumberFormatter()
            formatter.numberStyle = .scientific
            formatter.maximumSignificantDigits = 6
            formatter.minimumSignificantDigits = 6
            let string = formatter.string(from: NSNumber(value: self))
            let res = string?.replacingOccurrences(of: "E", with: "e+")
            return res
        } else {
            return stringValue
        }
    }

    public func toString(with precision: Int) -> String {
        let precision = precision < 0 ? 0 : precision
        let sq = pow(10, Double(precision))
        let roundNumber = Double((sq * self).rounded() / sq)
        let defaultString = String(format: "%.\(precision)f", self)
        let scientificCount: Int = 11
        if self >= pow(10, Double(scientificCount)) {
            return "\(self.toScientificString(with: scientificCount) ?? defaultString)"
        } else {
            return String(format: "%.\(precision)f", roundNumber)
        }
    }
}
