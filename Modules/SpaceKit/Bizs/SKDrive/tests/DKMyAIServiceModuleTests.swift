//
//  DKMyAIModuleTests.swift
//  SKDrive-Unit-Tests
//
//  Created by zenghao on 2023/10/13.
//
import XCTest
import SKFoundation
@testable import SKDrive
import LarkContainer
import SpaceInterface
import LarkAIInfra
import EENavigator
import RxSwift
import RxCocoa


class DKMyAIServiceModuleTests: XCTestCase {
    
    var bag = DisposeBag()
    
    var hostModule: DKHostModuleType!
    var myAIModule: DKMyAIServiceModule!

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }
    
    
    class MockAIService: CCMAIService {
        var enable: RxRelay.BehaviorRelay<Bool> {
            return .init(value: true)
        }
        
        var needOnboarding: RxRelay.BehaviorRelay<Bool> = .init(value: false)
        
        func openMyAIChatMode(config: SpaceInterface.CCMAIChatModeConfig, from: UIViewController) {
            let chatId = config.chatId
            let chatModeId = config.aiChatModeId
            
            XCTAssertEqual(chatId, 123456789)
            XCTAssertEqual(chatModeId, 987654321)
        }
        
        func openOnboarding(from: EENavigator.NavigatorFrom, onSuccess: ((Int64) -> Void)?, onError: ((Error?) -> Void)?, onCancel: (() -> Void)?) {
            if needOnboarding.value {
                onSuccess?(123456789)
            } else {
                XCTFail()
            }
        }
        
        func getAIChatModeInfo(scene: String, link: String?, appData: String?, complete: @escaping (SpaceInterface.CCMBasicAIChatModeInfo?) -> Void) {
            let chatMode = CCMBasicAIChatModeInfo(chatID: 123456789, chatModeID: 987654321)
            complete(chatMode)
            return
        }
            
    }
    
    func testEnterAIPage() {
        Container.shared.register(CCMAIService.self) { r in
            return MockAIService()
        }.inObjectScope(.user)

        let hostModuleVC = MockDKHostSubModule()
        hostModule = MockHostModule(hostController: hostModuleVC)
        myAIModule = DKMyAIServiceModule(hostModule: hostModule)
        _ = myAIModule.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.showMyAIVC)
    }
    
    func testOpenAIOnbarding() {
        Container.shared.register(CCMAIService.self) { r in
            return MockAIService()
        }.inObjectScope(.user)

        let hostModuleVC = MockDKHostSubModule()
        hostModule = MockHostModule(hostController: hostModuleVC)
        myAIModule = DKMyAIServiceModule(hostModule: hostModule)
        _ = myAIModule.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.showMyAIVC)
    }
}
