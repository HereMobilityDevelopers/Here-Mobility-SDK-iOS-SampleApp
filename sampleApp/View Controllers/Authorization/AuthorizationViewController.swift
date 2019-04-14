//
// Copyright © 2018 HERE Global B.V. All rights reserved.
//

import UIKit

import HereSDKCoreKit

class AuthorizationViewController: UIViewController {

    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var verifyPhoneNumberTextField: UITextField!

    @IBOutlet weak var nextButton: UIButton!
    var shouldHideNextButton : Bool = false
    
    @IBOutlet weak var verificationView: UIView!
    var shouldHideVerificationView = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nextButton.isHidden = shouldHideNextButton
        verificationView.isHidden = shouldHideVerificationView
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    @IBAction func requestVerificationCodePressed(_ sender: Any) {
        guard let phoneNumber = phoneNumberTextField.text, phoneNumber.count > 0 else {
            UIAlertController.show("phone number text is empty", from: self)
            return
        }

        self.requestVerificationCodeFor(number: phoneNumber)
    }

    @IBAction func verifyPhoneNumberPressed(_ sender: Any) {
        guard let phoneNumber = phoneNumberTextField.text, let verificationCode = verifyPhoneNumberTextField.text, phoneNumber.count > 0, verificationCode.count > 0 else {
            UIAlertController.show("phone number or verification code missing", from: self)
            return
        }

        verifyVerificationCode(verificationCode: verificationCode, phoneNumber: phoneNumber)
    }

    // MARK: phone verification

    private func requestVerificationCodeFor(number: String){
        HereSDKManager.shared?.sendVerificationSMS(number, withHandler: { [weak self] (error) in
            if let error = error{
                UIAlertController.show(error.localizedDescription, from: self!)
            }
            else{
                UIAlertController.show("Verification code sent", from: self!)
            }
        })
    }

    private func verifyVerificationCode(verificationCode: String, phoneNumber: String){
        HereSDKManager.shared?.verifyUserPhoneNumber(phoneNumber, pinCode: verificationCode, withHandler: { [weak self] (error) in
            if (error != nil){
                UIAlertController.show((error?.localizedDescription)!, from: self!)
            }
            else{
                UIAlertController.show("Verification success", from: self!)
            }
        })
    }
}

extension AuthorizationViewController : UITextFieldDelegate  {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
