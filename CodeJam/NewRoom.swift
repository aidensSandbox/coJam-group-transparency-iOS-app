/*-------------------------

- BuzzIt -

created by FV iMAGINATION © 2015
All Rights reserved

-------------------------*/

import UIKit
import Parse


class NewRoom: UIViewController,
UITextFieldDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
UIAlertViewDelegate
{

    /* Views */
    @IBOutlet weak var nameTxt: UITextField!
    @IBOutlet weak var roomImage: UIImageView!
    
    
override func viewDidLoad() {
        super.viewDidLoad()

}

    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
  
    
// MARK: - CHANGE IMAGE BUTTON
@IBAction func changeImageButt(_ sender: AnyObject) {
    let alert = UIAlertView(title: APP_NAME,
    message: "Select source",
    delegate: self,
    cancelButtonTitle: "Cancel",
    otherButtonTitles: "Camera",
                       "Photo Library")
    alert.show()
    
}
// AlertView delegate
func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
    if alertView.buttonTitle(at: buttonIndex) == "Camera" {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)
        {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }

    
    } else if alertView.buttonTitle(at: buttonIndex) == "Photo Library" {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary)
        {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
}
// ImagePicker delegate
func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [AnyHashable: Any]!) {
        roomImage.image = image
    dismiss(animated: true, completion: nil)
}

    
    
    
    
// CREATE ROOM BUTTON -> SAVE IT TO PARSE DATABASE
@IBAction func createRoomButt(_ sender: AnyObject) {
    
    if nameTxt.text != "" {
        showHUD()
    
        let roomsClass = PFObject(className: ROOMS_CLASS_NAME)
        let currentUser = PFUser.current()
    
        // Save PFUser as a Pointer
        roomsClass[ROOMS_USER_POINTER] = currentUser
    
        // Save data
        roomsClass[ROOMS_NAME] = nameTxt.text!.uppercased()
    
        // Save Image (if exists)
        if roomImage.image != nil {
            let imageData = UIImageJPEGRepresentation(roomImage.image!, 0.8)
            let imageFile = PFFile(name:"image.jpg", data:imageData!)
            roomsClass[ROOMS_IMAGE] = imageFile
        }
    
        // Saving block
        roomsClass.saveInBackground { (success, error) -> Void in
            if error == nil {
                self.simpleAlert("Your new room has been created!")
                self.hideHUD()
                self.dismiss(animated: true, completion: nil)
            
            } else {
                self.simpleAlert("\(error!.localizedDescription)")
                self.hideHUD()
        }}
        
        
    // You must type a title
    } else {
        simpleAlert("You must type a title to your Room!")
    }
}
    

// MARK: - TEXT FIELD DELEGATE
func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    nameTxt.resignFirstResponder()

return true
}
    
    
    
@IBAction func closeButt(_ sender: AnyObject) {
    dismiss(animated: true, completion: nil)
}
    
    
    
    
    
    
override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
