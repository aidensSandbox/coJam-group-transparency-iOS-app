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
UITableViewDelegate,
UITableViewDataSource,
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
    
    @IBOutlet weak var myRoomsTableView: UITableView!
    
    //Ad banners properties
    var adMobBannerView = GADBannerView()
    
    
    
    /* Variables */
    var roomsArray = [PFObject]()
    
    
  
 
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
    
    // Reset app's badge icon to 0
    UIApplication.shared.applicationIconBadgeNumber = 0
    
    
    // Round views corners
    avatarImage.layer.cornerRadius = avatarImage.bounds.size.width/2
    userView.layer.cornerRadius = 8
    myRoomsTableView.layer.cornerRadius = 8
    myRoomsTableView.layer.borderColor = UIColor.white.cgColor
    myRoomsTableView.layer.borderWidth = 1.5
    
    
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
    
    
    // Call a query for your rooms
    queryMyRooms()
}
    
    
    
    
// MARK: - QUERY THE ROOMS YOU'VE CREATED (IF ANY)
func queryMyRooms() {
    roomsArray.removeAll()
    showHUD()
    
    let query = PFQuery(className: ROOMS_CLASS_NAME)
    query.whereKey(ROOMS_USER_POINTER, equalTo: PFUser.current()!)
    query.findObjectsInBackground { (objects, error)-> Void in
        if error == nil {
            self.roomsArray = objects!
            self.myRoomsTableView.reloadData()
            self.hideHUD()
        } else {
            self.simpleAlert("\(error!.localizedDescription)")
            self.hideHUD()
    }}
    
}
    
    
    
    
// MARK: - TABLEVIEW DELEGATES
func numberOfSections(in tableView: UITableView) -> Int {
    return 1
}
    
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return roomsArray.count
}
    
func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "MyRoomsCell", for: indexPath) as! MyRoomsCell
    
    var myRoomsClass = PFObject(className: ROOMS_CLASS_NAME)
    myRoomsClass = roomsArray[indexPath.row]
    
    // Get data
    cell.rTitle.text = "\(myRoomsClass[ROOMS_NAME]!)"
    
    // Get image
    let imageFile = myRoomsClass[ROOMS_IMAGE] as? PFFile
    imageFile?.getDataInBackground { (imageData, error) -> Void in
        if error == nil {
            if let imageData = imageData {
                cell.rImage.image = UIImage(data:imageData)
    }}}
    cell.rImage.layer.cornerRadius = 5
    
    
return cell
}
func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 60
}


// MARK: -  CELL HAS BEEN TAPPED -> GO TO THE SELECTED CHAT ROOM
func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var myRoomObj = PFObject(className: ROOMS_CLASS_NAME)
    myRoomObj = roomsArray[indexPath.row]
    
    let cVC = storyboard?.instantiateViewController(withIdentifier: "Chats") as! Chats
    cVC.roomObj = myRoomObj
    navigationController?.pushViewController(cVC, animated: true)
}

    

// MARK: - DELETE ROW BY SWIPING THE CELL LEFT
func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
}
func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
        
        self.showHUD()
        var roomsClass = PFObject(className: ROOMS_CLASS_NAME)
        roomsClass = roomsArray[(indexPath as NSIndexPath).row]
        
        // Deleting block
        roomsClass.deleteInBackground {(success, error) -> Void in
            if error == nil {
                self.hideHUD()
                // Remove the swiped cell
                self.roomsArray.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            } else {
                self.simpleAlert("\(error!.localizedDescription)")
                self.hideHUD()
        }}
    }
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

    
    
  
// MARK: - MAKE A NEW ROOM BUTTON
@IBAction func newRoomButt(_ sender: AnyObject) {
    let nrVC = self.storyboard?.instantiateViewController(withIdentifier: "NewRoom") as! NewRoom
    nrVC.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
    present(nrVC, animated: true, completion: nil)
}
  
    

// MARK: - SETTINGS BUTTON
@IBAction func settingsButt(_ sender: AnyObject) {
    let settVC = self.storyboard?.instantiateViewController(withIdentifier: "Settings") as! Settings
    
    if UIDevice.current.userInterfaceIdiom == .pad { // iPad
        let popOver = UIPopoverController(contentViewController: settVC)
        settVC.preferredContentSize = CGSize(width: view.frame.size.width-320, height: view.frame.size.height-450)
        popOver.present(from: CGRect(x: 400, y: 400, width: 0, height: 0), in: self.view, permittedArrowDirections: UIPopoverArrowDirection(), animated: true)
    } else { // iPhone
        present(settVC, animated: true, completion: nil)
    }
    

}
    
    
    
    
    
// MARK: - LOGOUT BUTTON
@IBAction func logoutButt(_ sender: AnyObject) {
    let alert = UIAlertController(title: APP_NAME,
        message: "Are you sure you want to logout?",
        preferredStyle: .alert)
    
    let ok = UIAlertAction(title: "Logout", style: .default, handler: { (action) -> Void in
        self.showHUD()
        
        PFUser.logOutInBackground(block: { (error) in
            if error == nil {
                // Show the Login screen
                let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "Login") as! Login
                self.present(loginVC, animated: true, completion: nil)
            }
            self.hideHUD()
        })
    })
    
    
    let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in })
    
    alert.addAction(ok); alert.addAction(cancel)
    present(alert, animated: true, completion: nil)
}
    
    
    
    
    
    
    
    
// MARK: - AdMob BANNER METHODS
func initAdMobBanner() {
        adMobBannerView.adSize =  GADAdSizeFromCGSize(CGSize(width: 320, height: 50))
        adMobBannerView.frame = CGRect(x: 0, y: self.view.frame.size.height, width: 320, height: 50)
        adMobBannerView.adUnitID = ADMOB_UNIT_ID
        adMobBannerView.rootViewController = self
        adMobBannerView.delegate = self
        view.addSubview(adMobBannerView)
        
        let request = GADRequest()
        adMobBannerView.load(request)
    }
    
    
    // Hide the banner
    func hideBanner(_ banner: UIView) {
        UIView.beginAnimations("hideBanner", context: nil)
        // Hide the banner moving it below the bottom of the screen
        banner.frame = CGRect(x: 0, y: self.view.frame.size.height, width: banner.frame.size.width, height: banner.frame.size.height)
        UIView.commitAnimations()
        banner.isHidden = true
        
    }
    
    // Show the banner
    func showBanner(_ banner: UIView) {
        UIView.beginAnimations("showBanner", context: nil)
        
        // Move the banner on the bottom of the screen
        banner.frame = CGRect(x: view.frame.size.width/2 - banner.frame.size.width/2,
                              y: view.frame.size.height - banner.frame.size.height - 48,
                              width: banner.frame.size.width,
                              height: banner.frame.size.height);
        UIView.commitAnimations()
        banner.isHidden = false
        
    }
    
    // AdMob banner available
    func adViewDidReceiveAd(_ view: GADBannerView) {
        print("AdMob loaded!")
        showBanner(adMobBannerView)
    }
    
    // NO AdMob banner available
    func adView(_ view: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print("AdMob Can't load ads right now, they'll be available later \n\(error)")
        hideBanner(adMobBannerView)
    }
    
    
    
    
    
    
    
override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
