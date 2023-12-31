//
//  MinutesSapceAPI.swift
//  MinutesFoundation
//
//  Created by Todd Cheng on 2021/2/25.
//

import Foundation

public final class MinutesSapceAPI {
    public lazy var api: MinutesAPI = MinutesAPI.clone()

    public init() {

    }

    public func doHomeSpaceListRequest(timestamp: String, spaceName: MinutesSpaceType, size: Int?, ownerType: MinutesOwnerType?, rank: MinutesRankType?, asc: Bool?, completionHandler: @escaping (Result<MinutesSpaceList, Error>) -> Void) {
        let request = HomeSpaceListRequest(timestamp: timestamp, spaceName: spaceName, size: size, ownerType: ownerType, rank: rank, asc: asc)
        api.sendRequest(request) { (result) in
            completionHandler(result.map { $0.data })
        }
    }

    public func doMinutesDeleteRequest(catchError: Bool, objectTokens: [String], isDestroyed: Bool, completionHandler: @escaping (Result<BasicResponse, Error>) -> Void) {
        let request = MinutesDeleteRequest(objectTokens: objectTokens, isDestroyed: isDestroyed, catchError: catchError)

        api.sendRequest(request, completionHandler: completionHandler)
    }

    public func doMinutesDeleteRestoreRequest(objectTokens: [String], completionHandler: @escaping (Result<BasicResponse, Error>) -> Void) {
        let request = MinutesDeleteRestoreRequest(objectTokens: objectTokens)

        api.sendRequest(request, completionHandler: completionHandler)
    }

    public func doMinutesRemoveRequest(objectTokens: [String], spaceName: MinutesSpaceType, completionHandler: @escaping (Result<BasicResponse, Error>) -> Void) {
        let request = MinutesRemoveRequest(objectTokens: objectTokens, spaceName: spaceName)

        api.sendRequest(request, completionHandler: completionHandler)
    }

    public func doMinutesRemoveRestoreRequest(objectTokens: [String], spaceName: MinutesSpaceType, completionHandler: @escaping (Result<BasicResponse, Error>) -> Void) {
        let request = MinutesRemoveRestoreRequest(objectTokens: objectTokens, spaceName: spaceName)

        api.sendRequest(request, completionHandler: completionHandler)
    }

    public func fetchSpaceMyFeedList(timestamp: String, size: Int, completionHandler: @escaping (Result<MinutesFeedList, Error>) -> Void) {
        let request = FetchSpaceMyFeedListRequest(timestamp: timestamp, size: size)
        api.sendRequest(request) { (result) in
            completionHandler(result.map { $0.data })
        }
    }

    public func fetchSpaceShareFeedList(timestamp: String, size: Int, completionHandler: @escaping (Result<MinutesFeedList, Error>) -> Void) {
        let request = FetchSpaceShareFeedListRequest(timestamp: timestamp, size: size)
        api.sendRequest(request) { (result) in
            completionHandler(result.map { $0.data })
        }
    }

    public func deleteFeed(objectToken: String, completionHandler: @escaping (Result<BasicResponse, Error>) -> Void) {
        let request = DeleteRequest(objectToken: objectToken)

        api.sendRequest(request, completionHandler: completionHandler)
    }

    public func fetchSpaceFeedListBatchStatus(catchError: Bool, objectToken: [String], completionHandler: @escaping (Result<MinutesFeedListStatus, Error>) -> Void) {
        let request = FetchSpaceFeedListBatchStatus(objectToken: objectToken, catchError: catchError)
        api.sendRequest(request) { (result) in
            completionHandler(result.map { $0.data })
        }
    }

    public func updateTitle(catchError: Bool, objectToken: String, topic: String, completionHandler: ((Result<Void, Error>) -> Void)? = nil) {
        let request = UpdateTitleRequest(objectToken: objectToken, topic: topic, catchError: catchError)

        api.sendRequest(request) { result in
            completionHandler?(result.map({ _ in () }))
        }
    }
}
