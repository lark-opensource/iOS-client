//
//  DocsClientVarsPreloadTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by zengsenyuan on 2022/6/19.
//  



import XCTest
import OHHTTPStubs
@testable import SKCommon
import RxSwift
import RxCocoa
import SKFoundation
import SpaceInterface
import SKInfra

class DocsClientVarsPreloadTests: XCTestCase {
    
    let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        DocsContainer.shared.register(DocCommonDownloadProtocol.self) {_ in
            return DocCommonDownloadTest()
        }.inObjectScope(.container)
        
        DocsContainer.shared.register(SpaceDownloadCacheProtocol.self) { _ in
            return DocCommonCacheTest()
        }.inObjectScope(.container)
    }
    

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }
    
    func testClientVarsDocxRequest() {
        let docxKey = PreloadKey(objToken: "doxcn3WXzB6UN66B2K2ZYrNNqPh", type: .docX)
        clientVarsRequest(docxKey)
    }
    
    func testClientVarsDocRequest() {
        let docKey = PreloadKey(objToken: "doccnwQPpbd02NPH7gikvHKIxEc", type: .doc)
        clientVarsRequest(docKey)
    }

    func testClientVarsMindnoteRequest() {
        let mindnoteKey = PreloadKey(objToken: "bmncnAILsw5Rrw5QWjgy5qstdyg", type: .mindnote)
        clientVarsRequest(mindnoteKey)
    }


    private func clientVarsRequest(_ preloadKey: PreloadKey) {
        mockClientVarsPreloadNeetwork()
        let expect = expectation(description: "test clientvar preload request \(preloadKey.type)")
        let request = DocsRequest.requestWith(preloadKey)
        request.load(preloadKey: preloadKey) { _, response, _ in
            expect.fulfill()
            XCTAssertFalse((response as? HTTPURLResponse)?.statusCode == 400, "statusCode is wrong")
        }
        request.referenceSelf()
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    func mockClientVarsPreloadNeetwork() {
        
        func stubResponse(statusCode: Int32, msg: String) -> HTTPStubsResponse {
            return HTTPStubsResponse(jsonObject: ["code": 4,
                                                  "msg": msg,
                                                  "data": [:]],
                                     statusCode: statusCode,
                                     headers: ["Content-Type": "application/json"])
        }
        
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.preloadPageClientVar) ||
                          urlString.contains(OpenAPI.APIPath.preloadContent)
            return contain
        }, response: { request in
            
            func isBodyEmpty() -> Bool {
                return request.httpBodyStream == nil && request.httpBody == nil
            }
            
            if request.httpMethod == "GET", !isBodyEmpty() {
                return stubResponse(statusCode: 400, msg: "GET Method has httpBody")
            }
            if request.httpMethod == "POST", isBodyEmpty() {
                return stubResponse(statusCode: 400, msg: "Post Method has no httpBody")
            }
            return stubResponse(statusCode: 200, msg: "success")
        })
    }
}

class DocCommonDownloadTest: DocCommonDownloadProtocol {
    func download(with context: DocCommonDownloadRequestContext) -> Observable<DocCommonDownloadResponseContext> {
        fatalError("placeholder")
    }
    func download(with contexts: [DocCommonDownloadRequestContext]) -> Observable<DocCommonDownloadResponseContext> {
        fatalError("placeholder")
    }
    func downloadNormal(remoteUrl: String, localPath: String, priority: DocCommonDownloadPriority) -> Observable<DocCommonDownloadResponseContext> {
        fatalError("placeholder")
    }
    func cancelDownload(key: String) -> Observable<Bool> {
        fatalError("placeholder")
    }
}

class DocCommonCacheTest: SpaceDownloadCacheProtocol {
    func save(request: DocCommonDownloadRequestContext, completion: ((_ success: Bool) -> Void)?) {
        fatalError("placeholder")
    }
    func data(key: String, type: DocCommonDownloadType) -> Data? {
        fatalError("placeholder")
    }
    func dataWithVersion(key: String, type: DocCommonDownloadType, dataVersion: String?) -> Data? {
        fatalError("placeholder")
    }
    func addImagesToManualCache(infos: [(String, DocCommonDownloadType)]) {
        fatalError("placeholder")
    }
    func removeImagesFromManualCache(infos: [(String, DocCommonDownloadType)]) {
        fatalError("placeholder")
    }
}
