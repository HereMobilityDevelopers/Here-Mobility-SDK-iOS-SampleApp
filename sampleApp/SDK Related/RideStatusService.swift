//
// Copyright © 2018 HERE Global B.V. All rights reserved.
//

import Foundation
import HereSDKDemandKit


protocol RideStatusObserver: class {
    func didUpdateStatus(for ride: HereSDKDemandRide)
    func didUpdateLocation(_ location: HereSDKDemandRideLocation, for ride: HereSDKDemandRide)
}

protocol RideStatusService: SDKErrorReporter {
    func addObserver(_ observer: RideStatusObserver, for rideID: String)
    func removeObserver(_ observer: RideStatusObserver, for rideID: String)
    func removeObserver(_ observer: RideStatusObserver)
}

// MARK: -
class RideStatusServiceImpl: NSObject, SDKService {
    weak var errorObserver: SDKErrorObserver?
    private var demandManager = HereSDKDemandManager.shared
    private var observersRegistry = NSMapTable<AnyObject, NSMutableSet>(keyOptions: .weakMemory, valueOptions: .strongMemory)

    private static var sharedService: RideStatusServiceImpl = {
        let rideStatusesService = RideStatusServiceImpl()
        return rideStatusesService
    }()

    // MARK: - Accessors
    class func shared() -> RideStatusServiceImpl {
        return sharedService
    }

    private override init() {
        super.init()
        HereSDKDemandManager.shared.registerForRidesUpdates(with: self)
    }
}

extension RideStatusServiceImpl: RideStatusService {

    func addObserver(_ observer: RideStatusObserver, for rideID: String) {
        let observedRideIds = self.observedRideIds(for: observer)
        observedRideIds.add(rideID)
        observersRegistry.setObject(observedRideIds, forKey: observer)
        debugPrint("SDK Rides status monitoring is started for ride \(rideID)")
    }
    
    func removeObserver(_ observer: RideStatusObserver, for rideID: String) {
        let observedRideIds = self.observedRideIds(for: observer)
        observedRideIds.remove(rideID)
        debugPrint("SDK Rides status monitoring is stopped for ride \(rideID)")
        if observedRideIds.count == 0 {
            observersRegistry.removeObject(forKey: observer)
        }
    }
    
    func removeObserver(_ observer: RideStatusObserver) {
        observersRegistry.removeObject(forKey: observer)
    }

    private func observedRideIds(for observer: RideStatusObserver) -> NSMutableSet {
        let registeredRideIds = observersRegistry.object(forKey: observer)
        return registeredRideIds ?? NSMutableSet()
    }
    
    private func observers(for rideId: String) -> [RideStatusObserver] {
        var result = [RideStatusObserver]()
        
        let registryEnumerator = observersRegistry.keyEnumerator()
        while let observer = registryEnumerator.nextObject() as? RideStatusObserver {
            let observedRideIds = observersRegistry.object(forKey: observer)
            if observedRideIds?.contains(rideId) == true {
                result.append(observer)
            }
        }
        
        return result
    }
}

extension RideStatusServiceImpl: HereSDKDemandRidesUpdatesDelegate {
    func didReceiveUpdate(_ statusLog: HereSDKDemandRideStatusLog!, for ride: HereSDKDemandRide!) {
        let rideId = ride.rideId

        debugPrint("SDK Ride \(rideId) updated status: \(statusLog.currentStatus.rawValue) at \(statusLog.lastUpdateTime)")

        observers(for: rideId).forEach {observer in
            DispatchQueue.main.async {
                observer.didUpdateStatus(for: ride)
            }
        }

    }

    func didReceive(_ location: HereSDKDemandRideLocation!, for ride: HereSDKDemandRide!) {
        guard let location = location else { return }

        if let vehicleLocation = location.vehicleLocation {
            debugPrint("SDK Ride \(ride.rideId) updated location: \(vehicleLocation.coordinate)")

            observers(for: ride.rideId).forEach {observer in
                DispatchQueue.main.async {
                    observer.didUpdateLocation(location, for: ride)
                }
            }
        }
    }
    
    func didReceiveUpdateError(_ error: Error!) {
        guard let error = error else { return }

        debugPrint("SDK Ride status update failed with error: \(error.localizedDescription)")
        handleResponseError(error)
    }
    
}
