//
//  LarkLocationPickerViewModel.swift
//  LarkLocationPicker
//
//  Created by Fangzhou Liu on 2019/7/9.
//

import Foundation
import CoreLocation
import MapKit
import LarkLocalizations
import RxCocoa
import RxSwift
import RxDataSources
import LKCommonsLogging

enum State {
    case initial            // 初始状态
    case hint               // 输入提示搜索ing
    case hintResult         // 提示搜索有结果
    case search             // 搜索ing
    case result             // 有结果
    case resultMore         // 加载更多
    case empty              // 无结果
    case error              // 错误
}

public struct StateWrapper {
    let state: State
    let isFirstPage: Bool

    init(state: State, isFirstPage: Bool = true) {
        self.state = state
        self.isFirstPage = isFirstPage
    }
}

final class LocationTopPanelViewModel: NSObject {
    private static let logger = Logger.log(LocationTopPanelViewModel.self, category: "LocationPicker.LocationTopPanelViewModel")

    var state: BehaviorRelay<StateWrapper> = BehaviorRelay<StateWrapper>(value: StateWrapper(state: .initial))
    private var type: MapType?
    private var searchService: POISearchService = POISearchService(language: LanguageManager.currentLanguage)
    private var page: Int = 1
    private var textFieldInput: String = ""
    private var keyword: String = ""
    private var language: Lang = LanguageManager.currentLanguage
    // 本次查询返回的所有POI集合
    var searchResultDataSource: [UILocationData] = []
    let searchResult = BehaviorRelay<[UILocationData]>(value: [])
    var searchResultDriver: Driver<[UILocationData]> {
        return searchResult.asDriver()
    }

    // 本次查询返回的所有InpupTip集合
    var searchInputTipDataSource: [(UILocationData, Bool)] = []
    let searchInputTipResult = BehaviorRelay<[(UILocationData, Bool)]>(value: [])
    var searchInputTipDriver: Driver<[(UILocationData, Bool)]> {
        return searchInputTipResult.asDriver()
    }

    init(allowCustomLocation: Bool) {
        super.init()
        searchService.allowCustomLocation = allowCustomLocation
        self.searchService.delegate = self
    }

    func setCoordinateSystem(useWGS84: Bool) {
        searchService.setCoordinateSystem(system: useWGS84 ? .wgs84 : .origin)
    }

    func clearInputTipResult() {
        self.searchInputTipResult.accept([])
    }

    func reset() {
        textFieldInput = ""
        keyword = ""
        page = 1
        searchInputTipResult.accept([])
        searchResult.accept([])
        state.accept(StateWrapper(state: .initial))
    }

    func updateMapType(_ type: MapType) {
        self.type = type
        if type == .amap {
            LocationTopPanelViewModel.logger.info("Update Map Type By Amap")
        } else {
            LocationTopPanelViewModel.logger.info("Update Map Type By Apple")
        }
    }

    // 保证输入提示的搜索的结果和用户当前输入的保持一致
    func matchInputText(center: CLLocationCoordinate2D, text: String) {
        textFieldInput = text
        searchInputTip(center: center, keyword: text)
    }

    // 保证关键字搜索的结果和搜索的关键字保持一致
    func matchKeywordText(center: CLLocationCoordinate2D, text: String) {
        keyword = text
        searchKeyword(center: center, keyword: text)
    }

    // 根据数据搜索用户可能想要输入的关键字
    private func searchInputTip(center: CLLocationCoordinate2D, keyword: String, page: Int = 1) {
        guard let type = self.type else {
            return
        }
        self.keyword = keyword
        if keyword.isEmpty {
            state.accept(StateWrapper(state: .initial))
            return
        }
        // 加载更多数据时不需要清空
        if page == 1 {
            state.accept(StateWrapper(state: .hint))
            searchResult.accept([])
        }
        // 目前只有高德地图支持搜索联想
        // 苹果地图需要特殊设计 苹果地图联想Demo请见
        // https://developer.apple.com/documentation/mapkit/searching_for_nearby_points_of_interest
        if type == .amap {
            LocationTopPanelViewModel.logger.info("Search Input Tip By Gaode")
            searchService.searchInputTip(center: center, mapType: type, keyword: keyword)
        } else {
            LocationTopPanelViewModel.logger.info("Search Input Tip By Apple")
            searchKeyword(center: center, keyword: keyword, page: page)
        }
    }

