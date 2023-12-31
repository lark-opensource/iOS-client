//
//  MinutesAudioDataUploadModels.swift
//  Minutes
//
//  Created by lvdaqian on 2021/5/20.
//

import Foundation
import MinutesFoundation
import LarkCache
import LarkStorage
import LarkClean
import MinutesNetwork

func makeMinutesCache() -> Cache {
    let rootPath = createCachePath()
    return CacheManager.shared.cache(rootPath: rootPath, cleanIdentifier: "minutes.global.library")
}

func createCachePath() -> IsoPath {
    let rootPath = IsoPath.in(
        space: .global,
        domain: Domain.biz.minutes.child("Cache")
    ).build(.library)
    return rootPath
}

extension CleanRegistry {
    @_silgen_name("Lark.LarkClean_CleanRegistry.Minutes")
    public static func registerMinutes() {
        registerPaths(forGroup: "minutes") { _ in
            return [
                .abs(createCachePath().absoluteString)
            ]
        }
    }
}

enum MinutesPerfromTask: CustomStringConvertible {
    var description: String {
        switch self {
        case .upload(let task):
            return "uploadTask \(task.objectToken.suffix(6))-\(task.segID)"
        case .complete(let token):
            return "completeTask \(token.suffix(6))"
        }
    }

    case upload(MinutesAudioDataUploadTask)
    case complete(String)

    var cacheKey: String {
        switch self {
        case .upload(let task):
            return task.cacheKey
        case .complete(let token):
            return "\(token)"
        }
    }
}

extension MinutesAudioDataUploadTask {
    var cacheKey: String {
        return "\(objectToken)-\(segID)"
    }

    var extendData: Data? {
        var parameters = self.parameters
        parameters["size"] = size
        return try? JSONSerialization.data(withJSONObject: parameters)
    }

    var filename: String {
        let filename = "\(self.cacheKey).aac"
        return filename
    }
    var fileURL: URL {
        let cache = MinutesAudioDataUploadCenter.shared.cache
        let path = cache.filePath(forKey: filename)
        let fileURL = URL(fileURLWithPath: path)
        return fileURL
    }

    init?(payload: Data, extendData: Data, encodedData: Bool = false) {
        guard let params = try? JSONSerialization.jsonObject(with: extendData) as? [String: Any] else { return nil }
        guard let objectToken = params["object_token"] as? String,
              let language = params["recording_lang"] as? String,
              let startTime = params["start_ms"] as? String,
              let duration = params["duration"] as? Int,
              let segID = params["seg_id"] as? Int else {
            return nil
        }

        if encodedData {
            self.init(objectToken: objectToken, language: language, startTime: startTime, duration: duration, segID: segID, payload: payload, format: .aac, originSize: params["size"] as? Int)
        } else {
            // disable-lint: magic number
            let durationSize = Double(duration) * 44.1 * 2
            // enable-lint: magic number
            let size = params["size"] as? Int ?? Int(durationSize)
            let start = payload.count - size
            let rawData = start > 0 ? payload[start...] : payload
            self.init(objectToken: objectToken, language: language, startTime: startTime, duration: duration, segID: segID, payload: rawData)
        }

    }

    // 存储文件名到数据库
    func save(to cache: Cache) {
        cache.saveFile(key: cacheKey, fileName: filename, size: nil, extendedData: extendData)
    }

    static func load(from cache: Cache, key: String, extendInfo: Data, encodedData: Bool = false) -> MinutesAudioDataUploadTask? {
        // 返回被缓存的文件路径
        let path = cache.filePath(forKey: key)
        let fileURL = URL(fileURLWithPath: path)
        // 取出路径下的分片数据，空数据校验
        if encodedData, let payload = try? Data.read(from: fileURL.asAbsPath()), payload.count > 0 {
            return MinutesAudioDataUploadTask(payload: payload, extendData: extendInfo, encodedData: true)
        } else {
            MinutesLogger.record.info("load payload data failed: \(fileURL)")
            let reader = MinutesAudioFileReader(fileURL)
            guard let payload = reader.read() else { return nil }
            return MinutesAudioDataUploadTask(payload: payload, extendData: extendInfo)
        }
    }
}

public enum MinutesAudioDataUploadCenterWorkLoad {
    case heavy
    case normal
    case light

    static func workload(for taskCount: Int) -> Self {
        switch taskCount {
        case 1:
            return .light
        case 2:
            return .normal
        default:
            return .heavy
        }
    }
}
