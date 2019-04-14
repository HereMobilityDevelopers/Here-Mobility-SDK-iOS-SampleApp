//
// Copyright © 2018 HERE Global B.V. All rights reserved.
//

import UIKit
import HereSDKDemandKit

class RideStatusViewController: UIViewController {

    static let segueId = "showRideStatusSegue"
    var ride: HereSDKDemandRide?

    // MARK: - IBOutlets

    @IBOutlet private var callButton: UIButton!
    @IBOutlet private var rideView: UIView!
    @IBOutlet private var supplierImage: UIImageView!
    @IBOutlet private var supplierName: UILabel!
    @IBOutlet private var tripETA: UILabel!
    @IBOutlet private var tripETATitleButton: UIButton!
    @IBOutlet private var tripPrice: UILabel!
    @IBOutlet private var tripPriceTitleButton: UIButton!
    @IBOutlet private var driverNameLabel: UILabel!
    @IBOutlet private var carDetailsLabel: UILabel!
    @IBOutlet private var driverImage: UIImageView!

    @IBOutlet private var rideProgressContainerView: UIView!
    @IBOutlet private var rideCanceledView: UIView!
    @IBOutlet private var rideCanceledLabel: UILabel!

    @IBOutlet weak var actionButton: UIButton!

    // MARK: - Private properties

    private var currentRideId: String? {
        return ride?.rideId
    }

    private var phoneNumber: String?
    private var lastDropOffTime: String?

    private let cancelRideString = "CANCEL RIDE"
    private let finishRideString = "FINISH RIDE"

    @IBOutlet weak var statusTableView: UITableView!
    private var statussesArray : [HereSDKDemandRideStatusLog] = []


