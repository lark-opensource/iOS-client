//
//  MockRustManager.swift
//  LarkRustClient
//
//  Created by liuwanlin on 2020/3/17.
//

import Foundation
import RustPB
import SocketIO

public struct MockClientConfig: Codable {
    static let defaultsKey = "mock.rust.manager.config"

    /// socket url for proxy server
    public let socketURL: String
    /// channel that the client will connet to
    public let channel: String
    /// command ids for the requests that are proxyed to the proxy server
    public let proxyRequests: [Int]

    /// MockClientConfig init
    /// - Parameters:
    ///   - socketURL: socket url for proxy server
    ///   - channel: channel that the client will connet to
    ///   - proxyRequests: command ids for the requests that are proxyed to the proxy server
    public init(socketURL: String, channel: String, proxyRequests: [Int] = []) {
        self.socketURL = socketURL
        self.channel = channel
        self.proxyRequests = proxyRequests
    }

    /// save config to userdefaults, new config will be loaded next launch
    /// - Parameter config: config of the mock client
    public static func save(config: MockClientConfig) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(config) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    /// load local config
    public static func load() -> MockClientConfig? {
        let decoder = JSONDecoder()
        guard let data = UserDefaults.standard.value(forKey: defaultsKey) as? Data else {
            return nil
        }
        return try? decoder.decode(MockClientConfig.self, from: data)
    }
}

/// mock
public func replaceMockRustManager(config: MockClientConfig? = nil) {
    let mockManager = MockRustManager(config: config)
    RustManager.shared = mockManager
}

class MockRustManager: RustManager {
    // socket manager
    private var manager: SocketManager!
    // socket client
    private var socket: SocketIOClient!
    // proxy requests id: these request will be proxyed to proxy server
    var proxyRequests: [Int] = []
    // socket io data handle queue
    private let handleQueue = DispatchQueue(label: "mock.rust.manager")
    // socket is connectd to the proxy server or not
    var socketConnected = false

    init(config: MockClientConfig? = nil) {
        super.init()
        initSocket(config: config)
    }

    private func initSocket(config: MockClientConfig?) {
        // 先使用外出传入的，在使用本地存储的
        guard let config = config ?? MockClientConfig.load() else {
            SimpleRustClient.logger.error("initial config or local config need")
            return
        }
        guard let socketURL = URL(string: config.socketURL) else {
            SimpleRustClient.logger.error("invalid socketURL [\(config.socketURL)]")
            return
        }

        self.proxyRequests = config.proxyRequests

        self.manager = SocketManager(
            socketURL: socketURL,
            config: [
                .connectParams([
                    "channel": config.channel,
                    "proxyRequests": config.proxyRequests
                ]),
                .handleQueue(self.handleQueue)
            ]
        )
        self.socket = manager.defaultSocket

        // socket connetctd
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            self?.socketConnected = true
            SimpleRustClient.logger.info("mock client connected to server")
        }

        // response receviced when a request sended
        socket.on("response") { data, ack in
            defer {
                ack.with("Got response")
            }
            guard let obj = data.first as? [String: Any],
                let id = obj["id"] as? Int64,
                let responseData = obj["data"] as? Data else {
                SimpleRustClient.logger.error("mock response wrong data formate")
                return
            }
            self.handleResponse(requestId: id, data: responseData)
        }

        // receive push from mock server
        socket.on("reveive push") { [weak self] data, ack in
            defer {
                ack.with("reveive push")
            }
            guard let data = data.first as? Data else {
                SimpleRustClient.logger.error("mock push isn't Data")
                return
            }
            self?.handlePush(data: data)
        }

        // receive mock config from mock server
        socket.on("reveive config") { data, ack in
            defer {
                ack.with("reveive config")
            }
            guard let dict = data.first as? [String: Any],
                let proxyRequests = dict["proxyRequests"] as? [Int] else {
                SimpleRustClient.logger.error("config isn't dictionary")
                return
            }
            self.proxyRequests = proxyRequests
        }

        socket.connect()
    }

    private func handleResponse(requestId: Int64, data: Data) {
        guard let callback = self.removeRequest(for: requestId) else { return }
        callback(data, false)
    }

    private func handlePush(data: Data) {
        do {
            let packet = try Packet(serializedData: data)
            self.push(handle: packet)
        } catch {
            SimpleRustClient.logger.error("deserialize mock push fail with error \(error.localizedDescription)")
        }
    }

    override func invokeAsync(command: RustManager.RawCommand, data: Data, callback: RustManager.AsyncCallback?) {
        do {
            if self.socketConnected && command == Command.wrapperWithPacket.rawValue {
                // wrapperWithPacket 的command id是10000，需要解一层来获取实际的command id
                let packet = try Basic_V1_RequestPacket(serializedData: data)
                if proxyRequests.contains(packet.cmd.rawValue) {
                    let id = self.nextRequestID()
                    self.addRequest(for: id, handler: callback)
                    let emitData: [String: Any] = [
                        "cmd": packet.cmd.rawValue,
                        "id": id
                    ]
                    self.socket.emit("request", with: [emitData])
                    return
                }
            }
            super.invokeAsync(command: command, data: data, callback: callback)
        } catch {
            SimpleRustClient.logger.error("deserialize request fail with error \(error.localizedDescription)")
        }
    }
}
