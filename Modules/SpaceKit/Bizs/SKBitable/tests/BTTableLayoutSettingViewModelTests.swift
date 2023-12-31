//
//  BTTableLayoutSettingViewModelTests.swift
//  SKBitable-Unit-Tests
//
//  Created by zhysan on 2023/2/14.
//

import XCTest
@testable import SKBitable

final class BTTableLayoutSettingViewModelTests: XCTestCase {
    
    private var field1: BTFieldOperatorModel = {
        var it = BTFieldOperatorModel()
        it.id = "1"
        it.name = "字段1"
        return it
    }()
    
    private var field2: BTFieldOperatorModel = {
        var it = BTFieldOperatorModel()
        it.id = "2"
        it.name = "字段2"
        return it
    }()
    private var field3: BTFieldOperatorModel = {
        var it = BTFieldOperatorModel()
        it.id = "3"
        it.name = "隐藏字段3"
        it.isHidden = true
        return it
    }()
    private var field4: BTFieldOperatorModel = {
        var it = BTFieldOperatorModel()
        it.id = "4"
        it.name = "字段4"
        return it
    }()

    private lazy var vm = BTTableLayoutSettingViewModel(
        settings: BTTableLayoutSettings(
            gridViewLayoutType: .classic,
            columnCount: 3,
            visibleFieldIds: [field1.id, field2.id],
            titleFieldId: field1.id,
            subtitleFieldId: field2.id
        ),
        fields: [field1, field2, field3, field4]
    )

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        vm.updateViewType(BTTableLayoutSettings.ViewType.card)
        vm.cardSettings.update(columnType: BTTableLayoutSettings.ColumnType.two)
        vm.cardSettings.update(titleField: field2)
        vm.cardSettings.update(subTitleField: field1)
        vm.cardSettings.update(deleteFromVisiable: field1)
        vm.cardSettings.update(addToVisiable: field4)
        vm.cardSettings.update(sortVisiable: [field4, field2])
        
        let settings = vm.getCurrentLayoutSettings()
        
        XCTAssertTrue(settings.gridViewLayoutType == .card)
        XCTAssertTrue(settings.columnCount == 2)
        XCTAssertTrue(settings.visibleFieldIds == [field4.id, field2.id])
        XCTAssertTrue(settings.titleFieldId == field2.id)
        XCTAssertTrue(settings.subtitleFieldId == field1.id)
        
    }

}
