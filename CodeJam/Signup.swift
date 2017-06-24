/*-------------------------

- BuzzIt -

created by FV iMAGINATION © 2015
All Rights reserved

-------------------------*/

import UIKit
import Parse

class Signup: UIViewController,
    UITextFieldDelegate
{
    
    /* Views */
    @IBOutlet var containerScrollView: UIScrollView!
    @IBOutlet var usernameTxt: UITextField!
    @IBOutlet var passwordTxt: UITextField!
    @IBOutlet weak var emailTxt: UITextField!
    
    @IBOutlet weak var contView: UIView!
    
    
   
  
override var prefersStatusBarHidden: Bool {
    return true
}

override func viewDidLoad() {
        super.viewDidLoad()
    
    contView.frame.size.width = view.frame.size.width
    
    
    containerScrollView.contentSize = CGSize(width:containerScrollView.frame.size.width, height: 500)
        
    navigationController?.isNavigationBarHidden = true
}
    
    
    @IBAction func cancel(_ sender: UIButton) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
// TAP TO DISMISS KEYBOARD
@IBAction func tapToDismissKeyboard(_ sender: UITapGestureRecognizer) {
    dismissKeyboard()
}
func dismissKeyboard() {
    usernameTxt.resignFirstResponder()
    passwordTxt.resignFirstResponder()
    emailTxt.resignFirstResponder()
}
    
    
// MARK: - SIGNUP BUTTON
@IBAction func signupButt(_ sender: AnyObject) {
    dismissKeyboard()
    showHUD()
        
    let userForSignUp = PFUser()
    userForSignUp.username = usernameTxt.text!.lowercased()
    userForSignUp.password = passwordTxt.text
    userForSignUp.email = emailTxt.text
    
    userForSignUp.signUpInBackground { (succeeded, error) -> Void in
        if error == nil { // Successful Signup
            self.dismiss(animated: true, completion: nil)
            self.hideHUD()
                
        } else { // No signup, something went wrong
            self.simpleAlert("\(error!.localizedDescription)")
            self.hideHUD()
    }}
}
    
    
    
// MARK: -  TEXTFIELD DELEGATE
func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == usernameTxt {   passwordTxt.becomeFirstResponder()  }
    if textField == passwordTxt {   emailTxt.becomeFirstResponder()  }
    if textField == emailTxt {   emailTxt.resignFirstResponder()  }
    
return true
}
    
    
    
override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

