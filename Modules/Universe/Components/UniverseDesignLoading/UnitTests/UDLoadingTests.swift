import UIKit
import Foundation
import XCTest
@testable import UniverseDesignLoading
import UniverseDesignColor

class UDLoadingTests: XCTestCase {

    func testSpin() {
        let indicatorConfig = UDSpinIndicatorConfig(size: 12, color: .blue, circleDegree: 0.9, animationDuration: 2.0)
        let textLabelConfig = UDSpinLabelConfig(text: "1232", font: .systemFont(ofSize: 15), textColor: .red)
        let config = UDSpinConfig(indicatorConfig: indicatorConfig, textLabelConfig: textLabelConfig)
        let spin = UDLoading.spin(config: config)
        XCTAssertEqual(spin.textLabel?.text, textLabelConfig.text)
        XCTAssertEqual(spin.textLabel?.font.pointSize, textLabelConfig.font.pointSize)
        XCTAssertEqual(spin.textLabel?.textColor.cgColor.components, textLabelConfig.textColor.cgColor.components)
    }

    func testPresetSpin() {
        let spin = UDLoading.presetSpin()
        XCTAssertNil(spin.textLabel)
        XCTAssertEqual(spin.textLabel?.font.pointSize, UIFont.systemFont(ofSize: 14).pointSize)
        XCTAssertEqual(spin.textLabel?.textColor.cgColor.components, UIColor.ud.neutralColor8.cgColor.components)
    }
}