    // 根据关键词搜索地理位置
    private func searchKeyword(center: CLLocationCoordinate2D, keyword: String, page: Int = 1) {
        guard let type = self.type else {
            return
        }
        LocationTopPanelViewModel.logger.info("Search Keyword")
        if keyword.isEmpty {
            state.accept(StateWrapper(state: .initial))
            return
        }
        // 加载更多数据时不需要清空
        if page == 1 {
            state.accept(StateWrapper(state: .search))
            searchResult.accept([])
        }
        searchService.searchKeyword(center: center,
                                    mapType: type,
                                    keyword: keyword, page: page)
    }

    func loadMoreSearchResult(center: CLLocationCoordinate2D) {
        state.accept(StateWrapper(state: .resultMore))
        page += 1
        searchKeyword(center: center, keyword: keyword, page: page)
    }
}

extension LocationTopPanelViewModel: SearchAPIDelegate {
    func reGeocodeFailed(data: UILocationData, err: Error) {
        // reGeocode Failed
    }

    func regionOutOfService(current: UILocationData) {
        // region out of service
    }

    func reGeocodeDone(data: UILocationData) {
        // do nothing
    }

    func searchInputTipDone(keyword: String, data: [(UILocationData, Bool)]) {
        /* 如果搜索结果与搜索关键字不一致，直接丢弃 */
        guard keyword == self.textFieldInput else { return }
        var tempState = StateWrapper(state: .result)
        // 如果数据为空, 显示无结果或者没有更多
        if data.isEmpty {
            tempState = StateWrapper(state: .empty)
        }
        self.state.accept(tempState)
        self.searchInputTipDataSource = data
        LocationTopPanelViewModel.logger.info("Get The Result Of Searching By Input Tip, count: \(data.count)")
        self.searchInputTipResult.accept(self.searchInputTipDataSource)
    }

    func searchFailed(err: Error) {
        // 显示无数据，并且隐藏小菊花
        LocationTopPanelViewModel.logger.error("Search Error")
        state.accept(StateWrapper(state: .error))
    }

    func searchDone(keyword: String?, data: [UILocationData], isFirstPage: Bool) {
        /* 如果搜索结果与搜索关键字不一致，直接丢弃 */
        guard let query = keyword, query == self.keyword else { return }
        var tempState = StateWrapper(state: .result, isFirstPage: isFirstPage)
        // 如果数据为空, 显示无结果或者没有更多
        if data.isEmpty {
            tempState = StateWrapper(state: .empty, isFirstPage: isFirstPage)
        } else if isFirstPage && data.count < LarkLocationPickerUtils.defaultPageOffset {
            // 如果第一次搜索结果少于24个，直接显示no more result
            tempState = StateWrapper(state: .empty, isFirstPage: !isFirstPage)
        }
        self.state.accept(tempState)
        // 下拉刷新时，直接将查询到的结果替换原数据, 上拉加载时，将查询到的结果拼接到原数据底部
        if isFirstPage {
            self.searchResultDataSource = data
        } else {
            self.searchResultDataSource.append(contentsOf: data)
        }
        LocationTopPanelViewModel.logger.info("Get The Result Of Searching By keyword, count: \(data.count)")
        self.searchResult.accept(self.searchResultDataSource)
    }
}

final class LocationPickerViewModel: NSObject {
    private static let logger = Logger.log(LocationPickerViewModel.self, category: "LocationPicker.LocationPickerViewModel")

    var state: BehaviorRelay<StateWrapper> = BehaviorRelay<StateWrapper>(value: StateWrapper(state: .initial))
    private var type: MapType?
    private let searchService: POISearchService = POISearchService(language: LanguageManager.currentLanguage)
    private var page: Int = 1
    private var poiCenter: CLLocationCoordinate2D?
    // 本次查询返回的所有POI集合
    var dataSource: [UILocationData] = []
    /// 本次查询返回的POI数据是否为空，用于提示优化判断使用，无业务数据逻辑
    var currentPOIDataIsEmpty = true
    // 当前位置的地理信息
    private var currentGeocode: UILocationData?
    // 搜索到的地理位置 (因为从搜索中选择地址后会刷新列表，所以需要先存下来搜索目的地，等列表刷新后再将这个数据添加到第一个位置）
    var searchedLocation: UILocationData? {
        didSet {
            defaultUserLocation = searchedLocation
            if let selectedLocation = searchedLocation {
                updateLocationList(selectedLocation: selectedLocation)
                if let centerGeocode = self.currentGeocode {
                    self.searchResult.accept([
                        SectionModel(model: 0, items: [centerGeocode]),
                        SectionModel(model: 1, items: self.dataSource)
                        ])
                }
            }
        }
    }
    // 选中的地理位置信息
    var selectedIndexPath = IndexPath(row: 0, section: 0)
    // 选中来源
    var selectedType: SelectedType = .defaultType
    // 默认反编码为初始用户想发送的地理信息
    var defaultUserLocation: LocationData?

