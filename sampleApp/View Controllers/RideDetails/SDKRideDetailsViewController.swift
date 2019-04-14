//
// Copyright © 2018 HERE Global B.V. All rights reserved.
//

import UIKit
import HereSDKMapKit
import HereSDKDemandKit

class SDKRideDetailsViewController: RideDetailsViewController {

}

extension RideDetailsViewController{

    /// in order to present rides, origin & destination HereSDKAddressData needed (as the object provide full address)
    func showRides(){
        weak var wSelf = self

        if let geoOrigin = originGeocodeResult, let geoDestination = destinationGeocodeResult, let originAddressId = geoOrigin.addressId, let destinationAddressId = geoDestination.addressId {
            // get full address data for origin & destination HereSDKGeocodeResult
            getAddressDataFor(originAddressId: originAddressId, destinationAddressId: destinationAddressId, completion: { (results) in
                if let originGeocodeData = results[0]?.0 , let destinationGeocodeData = results[1]?.0{

                    let rideOffersRequest = wSelf?.hereSDKRouteRequestFor(originGeocodeResult: geoOrigin, destinationGeocodeResult: geoDestination, originAddressData: originGeocodeData, destinationAddressData: destinationGeocodeData)

                    let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                    let rideOffersVC : RideOffersViewController = storyboard.instantiateViewController(withIdentifier: RideOffersViewController.segueId) as! RideOffersViewController
                    rideOffersVC.rideRequest = rideOffersRequest
                    rideOffersVC.passengerDetails = HereSDKDemandPassenger(name: wSelf?.nameCell.textLabel?.text ?? RideDetailsDefaultValues.name,
                                                                           phoneNumber: wSelf?.phoneNumberCell.textLabel?.text ?? RideDetailsDefaultValues.phoneNumber,
                                                                           photoUrl: "",
                                                                           email : "")
                    rideOffersVC.passengerNotes = wSelf?.noteCell.textLabel?.text ?? ""
                    rideOffersVC.isPrebook = !self.bookNowCell.on

                    wSelf?.navigationController?.pushViewController(rideOffersVC, animated: true)
                }
            })
        }
    }

    // return array of 2 tuples of (HereSDKAddressData?, Error?) that include the data received for origin & destination in HereSDKGeocodeResult
    func getAddressDataFor(originAddressId : String, destinationAddressId : String, completion :@escaping (_ results : [Int : (HereSDKAddressData?, Error?)]) -> Void)
    {
        var results :  [Int : (HereSDKAddressData?, Error?)] = [:]

        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        mapService.getAddressData(withAddressId: originAddressId, andHandler: { (addressData, error) in
            results[0] = (addressData, error)
            if (error != nil){
                debugPrint(error.debugDescription)
            }
            dispatchGroup.leave()
        })
        dispatchGroup.enter()
        mapService.getAddressData(withAddressId: destinationAddressId, andHandler: { (addressData, error) in
            results[1] = (addressData, error)
            if (error != nil){
                debugPrint(error.debugDescription)
            }
            dispatchGroup.leave()
        })
        dispatchGroup.notify(queue: DispatchQueue.main) {
            completion(results)
        }
    }

    // creates ride offers request from origin & destination HereSDKGeocodeResult ,HereSDKDemandPriceRange ,HereSDKDemandBookingConstraints
    func hereSDKRouteRequestFor(originGeocodeResult : HereSDKGeocodeResult, destinationGeocodeResult : HereSDKGeocodeResult, originAddressData : HereSDKAddressData, destinationAddressData : HereSDKAddressData) -> HereSDKDemandRideOffersRequest{

        let demandRoute = getDemandRoute(originGeocodeResult: originGeocodeResult, destinationGeocodeResult: destinationGeocodeResult, originAddressData: originAddressData, destinationAddressData: destinationAddressData)
        // example of HereSDKDemandPriceRange
        let priceRange =  HereSDKDemandPriceRange(upperBound: 50.0, lowerBound: 10.0, currency: "USD")

        // example of hereSDKDemandTransitOptions - optional
        let demandTransitOptions = HereSDKDemandTransitOptions(maxTransfers: NSNumber(value : 3), maxWalkingDistance: NSNumber(value : 2000), locale: nil)

        let rideOffersRequest = HereSDKDemandRideOffersRequest(route: demandRoute)
        rideOffersRequest.constraints = self.getBookingConstraints()
        if self.bookNowCell.on, let prebookRideDate = self.prebookRideDate {
            rideOffersRequest.prebookPickupTime = prebookRideDate
        }
        rideOffersRequest.priceRange = priceRange
        rideOffersRequest.transitOptions = demandTransitOptions

        return rideOffersRequest
    }

    /// returns demand ride booking constraint object
    func getBookingConstraints() -> HereSDKDemandBookingConstraints{
        let hereSDKDemandBookingConstraints = HereSDKDemandBookingConstraints()
        hereSDKDemandBookingConstraints.numberOfPassengers = UInt32(self.passengersCell.value)
        hereSDKDemandBookingConstraints.numberOfSuitcases = UInt32(self.suitcasesCell.value)
        return hereSDKDemandBookingConstraints
    }

    func getDemandRoute(originGeocodeResult : HereSDKGeocodeResult, destinationGeocodeResult : HereSDKGeocodeResult, originAddressData : HereSDKAddressData, destinationAddressData : HereSDKAddressData) ->HereSDKDemandRoute{

        let originCLLocation = CLLocation(latitude: originGeocodeResult.center.latitude, longitude:originGeocodeResult.center.longitude)
        let destinationCLLocation = CLLocation(latitude: destinationGeocodeResult.center.latitude, longitude:destinationGeocodeResult.center.longitude)

        let originDemandLocation = HereSDKDemandLocation(location: originCLLocation, address: originAddressData, freeText: nil)
        let destinationDemandLocation = HereSDKDemandLocation(location: destinationCLLocation, address: destinationAddressData, freeText: nil)

        return HereSDKDemandRoute(pickupLocation: originDemandLocation, destinationLocation: destinationDemandLocation)
    }
}
