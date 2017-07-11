/*-------------------------

- BuzzIt -

created by FV iMAGINATION © 2015
All Rights reserved

-------------------------*/

import UIKit
import Parse
import GoogleMobileAds
import AudioToolbox


// MARK: - CUSTOM CELL
class MyRoomsCell: UITableViewCell {
    /* Views */
    @IBOutlet weak var rImage: UIImageView!
    @IBOutlet weak var rTitle: UILabel!
}






// MARK: - ACCOUNT CONTROLLER
class Account: UIViewController,
UITextFieldDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
UIAlertViewDelegate,
GADBannerViewDelegate
{

    /* Views */
    @IBOutlet weak var userView: UIView!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var usernameTxt: UITextField!
    
  
override func viewDidAppear(_ animated: Bool) {
    if PFUser.current() == nil {
        let loginVC = storyboard?.instantiateViewController(withIdentifier: "Login") as! Login
        navigationController?.pushViewController(loginVC, animated: true)
    } else {
        // Call query
        showUserDetails()
    }
}
    
override func viewDidLoad() {
        super.viewDidLoad()
    
    // Round views corners
    avatarImage.layer.cornerRadius = avatarImage.bounds.size.width/2
    userView.layer.cornerRadius = 8
    // Init ad banners
    //initAdMobBanner()
}

    


    
    
// MARK: - SHOW CURRENT USER DETAILS
func showUserDetails() {
    let CurrentUser = PFUser.current()!
    
    // Get avatar
    avatarImage.image = UIImage(named: "logo")
    let imageFile = CurrentUser[USER_AVATAR] as? PFFile
    imageFile?.getDataInBackground { (imageData, error) -> Void in
        if error == nil {
            if let imageData = imageData {
                self.avatarImage.image = UIImage(data:imageData)
    }}}
    
    // Get username
    usernameTxt.text = "\(CurrentUser[USER_USERNAME]!)"
}
    
    @IBAction func closeBtn(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
// MARK: - EDIT AVATAR BUTTON
@IBAction func editAvatarButt(_ sender: AnyObject) {
    let alert = UIAlertView(title: APP_NAME,
        message: "Select source",
        delegate: self,
        cancelButtonTitle: "Cancel",
        otherButtonTitles: "Camera", "Photo Library")
    alert.show()
}
// AlertView delegate
func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if alertView.buttonTitle(at: buttonIndex) == "Camera" {
            if UIImagePickerController.isSourceTypeAvailable(.camera)
            {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera;
                imagePicker.allowsEditing = true
                self.present(imagePicker, animated: true, completion: nil)
            }
            
            
        } else if alertView.buttonTitle(at: buttonIndex) == "Photo Library" {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
            {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary;
                imagePicker.allowsEditing = true
                self.present(imagePicker, animated: true, completion: nil)
            }
    }
    
}

// ImagePicker delegate
func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
        avatarImage.image = image
        
        // Save Avatar Image
        if avatarImage.image != nil {
            let imageData = UIImageJPEGRepresentation(avatarImage.image!, 0.5)
            let imageFile = PFFile(name:"avatar.jpg", data:imageData!)
            PFUser.current()![USER_AVATAR] = imageFile
        }
    }
    dismiss(animated: true, completion: nil)
}
    
    
    
    
// MARK: -  UPDATE PROFILE BUTTON
@IBAction func updateProfileButt(_ sender: AnyObject) {
    showHUD()
    
    let updatedUser = PFUser.current()!
    updatedUser[USER_USERNAME] = usernameTxt.text!
    
    // Saving block
    updatedUser.saveInBackground { (success, error) -> Void in
        if error == nil {
            self.simpleAlert("Your Profile has been updated!")
            self.hideHUD()
            self.usernameTxt.resignFirstResponder()
        } else {
            self.simpleAlert("\(error!.localizedDescription)")
            self.hideHUD()
            self.usernameTxt.resignFirstResponder()
    }}
}

    
  
// MARK: - TEXT FIELD DELEGATE
func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    usernameTxt.resignFirstResponder()

return true
}


override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
