//
//  NavigatorExensionTest.swift
//  EENavigatorDevEEUnitTest
//
//  Created by xiongmin on 2021/10/18.
//

import UIKit
import Foundation
import XCTest
import EENavigator

class TestURLInterceptorFrom: NavigatorFrom {
    
    var fromViewController: UIViewController?
    
}

class NavigatorExensionTest: XCTestCase {
    
    static let body = TestOpenBody()
    
    override class func setUp() {
        super.setUp()
        Navigator.shared.registerRoute(type: TestOpenBody.self) { body, req, res in
            let vc = UIViewController()
            res.end(resource: vc)
        }
        Navigator.shared.registerRoute(pattern: "/testInterceptor") { req, res in
            let vc = UIViewController()
            res.end(resource: vc)
        }
        
        URLInterceptorManager.shared.register("/testInterceptor") { url, from in
            
        }
        
    }
    
    override class func tearDown() {
        super.tearDown()
    }
    
    func testMainScene() throws {
        guard #available(iOS 13.0, *) else {
            throw XCTSkip("Unsupported iOS Version")
        }
        let mainScene = Navigator.shared.mainScene
        XCTAssertNotNil(mainScene)
    }
    
    func testMainSceneWindow() {
        let mainWindow = Navigator.shared.mainSceneWindow
        XCTAssertNotNil(mainWindow)
    }
    
    func testmainSceneWindows() {
        let mainWindow = Navigator.shared.mainSceneWindows
        XCTAssert(mainWindow.count != 0)
    }
    
    func testMainSceneTopMost() {
        let controller = Navigator.shared.mainSceneTopMost
        XCTAssertNotNil(controller)
    }
    
    func testGetResource() {
        Navigator.shared.getResource(body: Self.body, context: [:]) { res in
            XCTAssertNotNil(res)
        }
    }
    
    func testURLInterceptor() {
        let controller = Navigator.shared.mainSceneTopMost
        let from = TestURLInterceptorFrom()
        from.fromViewController = controller
        URLInterceptorManager.shared.handle(URL(string: "/testInterceptor")!, from: from, options: [UIApplication.OpenURLOptionsKey.sourceApplication: "test"])
    }
    

}
