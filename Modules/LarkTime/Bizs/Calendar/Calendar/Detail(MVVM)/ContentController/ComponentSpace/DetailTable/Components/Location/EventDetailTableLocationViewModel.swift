//
//  EventDetailTableLocationViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/4/6.
//

import Foundation
import LarkCombine
import LarkContainer
import RxSwift
import RxRelay

final class EventDetailTableLocationViewModel: EventDetailComponentViewModel {

    var model: EventDetailModel { rxModel.value }
    let viewData = CurrentValueSubject<DetailLocationCellContent?, Never>(nil)
    let showMap = PassthroughSubject<ShowLocation, Never>()
    private let disposeBag = DisposeBag()

    @ContextObject(\.rxModel) var rxModel

    @ScopedInjectedLazy
    private var calendarApi: CalendarRustAPI?

    let rxParsedLocations = BehaviorRelay<[Rust.ParsedEventLocationItem]>(value: [])

    override init(context: EventDetailContext, userResolver: UserResolver) {
        super.init(context: context, userResolver: userResolver)

        bindRx()
    }

    private func bindRx() {
        rxModel.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.buildViewData()
            self.parseEventLocations()
        })
        .disposed(by: disposeBag)

        rxParsedLocations.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            if self.isLocationParsed {
                self.buildViewData(hasParsed: true)
            }
        })
        .disposed(by: disposeBag)
    }
}

extension EventDetailTableLocationViewModel {
    private func buildViewData(hasParsed: Bool = false) {
        let location = hasParsed ? getParsedLocation() : getLocation()
        viewData.send(location)
    }

    private func parseEventLocations() {
        guard shouldParseLocation, !event.location.location.isEmpty else { return }

        let resourceName: [String] = event.source == .google ? event.attendees.filter { $0.category == .resource }.map { $0.displayName } : []

        calendarApi?.parseEventMeetingLinks(eventLocation: event.location.location,
                                           eventDescription: "",
                                           eventSource: event.source,
                                           resourceName: resourceName)
        .subscribe(onNext: {[weak self] resp in
            guard let self = self else { return }
            let parsedEvents = resp.locationItem
            if !parsedEvents.isEmpty {
                EventDetail.logInfo("get \(parsedEvents.count) locationItems from parseEventLocations")
                self.rxParsedLocations.accept(parsedEvents)
            }
        }, onError: { error in
            EventDetail.logError("parseEventLocations failed: \(error)")
        }).disposed(by: disposeBag)
    }
}

extension EventDetailTableLocationViewModel {

    enum ShowLocation {
        case query(query: String)
        case location(location: CalendarLocation)
        case selector(parsedLocation: [Rust.ParsedEventLocationItem])
        case applink(url: URL)
    }

    func onTapMap() {
        if isLocationParsed {
            EventDetail.logInfo("tapMap. show location selector")
            showMap.send(.selector(parsedLocation: rxParsedLocations.value))
            return
        }
        let location = model.location
        let validLocation = location.latitude != 360.0 && location.longitude != 360.0
        let zeroLocation = location.latitude == 0.0 && location.longitude == 0.0
        if validLocation && !zeroLocation {
            EventDetail.logInfo("tapMap. to latitude-longitude location")
            showMap.send(.location(location: location))
        } else if let url = URL(string: location.location), UIApplication.shared.canOpenURL(url) {
            EventDetail.logInfo("tapMap. open url location")
            showMap.send(.applink(url: url))
        } else if rxParsedLocations.value.count == 1,
                  let parsedLocation = rxParsedLocations.value.first,
                  parsedLocation.linkType != .text,
                  let url = URL(string: parsedLocation.locationURL), UIApplication.shared.canOpenURL(url) {
            EventDetail.logInfo("tapMap. open url location")
            showMap.send(.applink(url: url))
        } else {
            EventDetail.logInfo("tapMap. query, location is not url")
            showMap.send(.query(query: location.location))
        }
    }
}

extension EventDetailTableLocationViewModel {

    struct ViewData: DetailLocationCellContent {
        let location: String?
        let address: String?
        let latitude: Float?
        let longitude: Float?
    }

    private func getLocation() -> DetailLocationCellContent {
        return ViewData(location: model.location.location,
                        address: model.location.address,
                        latitude: model.location.latitude,
                        longitude: model.location.longitude)
    }

    private func getParsedLocation() -> DetailLocationCellContent {
        EventDetail.logInfo("show parsed location")
        let locationText = rxParsedLocations.value.map { $0.locationContent.trimmingCharacters(in: .whitespacesAndNewlines) }.joined(separator: ";\n")
        return ViewData(location: locationText,
                        address: "",
                        latitude: 360.0,
                        longitude: 360.0)
    }
}

extension EventDetailTableLocationViewModel {
    var event: EventDetail.Event {
        guard let event = rxModel.value.event else {
            EventDetail.logUnreachableLogic()
            return EventDetail.Event()
        }
        return event
    }

    // 经纬度不合法的话需要解析
    var shouldParseLocation: Bool {
        let location = event.location
        let validLocation = -90.0 <= location.latitude && location.latitude <= 90.0 && -180.0 <= location.longitude && location.longitude <= 180.0
        let zeroLocation = (location.latitude == 0.0 && location.longitude == 0.0)
        if validLocation && !zeroLocation {
            return false
        } else {
            let sources: [Rust.Event.Source] = [.google, .email, .exchange]
            return sources.contains(event.source) || (event.videoMeeting.videoMeetingType == .noVideoMeeting)
        }
    }

    var isLocationParsed: Bool {
        let count = rxParsedLocations.value.count
        EventDetail.logInfo("isLocationParsed: \(count)")
        // 解析结果只有一个或0个的话，当成没解析，按原来的方式展示
        return count > 1
    }
}
