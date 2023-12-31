//
//  BTFetchGeoLocationHelperTest.swift
//  SKBitable_Tests-Unit-_Tests
//
//  Created by 曾浩泓 on 2022/6/20.
//  


import XCTest
@testable import SKBitable
import CoreLocation
import SKFoundation
import LarkLocationPicker

class BTFetchGeoLocationHelperTest: XCTestCase {

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFetchGeoLocation() {
        let fetchingExpectation = XCTestExpectation(description: "helper fetching geoLocation for fieldLocation")
        let didFetchExpectation = XCTestExpectation(description: "helper did fetch geoLocation for fieldLocation")
        let field = BTFieldLocation(
            originBaseID: "mockOriginBaseID",
            originTableID: "mockOriginTableID",
            baseID: "mockBaseID", tableID: "mockTableID",
            viewID: "mockViewID", recordID: "mockRecordID",
            fieldID: "mockFieldID"
        )
        let record = BTRecord()
        let geoLocation = ChooseLocation(name: "xxx", address: "xxxx", location: CLLocationCoordinate2D(latitude: 0, longitude: 0), zoomLevel: 1, image: UIImage(), mapType: "gaode", selectType: "")
        var didReceiveFetching = false
        let helperDelegate = BTFetchGeoLocationHelperTestDelegate()
        helperDelegate.updateFetchingLocationsBlock = { fieldLocations in
            guard !didReceiveFetching else {
                return
            }
            let isContains = fieldLocations.contains {
                $0.tableID == field.tableID &&
                $0.recordID == field.recordID &&
                $0.fieldID == field.fieldID
            }
            XCTAssertTrue(isContains)
            didReceiveFetching = true
            didFetchExpectation.fulfill()
        }
        helperDelegate.notifyFrontendDidFetchGeoLocationBlock = { fieldLocation, _, isAutoLocate, _ in
            let isEqual = fieldLocation.tableID == field.tableID &&
            fieldLocation.recordID == field.recordID &&
            fieldLocation.fieldID == field.fieldID
            XCTAssertTrue(isEqual && !isAutoLocate)
            fetchingExpectation.fulfill()
        }
        let mockReGeocodeResult = BTReGeocodeResult(
            location: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            country: "中国", pname: "广东省",
            cityname: "深圳市", adname: "南山区", name: "深圳湾创新科技中心",
            address: "科苑地铁站 C 出口",
            fullAddress: "广东省深圳市南山区科苑地铁站 C 出口深圳湾创新科技中心"
        )
        let reGeocoder = BTReGeocoderMock()
        reGeocoder.mockResult = mockReGeocodeResult
        let helper = BTFetchGeoLocationHelper(actionParams: BTActionParamsModel(), delegate: helperDelegate, reGeocoder: reGeocoder)
        helper.didSelectLocation(forField: field, inRecord: record, geoLocation: geoLocation)
        wait(for: [fetchingExpectation, didFetchExpectation], timeout: 10)
    }
    
    func testFetchGeoLocationEmpty() {
        let mockLocation = CLLocation(latitude: 0, longitude: 0)
        let result = BTFetchGeoLocationHelper.createUnnamedGeoLocationModel(location: mockLocation)
        XCTAssertFalse(result.name.isEmpty)
        XCTAssertFalse(result.address.isEmpty)
        XCTAssertFalse(result.fullAddress.isEmpty)
        XCTAssertEqual(result.location?.longitude, mockLocation.coordinate.longitude)
        XCTAssertEqual(result.location?.latitude, mockLocation.coordinate.latitude)
    }
    
