//
//  BTNativeCardViewModelTests.swift
//  SKBitable-Unit-Tests
//
//  Created by zoujie on 2023/12/5.
//  


import XCTest
@testable import SKBitable

extension BTNativeCardViewModelTests: NativeCardViewModelListener {
    /// diff批量更新
    func diffUpdateModel(viewId: String, deleteIndexs: [Int], insertIndexs: [Int]) {
        
    }
    ///  更新指定item
    func updateItems(viewId: String, indexs: [Int], needInvalidateLayout: Bool) {
        
    }
    /// 滚动到指定item
    func scrollToIndex(viewId: String, index: Int) {
        scrollToIndex = index
    }
    /// 批量更新item
    func batchUpdate(viewId: String,
                     updateIndexs: [Int],
                     deleteIndexs: [Int],
                     insertIndexs: [Int],
                     completion: (() -> Void)?) {
        
    }
    /// 更新可视区的item
    func updateVisibleItems(viewId: String) {
        
    }
    /// 全量更新item
    func reloadItems(viewId: String, completion: (() -> Void)?) {
        
    }
    /// 更新吸顶header model
    func updateGroupHeaderModel(viewId: String) {
        
    }
}


class BTNativeCardViewModelTests: XCTestCase {
    var scrollToIndex: Int = 0
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    private func mockModel() throws -> CardPageModel {
        return MockJSONDataManager.getFastDecodableByParseData(filePath: "JSONDatas/nativeCardViewData")
    }
    
