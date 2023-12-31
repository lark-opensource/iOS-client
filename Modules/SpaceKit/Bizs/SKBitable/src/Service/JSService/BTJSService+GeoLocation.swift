//
//  BTJSService+GeoLocation.swift
//  SKBitable
//
//  Created by 曾浩泓 on 2022/5/29.
//  


import SKFoundation
import SKResource
import UniverseDesignToast

extension BTJSService: BTFetchGeoLoactionHelperDelegate {
    func updateFetchingLocations(fieldLocations: Set<BTFieldLocation>) {
        cardVC?.viewModel.tableModel.update(fetchingGeoLocationFields: fieldLocations)
        cardVC?.viewModel.notifyModelUpdate()
    }
    func notifyFrontendDidFetchGeoLocation(forLocation location: BTFieldLocation, geoLocation: BTGeoLocationModel, isAutoLocate: Bool, callback: String) {
        guard geoLocation.isLocationValid else {
            DocsLogger.error("geo location is invalid:(\(String(describing: geoLocation.location?.latitude)), \(String(describing: geoLocation.location?.longitude)))")
            if let vc = cardVC {
                UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Field_LocationDataErrorRetry, on: vc.view)
            }
            return
        }
        let needToast = cardVC?.viewModel.tableModel
            .getRecordModel(id: location.recordID)?
            .getFieldModel(id: location.fieldID)?
            .geoLocationValue.first != nil
        
        let value = ["locations": [["poiInfo": geoLocation.toJSON()]]]
        let args = BTSaveFieldArgs(originBaseID: location.originBaseID,
                                   originTableID: location.originTableID,
                                   currentBaseID: location.baseID,
                                   currentTableID:  location.tableID,
                                   currentViewID: location.viewID,
                                   currentRecordID: location.recordID,
                                   currentFieldID: location.fieldID,
                                   callback: callback,
                                   editType: .cover,
                                   value: value)
        saveField(args: args)
        guard needToast, isAutoLocate, let vc = cardVC else {
            return
        }
        UDToast.showSuccess(with: BundleI18n.SKResource.Bitable_Field_LocationUpdated, on: vc.view)
    }
}