    func testFullAddress() {
        let record = BTRecord()
        let field = BTFieldLocation(
            originBaseID: "mockOriginBaseID",
            originTableID: "mockOriginTableID",
            baseID: "mockBaseID", tableID: "mockTableID",
            viewID: "mockViewID", recordID: "mockRecordID",
            fieldID: "mockFieldID"
        )
        
        _ = {
            let chooseLocation = ChooseLocation(
                name: "深圳湾创新科技中心", address: "科苑地铁站 C 出口",
                location: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                zoomLevel: 14.5, image: UIImage(), mapType: "gaode", selectType: ""
            )
            let mockReGeocodeResult = BTReGeocodeResult(
                location: chooseLocation.location, country: "中国", pname: "广东省",
                cityname: "深圳市", adname: "南山区", name: "深圳湾创新科技中心", address: "科苑地铁站 C 出口",
                fullAddress: "广东省深圳市南山区科苑地铁站 C 出口深圳湾创新科技中心"
            )
            let expectedFullAddress = "深圳湾创新科技中心，广东省深圳市南山区科苑地铁站C出口"
            let expectation = XCTestExpectation(description: "test reGeocode fullAddress")
            _testFullAddress(field: field, record: record, chooseLocation: chooseLocation, mockReGeocodeResult: mockReGeocodeResult, expectFullAddress: expectedFullAddress, expectation: expectation)
        }()

        _ = {
            let chooseLocation = ChooseLocation(
                name: "广东省深圳市宝安区西乡街道建安二路xx小区", address: "西乡街道",
                location: CLLocationCoordinate2D(latitude: 1, longitude: 1),
                zoomLevel: 14.5, image: UIImage(), mapType: "gaode", selectType: ""
            )
            let mockReGeocodeResult = BTReGeocodeResult(
                location: chooseLocation.location, country: "中国", pname: "广东省",
                cityname: "深圳市", adname: "宝安区", name: "xx小区", address: "西乡街道建安二路",
                fullAddress: "广东省深圳市宝安区西乡街道建安二路xx小区"
            )
            let expectedFullAddress = "广东省深圳市宝安区西乡街道建安二路xx小区"
            let expectation = XCTestExpectation(description: "test reGeocode fullAddress")
            _testFullAddress(field: field, record: record, chooseLocation: chooseLocation, mockReGeocodeResult: mockReGeocodeResult, expectFullAddress: expectedFullAddress, expectation: expectation)
        }()

        _ = {
            let chooseLocation = ChooseLocation(
                name: "D2 Place TWO(利来中心店)", address: "中国 香港特别行政区 深水埗区 深水埗区长沙湾长顺街15号利来中心",
                location: CLLocationCoordinate2D(latitude: 2, longitude: 2),
                zoomLevel: 14.5, image: UIImage(), mapType: "apple", selectType: "list"
            )
            let mockReGeocodeResult = BTReGeocodeResult(
                location: chooseLocation.location, country: "中国", pname: "香港特别行政区",
                cityname: "香港特别行政区", adname: "深水埗区", name: "利来中心", address: "",
                fullAddress: "香港特别行政区深水埗区利来中心亿利工业中心"
            )
            let expectedFullAddress = "D2 Place TWO(利来中心店)，香港特别行政区深水埗区"
            let expectation = XCTestExpectation(description: "test reGeocode fullAddress")
            _testFullAddress(field: field, record: record, chooseLocation: chooseLocation, mockReGeocodeResult: mockReGeocodeResult, expectFullAddress: expectedFullAddress, expectation: expectation)
        }()

        _ = {
            let chooseLocation = ChooseLocation(
                name: "中山市", address: "中国 广东省 中山市",
                location: CLLocationCoordinate2D(latitude: 3, longitude: 3),
                zoomLevel: 14.5, image: UIImage(), mapType: "apple", selectType: "list"
            )
            let mockReGeocodeResult = BTReGeocodeResult(
                location: chooseLocation.location, country: "中国", pname: "广东省",
                cityname: "中山市", adname: "", name: "广东省中山市石岐街道河泊大街二巷", address: "石岐街道",
                fullAddress: "广东省中山市石岐街道河泊大街二巷"
            )
            let expectedFullAddress = "广东省中山市"
            let expectation = XCTestExpectation(description: "test reGeocode fullAddress")
            _testFullAddress(field: field, record: record, chooseLocation: chooseLocation, mockReGeocodeResult: mockReGeocodeResult, expectFullAddress: expectedFullAddress, expectation: expectation)
        }()

        _ = {
            let chooseLocation = ChooseLocation(
                name: "南山区", address: "中国 广东省 深圳市 南山区",
                location: CLLocationCoordinate2D(latitude: 4, longitude: 4),
                zoomLevel: 14.5, image: UIImage(), mapType: "gaode", selectType: "default"
            )
            let mockReGeocodeResult = BTReGeocodeResult(
                location: chooseLocation.location, country: "中国", pname: "广东省",
                cityname: "深圳市", adname: "南山区", name: "友邻公寓", address: "桃园路5号",
                fullAddress: "广东省深圳市南山区南头街道友邻公寓"
            )
            let expectedFullAddress = "广东省深圳市南山区"
            let expectation = XCTestExpectation(description: "test reGeocode fullAddress")
            _testFullAddress(field: field, record: record, chooseLocation: chooseLocation, mockReGeocodeResult: mockReGeocodeResult, expectFullAddress: expectedFullAddress, expectation: expectation)
        }()

        _ = {
            let chooseLocation = ChooseLocation(
                name: "简阳市", address: "中国 四川省 成都市 简阳市",
                location: CLLocationCoordinate2D(latitude: 4, longitude: 4),
                zoomLevel: 14.5, image: UIImage(), mapType: "gaode", selectType: "default"
            )
            let mockReGeocodeResult = BTReGeocodeResult(
                location: chooseLocation.location, country: "中国", pname: "四川省",
                cityname: "成都市", adname: "简阳市", name: "香港城", address: "香港城121号(政府街与大古井街交汇处)",
                fullAddress: "四川省成都市简阳市简城街道政府街91号香港城"
            )
            let expectedFullAddress = "四川省成都市简阳市"
            let expectation = XCTestExpectation(description: "test reGeocode fullAddress")
            _testFullAddress(field: field, record: record, chooseLocation: chooseLocation, mockReGeocodeResult: mockReGeocodeResult, expectFullAddress: expectedFullAddress, expectation: expectation)
        }()
    }
    func _testFullAddress(
        field: BTFieldLocation, record: BTRecord, chooseLocation: ChooseLocation,
        mockReGeocodeResult: BTReGeocodeResult?, expectFullAddress: String,
        expectation: XCTestExpectation
    ) {
        let helperDelegate = BTFetchGeoLocationHelperTestDelegate()
        let mockReGeocoder = BTReGeocoderMock()
        mockReGeocoder.mockResult = mockReGeocodeResult
        helperDelegate.notifyFrontendDidFetchGeoLocationBlock = { _, geoLocation, isAutoLocate, _ in
            let isExpected = geoLocation.fullAddress == expectFullAddress
            XCTAssertTrue(!isAutoLocate && isExpected)
            expectation.fulfill()
        }
        let helper = BTFetchGeoLocationHelper(actionParams: BTActionParamsModel(), delegate: helperDelegate, reGeocoder: mockReGeocoder)
        helper.didSelectLocation(forField: field, inRecord: record, geoLocation: chooseLocation)
        wait(for: [expectation], timeout: 10)
    }
    
