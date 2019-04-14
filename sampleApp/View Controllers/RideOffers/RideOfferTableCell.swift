//
// Copyright © 2018 HERE Global B.V. All rights reserved.
//

import UIKit
import HereSDKDemandKit

protocol RideOfferTableCellDelegate: class {
    func offerCell(_ cell: RideOfferTableCell, didBookOffer offer: HereSDKDemandTaxiRideOffer)
    func offerCell(_ cell: RideOfferTableCell, showRideOfferDetails offer: HereSDKDemandPublicTransportRideOffer)
}

class RideOfferTableCell: BaseRideTableViewCell {

    static let storyboardIdentifier = "RideOfferTableCell"

    weak var delegate: RideOfferTableCellDelegate?

    // offer are passed in by RideOfferVC:cellForRowAt
    var offer: HereSDKDemandRideOfferProtocol! {
        didSet {
            updateUI(for: offer)
        }
    }

    // MARK: IBActions
    override func actionButtonTapped() {
        if let offer = self.offer{
            switch offer.getTransitType() {
            case .taxi:
                delegate?.offerCell(self, didBookOffer: offer as! HereSDKDemandTaxiRideOffer)
                break
            case .publicTransport:
                delegate?.offerCell(self, showRideOfferDetails: offer as! HereSDKDemandPublicTransportRideOffer)
                break
            }
        }
    }

    private func updateUI(for offer: HereSDKDemandRideOfferProtocol) {
        switch offer.getTransitType() {
        case .taxi:
            updateDriverOfferUI(for: offer as! HereSDKDemandTaxiRideOffer)
            break
        case .publicTransport:
            updatePTOfferUI(for: offer as! HereSDKDemandPublicTransportRideOffer)
            break
        }
    }

    private func updateDriverOfferUI(for offer : HereSDKDemandTaxiRideOffer){
        supplierName.text = offer.supplier.englishName
        if let _logoURL = offer.supplier.logoURL {
            supplierImage.setImage(url: URL(string: _logoURL))
        }
        if let estimatedPickupTimeSeconds = offer.estimatedPickupTimeSeconds?.doubleValue {
            offerETALabel.text = Date(timeIntervalSinceNow: estimatedPickupTimeSeconds).justTime
        } else {
            offerETALabel.text = "N/A"
        }
        if let priceRange = offer.estimatedPrice?.range{
            offerPriceLabel.text = "\(priceRange.lowerBound) - \(priceRange.upperBound)$"
        }
        bookButton.setTitle("Book", for: .normal)
    }

    private func updatePTOfferUI(for offer : HereSDKDemandPublicTransportRideOffer){
        supplierName.text = "Public Transport"
        supplierImage.setImage(url: URL(string: ""))
        offerETALabel.text =  "N/A"
        bookButton.setTitle("Details", for: .normal)
    }
}

