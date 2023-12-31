//
//  BTFilterPanelViewModelTests.swift
//  SKBitable_Tests-Unit-_Tests
//
//  Created by zengsenyuan on 2022/8/2.
//  


import XCTest
@testable import SKBitable
import SKCommon
import RxSwift
import RxCocoa
@testable import SKFoundation

class BTFilterPanelViewModelTests: XCTestCase {
    
    var viewModel: BTFilterPanelViewModel?
    
    override func setUp() {
        super.setUp()
        viewModel = BTFilterPanelViewModel(filterPanelService: MockFilterPanelService(),
                                           filterFlowService: MockFilterDataService(),
                                           callback: "")
        // mock fg
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.nopermission", value: true)
        testGetFilterPanelModel()
    }

    override func tearDown() {
        super.tearDown()
        UserScopeNoChangeFG.removeMockFG(key: "ccm.bitable.nopermission")
    }
    
    func testGetFilterPanelModel() {
        let expect = expectation(description: "testGetFilterPanelModel")
        viewModel?.getFilterPanelModel(completion: { model in
            XCTAssertNotNil(model)
            expect.fulfill()
        })
        waitForExpectations(timeout: 0.05) { error in
            XCTAssertNil(error)
        }
    }
    
    func testUpdateFilterInfo() {
        let expect = expectation(description: "testUpdateFilterInfo")
        viewModel?.updateFilterInfo(action: .updateConjuction(value: "and"), completion: { model in
            guard let model = model else {
                XCTAssertTrue(false)
                return
            }
            XCTAssertTrue(model.conjuction.id == "and")
            expect.fulfill()
        })
        waitForExpectations(timeout: 0.05) { error in
            XCTAssertNil(error)
        }
    }
    
    func testReloadCondition() {
        let expect = expectation(description: "testUpdateFilterInfoReloadCondition")
        viewModel?.getFilterPanelModel(completion: { [weak self] _ in
            guard let self = self else {
                expect.fulfill()
                return
            }
            
            self.viewModel?.updateFilterInfo(action: .reloadCondition("conT0TSxqm"), completion: { model in
                XCTAssertTrue(model?.conditions.count == 2)
                expect.fulfill()
            })
        })
        
        waitForExpectations(timeout: 0.1) { error in
            XCTAssertNil(error)
        }
    }
    
