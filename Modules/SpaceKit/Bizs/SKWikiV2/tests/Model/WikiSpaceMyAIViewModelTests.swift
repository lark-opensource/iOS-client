//
//  WikiSpaceMyAIViewModelTests.swift
//  SKWikiV2-Unit-Tests
//
//  Created by zenghao on 2023/10/7.
//

@testable import SKWikiV2
@testable import SKFoundation
@testable import SKWorkspace
import XCTest
import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import SpaceInterface
import LarkAIInfra
import EENavigator

final class WikiSpaceMyAIViewModelTests: XCTestCase {
    
    var bag = DisposeBag()
    let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)

    
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

        let vm = WikiSpaceMyAIViewModel(spaceID: "Test_Space_1", hostVC: UIViewController())
        vm.enterMyAIChat()
    }
    
    func testOpenAIOnbarding() {
        let mockAIService = MockAIService()
        mockAIService.needOnboarding.accept(true)
        Container.shared.register(CCMAIService.self) { r in
            return mockAIService
        }.inObjectScope(.user)
        
        let vm = WikiSpaceMyAIViewModel(spaceID: "Test_Space_1", hostVC: UIViewController())
        vm.enterMyAIChat()
    }

}
