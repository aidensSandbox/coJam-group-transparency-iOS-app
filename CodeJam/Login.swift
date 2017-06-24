/*-------------------------

- BuzzIt -

created by FV iMAGINATION © 2015
All Rights reserved

-------------------------*/


import UIKit
import Parse
import ParseFacebookUtilsV4



class Login: UIViewController,
UITextFieldDelegate,
UIAlertViewDelegate
{
    
    /* Views */
    @IBOutlet var containerScrollView: UIScrollView!
    @IBOutlet var usernameTxt: UITextField!
    @IBOutlet var passwordTxt: UITextField!
    @IBOutlet var logo: UIImageView!

    @IBOutlet weak var contView: UIView!
    
    
    
 

override func viewWillAppear(_ animated: Bool) {
    if PFUser.current() != nil {
        dismiss(animated: true, completion: nil)
    }
}
    
    
override func viewDidLoad() {
        super.viewDidLoad()
}
    
    
    
// MARK: - LOGIN BUTTON
@IBAction func loginButt(_ sender: AnyObject) {
        passwordTxt.resignFirstResponder()
        showHUD()
        
        PFUser.logInWithUsername(inBackground: usernameTxt.text!, password:passwordTxt.text!.lowercased()) {
            (user, error) -> Void in
            print(user)
            if user != nil { // Login successfull
                //self.dismiss(animated: true, completion: nil)
                /*let signupVC = self.storyboard?.instantiateViewController(withIdentifier: "CodeJam") as! CodeJam
                signupVC.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
                self.present(signupVC, animated: true, completion: nil)
                */
                
                let appDelegate = UIApplication.shared.delegate! as! AppDelegate
                
                let initialViewController = self.storyboard!.instantiateViewController(withIdentifier: "mainController")
                appDelegate.window?.rootViewController = initialViewController
                appDelegate.window?.makeKeyAndVisible()
                self.hideHUD()
                
            } else { // Login failed. Try again or SignUp
                let alert = UIAlertView(title: APP_NAME,
                    message: "\(error!.localizedDescription)",
                    delegate: self,
                    cancelButtonTitle: "Retry",
                    otherButtonTitles: "Sign Up")
                alert.show()
                
                self.hideHUD()
        }}
}
    
// AlertView delegate
func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if alertView.buttonTitle(at: buttonIndex) == "Sign Up" {
            //signupButt(self)
        }
        
        if alertView.buttonTitle(at: buttonIndex) == "Reset Password" {
            PFUser.requestPasswordResetForEmail(inBackground: "\(alertView.textField(at: 0)!.text!)")
            showNotifAlert()
        }
}
    
    
    
    
    
// MARK: - FACEBOOK SIGNUP BUTTON
@IBAction func facebookButt(_ sender: Any) {
    // Set permissions required from the Facebook user account
    let permissions = ["public_profile", "email"];
    showHUD()
        
    // Login PFUser using Facebook
    PFFacebookUtils.logInInBackground(withReadPermissions: permissions) { (user, error) in
        if user == nil {
            self.simpleAlert("Facebook login cancelled")
            self.hideHUD()
                
        } else if (user!.isNew) {
            print("NEW USER signed up and logged in through Facebook!");
            self.getFBUserData()
                
        } else {
            print("User logged in through Facebook!");
                
            self.dismiss(animated: true, completion: nil)
            self.hideHUD()
        }}
}
    
    
func getFBUserData() {
    let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, email, picture.type(large)"])
    let connection = FBSDKGraphRequestConnection()
    connection.add(graphRequest) { (connection, result, error) in
        if error == nil {
            let userData:[String:AnyObject] = result as! [String : AnyObject]
                
            // Get data
            let facebookID = userData["id"] as! String
            let name = userData["name"] as! String
            let email = userData["email"] as! String
                
            // Get avatar
            let currUser = PFUser.current()!
                
            let pictureURL = URL(string: "https://graph.facebook.com/\(facebookID)/picture?type=large")
            let urlRequest = URLRequest(url: pictureURL!)
            let session = URLSession.shared
            let dataTask = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
                if error == nil && data != nil {
                    let image = UIImage(data: data!)
                    let imageData = UIImageJPEGRepresentation(image!, 0.8)
                    let imageFile = PFFile(name:"avatar.jpg", data:imageData!)
                    currUser[USER_AVATAR] = imageFile
                    currUser.saveInBackground(block: { (succ, error) in
                        print("...AVATAR SAVED!")
                        self.hideHUD()
                        self.dismiss(animated: true, completion: nil)
                    })
                } else {
                    self.simpleAlert("\(error!.localizedDescription)")
                    self.hideHUD()
            }})
            dataTask.resume()
                
            
            // Make username out of full FB profile's name
            let nameArr = name.components(separatedBy: " ")
            var username = String()
            for word in nameArr { username.append(word.lowercased()) }
            
            // Update user data
            currUser.username = username
            currUser.email = email
            currUser.saveInBackground(block: { (succ, error) in
                if error == nil {
                    print("USER'S DATA UPDATED...")
            }})
                
                
        } else {
            self.simpleAlert("\(error!.localizedDescription)")
            self.hideHUD()
    }}
    connection.start()
}
    

    
    
    
// MARK: - SIGNUP BUTTON
/*@IBAction func signupButt(_ sender: AnyObject) {
    let signupVC = self.storyboard?.instantiateViewController(withIdentifier: "Signup") as! Signup
    signupVC.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
    present(signupVC, animated: true, completion: nil)
}*/
    
    
    
    
// MARK: - TEXTFIELD DELEGATES
func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == usernameTxt { passwordTxt.becomeFirstResponder()  }
    if textField == passwordTxt { passwordTxt.resignFirstResponder()  }
    
return true
}
    
    
    
    
// MARK: - TAP TO DISMISS KEYBOARD
@IBAction func tapToDismissKeyboard(_ sender: UITapGestureRecognizer) {
    dismissKeyboard()
}
func dismissKeyboard() {
    usernameTxt.resignFirstResponder()
    passwordTxt.resignFirstResponder()
}
    
    
    
    
// MARK: - RESET PASSWORD BUTTON
@IBAction func resetPasswButt(_ sender: AnyObject) {
        let alert = UIAlertView(title: APP_NAME,
            message: "Type your email address you used to register.",
            delegate: self,
            cancelButtonTitle: "Cancel",
            otherButtonTitles: "Reset Password")
        alert.alertViewStyle = UIAlertViewStyle.plainTextInput
        alert.show()
}
    
 
// NOTIFICATION ALERT FOR PASSWORD RESET
func showNotifAlert() {
    let alert = UIAlertView(title: APP_NAME,
    message: "You will receive an email shortly with a link to reset your password",
    delegate: nil,
    cancelButtonTitle: "OK")
    alert.show()
}
 
    
    
    
    
// MARK: - OPEN TERMS OF USE
@IBAction func touButt(_ sender: AnyObject) {
    let touVC = self.storyboard?.instantiateViewController(withIdentifier: "TermsOfUse") as! TermsOfUse
    
    if UIDevice.current.userInterfaceIdiom == .pad { // iPad
        let popOver = UIPopoverController(contentViewController: touVC)
        touVC.preferredContentSize = CGSize(width: view.frame.size.width-320, height: view.frame.size.height-450)
        popOver.present(from: CGRect(x: 400, y: 400, width: 0, height: 0), in: self.view, permittedArrowDirections: UIPopoverArrowDirection(), animated: true)
    } else { // iPhone
        present(touVC, animated: true, completion: nil)
    }
}
    

    
    
    
    
    
override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

