//
//  AssetPreProcessManagerIntegrationTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/12.
//

/* import XCTest
 import RustPB // Media_V1_PreprocessResourceRequest
 import RxSwift // DisposeBag
 import LarkStorage // IsoPath
 import LarkContainer // InjectedSafeLazy
 import LarkSDKInterface // SDKRustService
 @testable import LarkSendMessage
 
 /// AssetPreProcessManager集成测试：判断秒传预处理是否生效（目前好像没啥好办法去判断是否生效）
 final class AssetPreProcessManagerIntegrationTest: CanSkipTestCase {
 @InjectedSafeLazy private var rustService: SDKRustService
 
 /// 测试图片秒传预处理是否生效，内容需要大一点，不然SDK不会进行秒传判断
 func testImagePreProcess() {
 var testResult = true
 let expectation = LKTestExpectation(description: "@test rust image preprocess")
 // 图片比较大，我们缩小到2MB
 var testImageData = Resources.imageData(named: "1170x2532-PNG")
 testImageData = testImageData.subdata(in: 0..<2 * 1024 * 1024)
 // 先把图片进行秒传预处理
 var request = RustPB.Media_V1_PreprocessResourceRequest()
 request.fileType = .image
 request.image = testImageData
 self.rustService.sendAsyncRequest(request).subscribe(onNext: { (resp: Media_V1_PreprocessResourceResponse) in
 // 创建图片假消息
 let apiContext = APIContext(contextID: RandomString.random(length: 10))
 apiContext.preprocessResourceKey = resp.key
 let messageCid = RandomString.random(length: 16)
 var originContent = QuasiContent()
 originContent.isOriginSource = true
 originContent.width = 1200
 originContent.height = 1400
 originContent.image = testImageData
 guard let quasiMessage = try? RustSendMessageModule.createQuasiMessage(chatId: "7180179231060557852",
 type: .image,
 content: originContent,
 cid: messageCid,
 client: self.rustService,
 context: apiContext).0 else {
 testResult = false
 expectation.fulfill()
 return
 }
 // 发送消息
 RustSendMessageModule.sendMessage(cid: quasiMessage.cid, client: self.rustService, context: apiContext).subscribe(onNext: { result in
 if result.messageId.isEmpty {
 testResult = false
 expectation.fulfill()
 return
 }
 // span中预期没有swift_upload_file_network_time_consumption
 if result.trace?.spans.contains(where: { $0.name == "swift_upload_file_network_time_consumption" }) ?? false {
 testResult = false
 expectation.fulfill()
 return
 }
 expectation.fulfill()
 }).disposed(by: disposeBag)
 }, onError: { _ in
 testResult = false
 expectation.fulfill()
 }).disposed(by: disposeBag)
 wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
 XCTAssertTrue(testResult)
 }
 
 /// 测试文件秒传预处理是否生效，内容需要大一点，不然SDK不会进行秒传判断
 func testFilePreProcess() {
 var testResult = true
 let expectation = LKTestExpectation(description: "@test rust file preprocess")
 // 图片比较大，我们缩小到2MB
 var testImageData = Resources.imageData(named: "1170x2532-PNG")
 testImageData = testImageData.subdata(in: 0..<2 * 1024 * 1024)
 // 自己搞一个临时路径
 let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "preprocess"
 try? tempFileDir.createDirectoryIfNeeded()
 let tempFilePath = tempFileDir + "temp"
 try? tempFilePath.removeItem()
 do {
 let imageData = testImageData
 try imageData.write(to: tempFilePath)
 } catch {
 testResult = false
 expectation.fulfill()
 }
 // 先把文件进行秒传预处理
 var request = RustPB.Media_V1_PreprocessResourceRequest()
 request.fileType = .file
 request.filePath = tempFilePath.absoluteString
 self.rustService.sendAsyncRequest(request).subscribe(onNext: { (resp: Media_V1_PreprocessResourceResponse) in
 // 创建图片假消息
 let apiContext = APIContext(contextID: RandomString.random(length: 10))
 apiContext.preprocessResourceKey = resp.key
 let messageCid = RandomString.random(length: 16)
 var originContent = QuasiContent()
 originContent.path = tempFilePath.absoluteString
 originContent.name = "1170x2532-PNG"
 originContent.fileSource = .larkServer
 guard let quasiMessage = try? RustSendMessageModule.createQuasiMessage(chatId: "7180179231060557852",
 type: .file,
 content: originContent,
 cid: messageCid,
 client: self.rustService,
 context: apiContext).0 else {
 testResult = false
 expectation.fulfill()
 return
 }
 // 发送消息
 RustSendMessageModule.sendMessage(cid: quasiMessage.cid, client: self.rustService, context: apiContext).subscribe(onNext: { result in
 if result.messageId.isEmpty {
 testResult = false
 expectation.fulfill()
 return
 }
 // span中预期没有swift_upload_file_network_time_consumption
 if result.trace?.spans.contains(where: { $0.name == "swift_upload_file_network_time_consumption" }) ?? false {
 testResult = false
 expectation.fulfill()
 return
 }
 expectation.fulfill()
 }).disposed(by: disposeBag)
 }, onError: { _ in
 testResult = false
 expectation.fulfill()
 }).disposed(by: disposeBag)
 wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
 XCTAssertTrue(testResult)
 }
 
 /// 测试图片没有秒传预处理，内容需要大一点，不然SDK不会进行秒传判断
 func testImageNoPreProcess() {
 var testResult = true
 let expectation = LKTestExpectation(description: "@test rust image preprocess")
 DispatchQueue.global().async {
 // 创建图片假消息
 let apiContext = APIContext(contextID: RandomString.random(length: 10))
 let messageCid = RandomString.random(length: 16)
 var originContent = QuasiContent()
 originContent.isOriginSource = true
 originContent.width = 1200
 originContent.height = 1400
 originContent.image = Resources.imageData(named: "1170x2532-PNG")
 guard let quasiMessage = try? RustSendMessageModule.createQuasiMessage(chatId: "7180179231060557852",
 type: .image,
 content: originContent,
 cid: messageCid,
 client: self.rustService,
 context: apiContext).0 else {
 testResult = false
 expectation.fulfill()
 return
 }
 // 发送消息
 RustSendMessageModule.sendMessage(cid: quasiMessage.cid, client: self.rustService, context: apiContext).subscribe(onNext: { result in
 if result.messageId.isEmpty {
 testResult = false
 expectation.fulfill()
 return
 }
 // span中预期有swift_upload_file_network_time_consumption
 if result.trace?.spans.contains(where: { $0.name == "swift_upload_file_network_time_consumption" }) ?? false {
 expectation.fulfill()
 return
 }
 testResult = false
 expectation.fulfill()
 }).disposed(by: disposeBag)
 }
 wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
 XCTAssertTrue(testResult)
 }
 
 /// 测试文件没有秒传预处理，内容需要大一点，不然SDK不会进行秒传判断
 func testFileNoPreProcess() {
 var testResult = true
 let expectation = LKTestExpectation(description: "@test rust file preprocess")
 DispatchQueue.global().async {
 // 自己搞一个临时路径
 let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "preprocess"
 try? tempFileDir.createDirectoryIfNeeded()
 let tempFilePath = tempFileDir + "temp"
 try? tempFilePath.removeItem()
 do {
 let imageData = Resources.imageData(named: "1170x2532-PNG")
 try imageData.write(to: tempFilePath)
 } catch {
 testResult = false
 expectation.fulfill()
 }
 // 创建图片假消息
 let apiContext = APIContext(contextID: RandomString.random(length: 10))
 let messageCid = RandomString.random(length: 16)
 var originContent = QuasiContent()
 originContent.path = tempFilePath.absoluteString
 originContent.name = "1170x2532-PNG"
 originContent.fileSource = .larkServer
 guard let quasiMessage = try? RustSendMessageModule.createQuasiMessage(chatId: "7180179231060557852",
 type: .file,
 content: originContent,
 cid: messageCid,
 client: self.rustService,
 context: apiContext).0 else {
 testResult = false
 expectation.fulfill()
 return
 }
 // 发送消息
 RustSendMessageModule.sendMessage(cid: quasiMessage.cid, client: self.rustService, context: apiContext).subscribe(onNext: { result in
 if result.messageId.isEmpty {
 testResult = false
 expectation.fulfill()
 return
 }
 // span中预期有swift_upload_file_network_time_consumption
 if result.trace?.spans.contains(where: { $0.name == "swift_upload_file_network_time_consumption" }) ?? false {
 expectation.fulfill()
 return
 }
 testResult = false
 expectation.fulfill()
 }).disposed(by: disposeBag)
 }
 wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
 XCTAssertTrue(testResult)
 }
 } */
import Foundation
