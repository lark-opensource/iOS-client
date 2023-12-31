//
//  DrivePDFViewController+State.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/4/1.
//  

import SKUIKit
import PDFKit
import RxSwift
import RxCocoa
import SKFoundation
import SKCommon
import SKResource
import SpaceInterface

extension DrivePDFViewController: DriveFollowContentProvider {

    var vcFollowAvailable: Bool {
        return true
    }

    var followScrollView: UIScrollView? {
        return pdfScrollView
    }

    func setup(followDelegate: DriveFollowAPIDelegate, mountToken: String?) {
        driveViewModel.setup(followDelegate: followDelegate, mountToken: mountToken)
    }

    func registerFollowableContent() {
        driveViewModel.registerFollowableContent()
    }
    
    func unregisterFollowableContent() {
        driveViewModel.unregisterFollowableContent()
    }
    
    func onRoleChange(_ newRole: FollowRole) {
        driveViewModel.followRoleChangeSubject.onNext(newRole)
        var title = BundleI18n.SKResource.Drive_Drive_PresentationEnd
        if newRole == .presenter {
            title = BundleI18n.SKResource.Drive_Drive_PresentationEnd
        } else {
            title = BundleI18n.SKResource.CreationMobile_MS_ExitFullScreen
        }
        updatePresentationCloseTitle(title)
    }
}

// MARK: - State
extension DrivePDFViewController {
    typealias State = DrivePDFFollowState

    private enum Const {
        static let debounceMilliseconds = 50
        static let animateDuration = 0.2
    }

    func bindScrollViewState(_ scrollView: UIScrollView) {
        scrollView.rx.didScroll
            .bind(to: followStateSubject)
            .disposed(by: disposeBag)
        scrollView.rx.didZoom
            .bind(to: followStateSubject)
            .disposed(by: disposeBag)
    }

    func bindStateUpdated() {
        // 收到 follow 同步的状态时，重放状态
        driveViewModel.pdfFollowStateUpdated
            .drive(onNext: { [weak self] newState in
                self?.set(state: newState)
            })
            .disposed(by: disposeBag)

        // PDF 状态变化时，通知 viewModel
        followStateSubject
            .debounce(.milliseconds(Const.debounceMilliseconds), scheduler: MainScheduler.instance)
            .flatMap({ [weak self] _ -> Observable<State> in
                guard let state = self?.getState() else {
                    return .never()
                }
                return .just(state)
            })
            .bind(to: driveViewModel.pdfStateRelay)
            .disposed(by: disposeBag)

        // 演示模式翻页时，更新状态
        viewModel.goPrevious
            .asObservable()
            .bind(to: followStateSubject)
            .disposed(by: disposeBag)

        viewModel.goNext
            .asObservable()
            .bind(to: followStateSubject)
            .disposed(by: disposeBag)
    }

    func set(state: State) {
        // 开始 Follow 时，收起可能已经打开的缩略图页面
        gridModeView.reset()
        switch state {
        case let .preview(location, topLocation):
            DocsLogger.driveInfo("drive.pdf.follow --- applying preview state")
            driveViewModel.presentationModeChangedSubject.onNext((false, .auto))
            if let topLocation = topLocation {
                set(location: topLocation, for: .top)
            } else {
                set(location: location, for: .center)
            }
        case let .presentation(pageNumber):
            DocsLogger.driveInfo("drive.pdf.follow --- applying presentation pageNum: \(pageNumber)")
            driveViewModel.presentationModeChangedSubject.onNext((true, .auto))
            _ = go(to: pageNumber - 1)
        }
    }

    func getState() -> State {
        let isPresentationMode = viewModel.currentConfig.shouldLandscape
        if isPresentationMode {
            let pageNumber = currentPageNumber ?? 1
            return .presentation(pageNumber: pageNumber)
        } else {
            let location = getLocation(for: .center)
            let topLocation = getLocation(for: .top)
            return .preview(location: location, topLocation: topLocation)
        }
    }
}

// MARK: - Location
extension DrivePDFViewController {

    typealias Location = DrivePDFFollowState.Location