    override func viewDidLoad() {
        super.viewDidLoad()

        setupDesignStyle()
        rideView.setRoundedBorder()

        navigationItem.hidesBackButton = true

        guard let ride = ride else { return }

        update(for: ride)

        self.statusTableView.delegate = self
        self.statusTableView.dataSource = self

        tripETA.text = "N/A"
        tripPrice.text = "N/A"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Utility functions

    private func updatePhoneNumber(for ride: HereSDKDemandRide) {
        phoneNumber = ride.driver?.phoneNumber

        if (phoneNumber ?? "").isEmpty {
            phoneNumber = ride.supplier.phoneNumber
        }
    }

    private func update(for ride: HereSDKDemandRide) {
        self.ride = ride
        updatePhoneNumber(for: ride)
        updateUI(for: ride)
        updateFinishedStatus(for: ride)
    }

    private func carDetails(for ride: HereSDKDemandRide) -> String {
        let vehicle = ride.vehicle
        var result = vehicle?.licensePlateNumber ?? ""
        if !result.isEmpty {
            result += ", "
        }
        if let manufacturer = vehicle?.manufacturer, !manufacturer.isEmpty {
            result += "\(manufacturer) "
        }
        if let model = vehicle?.model, !model.isEmpty {
            result += model
        }

        return result
    }

    internal func updateUI(for ride: HereSDKDemandRide) {

        supplierName.text = ride.supplier.englishName
        if let _logoURL = ride.supplier.logoURL {
            supplierImage.setImage(url: URL(string: _logoURL))
        }

        // example of generated price range
        if let pricesRange = ride.bookingEstimatedPrice?.range {
            tripPrice.text = "\(pricesRange.lowerBound) - \(pricesRange.upperBound) $"
        }

        if let driver = ride.driver {
            driverNameLabel.text = driver.name.isEmpty ? "Your driver" : driver.name
            driverImage.setImage(url: URL(string: (driver.photoURL ?? "")))
        }

        carDetailsLabel.text = carDetails(for: ride)
    }

    internal func updateUI(for demandLocation: HereSDKDemandRideLocation){
        if let lastupdateStatus = self.statussesArray.first?.currentStatus.rawValue {
            if (lastupdateStatus >= 4 && lastupdateStatus <= 7){ // driver assigned <-> driver at pickup point
                if let pickupTimeSec = demandLocation.estimatedPickupTimeSeconds?.doubleValue {
                    tripETA.text = Date.init(timeIntervalSinceNow: pickupTimeSec).justTime
                }
            }
            if (lastupdateStatus == 8){ // driver
                if let dropOffTimeSec = demandLocation.estimatedDropOffTimeSeconds?.doubleValue {
                    tripETA.text = Date.init(timeIntervalSinceNow: dropOffTimeSec).justTime
                }
            }
        }
    }

    private func updateFinishedStatus(for ride: HereSDKDemandRide) {
        switch ride.statusLog.currentStatus {
        case .logRecordRejected, .logRecordCancelled, .logRecordDriverAtDropoff, .logRecordCompleted:
            finishRide()
        default:
            break
        }
    }

    private func finishRide() {
        dismiss()
    }

    private func setupDesignStyle() {
        supplierName.font = .plainTextBigLeft
        tripPrice.font = .plainTextMediumCenter
        tripETA.font = .plainTextMediumCenter
        driverNameLabel.font = .plainTextMediumLeft
        carDetailsLabel.font = .plainTextSmallLeft
        tripPriceTitleButton.titleLabel?.font = .plainTextSmallCenterGray

        supplierName.textColor = .charcoalGrey
        tripPrice.textColor = .charcoalGrey
        tripETA.textColor = .charcoalGrey
        driverNameLabel.textColor = .charcoalGrey
        carDetailsLabel.textColor = .charcoalGrey
        tripPriceTitleButton.setTitleColor(.charcoalGrey50, for: .normal)
    }

    func updateActionButton(status : HereSDKDemandRideStatusUpdateStatus)
    {
        switch status {
        case .logRecordUnknown, .logRecordProcessing, .logRecordAccepted, .logRecordDriverAssigned, .logRecordDriverEnRoute, .logRecordDriverAtPickup:
            // there's an cancelation policy for ride?.cancellationPolicy which can be allowed or disallowed. (cancelation can be s
            self.actionButton.setTitle(cancelRideString, for: .normal)
        case .logRecordRejected, .logRecordCompleted, .logRecordDriverAtDropoff, .logRecordPassengerOnBoard, .logRecordCancelled:
            self.actionButton.setTitle(finishRideString, for: .normal)
        case .logRecordFailure:
            break
        }
    }

    @IBAction func actionButtonTapped(_ sender: UIButton) {
        if let actionButtonText = sender.titleLabel?.text, actionButtonText == cancelRideString{
            self.cancelRide()
        }
        else{
            self.finishRide()
        }
    }

    internal func cancelRide() {
        guard let ride = ride else { return }
        let cancelRequest = HereSDKDemandCancelRideRequest.cancelRide(withRideId: ride.rideId, cancelReason: "")
        HereSDKDemandManager.shared.cancelRide(with: cancelRequest) { [weak self] (info, error) in
            if error != nil {

            } else {
                if let rideID = self?.ride?.rideId{
                    print ("canceled ride ID  \(rideID)")
                }

                if let info = info {
                    self?.showDismissableAlert(title: "Cancellation info", message: info.cancellationInfo) {
                        self?.dismiss()
                    }
                } else {
                    self?.dismiss()
                }
            }
        }
    }

    private func dismiss() {
        navigationController?.popToRootViewController(animated: true)
    }

    internal func updateStatusesArray(statusLog : HereSDKDemandRideStatusLog){
        if (statussesArray.first == nil){
            statussesArray.append(statusLog)
            animateInsertStatusTableView()
        }
        else if (statussesArray.first?.currentStatus.rawValue != statusLog.currentStatus.rawValue){
            statussesArray.insert(statusLog, at: 0)
            animateInsertStatusTableView()
            animateUpdateStatusTableView()
        }
    }

    private func animateInsertStatusTableView(){
        self.statusTableView.beginUpdates()
        let insertIndexPath = IndexPath(item: 0, section: 0)
        self.statusTableView.insertRows(at: [insertIndexPath], with: .automatic)
        self.statusTableView.endUpdates()
    }

    private func animateUpdateStatusTableView(){
        self.statusTableView.beginUpdates()
        let reloadIndexPath = IndexPath(item: 1, section: 0)
        self.statusTableView.reloadRows(at: [reloadIndexPath], with: .automatic)
        self.statusTableView.endUpdates()
    }
}

extension RideStatusViewController: UITableViewDataSource, UITableViewDelegate
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return statussesArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard statussesArray.count > indexPath.row else { return UITableViewCell() }

        let cell = tableView.dequeueReusableCell(withIdentifier: "statusRIdeTableViewCell" , for: indexPath)
        let status = statussesArray[indexPath.row]
        cell.textLabel?.text = "\(HereSDKDemandRideStatusUpdate.recordStatus(toString: status.currentStatus))"
        cell.detailTextLabel?.text = "\(status.lastUpdateTime.description)"
        cell.textLabel?.textColor = indexPath.row == 0 ? UIColor.black : UIColor.gray
        cell.detailTextLabel?.textColor = indexPath.row == 0 ? UIColor.black : UIColor.gray
        return cell
    }
}



