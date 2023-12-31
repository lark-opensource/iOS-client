//
//  LarkAutoUITests.swift
//  LarkAutoUITests
//
//  Created by zhoushijie on 2019/2/1.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import XCTest

final class LarkAutoUITests: XCTestCase {

    // 对于需要滑动的元素，分为上下左右四种情况
    enum Direction: Int {
        case up = 0
        case right = 1
        case down = 2
        case left = 3
    }

    // UI元素的类型，有的元素需要点击，有的需要长按，有的需要滑动，有的需要输入文本
    enum TypeOfElment {
        case needTap
        case needPress(Double)
        case needSwipe(Direction)
        case needInputText(String)
    }

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.

        super.setUp()
        let app = XCUIApplication()

        // 设置语言环境为英文
        app.launchArguments += ["-AppleLanguages", "(en-US)"]
        app.launchArguments += ["-AppleLocale", "\"en-US\""]

        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testLark() {

        let app = XCUIApplication()

        // 设置随机数，最终生成的随机数是randomNumber1-randomNumber2，这样可以确保每次发送的纯文本一定是唯一的，方便后续的pin操作可以找到纯文本element
        let randomNumber1 = Int(arc4random() % 100_000)
        let randomNumber2 = Int(arc4random() % 100_000)
        let inputString = "This is a test case, the random number is \(randomNumber1)\(randomNumber2)"
        let searchNameString = "Shijie Zhou"

        // 将每次操作需要处理的UI元素存入一个数组
        // 准备阶段
        let prepareElementArray: [XCUIElement] = [
            app.buttons["⚙️"],
            app.tables.children(matching: .other).element(boundBy: 0),
            app.tables.switches["临时禁用调试悬浮球"],
            app.tables.collectionViews.cells.otherElements
            .containing(.staticText, identifier: "LarkLeakTest").children(matching: .other)
            .element.children(matching: .other).element
        ]

        // 发送纯文本
        let inputPureTextElementArray: [XCUIElement] = [
            app.textViews["ChatInput"], // 先点击
            app.textViews["ChatInput"], // 再输入
            app.buttons["Send"]
        ]

        // pin
        let pinElementArray: [XCUIElement] = [
            app.tables.staticTexts[inputString].firstMatch,
            app.collectionViews.cells.containing(.image, identifier: "menu_pin").children(matching: .other).element,
            app.buttons["Yes"]
        ]

        // 发送表情
        let sendEmoticonElementArray: [XCUIElement] = [
            app.buttons["emoji bottombar"],
            app.collectionViews.cells.otherElements.containing(.image, identifier: "10").element,
            app.buttons["Send"]
        ]

        // 发送文件
        let sendFileElementArray: [XCUIElement] = [
            app.buttons["others plus"],
            app.collectionViews.buttons["cloud file"],
            app.buttons["On Drive"],
            app.scrollViews.otherElements.tables.staticTexts["我的坚果云"],
            app.tables.staticTexts["【01】坚果云快速向导.pdf"],
            app.buttons["Send(1)"]
        ]

        // 发送Docs
        let sendDocsElementArray: [XCUIElement] = [
            app.collectionViews.buttons["send docs"],
            app.cells.element(boundBy: 0),
            app.buttons["Send"]
        ]

        // 搜索
        let searchElementArray: [XCUIElement] = [
            app.buttons["side bar off"],
            app.buttons["side search"],
            app.buttons["Docs"],
            app.buttons["Files"],
            app.buttons["Photos"],
            app.navigationBars["Search"].buttons["navigation back light"]
        ]

        // 聊天设置
        let chatSettingElementArray: [XCUIElement] = [
            app.buttons["side bar off"],
            app.buttons["side setting"],
            app.switches["Pin to QuickSwitcher"],
            app.switches["Pin to QuickSwitcher"],
            app.switches["Notification"],
            app.switches["Notification"],
            app.navigationBars["Settings"].buttons["navigation back light"]
        ]

        // 查看个人信息
        let lookOverPersonalInfoElementArray: [XCUIElement] = [
            app.buttons["side bar off"],
            app.buttons["side setting"],
            app.tables.staticTexts["Members"],
            app.tables.staticTexts["Admin"],
            app.buttons["back white"],
            app.navigationBars["Members"].buttons["navigation back light"],
            app.navigationBars["Settings"].buttons["navigation back light"]
        ]

        // 发送图片
        let sendPictureElementArray: [XCUIElement] = [
            app.buttons["picture bottombar"],
            app.collectionViews.children(matching: .cell).element(boundBy: 0).buttons["select picture"],
            app.buttons["Preview(1)"],
            app.buttons["Edit"],
            app.buttons["image edit trim"],
            app.buttons["image edit rotate"],
            app.buttons["image edit bottom save"],
            app.buttons["image edit text"],
            app.buttons["image edit line"],
            app.buttons["image edit mosaic"],
            app.buttons["image edit bottom save"],
            app.buttons["Send(1)"]
        ]

        // 群聊天处理
        let groupChattingElementArray: [XCUIElement] = [
            app.buttons["side bar off"],
            app.buttons["side setting"],
            app.tables.staticTexts["Share Group"],
            app.tables.staticTexts["LarkLeakTest"],
            app.buttons["Confirm"],
            app.tables.staticTexts["LarkLeakTest"],
            app.tables.staticTexts["Group Name"],
            app.navigationBars["Group Name"].buttons["navigation back light"],
            app.tables.staticTexts["Group QR Code"],
            app.navigationBars["LarkChat.GroupQRCode"].buttons["navigation back light"],
            app.navigationBars["Group Info"].buttons["navigation back light"],
            app.navigationBars["Settings"].buttons["navigation back light"],
            app.buttons["navigation back light"]
        ]

        // 日历
        let viewElement1 = app.scrollViews.children(matching: .other).element
            .children(matching: .other).element(boundBy: 2).children(matching: .other)
            .element(boundBy: 3).children(matching: .other).element(boundBy: 1)
        let viewElement2 = viewElement1.children(matching: .other).element(boundBy: 6)
        let calendarElementArray: [XCUIElement] = [
            app.tabBars.children(matching: .other).element(boundBy: 1),
            app.buttons["rilixuanze"],
            app.buttons["switchSchedule"],
            app.buttons["rilixuanze"],
            app.buttons["switchThreeDay"],
            app.buttons["rilixuanze"],
            app.buttons["switchOneDay"],
            app.buttons["rilixuanze"],
            app.buttons["switch month"],
            viewElement2,
            viewElement2,
            viewElement2,
            viewElement1,
            app.buttons["settingButton"],
            app.buttons["calendar setting"],
            app.scrollViews.children(matching: .other).element.children(matching: .other).element(boundBy: 4).children(matching: .button).element,
            app.navigationBars["Calendar settings"].buttons["nav back"],
            app.scrollViews.children(matching: .other).element.children(matching: .other).element(boundBy: 6).children(matching: .button).element,
            app.navigationBars["Event color settings"].buttons["nav back"],
            app.navigationBars["Calendar settings"].buttons["newEvnetClose"],
            app.buttons["settingButton"],
            app.buttons["sidebar subscribe"],
            app.buttons["Rooms"],
            app.buttons["Public"],
            app.navigationBars["Subscribe Calendars"].buttons["newEvnetClose"],
            app.buttons["addEvent"],
            app.buttons["newEvnetClose"]
        ]

        // Docs
        let docsElementArray: [XCUIElement] = [
            app.tabBars.otherElements.containing(.image, identifier: "tabbar_docs_shadow").element,
            app.collectionViews.buttons["Shared"],
            app.collectionViews.buttons["Favorites"],
            app.buttons["docs.nav.right.button0"],
            app.buttons["navigation.create.doc"],
            app.buttons["docs.nav.left.button0"],
            app.buttons["docs.nav.right.button0"],
            app.buttons["Document"],
            app.buttons["docs.nav.left.button0"],
            app.tabBars.otherElements.containing(.image, identifier: "tabbar_conversation_shadow").element
        ]

        // 应用中心
        let appCenterElementArray: [XCUIElement] = [
        app.tabBars.otherElements.containing(.image, identifier: "tabbar_toutiaoquan_shadow").element,
        app.tables.staticTexts["More App"],
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element
            .children(matching: .other).element.children(matching: .collectionView).element,
        app.buttons["navigation back light"],
        app.tables.staticTexts["More amazing content"],
        app.navigationBars["ByteMoments"].buttons["tma navi close"],
        app.tabBars.otherElements.containing(.image, identifier: "tabbar_conversation_shadow").element
        ]

        // 设置
        let settingEntryElement = app.children(matching: .window).element(boundBy: 0)
            .children(matching: .other).element(boundBy: 0).children(matching: .other)
            .element.children(matching: .other).element
            .children(matching: .other).element.children(matching: .other).element
            .children(matching: .other).element.children(matching: .other).element
            .children(matching: .other).element(boundBy: 1).children(matching: .other)
            .element(boundBy: 0).children(matching: .other).element(boundBy: 0).children(matching: .other).element
        let settingButton = app.children(matching: .window).element(boundBy: 0).children(matching: .other)
            .element(boundBy: 0).children(matching: .other).element.children(matching: .other)
            .element.children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .button).element(boundBy: 0)
        let settingsElementArray: [XCUIElement] = [
            settingEntryElement,
            app.tables.staticTexts["Wallet"],
            app.buttons["Cards"],
            settingButton,
            app.buttons["Transactions"],
            settingButton,
            app.buttons["Security"],
            settingButton,
            app.buttons["Help Center"],
            app.buttons["docs.nav.left.button0"],
            app.navigationBars["LarkFinance.WalletView"].buttons["navigation back light"],
            settingEntryElement,
            app.tables.staticTexts["Favorites"],
            app.navigationBars["Favorites"].buttons["navigation back light"],
            settingEntryElement,
            app.tables.staticTexts["My QR code"],
            app.scrollViews.otherElements.staticTexts["Reset"],
            app.alerts["Sure to reset?"].buttons["Reset"],
            app.buttons["My link"],
            app.navigationBars["Share to friends"].buttons["navigation back light"],
            settingEntryElement,
            app.tables.staticTexts["Devices"],
            app.navigationBars["Devices"].buttons["navigation back light"],
            settingEntryElement,
            app.tables.staticTexts["About"],
            app.navigationBars["About Lark"].buttons["navigation back light"],
            settingEntryElement,
            app.tables.staticTexts["Settings"],
            app.navigationBars["Settings"].buttons["navigation back light"]
        ]