    let searchResult = BehaviorRelay<[SectionModel<Int, UILocationData>]>(value: [])

    // 由于当前地理位置反解析和周边信息查询是两个request, 因此用这两个Bool值来保证当两个请求都有响应时才更新列表
    private var responseFromRegeocode: Bool = false
    private var responseFromPOISearch: Bool = false

    public override init() {
        super.init()
        self.searchService.delegate = self
    }

    deinit {
        searchService.delegate = nil
        print("LocationPickerViewModel deinit")
    }

    func setCoordinateSystem(useWGS84: Bool) {
        LocationPickerViewModel.logger.info("Use WGS84 \(useWGS84)")
        searchService.setCoordinateSystem(system: useWGS84 ? .wgs84 : .origin)
    }

    // 根据中心点搜索地理位置
    func searchPOI(center: CLLocationCoordinate2D, page: Int = 1) {
        guard self.type != nil else {
            LocationPickerViewModel.logger.info("type is nil")
            return
        }
        if center.latitude == 0.0 && center.longitude == 0.0 {
            LocationPickerViewModel.logger.info("invalid center latidute && longitude")
            return
        }
        LocationPickerViewModel.logger.info("Search POI")
        poiCenter = center
        if page == 1 {
            searchResult.accept([])
            selectedIndexPath = IndexPath(row: 0, section: 0)
            state.accept(StateWrapper(state: .search))
        }
        responseFromPOISearch = false
        responseFromRegeocode = false

        if page == 1 { searchService.searchReGeocode(center: center) }
        searchService.searchPOI(center: center, page: page)
    }

    func loadMoreSearchResult() {
        guard let center = poiCenter else {
            return
        }
        state.accept(StateWrapper(state: .resultMore))
        page += 1
        searchPOI(center: center, page: page)
        LocationPickerViewModel.logger.info("Load More")
    }

    func setSelectItem(index: IndexPath) {
        guard searchResult.value.count > index.section && searchResult.value[index.section].items.count > index.row else { return }

        var temp = searchResult.value
        // 将之前选择的重置
        if temp.count > selectedIndexPath.section && temp[selectedIndexPath.section].items.count > selectedIndexPath.row {
            temp[selectedIndexPath.section].items[selectedIndexPath.row].isSelected = false
        }
        // 更新最新选择的
        temp[index.section].items[index.row].isSelected = true
        selectedIndexPath = index
        searchResult.accept(temp)
    }

    func updateMapType(_ type: MapType) {
        self.type = type
        if type == .amap {
            LocationPickerViewModel.logger.info("Search Input Tip By Gaode")
        } else {
            LocationPickerViewModel.logger.info("Search Input Tip By Apple")
        }
    }

    func updateLocationList(selectedLocation: UILocationData) {
        // 如果搜索的地址已经存在在地址列表中，应从列表中删除并加到第一行
        // 否则直接加到第一行
        if self.dataSource.contains(where: { $0.name == selectedLocation.name &&
            $0.address == selectedLocation.address }
            ) {
            self.dataSource.removeAll(where: { $0.name == selectedLocation.name &&
                $0.address == selectedLocation.address })
        }
        self.dataSource.insert(selectedLocation, at: 0)
    }
}

extension LocationPickerViewModel: SearchAPIDelegate {
    func regionOutOfService(current: UILocationData) {
        // 高德地图无法解析海外的POI信息，因此当中心点位于海外时，只返回当前位置
        // region out of service
        LocationPickerViewModel.logger.info("Region Out Of Service By Gaode")
        state.accept(StateWrapper(state: .empty, isFirstPage: false))
        self.searchResult.accept([
            SectionModel(model: 0, items: [current]),
            SectionModel(model: 1, items: [])
            ])
    }

