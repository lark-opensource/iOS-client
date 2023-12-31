//
//  LarkTemplateTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/2/2.
//  iOS-飞书 单测通用模板
/**
import XCTest
import ECOProbe
@testable import LarkSetting

/**
 - 为在代码中使用async/await语法，可在单测类前添加`@available(iOS 13.0, *)`并指定模拟器iOS版本>=13.0.
 */
@available(iOS 13.0, *)
final class LarkTemplateTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // MARK: NSAssert -> OPAssert
        /// 如果遇到Assert问题, 需要把对应`NSAssert`替换成`OPAssert`, 并在`setUpWithError()`和`tearDownWithError()`成对调用下述实例方法
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        AssertionConfigForTest.reset()
    }
    
    
    // MARK: - FG
    /**
     - 修改FG: 需添加`@testable import LarkSetting`
     - 在预期会读到`TestFGKey`的单测代码前调用`FeatureGatingStorage.updateDebugFeatureGating(fg:  "TestFGKey", isEnable: true/false, id: "")`.
     - warning: 确保读取FG的代码没有内部缓存FG的值, 都是从FeatureGatingManager获取的.
     */
    func test_larkFG() throws {
        let key = "TestFGKey"
        
        addTeardownBlock {
            // 结束时把默认值设置回false
            FeatureGatingStorage.updateDebugFeatureGating(fg: key, isEnable: false, id: "") // Global
        }
        
        // 无默认值
        let fgDefault = FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: key)) // Global
        XCTAssertFalse(fgDefault)
        
        // 修改成true，可生效
        FeatureGatingStorage.updateDebugFeatureGating(fg: key, isEnable: true, id: "")
        let fgTrue = FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: key)) // Global
        XCTAssertTrue(fgTrue)
        
        // 修改成false，可生效
        FeatureGatingStorage.updateDebugFeatureGating(fg: key, isEnable: false, id: "")
        let fgFalse = FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: key)) // Global
        XCTAssertFalse(fgFalse)
    }
    
    
    // MARK: - Setting
    /**
     - 修改Setting: 需添加`@testable import LarkSetting`
     - 在预期会读到`TestSettingKey`的单测代码前调用`SettingStorage.updateSettingValue("{}", with: "", and: "TestSettingKey")`。
     - 若未先调用`SettingStorage.updateSettingValue()`方法覆盖Setting， 那么通过`SettingManager.shared.setting(with: key)`获取到的值， 会来自`lark_setting`文件。 如果需要对下发默认值做单测判断， 请在Setting线上变更后及时修改单测判断。
     - warning: 确保读取Setting的代码没有自行缓存Setting的值， 而应当是从SettingManager获取的。
     */
    func test_larkSetting() throws {
        let key = "TestSettingKey"
        let mockValue = "{\"key\": \"value\"}"
        
        // 无默认值时，获取结果为error
        var error: Error?
        do {
            let defaultSetting = try SettingManager.shared.setting(with: key) // Global
            XCTAssert(true, "defaultSetting: \(defaultSetting) should not exist")
        } catch let err {
            error = err
        }
        XCTAssertNotNil(error)
        
        addTeardownBlock {
            // 结束时把默认值设置为空
            SettingStorage.updateSettingValue("", with: SettingManager.currentChatterID(), and: key)
        }
        
        // 修改指定值
        SettingStorage.updateSettingValue(mockValue, with: SettingManager.currentChatterID(), and: key)
        let addResult = try SettingManager.shared.setting(with: key) // Global
        let outputValue = addResult["key"] as? String
        XCTAssertTrue(outputValue == "value")
    }
    
    
    // MARK: - LarkAssembly
    /**
     - 若代码对在LarkAssembly注册的能力有依赖， 请确保在Ecosystem壳工程中对相应的协议做实现和注入。
     */
    func test_larkAssembly() throws {
       
    }
}
*/
