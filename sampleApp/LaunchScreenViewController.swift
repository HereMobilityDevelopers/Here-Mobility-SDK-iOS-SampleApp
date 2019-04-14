//
// Copyright © 2018 HERE Global B.V. All rights reserved.
//

import UIKit

import HereSDKCoreKit

class LaunchScreenViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        generateAppCredentials()
    }

    private func generateHash(appKey: String, creationSec:Int32, key: String) -> String {
        return HMACGenerator.hmacSHA384(from: appKey, creationTimeSec: creationSec, withKey: key)
    }

    private func generateAppCredentials(creationTime : Date = Date()) {
        guard let infoDictionary = Bundle.main.infoDictionary,
            let appKey = infoDictionary["HereMobilitySDKAppId"] as? String,
            let appSecret = infoDictionary["HereMobilitySDKAppSecret"] as? String else { return }

        let hashString = generateHash(appKey: appKey, creationSec: Int32(creationTime.timeIntervalSince1970), key: appSecret)
        HereSDKManager.shared?.authenticateApplication(HereSDKApplicationAuthenticationInfo(creationTime: creationTime, verificationHash: hashString), withHandler:{ [weak self] (error) in
            if let error = error{
                UIAlertController.show("Login fail \(error.localizedDescription)", from: self)
            }
            self?.performSegue(withIdentifier: String(describing: GetRidesViewController.self), sender: self)
        })
    }
}