    /// 将指定位置转换为 Location
    /// - Parameters:
    ///   - destination: 需要转换的 PDFView destination
    ///   - anchorPointOffset: 参考点相对 PDFDestination 的偏移量绝对值
    private func convert(destination: PDFDestination, anchorPointOffset: CGPoint) -> Location? {
        // 实际缩放系数
        let actualScaleFactor: CGFloat
        if pdfView.scaleFactor != 0 {
            actualScaleFactor = pdfView.scaleFactor
        } else {
            DocsLogger.error("drive.pdf.state --- pdfView scaleFactor is 0 when convert destionation to location")
            actualScaleFactor = pdfView.scaleFactorForSizeToFit
        }
        // 当前 page 对象
        guard let destinationPage = destination.page else {
            DocsLogger.error("drive.pdf.state --- failed to convert destination to location, destination page is nil")
            return nil
        }
        guard let destinationPageNumber = destinationPage.pageRef?.pageNumber else {
            DocsLogger.error("drive.pdf.state --- failed to convert destination to location, destination page number is nil")
            return nil
        }
        // 0-base 当前 page 页码
        let destinationIndex = destinationPageNumber - 1
        // 0-base 转换后的 page 页码
        var statePageIndex = destinationIndex
        // 当前 page 尺寸
        var destinationPageSize = destinationPage.bounds(for: .mediaBox).size
        // 加上 page 之间的分隔距离，避免 page 累加后导致错位
        destinationPageSize.height += pdfView.pageBreakMargins.top + pdfView.pageBreakMargins.bottom
        if destinationPageSize.width == 0 {
            DocsLogger.error("drive.pdf.state --- destinationPageSize.width is 0 when convert destionation to location")
            destinationPageSize.width = pdfView.frame.width
        }
        if destinationPageSize.height == 0 {
            DocsLogger.error("drive.pdf.state --- destinationPageSize.height is 0 when convert destionation to location")
            destinationPageSize.height = pdfView.frame.height
        }
        let destinationPoint = destination.point
        let statePoint = CGPoint(x: destinationPoint.x + anchorPointOffset.x, y: destinationPoint.y + anchorPointOffset.y)
        // 计算 pdfView 中心点相对于当前 page 左上角的偏移量，根据 page size 换算为百分比
        var stateRatioPoint = CGPoint(x: statePoint.x / destinationPageSize.width, y: 1 - (statePoint.y / destinationPageSize.height))
        // 如果 PDFView 中心点 y 方向相对偏移量小于 0，说明中心点位置高于当前 page，需要整体向上移动一页
        // TODO: 如果每一页的高度不同，会导致算出来的偏移量不正确，后续需要考虑根据每一页的尺寸进行计算
        while stateRatioPoint.y < 0,
            statePageIndex > 0 {
                stateRatioPoint.y += 1
                statePageIndex -= 1
        }

        // 计算相对缩放系数，以自适应缩放时的比例为单位 1
        let relativeScale = actualScaleFactor / pdfView.scaleFactorForSizeToFit

        return Location(pageNumber: statePageIndex + 1, pageOffset: stateRatioPoint, scale: Double(relativeScale))
    }

    /// 将 location 转换为 PDFDestination
    /// - Parameters:
    ///   - location: Follow 传来的 location
    ///   - anchorPointOffset: location 参考点相对 PDFView 左上角的偏移量绝对值
    private func convert(location: Location, anchorPointOffset: CGPoint) -> PDFDestination? {
        guard let document = document else {
            DocsLogger.error("drive.pdf.state --- failed to convert location to destination, document is nil")
            return nil
        }
        // 实际的缩放系数
        let actualScaleFactor = CGFloat(location.scale) * pdfView.scaleFactorForSizeToFit
        // location 所在的 page 对象
        guard let locationPage = document.page(at: location.pageNumber - 1) else {
            DocsLogger.error("drive.pdf.state --- failed to convert location to destination, cannot get page for pageNumber: \(location.pageNumber)")
            return nil
        }
        // pdfView 中心所在 page 尺寸
        var locationPageSize = locationPage.bounds(for: .mediaBox).size
        // 加上 page 之间的分隔距离，避免 page 累加后导致错位
        locationPageSize.height += pdfView.pageBreakMargins.top + pdfView.pageBreakMargins.bottom
        // pdfView 中心点相对当前 page 左下角的偏移量，根据 page size 转换为绝对值
        let locationPagePoint = CGPoint(x: locationPageSize.width * location.pageOffset.x, y: locationPageSize.height * (1 - location.pageOffset.y))
        // 绝了，PDFView go to destination 时，会将指定的位置滚动到 view 顶部
        // 但是从 PDFView 读 destination 时给的却是最底部的位置
        // 所以这里得计算 PDFView 左上角的偏移量，保证 go to destination 时滚动到正确的位置
        // 计算 PDFView 左上角相对当前 page 左下角的偏移量
        var destinationPoint = CGPoint(x: locationPagePoint.x + anchorPointOffset.x,
                                       y: locationPagePoint.y + anchorPointOffset.y)
        // 0-base 当前 page 页码
        var destinationPageIndex = location.pageNumber - 1
        // 如果 pdfView 左上角点 y 方向相对偏移量大于page高度，说明左上角点位置高于当前 page，需要整体向上移动一页
        // TODO: 如果每一页的高度不同，会导致算出来的偏移量不正确，后续需要考虑根据每一页的尺寸进行计算
        while destinationPageIndex > 0,
            destinationPoint.y > locationPageSize.height {
                destinationPageIndex -= 1
                destinationPoint.y -= locationPageSize.height
        }
        // 最终计算得到的 page 对象
        guard let destinationPage = document.page(at: destinationPageIndex) else {
            DocsLogger.error("drive.pdf.state --- failed to convert location to destination, cannot get page for destination page index: \(destinationPageIndex)")
            return nil
        }
        // 最终计算得到的终点
        let destination = PDFDestination(page: destinationPage, at: destinationPoint)
        // 设置缩放系数
        destination.zoom = actualScaleFactor
        return destination
    }