        // 联系人
        let contactElementArray: [XCUIElement] = [
            app.tabBars.otherElements.containing(.image, identifier: "tabbar_contacts_shadow").element,
            app.tables.staticTexts["New Contacts"],
            app.navigationBars["New Contacts"].buttons["navigation back light"],
            app.tables.staticTexts["My Groups"],
            app.buttons["Joined"],
            app.navigationBars["My Groups"].buttons["navigation back light"],
            app.tables.staticTexts["BOTs"],
            app.navigationBars["BOTs"].buttons["navigation back light"],
            app.tables.staticTexts["Oncalls"],
            app.navigationBars["Oncalls"].buttons["navigation back light"],
            app.tables.staticTexts["External Contacts"],
            app.navigationBars["External Contacts"].buttons["navigation back light"],
            app.tables.staticTexts["Organization"],
            app.tables.staticTexts["Efficiency Engineering-Wuhan iOS (11)"],
            app.navigationBars["Efficiency Engineering-Wuhan iOS"].buttons["navigation back light"],
            app.navigationBars["Organization"].buttons["navigation back light"],
            app.tabBars.otherElements.containing(.image, identifier: "tabbar_conversation_shadow").element
        ]

        // 其它
        let otherElementArray: [XCUIElement] = [
            app.textField["Search"],
            app.textField["Search"],
            app.buttons["Cancel"],
            app.buttons["conversation filter"],
            app.collectionViews.staticTexts["Everything"],
            app.buttons["conversation filter"],
            app.collectionViews.staticTexts["Chats"],
            app.buttons["Chats"],
            app.collectionViews.staticTexts["Docs"],
            app.buttons["Docs"],
            app.collectionViews.staticTexts["Secret"],
            app.buttons["Secret"],
            app.collectionViews.staticTexts["External"],
            app.buttons["External"],
            app.collectionViews.staticTexts["Everything"]
        ]

