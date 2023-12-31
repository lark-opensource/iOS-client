//
//  ECONetworkClientMock.swift
//  ECOInfra-Unit-Tests
//
//  Created by 刘焱龙 on 2023/6/2.
//

import LarkAssembler
import Swinject
import RustPB
@testable import ECOInfra

final class ECONetworkClientMockAssembly: LarkAssemblyInterface {
    private let resultMock: [String: Any]

    init(resultMock: [String: Any]) {
        self.resultMock = resultMock
    }

    func registContainer(container: Swinject.Container) {
        container.register(ECONetworkClientProtocol.self, name: ECONetworkChannel.rust.rawValue) { (_, _: OperationQueue, _: ECONetworkRequestSetting) in
            return ECONetworkClientMock(resultMock: self.resultMock)
        }.inObjectScope(.container)
    }
}

class ECONetworkClientMock: ECONetworkClientProtocol {
    weak var delegate: ECOInfra.ECONetworkClientEventDelegate?

    private let resultMock: [String: Any]

    init(resultMock: [String: Any]) {
        self.resultMock = resultMock
    }

    func dataTask(with context: ECOInfra.ECONetworkContextProtocol, request: URLRequest, completionHandler: ((AnyObject?, Data?, URLResponse?, Error?) -> Void)?) -> ECOInfra.ECONetworkTaskProtocol {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) {
            let response = HTTPURLResponse(
                url: URL(string: "https://www.feishu.cn")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
            let data = try! JSONSerialization.data(withJSONObject: self.resultMock)
            completionHandler!(context, data, response, nil)
        }
        return ECONetworkTask(
            context: context,
            client: self,
            task: URLSessionTask(),
            responseDataHandler: ECONetworkDataHandler(),
            completionHandler: nil
        )
    }

    func downloadTask(with context: ECOInfra.ECONetworkContextProtocol, request: URLRequest, cleanTempFile: Bool, completionHandler: ((AnyObject?, URL?, URLResponse?, Error?) -> Void)?) -> ECOInfra.ECONetworkTaskProtocol {
        fatalError()
    }

    func uploadTask(with context: ECOInfra.ECONetworkContextProtocol, request: URLRequest, fromFile fileURL: URL, completionHandler: ((AnyObject?, Data?, URLResponse?, Error?) -> Void)?) -> ECOInfra.ECONetworkTaskProtocol {
        fatalError()
    }

    func uploadTask(with context: ECOInfra.ECONetworkContextProtocol, request: URLRequest, from bodyData: Data, completionHandler: ((AnyObject?, Data?, URLResponse?, Error?) -> Void)?) -> ECOInfra.ECONetworkTaskProtocol {
        fatalError()
    }

    func finishTasksAndInvalidate() {}

    func invalidateAndCancel() {}
}

extension ECONetworkClientMock: ECONetworkTaskClient {
    func taskResuming(task: ECOInfra.ECONetworkTask) {}

    func taskPausing(task: ECOInfra.ECONetworkTask) {}

    func taskCanceling(task: ECOInfra.ECONetworkTask) {}

    func taskCompleting(task: ECOInfra.ECONetworkTask) {}
}
