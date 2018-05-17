//
// Copyright © 2018 HERE Global B.V. All rights reserved.
//

import UIKit
import HereSDKMapKit
import HereSDKDemandKit

class SDKGetRidesViewController: GetRidesViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // optional - if not specified default coordinate is Berlin
        self.mapView.centerCoordinate = GetRidesViewController.londonLocation;
        // optional - if not specified default zoom is 15.3999996
        self.mapView.zoom = 17;
        // required - map updates
        self.mapView.delegate = self;
        // configured to simulate London location. Location improves geocoding results
        mapView.showUserLocation(true)
    }

    // example of adding annotation to map
    func addAnnotationToMapView(coordinate : CLLocationCoordinate2D){
        self.mapView.addAnnotation(HereSDKPointAnnotation (coordinate: coordinate))
    }
}

extension GetRidesViewController {

    func getRides(){
        HereSDKDemandManager.shared.getRides(getHereSDKDemandRideQuery()) { [weak self] (result, error ) in
            if result.ridesArray.count > 0{
                print("Got \(result.ridesArray.count) rides from getRides")
                self?.prebookedRides = result.ridesArray
                self?.showFutureRidesButton.isHidden = false
            }
            else{
                print("Got 0 rides from getRides")
                self?.showFutureRidesButton.isHidden = true
            }
        }
    }

    func getHereSDKDemandRideQuery() -> HereSDKDemandRideQuery{
        // we set time Interval to the past - in case a new prebook was generated
        return HereSDKDemandRideQuery.init(updateTime: Date().addingTimeInterval(60 * 30 * -1), limit: 100, statusFilter: .future,  sortBy: .createTimeAsc)
    }

    func requestGeocodeResults(query: String) {
        guard let lastLocation = lastLocation else { return }
        mapService.geocodeQuery(query,
                                forlocation: lastLocation,
                                resultType: .place,
                                countryCode: "") { [weak self] (results, error) in
                                    if error == nil {
                                        debugPrint("SDK Request [GeocodeQuery] succeed with \(String(describing: results?.count)) routes")
                                        if let results = results{
                                            guard let strongSelf = self else { return }
                                            strongSelf.geocodeResults = results
                                            strongSelf.geocodeResultsTableView.reloadData()
                                        }
                                    }
                                    else {
                                        debugPrint("SDK Request [GeocodeQuery] failed with error: \(String(describing: error))")
                                    }
        }
    }

    func tryDisplayRoute(){
        if let originGeocodeResult = self.originGeocodeResult, let destinationGeocodeResult = self.destinationGeocodeResult{

            let startLocation = CLLocation(latitude: originGeocodeResult.center.latitude , longitude: originGeocodeResult.center.longitude)
            let endLocation = CLLocation(latitude: destinationGeocodeResult.center.latitude , longitude: destinationGeocodeResult.center.longitude)
            // set to get multiple routes
            // routeRequest.requestAlternativeRoutes = true

            // add location/s to add stop/s
            if let routeRequest = HereSDKRouteRequest(points: [startLocation, endLocation]){
                mapService.getRoutesWith(routeRequest, andHandler: {  [weak self] routes, error in
                    if (error == nil){
                        if let firstRoute = routes?.first{
                            if let polylines = self?.mapView.polylines, let displayedPolyline = self?.displayedRoutePolyline{
                                if polylines.contains(displayedPolyline)
                                {
                                    self?.mapView.removePolyline(displayedPolyline)
                                }
                            }
                            self?.mapView.addPolyline(firstRoute.polyline)
                            self?.displayedRoutePolyline = firstRoute.polyline
                            // bounding box of the route is the rect that contains the polyline
                            let edgeInsets : UIEdgeInsets = UIEdgeInsets(top: 180, left: 20, bottom: 70, right: 10)
                            self?.mapView.setVisibleMapRect(firstRoute.polyline.boundingBox, edgePadding: edgeInsets, animated: true)
                        }
                    }
                    else{
                        debugPrint(error.debugDescription)
                    }
                })
            }
        }
    }
}

extension SDKGetRidesViewController : HereSDKMapViewDelegate{

    /// indicates that mapview scene (map layout) has been loaded, annotations will be visible on map from that point and map start to load tiles from network.
    //  if there's no network - this still called
    /// - Parameter mapView: HereSDKMapView
    func mapViewDidFinishLoadingMap(_ mapView: HereSDKMapView) {
        debugPrint("SDK MapView finished map loading")
    }

    /// you can enable user location on map with mapView.showUserLocation(true) and get informative description in this callback
    ///
    /// - Parameters:
    ///   - mapView: HereSDKMapView
    ///   - userLocation: userLocationAnnotation that specifies user location
    func mapView(_ mapView: HereSDKMapView, didUpdate userLocationAnnotation: HereSDKUserLocationAnnotation) {
//        lastLocation = CLLocation(latitude:  userLocationAnnotation.coordinate.latitude, longitude: userLocationAnnotation.coordinate.longitude)
    }

    ///  used to set annotation layout after adding annotation to map
    ///
    /// - Parameters:
    ///   - mapView: HereSDKMapView
    ///   - annotation: HereSDKAnnotation
    /// - Returns: HereSDKPointAnnotationStyle that can customize annotation
    func mapView(_ mapView: HereSDKMapView, styleFor annotation: HereSDKAnnotation) -> HereSDKPointAnnotationStyle? {

        var annotationStyle: HereSDKPointAnnotationStyle? = nil
        if annotation === originAnnotation {
            annotationStyle = HereSDKPointAnnotationStyle(image: #imageLiteral(resourceName: "CurrentLocation"), anchor: .center)
        } else if annotation === destinationAnnotation {
            annotationStyle = HereSDKPointAnnotationStyle(image: #imageLiteral(resourceName: "Destination"), anchor: .top)
        }
        return annotationStyle
    }
}
