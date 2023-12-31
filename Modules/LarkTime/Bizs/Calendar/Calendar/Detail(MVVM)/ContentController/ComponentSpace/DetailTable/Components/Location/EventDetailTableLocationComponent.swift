//
//  EventDetailTableLocationComponent.swift
//  Calendar
//
//  Created by Rico on 2021/4/6.
//

import UIKit
import LarkLocationPicker
import LarkCombine
import LarkContainer
import CalendarFoundation
import RxSwift
import UniverseDesignActionPanel
import LarkUIKit
import EENavigator

final class EventDetailTableLocationComponent: UserContainerComponent {

    let viewModel: EventDetailTableLocationViewModel
    var cancelables: Set<AnyCancellable> = []

    private let bag = DisposeBag()

    init(viewModel: EventDetailTableLocationViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(locationView)
        locationView.snp.edgesEqualToSuperView()

        bindViewModel()
    }

    private func bindViewModel() {
        if let viewData = viewModel.viewData.value {
            self.locationView.updateContent(viewData)
        }

        viewModel.viewData
            .compactMap { $0 }
            .receive(on: DispatchQueue.main.ocombine)
            .sink { [weak self] (viewData) in
                guard let self = self else { return }
                self.locationView.updateContent(viewData)
            }.store(in: &cancelables)

        viewModel.showMap
            .receive(on: DispatchQueue.main.ocombine)
            .sink { [weak self] (show) in
                guard let self = self,
                      let viewController = self.viewController else { return }
                switch show {
                case let .query(query): LarkLocationPickerUtils.showMapSelectionSheet(from: viewController, query: query)
                case let .location(location):
                    LarkLocationPickerUtils.showMapSelectionSheet(from: viewController,
                                                                  isInternal: false,
                                                                  isGcj02: true,
                                                                  locationName: location.location,
                                                                  latitude: Double(location.latitude),
                                                                  longitude: Double(location.longitude))
                case let .selector(parsedLocations):
                    self.showLocationPicker(parsedLocations: parsedLocations)
                case let .applink(url):
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }.store(in: &cancelables)
    }

    private func generateEventLocationCellData(locations: [Rust.ParsedEventLocationItem]) -> [EventLocationCellData] {
        let eventLocationCellData = locations.map {
            EventLocationCellData(parsedLocation: $0, onClick: {[weak self] location in
                guard let self = self else { return }
                self.actionPanel?.dismiss(animated: true)
                switch location.linkType {
                case .text:
                    LarkLocationPickerUtils.showMapSelectionSheet(from: self.viewController, query: location.locationContent)
                case .normal:
                    guard let url = URL(string: location.locationContent) else { break }
                    if Display.pad {
                        self.userResolver.navigator.present(url,
                                                 context: ["from": "calendar"],
                                                 wrap: LkNavigationController.self,
                                                 from: self.viewController,
                                                 prepare: { $0.modalPresentationStyle = .fullScreen })
                    } else {
                        self.userResolver.navigator.push(url, context: ["from": "calendar"], from: self.viewController)
                    }
                case .vcLink:
                    guard let url = URL(string: location.locationContent) else { break }
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                default:
                    break
                }
            })
        }
        return eventLocationCellData
    }

    var actionPanel: UDActionPanel?

    private func showLocationPicker(parsedLocations: [Rust.ParsedEventLocationItem]) {
        let locationSelectorVC = ActionPanelContentViewController()
        let locationSelectorView = LocationSelectorView(locations: generateEventLocationCellData(locations: parsedLocations))

        let selectorViewHeight = locationSelectorView.estimateHeight()
        locationSelectorVC.addContentView(locationSelectorView, contentHeight: selectorViewHeight)

        let screenHeight = Display.height
        // 24 是 title 占的高度，location 的 picker 没有 title
        let actionPanelOriginY = max(screenHeight - CGFloat((selectorViewHeight + 140 - 24)), screenHeight * 0.2)
        let actionPanel = UDActionPanel(
            customViewController: locationSelectorVC,
            config: UDActionPanelUIConfig(
                originY: actionPanelOriginY,
                canBeDragged: false,
                backgroundColor: UIColor.ud.bgFloatBase
            )
        )
        self.actionPanel = actionPanel

        if Display.pad {
            let vc = ParsedLinkViewController()
            vc.addContentView(locationSelectorView, title: BundleI18n.Calendar.Calendar_Edit_Location)
            let nav = LkNavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .formSheet
            nav.update(style: .custom(UIColor.ud.bgFloat))
            viewController.present(nav, animated: true, completion: nil)
        } else {
            viewController.present(actionPanel, animated: true, completion: nil)
        }
    }

    private lazy var locationView: DetailLocationCell = {
        let locationView = DetailLocationCell()
        locationView.delegate = self
        return locationView
    }()
}

extension EventDetailTableLocationComponent: DetailLocationCellDelegate {
    func onTapMap() {
        viewModel.onTapMap()
    }
}