    func reGeocodeDone(data: UILocationData) {
        currentGeocode = data
        // 当用户从搜索关键字得到结果中选择位置时，默认即将被发送出去的位置需要变为用户选择的位置，而不是通过反解析得到的位置
        // 这样当用户从关键字搜索中选择好自己满意的结果时直接点击发送，仍可以发送用户选择的位置，而不是当前位置的反解析
        defaultUserLocation = (searchedLocation == nil) ? data : searchedLocation!
        responseFromRegeocode = true
        if responseFromPOISearch {
            LocationPickerViewModel.logger.info("ReGeoCode Done")
            state.accept(StateWrapper(state: .result))
            self.searchResult.accept([
                SectionModel(model: 0, items: [data]),
                SectionModel(model: 1, items: self.dataSource)
            ])
        }
    }

    func searchFailed(err: Error) {
        // 显示无数据，并且隐藏小菊花
        LocationPickerViewModel.logger.info("Search Error")
        responseFromPOISearch = true
        if responseFromRegeocode {
            if let centerGeocode = self.currentGeocode {
                state.accept(StateWrapper(state: .result))
                // 如果选了搜索结果，需要将他显示出来
                let data = (searchedLocation == nil) ? [] : [searchedLocation!]
                searchedLocation = nil
                self.currentPOIDataIsEmpty = data.isEmpty
                self.searchResult.accept([
                    SectionModel(model: 0, items: [centerGeocode]),
                    SectionModel(model: 1, items: data)
                    ])
                state.accept(StateWrapper(state: .error, isFirstPage: false))
            } else {
                state.accept(StateWrapper(state: .error, isFirstPage: true))
            }
        }
    }

    func reGeocodeFailed(data: UILocationData, err: Error) {
        responseFromRegeocode = true
        currentGeocode = data
        // 当用户从搜索关键字得到结果中选择位置时，默认即将被发送出去的位置需要变为用户选择的位置，而不是通过反解析得到的位置
        // 这样当用户从关键字搜索中选择好自己满意的结果时直接点击发送，仍可以发送用户选择的位置，而不是当前位置的反解析
        defaultUserLocation = (searchedLocation == nil) ? data : searchedLocation!
        LocationPickerViewModel.logger.info("ReGeoCode Failed")
        if responseFromPOISearch {
            var tempState = StateWrapper(state: .result)
            // 如果第一次搜索结果少于24个，直接显示no more result
            if self.dataSource.count < LarkLocationPickerUtils.defaultPageOffset {
                // 如果第一次搜索结果少于24个，直接显示no more result
                tempState = StateWrapper(state: .empty, isFirstPage: false)
            }
            state.accept(tempState)
            self.searchResult.accept([
                SectionModel(model: 0, items: [data]),
                SectionModel(model: 1, items: self.dataSource)
                ])
        }
    }

    func searchDone(keyword: String?, data: [UILocationData], isFirstPage: Bool) {
        LocationPickerViewModel.logger.info("Search Done")
        responseFromPOISearch = true
        var tempState = StateWrapper(state: .result, isFirstPage: isFirstPage)
        // 如果数据为空, 显示无结果或者没有更多
        if data.isEmpty {
            tempState = StateWrapper(state: .empty, isFirstPage: isFirstPage)
        } else if isFirstPage && data.count < LarkLocationPickerUtils.defaultPageOffset {
            // 如果第一次搜索结果少于24个，直接显示no more result
            tempState = StateWrapper(state: .empty, isFirstPage: !isFirstPage)
        }
        // 下拉刷新时，直接将查询到的结果替换原数据, 上拉加载时，将查询到的结果拼接到原数据底部
        if isFirstPage {
            self.dataSource = data
        } else {
            self.dataSource.append(contentsOf: data)
        }
        self.currentPOIDataIsEmpty = self.dataSource.isEmpty
        // 将搜索结果添加到POI搜索结果
        if let searchData = searchedLocation {
            selectedIndexPath = IndexPath(row: 0, section: 1)
            updateLocationList(selectedLocation: searchData)
            searchedLocation = nil
            defaultUserLocation = searchData
        }
        if responseFromRegeocode || !isFirstPage {
            self.state.accept(tempState)
            if let centerGeocode = self.currentGeocode {
                self.searchResult.accept([
                    SectionModel(model: 0, items: [centerGeocode]),
                    SectionModel(model: 1, items: self.dataSource)
                    ])
            }
        }
    }

    func searchInputTipDone(keyword: String, data: [(UILocationData, Bool)]) {
        // do nothing
    }
}
