import LarkEnv

public protocol PassportGlobalDeviceService {

    func getDeviceIdAndInstallId(unit: String) -> DeviceInfoTuple?
}