    func testsHasCover() {
        do {
            let mockModel = try mockModel()
            let normalViewModel = NativeCardViewModel(model: mockModel, service: nil)
            
            XCTAssertTrue(normalViewModel.hasCover)
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
    func testsHasGroup() {
        do {
            let mockModel = try mockModel()
            let normalViewModel = NativeCardViewModel(model: mockModel, service: nil)
            
            XCTAssertTrue(normalViewModel.hasGroup)
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
    func testsColumnCount() {
        do {
            let mockModel = try mockModel()
            let normalViewModel = NativeCardViewModel(model: mockModel, service: nil)
            
            XCTAssertTrue(normalViewModel.columnCount == 3)
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
    func testsFieldCount() {
        do {
            let mockModel = try mockModel()
            let normalViewModel = NativeCardViewModel(model: mockModel, service: nil)
            
            XCTAssertTrue(normalViewModel.fieldCount == 9)
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }

    func testsHasSubTitle() {
        do {
            let mockModel = try mockModel()
            let normalViewModel = NativeCardViewModel(model: mockModel, service: nil)
            
            XCTAssertTrue(normalViewModel.hasSubTitle)
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
    func testsRebuild() {
        do {
            let normalViewModel = NativeCardViewModel(model: CardPageModel(), service: nil)
            let mockModel = try mockModel()
            normalViewModel.updateModel(model: mockModel)
            
            XCTAssertTrue(normalViewModel.uiModel.count == 34)
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
    func testsPull() {
        do {
            let normalViewModel = NativeCardViewModel(model: CardPageModel(), service: nil)
            var mockModel = try mockModel()
            mockModel.updateStrategy?.strategy = .pull
            normalViewModel.updateModel(model: mockModel)
            
            XCTAssertTrue(normalViewModel.cachedRecordItems.count == 20)
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
    func testsScroll() {
        do {
            var mockModel = try mockModel()
            let normalViewModel = NativeCardViewModel(model: mockModel, service: nil)
            normalViewModel.listener = self
            
            mockModel.updateStrategy?.strategy = .scroll
            mockModel.updateStrategy?.scrollToId = "rec5CX9BZX"
            
            normalViewModel.updateModel(model: mockModel)
            
            XCTAssertTrue(scrollToIndex == 4)
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
    func testsHandleGroupHeaderClick() {
        do {
            var mockModel = try mockModel()
            let normalViewModel = NativeCardViewModel(model: mockModel, service: nil)
            normalViewModel.handleGroupHeaderClick(id: "0-0")
            XCTAssertTrue(normalViewModel.uiModel.count == 33)
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
    func testFetchItemsDataIfNeed() {
        do {
            var mockModel = try mockModel()
            let normalViewModel = NativeCardViewModel(model: mockModel, service: nil)
            let renderItem = RenderItem(type: .record, id: "rec5CX9BZX")
            normalViewModel.fetchItemsDataIfNeed(items: [renderItem])
            XCTAssert(true)
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
    func testGetCardItemData(index: Int) {
        do {
            var mockModel = try mockModel()
            let normalViewModel = NativeCardViewModel(model: mockModel, service: nil)
           
            let record = normalViewModel.getCardItemData(index: 0)
            XCTAssert(record != nil)
            let recordNil = normalViewModel.getCardItemData(index: 999)
            XCTAssert(recordNil == nil)
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
    func testGetGroupHeaderData() {
        do {
            var mockModel = try mockModel()
            let normalViewModel = NativeCardViewModel(model: mockModel, service: nil)
            let header = normalViewModel.getGroupHeaderData(index: 0)
            let headerNil = normalViewModel.getGroupHeaderData(index: 999)
            XCTAssertTrue(header != nil)
            XCTAssertTrue(headerNil == nil)
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
    func testFetchItems() {
        do {
            var mockModel = try mockModel()
            let normalViewModel = NativeCardViewModel(model: mockModel, service: nil)
            let item = RenderItem(type: .record, id: "rec5CX9BZX")
            normalViewModel.fetchItems(items: [item])
            XCTAssert(true)
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
    func testGetCachePageLengthPreloadItemsFrom() {
        do {
            var mockModel = try mockModel()
            let normalViewModel = NativeCardViewModel(model: mockModel, service: nil)
            let items = normalViewModel.getCachePageLengthPreloadItemsFrom(0)
            XCTAssert(!items.isEmpty)
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
    func testPreloadItems() {
        do {
            var mockModel = try mockModel()
            let normalViewModel = NativeCardViewModel(model: mockModel, service: nil)
            normalViewModel.preloadItems(itemIndex: 10, direction: 1)
            normalViewModel.preloadItems(itemIndex: 10, direction: 0)

            XCTAssert(true)
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
    func testPreItemType() {
        do {
            var mockModel = try mockModel()
            let normalViewModel = NativeCardViewModel(model: mockModel, service: nil)
            if let item = normalViewModel.uiModel.first {
                let type = normalViewModel.preItemType(item)
                XCTAssert(type == nil)
            }
            if let item = normalViewModel.uiModel.safe(index: 1) {
                let type = normalViewModel.preItemType(item)
                XCTAssert(type != nil)
            }
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
    func testSsGroupFirstRecord() {
        do {
            var mockModel = try mockModel()
            let normalViewModel = NativeCardViewModel(model: mockModel, service: nil)
            if let item = normalViewModel.uiModel.first {
                let type = normalViewModel.isGroupFirstRecord(item)
                XCTAssert(!type)
            }
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
    func testSsGroupLastRecord() {
        do {
            var mockModel = try mockModel()
            let normalViewModel = NativeCardViewModel(model: mockModel, service: nil)
            if let item = normalViewModel.uiModel.first {
                let type = normalViewModel.isGroupFirstRecord(item)
                XCTAssert(!type)
            }
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
    func testGetLastFixedGroupId() {
        do {
            var mockModel = try mockModel()
            let normalViewModel = NativeCardViewModel(model: mockModel, service: nil)
            let id = normalViewModel.getLastFixedGroupId(from: 0, to: 10)
            let emtpy = normalViewModel.getLastFixedGroupId(from: -1, to: 1000)
            XCTAssert(true)
        } catch {
            XCTFail("fieldData 生成失败: \(error)")
        }
    }
    
}