        // 所有上述数组再放入一个数组，形成一个二维数组
        let allElementArray = [
            prepareElementArray,
            inputPureTextElementArray,
            pinElementArray,
            sendEmoticonElementArray,
            sendFileElementArray,
            sendDocsElementArray,
            searchElementArray,
            chatSettingElementArray,
            lookOverPersonalInfoElementArray,
            sendPictureElementArray,
            groupChattingElementArray,
            calendarElementArray,
            docsElementArray,
            appCenterElementArray,
            settingsElementArray,
            contactElementArray,
            otherElementArray
        ]

        // 定义一个二维数组，存放的元素类型是一个元组，元组的第一项是元素，第二项是元素的类型
        var tupleArray: [[(XCUIElement, TypeOfElment)]] = [[(XCUIElement, TypeOfElment)]](repeating: [], count: allElementArray.count)

        // 根据UI元素类型的不同，进行不同的操作
        func dealWithElement(element: XCUIElement, type: TypeOfElment) {
            if app.alerts["Memory Leak"].buttons["OK"].exists {
                app.alerts["Memory Leak"].buttons["OK"].tap()
            }
            if app.alerts["Object Deallocated"].buttons["OK"].exists {
                app.alerts["Object Deallocated"].buttons["OK"].tap()
            }
            XCTAssertWaitForExistence(element)
            if element.exists {
                switch type {
                case .needTap:
                    element.tap()
                case let .needPress(pressTime):
                    element.press(forDuration: pressTime)
                case let .needSwipe(direction):
                    switch direction {
                    case .up:
                        element.swipeUp()
                    case .right:
                        element.swipeRight()
                    case .down:
                        element.swipeDown()
                    case .left:
                        element.swipeLeft()
                    }
                case let .needInputText(inputString):
                    element.typeText(inputString)
                }
            }
        }