    func set(location: Location, for followLocation: PDFFollowLocation) {
        guard isPDFLoaded else {
            DocsLogger.error("drive.pdf.state --- set location failed, PDF is not ready")
            return
        }
        let scaleFactor: CGFloat
        if pdfView.scaleFactor != 0 {
            scaleFactor = pdfView.scaleFactor
        } else {
            DocsLogger.error("drive.pdf.state --- pdfView scaleFactor is 0 when convert location to destionation")
            scaleFactor = pdfView.scaleFactorForSizeToFit
        }
        let offsetPoint = followLocation.calSetLocationAnchorPoint(frame: pdfView.frame, scaleFactor: scaleFactor)
        guard let destination = convert(location: location,
                                        anchorPointOffset: offsetPoint) else {
            DocsLogger.error("drive.pdf.state --- set \(followLocation.rawValue) location failed", extraInfo: ["location": location])
            return
        }
        UIView.animate(withDuration: Const.animateDuration) {
            if destination.zoom != kPDFDestinationUnspecifiedValue {
                self.pdfView.scaleFactor = destination.zoom
            }
            self.pdfView.go(to: destination)
        }
    }

    func getLocation(for followLocation: PDFFollowLocation) -> Location {
        guard isPDFLoaded else {
            DocsLogger.error("drive.pdf.state --- get location failed, PDF is not ready")
            return .zero
        }
        guard let currentDestination = pdfView.currentDestination else {
            DocsLogger.error("drive.pdfkit.state --- failed to get current destination")
            return .zero
        }
        let scaleFactor: CGFloat
        if pdfView.scaleFactor != 0 {
            scaleFactor = pdfView.scaleFactor
        } else {
            DocsLogger.error("drive.pdf.state --- pdfView scaleFactor is 0 when convert destionation to location")
            scaleFactor = pdfView.scaleFactorForSizeToFit
        }
        let offsetPoint = followLocation.calGetLocationAnchorPoint(frame: pdfView.frame, scaleFactor: scaleFactor)
        guard let location = convert(destination: currentDestination,
                                     anchorPointOffset: offsetPoint) else {
            DocsLogger.error("drive.pdfkit.state --- get \(followLocation.rawValue) location from destination failed")
            return .zero
        }
        return location
    }
    
    enum PDFFollowLocation: String {
        case center
        case top
        
        func calGetLocationAnchorPoint(frame: CGRect, scaleFactor: CGFloat) -> CGPoint {
            switch self {
            case .center:
                // pdfView中心点相对于 PDFView 左下角的偏移
                let xOffset = frame.width / 2 / scaleFactor
                let yOffset = frame.height / 2 / scaleFactor
                return CGPoint(x: xOffset, y: yOffset)
            case .top:
                // pdfView顶部中心点相对于当前 page 左下角的偏移量
                let xOffset = frame.width / 2 / scaleFactor
                let yOffset = frame.height / scaleFactor
                return CGPoint(x: xOffset, y: yOffset)
            }
        }
        
        func calSetLocationAnchorPoint(frame: CGRect, scaleFactor: CGFloat) -> CGPoint {
            switch self {
            case .center:
                // 计算 PDFView 中心相对 PDFView 左上角的偏移量
                let xOffset = -frame.width / 2 / scaleFactor
                let yOffset = frame.height / 2 / scaleFactor
                return CGPoint(x: xOffset, y: yOffset)
            case .top:
                // 计算 PDFView 顶部中心相对 PDFView 左上角的偏移量
                let xOffset = -frame.width / 2 / scaleFactor
                let yOffset: CGFloat = 0
                return CGPoint(x: xOffset, y: yOffset)
            }
        }
    }
}