    /// 测试地理位置权限。 这个不该需要单测
    func testRequestLocationAuth() {
        BTFetchGeoLocationHelper.requestAuthIfNeed(forToken: "") { _ in }
    }
    
    /* 依赖组件 crash 先屏蔽
    /// 测试地理位置权限。这个按理是请求服务，不算业务逻辑。
    func testDidClickAutoLocate() {
        let helperDelegate = BTFetchGeoLocationHelperTestDelegate()
        let mockReGeocoder = BTReGeocoderMock()
        let helper = BTFetchGeoLocationHelper(actionParams: BTActionParamsModel(), delegate: helperDelegate, reGeocoder: mockReGeocoder)
        let field = BTFieldLocation(originBaseID: "", originTableID: "", baseID: "", tableID: "", viewID: "", recordID: "", fieldID: "")
        helper.didClickAutoLocate(forField: field, forToken: "", inRecord: nil) { error in
            XCTAssertTrue(error != nil)
        }
    }
     */
}

class BTFetchGeoLocationHelperTestDelegate: BTFetchGeoLoactionHelperDelegate {
    var updateFetchingLocationsBlock: ((Set<BTFieldLocation>) -> Void)?
    var notifyFrontendDidFetchGeoLocationBlock: ((BTFieldLocation, BTGeoLocationModel, Bool, String) -> Void)?
    
    func updateFetchingLocations(fieldLocations: Set<BTFieldLocation>) {
        updateFetchingLocationsBlock?(fieldLocations)
    }
    func notifyFrontendDidFetchGeoLocation(forLocation location: BTFieldLocation, geoLocation: BTGeoLocationModel, isAutoLocate: Bool, callback: String) {
        notifyFrontendDidFetchGeoLocationBlock?(location, geoLocation, isAutoLocate, callback)
    }
}



class BTReGeocoderMock: BTReGeocoder {
    var mockResult: BTReGeocodeResult?
    func fetchLocationModel(coordinate: CLLocationCoordinate2D, completion: @escaping ReGeocodeCompletion) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(self.mockResult)
        }
    }
}