        // 将[[XCUIElement]]类型的二维数组转化成[[(XCUIElement, TypeOfElment)]]类型的二维数组
        func convertFromArrayToTupleArray(array: [XCUIElement], type: TypeOfElment) -> [(XCUIElement, TypeOfElment)] {
            var tupleArray: [(XCUIElement, TypeOfElment)] = [(XCUIElement, TypeOfElment)]()
            for element in array {
                tupleArray.append((element, type))
            }
            return tupleArray
        }

        // 更新tupleArray
        func updateTupleArray() {
            for (index, array) in allElementArray.enumerated() {
                tupleArray[index] = convertFromArrayToTupleArray(array: array, type: .needTap)
                switch index {
                case 0: // index为0表示是准备阶段，其中有的元素需要滑动，因此要做相应的修改
                    tupleArray[index][1].1 = .needSwipe(.up)
                case 1: // index为1表示是纯文本，其中textViews元素需要输入文本
                    tupleArray[index][1].1 = .needInputText(inputString)
                case 2: // index为2表示是pin，其中有的元素需要长按，有的元素需要滑动，因此需要更新tupleArray
                    tupleArray[index][0].1 = .needPress(1.5)
                case 11: // index为11表示是日历，有的元素需要滑动，因此需要更新tupleArray，下同
                    tupleArray[index][10].1 = .needSwipe(.left)
                    tupleArray[index][11].1 = .needSwipe(.left)
                    tupleArray[index][12].1 = .needSwipe(.left)
                    tupleArray[index][13].1 = .needSwipe(.right)
                case 13:
                    tupleArray[index][2].1 = .needSwipe(.up)
                case 16:
                    tupleArray[index][1].1 = .needInputText(searchNameString)
                default:
                    ()
                }
            }
        }

        // 遍历[[(XCUIElement, TypeOfElment)]]类型的二维数组，逐一对里面的每个元素进行相应的处理
        func sendSomething(sendElementArray: [[(XCUIElement, TypeOfElment)]]) {
            for array in sendElementArray {
                for tuple in array {
                    dealWithElement(element: tuple.0, type: tuple.1)
                }
            }
        }

        // 准备阶段
        func prepareForUpdate() {
            sleep(10)
            // 等待提示更新并点击Later，若不提示更新则继续后面的点击步骤
            if app.buttons["Later"].exists {
                app.buttons["Later"].tap()
            }
        }

        prepareForUpdate()
        updateTupleArray()
        sendSomething(sendElementArray: tupleArray)
        sleep(10_000_000)
    }
}