    func testAddCondition() {
        let expect = expectation(description: "testAddCondition")
        viewModel?.getFilterPanelModel(completion: { [weak self] _ in
            guard let self = self else {
                expect.fulfill()
                return
            }
            
            let newCondition = BTFilterCondition(conditionId: "mock_id",
                                                 fieldId: "mock_fieldId",
                                                 fieldType: 1)
            self.viewModel?.updateFilterInfo(action: .addCondition(newCondition), completion: { model in
                XCTAssertTrue(model?.conditions.count == 3)
                expect.fulfill()
            })
        })
        
        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }
    }
    
    func testRemoveCondition() {
        let expect = expectation(description: "testRemoveCondition")
        viewModel?.getFilterPanelModel(completion: { [weak self] _ in
            guard let self = self else {
                expect.fulfill()
                return
            }
            
            self.viewModel?.updateFilterInfo(action: .removeCondition("conT0TSxqm"), completion: { model in
                XCTAssertTrue(model?.conditions.count == 1)
                expect.fulfill()
            })
        })
        
        waitForExpectations(timeout: 0.1) { error in
            XCTAssertNil(error)
        }
    }
    
    func testGetConjuctionSelectedModels() {
        if let result = viewModel?.getConjuctionSelectedModels() {
            XCTAssertTrue(result.selectedIndex == 1)
            XCTAssertTrue(result.models.count == 2)
        } else {
            XCTAssertNotNil(false)
        }
    }

    func testMakeNewCondtion() {
        let expect = expectation(description: "testMakeNewCondtion")
        viewModel?.makeNewCondtion(completion: { [weak self] condition in
            expect.fulfill()
            guard let self = self else { return }
            if let condition = condition,
               let filterOptions = self.viewModel?.cacheJSData?.filterOptions {
                let fist = filterOptions.fieldOptions.first { $0.id == condition.fieldId && $0.compositeType.type.rawValue == condition.fieldType }
                XCTAssertNotNil(fist)
            } else {
                XCTAssertTrue(false)
            }
        })

        waitForExpectations(timeout: 0.05) { error in
                XCTAssertNil(error)
        }
    }
    
    func testConverJSDataToPanelMdoel() {
        if let jsData = viewModel?.cacheJSData {
            let expect = expectation(description: "testConverJSDataToPanelMdoel")
            viewModel?.converJSDataToPanelMdoel(with: jsData, completion: { model in
                XCTAssertNotNil(model)
                expect.fulfill()
            })
            waitForExpectations(timeout: 0.05) { error in
                XCTAssertNil(error)
            }
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func testGetFilterValueUserData() {
        let mockFilterDataService = BTFilterDataService(baseData: BTBaseData(baseId: "baseId",
                                                                             tableId: "tableId",
                                                                             viewId: "viewId"),
                                                        jsService: MockJSFunc(),
                                                        dataService: DataService())
        
        let viewModel = BTFilterValueChatterViewModel(fieldId: "mock_fieldId",
                                                      selectedMembers: [],
                                                      isAllowMultipleSelect: true,
                                                      chatterType: .user,
                                                      btDataService: mockFilterDataService)
        
        viewModel.getFilterValueDataTypeChatter(keywords: "") { result in
            switch result {
            case .success(let members):
                XCTAssertTrue(members.count == 1)
            default:
                break
            }
        } resultHandler: { result in
            switch result {
            case .success(let data):
                XCTAssertNil(data)
            default:
                break
            }
        }
    }
    
    func testGetFilterValueGroupData() {
        let mockFilterDataService = MockFilterDataService()
        
        let viewModel = BTFilterValueChatterViewModel(fieldId: "mock_field", selectedMembers: [], isAllowMultipleSelect: true, chatterType: .group, btDataService: mockFilterDataService)
        
        viewModel.getFilterValueDataTypeChatter(keywords: "") { result in
            switch result {
            case .success(let members):
                XCTAssertTrue(members.count == 1)
            default:
                break
            }
        } resultHandler: { result in
            switch result {
            case .success(let data):
                XCTAssertNil(data)
            default:
                break
            }
        }
    }
    
    func testUpdateAndJoinGroup() {
        let mockFilterDataService = MockFilterDataService()
        
        let viewModel = BTFilterValueChatterViewModel(fieldId: "mock_field", selectedMembers: [], isAllowMultipleSelect: true, chatterType: .group, btDataService: mockFilterDataService)
        let newItem = MemberItem(identifier: "new", selectType: .blue, imageURL: "imageURL", title: "title", detail: nil, token: nil, isExternal: true, displayTag: nil, isCrossTenanet: false)
        let update = viewModel.joinAndUpdate([newItem])
        XCTAssert(update.contains(newItem))
    }
    
    func testGetFilterValueLinkData() {
        let mockFilterDataService = BTFilterDataService(baseData: BTBaseData(baseId: "baseId",
                                                                             tableId: "tableId",
                                                                             viewId: "viewId"),
                                                        jsService: MockJSFunc(),
                                                        dataService: DataService())
        
        let viewModel = BTFilterValueLinkViewModel(fieldId: "mock_fieldId",
                                                   selectedRecordIds: [],
                                                   isAllowMultipleSelect: true,
                                                   btDataService: mockFilterDataService)
        
        viewModel.getFilterValueDataTypeLinks(keywords: "") { result in
            switch result {
            case .success(let record):
                XCTAssertTrue(record.count == 1)
            default:
                break
            }
        } resultHandler: { result in
            switch result {
            case .success(let data):
                XCTAssertNil(data)
            default:
                break
            }
        }
    }
    
    func testGetFilterValueLinkDataByIds() {
        let mockFilterDataService = BTFilterDataService(baseData: BTBaseData(baseId: "baseId",
                                                                             tableId: "tableId",
                                                                             viewId: "viewId"),
                                                        jsService: MockJSFunc(),
                                                        dataService: DataService())
        
        let viewModel = BTFilterValueLinkViewModel(fieldId: "mock_fieldId",
                                                   selectedRecordIds: [],
                                                   isAllowMultipleSelect: true,
                                                   btDataService: mockFilterDataService)
        
        viewModel.getFieldLinkOptionsByIds(recordIds: []) { result in
            switch result {
            case .success(let record):
                XCTAssertTrue(record.count == 1)
            default:
                break
            }
        } resultHandler: { result in
            switch result {
            case .success(let data):
                XCTAssertNil(data)
            default:
                break
            }
        }
    }
    
    func testFilterUserValueJoinAndUpdate() {
        let mockFilterDataService = BTFilterDataService(baseData: BTBaseData(baseId: "baseId",
                                                                             tableId: "tableId",
                                                                             viewId: "viewId"),
                                                        jsService: MockJSFunc(),
                                                        dataService: DataService())
        
        let viewModel = BTFilterValueChatterViewModel(fieldId: "mock_fieldId",
                                                      selectedMembers: [MemberItem(identifier: "mockMember",
                                                                                selectType: .blue,
                                                                                imageURL: nil,
                                                                                title: "mockMember",
                                                                                detail: nil,
                                                                                token: "",
                                                                                isExternal: false,
                                                                                displayTag: nil,
                                                                                isCrossTenanet: false,
                                                                                isShowSeparatorLine: false)],
                                                      isAllowMultipleSelect: true,
                                                      chatterType: .user,
                                                      btDataService: mockFilterDataService)
        
       let newMembers = viewModel.joinAndUpdate([MemberItem(identifier: "mockMember",
                                            selectType: .blue,
                                            imageURL: nil,
                                            title: "mockMember0",
                                            detail: nil,
                                            token: "",
                                            isExternal: false,
                                            displayTag: nil,
                                            isCrossTenanet: false,
                                            isShowSeparatorLine: false),
                                 MemberItem(identifier: "mockMember1",
                                            selectType: .blue,
                                            imageURL: nil,
                                            title: "mockMember1",
                                            detail: nil,
                                            token: "",
                                            isExternal: false,
                                            displayTag: nil,
                                            isCrossTenanet: false,
                                            isShowSeparatorLine: false)])
        XCTAssertTrue(newMembers.count == 2)
        
        viewModel.updateSelectedMembers(newMembers)
        XCTAssertTrue(viewModel.selectedMembers.count == 2)
    }
    
    func testFilterLinkValueJoinAndUpdate() {
        let mockFilterDataService = BTFilterDataService(baseData: BTBaseData(baseId: "baseId",
                                                                             tableId: "tableId",
                                                                             viewId: "viewId"),
                                                        jsService: MockJSFunc(),
                                                        dataService: DataService())
        
        let viewModel = BTFilterValueLinkViewModel(fieldId: "mock_fieldId",
                                                   selectedRecordIds: ["mockRecord1"],
                                                   isAllowMultipleSelect: true,
                                                   btDataService: mockFilterDataService)
        
        let newMembers = viewModel.joinAndUpdate([BTLinkRecordModel(id: "mockRecord1",
                                                                    text: "newRecord",
                                                                    isSelected: false),
                                                  BTLinkRecordModel(id: "mockRecord2",
                                                                    text: "newRecord2",
                                                                    isSelected: false)])
        XCTAssertTrue(newMembers.count == 2)
        
        viewModel.updateSelectedRecordModel(newMembers)
        XCTAssertTrue(viewModel.selectedRecordModel.count == 2)
    }
}
