/*-------------------------

- BuzzIt -

created by FV iMAGINATION © 2015
All Rights reserved

-------------------------*/


import UIKit

class Settings: UIViewController {
    
    /* Views */
    @IBOutlet weak var tenMessSwitch: UISwitch!
    
    

    
    
override func viewDidLoad() {
        super.viewDidLoad()

    // Set the message limit swicth
    if tenMessLimit { tenMessSwitch.setOn(true, animated: false)
    } else { tenMessSwitch.setOn(false, animated: false) }

}

 
// MARK: - TELL A FRIEND BUTTON
@IBAction func tellAfriendButt(_ sender: AnyObject) {
    let messageStr = "Hi there, join \(APP_NAME) and let's chat together! \(APPSTORE_LINK)"
    let img = UIImage(named: "logo")
    
    let shareItems = [messageStr, img!] as [Any]
    
    let activityViewController:UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
    activityViewController.excludedActivityTypes = [UIActivityType.print, UIActivityType.copyToPasteboard, UIActivityType.addToReadingList, UIActivityType.postToVimeo]
    
    if UIDevice.current.userInterfaceIdiom == .pad {
        // iPad
        let popOver = UIPopoverController(contentViewController: activityViewController)
        popOver.present(from: CGRect.zero, in: self.view, permittedArrowDirections: UIPopoverArrowDirection(), animated: true)
    } else {
        // iPhone
        present(activityViewController, animated: true, completion: nil)
    }
}
    
    
    
// MARK: - RATE THE APP BUTTON
@IBAction func rateButt(_ sender: AnyObject) {
    let reviewURL = URL(string: "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=\(APP_ID)")
    UIApplication.shared.openURL(reviewURL!)
}
    
    
    
// MARK: - SWITCH CHANGES
@IBAction func messSwitchChanged(_ sender: AnyObject) {
    let sw = sender as! UISwitch
    
    if sw.isOn { tenMessLimit = true
    } else { tenMessLimit = false }
    
    // Save the state of the Switch
    UserDefaults.standard.set(tenMessLimit, forKey: "tenMessLimit")
}
    
    
    
// READ TERMS BUTTON
@IBAction func readTOUbutt(_ sender: AnyObject) {
    let touVC = self.storyboard?.instantiateViewController(withIdentifier: "TermsOfUse") as! TermsOfUse
    present(touVC, animated: true, completion: nil)
}
 
    
    
// MARK: - DISMISS BUTTON
@IBAction func dismissButt(_ sender: AnyObject) {
    dismiss(animated: true, completion: nil)
}
    
    
    
    
    
override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
