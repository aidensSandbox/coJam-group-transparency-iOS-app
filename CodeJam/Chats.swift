/*-------------------------

- BuzzIt -

created by FV iMAGINATION © 2015
All Rights reserved

-------------------------*/


import UIKit
import Parse
import AVFoundation
import MessageUI
import GoogleMobileAds
import AudioToolbox

var progress = 0


// MARK: - CUSTOM CHAT CELL
class ChatCell: UITableViewCell {
    /* Views */
    @IBOutlet weak var userAvatar: UIImageView!
    @IBOutlet weak var playOutlet: UIButton!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
}








// MARK: - CHATS CONTROLLER
class Chats: UIViewController,
UITableViewDelegate,
UITableViewDataSource,
AVAudioPlayerDelegate,
UIAlertViewDelegate,
MFMailComposeViewControllerDelegate,
GADBannerViewDelegate
{

    /* Views */
    @IBOutlet weak var chatsTableView: UITableView!
    
    var circularProgress: KYCircularProgress!

    // Ad banners properties
    var adMobBannerView = GADBannerView()
    
    
    
    
    /* Variables */
    var roomObj = PFObject(className: ROOMS_CLASS_NAME)
    var chatsArray = [PFObject]()

    var audioPlayer:AVAudioPlayer?
    var messTimer = Timer()
    var buttTAG = 0
    var refreshTimer = Timer()
    var messageIsPlaying = false
    
    

    
    
    
override func viewWillAppear(_ animated: Bool) {

    // Reset app's badge icon to 0
    UIApplication.shared.applicationIconBadgeNumber = 0
    
    
    // Check id audio URL String is nil
    print("audio Str: \(audioURLStr)")
    
    messageIsPlaying = false
    
    // Send an audio message or load chat
    if audioURLStr != "" { sendAudioMessage(audioURLStr)
    } else { loadChats()  }
    
}

// Stop the Refresh Timer
override func viewDidDisappear(_ animated: Bool) {
    refreshTimer.invalidate()
}
    
override func viewDidLoad() {
        super.viewDidLoad()

    // Set title
    self.title = "\(roomObj[ROOMS_NAME]!)"
    

    // Initialize a Record BarButton Item
    let butt = UIButton(type: UIButtonType.custom)
    butt.adjustsImageWhenHighlighted = false
    butt.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
    butt.setBackgroundImage(UIImage(named: "miniRecButt"), for: UIControlState())
    butt.addTarget(self, action: #selector(recButt(_:)), for: UIControlEvents.touchUpInside)
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: butt)
    
    // Initialize a BACK BarButton Item
    let backButt = UIButton(type: UIButtonType.custom)
    backButt.adjustsImageWhenHighlighted = false
    backButt.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
    backButt.setBackgroundImage(UIImage(named: "backButt"), for: UIControlState())
    backButt.addTarget(self, action: #selector(backButton), for: UIControlEvents.touchUpInside)
    navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButt)
    
    
    // Init ad banners
    initAdMobBanner()
   
}

 
// MARK: - BACK BUTTON
func backButton() {
    if audioPlayer?.isPlaying == true {
        audioPlayer?.stop()
    }
    _ = navigationController?.popViewController(animated: true)
}

    
    
// MARK: - LOAD CHATS OF THIS ROOM
func loadChats() {
    showHUD()
    chatsArray.removeAll()
    
    let query = PFQuery(className: CHAT_CLASS_NAME)
    query.whereKey(CHAT_ROOM_POINTER, equalTo: roomObj)
    query.whereKey(CHAT_IS_REPORTED, equalTo: false)
    query.order(byAscending: "createdAt")
    
    // Set a limit of 10 to the query (if switch = ON in the Settings screen)
    if tenMessLimit { query.limit = 10 }
    
    query.findObjectsInBackground { (objects, error)-> Void in
        if error == nil {
            self.chatsArray = objects!
            self.chatsTableView.reloadData()
            self.hideHUD()
            
            // Refresh the Chat Room
            self.refreshTimer.invalidate()
            self.refreshTimer = Timer.scheduledTimer(timeInterval: REFRESH_TIME, target: self, selector: #selector(self.loadChats), userInfo: nil, repeats: true)
            
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
    return chatsArray.count
}
    
func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatCell
    
    var chatsClass = PFObject(className: CHAT_CLASS_NAME)
    chatsClass = chatsArray[(indexPath as NSIndexPath).row]
    
    // Get userPointer
    let userPointer = chatsClass[CHAT_USER_POINTER] as! PFUser
    userPointer.fetchIfNeededInBackground { (user, error) in
        
        // Get user avatar
        cell.userAvatar.layer.cornerRadius = cell.userAvatar.bounds.size.width/2
        let imageFile = userPointer[USER_AVATAR] as? PFFile
        imageFile?.getDataInBackground { (imageData, error) -> Void in
            if error == nil {
                if let imageData = imageData {
                    cell.userAvatar.image = UIImage(data:imageData)
        }}}
    
        // Get username
        cell.usernameLabel.text = "\(userPointer[USER_USERNAME]!)"
        
    
        // Get Date
        let currDate = Date()
        let createdDate = chatsClass.createdAt!
        cell.dateLabel.text = self.timeAgoSinceDate(createdDate, currentDate: currDate, numericDates: true)
        
    
        // Assign tags to buttons
        cell.playOutlet.tag = indexPath.row
    
    }// end userpointer
    
    
return cell
}
    
func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 65
}




    
// MARK: - EDIT ACTIONS ON SWIPE ON A CELL
func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
}
func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    
    // Get message's data (based on the cell you've swiped)
    var chatsClass = PFObject(className: CHAT_CLASS_NAME)
    chatsClass = self.chatsArray[indexPath.row]
    let userPointer = chatsClass[CHAT_USER_POINTER] as! PFUser
    
    
    // REPORT INAPPROPRIATE MESSAGE
    let reportAction = UITableViewRowAction(style: .default, title: "Report" , handler: { (action:UITableViewRowAction, indexPath:IndexPath) -> Void in
        
        let alert = UIAlertController(title: APP_NAME,
            message: "Report message",
            preferredStyle: .alert)
        
        
        // REPORTE MESSAGE
        let ok = UIAlertAction(title: "Message is inappropriate", style: .default, handler: { (action) -> Void in
            self.showHUD()
            chatsClass[CHAT_IS_REPORTED] = true
            chatsClass.saveInBackground(block: { (succ, error) in
                if error == nil {
                    self.hideHUD()
                    self.simpleAlert("Thanks for reporting this message. We'll check it out within 24h")
                    
                    // Update the tableView
                    self.chatsArray.remove(at: indexPath.row)
                    self.chatsTableView.deleteRows(at: [indexPath], with: .fade)
                } else {
                    self.simpleAlert("\(error!.localizedDescription)")
                    self.hideHUD()
            }})
        })
        
        
        // Cancel button
        let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: { (action) -> Void in })
        
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    })
    
    
    
    
    // DELETE SELECTED MESSAGE
    let deleteAction = UITableViewRowAction(style: .default, title: "Delete" , handler: { (action:UITableViewRowAction, indexPath:IndexPath) -> Void in

        self.showHUD()
        if userPointer.username == PFUser.current()!.username {
            chatsClass.deleteInBackground {(success, error) -> Void in
                if error == nil {
                    self.hideHUD()
                    self.chatsArray.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                
                } else {
                    self.simpleAlert("\(error!.localizedDescription)")
                    self.hideHUD()
            }}
    
            
        // YOU CAN DELETE ONLY YOUR OWN MESSAGES!
        } else {
            self.simpleAlert("You can delete only your own messages!")
            self.hideHUD()
        }
    })
    
    
    // Set colors of the actions
    deleteAction.backgroundColor = UIColor.red
    reportAction.backgroundColor = UIColor.darkGray
    
    
return [reportAction, deleteAction]
}


    
    

// MARK: - PLAY MESSAGE BUTTON
@IBAction func playButt(_ sender: AnyObject) {
    if !messageIsPlaying {
    let button = sender as! UIButton
    buttTAG = button.tag
    button.setBackgroundImage(UIImage(named: "playingIcon"), for: UIControlState())

    // Setup circular progress
    circularProgress = KYCircularProgress(frame: CGRect(x: 0, y: 0, width: button.frame.size.width, height: button.frame.size.height))
    circularProgress.colors = [0xa4d22c, 0xa4d22c, 0xa4d22c, 0xa4d22c]
    circularProgress.lineWidth = 3
    circularProgress.progressChangedClosure({ (progress: Double, circularView: KYCircularProgress) in })
    button.addSubview(circularProgress)
    button.sendSubview(toBack: circularProgress)
    
    var chatsClass = PFObject(className: CHAT_CLASS_NAME)
    chatsClass = chatsArray[button.tag]
    
    let audioFile = chatsClass[CHAT_MESSAGE] as? PFFile
    audioFile?.getDataInBackground { (audioData, error) -> Void in
        if error == nil {
            self.audioPlayer = try? AVAudioPlayer(data: audioData!)
            self.audioPlayer?.delegate = self
            print("message duration: \(self.audioPlayer!.duration)")
            self.audioPlayer?.play()
            self.messageIsPlaying = true
            
            // Start timer (shows the progress of the message while playing)
            progress = 0
            let calcTime = self.audioPlayer!.duration * 0.004
            self.messTimer = Timer.scheduledTimer(timeInterval: calcTime, target: self, selector: #selector(self.updateTimer), userInfo: nil, repeats: true)
            
    }}
        
    } // end IF to prevent tapping on a message multiple times
    
}

    
    
    
// MARK: - UPDATE TIMER
func updateTimer() {
    progress = progress + 1
    let normalizedProgress = Double(progress) / 255.0
    circularProgress.progress = normalizedProgress
    
    // Timer ends
    if normalizedProgress >= 1.01 {  messTimer.invalidate()  }
}
    
func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    audioPlayer = nil
    messTimer.invalidate()
    circularProgress.removeFromSuperview()
    messageIsPlaying = false
    
    for i in 0..<chatsArray.count {
        let indexP = IndexPath(row: i, section: 0)
        let cell = chatsTableView.cellForRow(at: indexP) as! ChatCell
        cell.playOutlet.setBackgroundImage(UIImage(named: "playButt"), for: UIControlState())
    }
}
    
    
    
// MARK: - RECORD BUTTON
func recButt(_ sender:UIButton) {
    if PFUser.current() != nil {
        let recVC = self.storyboard?.instantiateViewController(withIdentifier: "Record") as! Record
        recVC.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        present(recVC, animated: true, completion: nil)

    } else {
        let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "Login") as! Login
        present(loginVC, animated: true, completion: nil)
    }
}
    
    
  
// MARK: - SEND AUDIO MESSAGE
func sendAudioMessage(_ urlStr: String) {
    showHUD()
    
    let chatsClass = PFObject(className: CHAT_CLASS_NAME)
    let currentUser = PFUser.current()
        
    // Save PFUser as a Pointer
    chatsClass[CHAT_USER_POINTER] = currentUser
        
    // Save data
    chatsClass[CHAT_ROOM_POINTER] = roomObj
    chatsClass[CHAT_ROOM_NAME] = "\(roomObj[ROOMS_NAME]!)"
    chatsClass[CHAT_IS_REPORTED] = false
    
    let audioURL = URL(string: audioURLStr)
    let audioData = try! Data(contentsOf: audioURL!)
    print("AUDIO DATA 2: \(audioData.count)")
    let audioFile = PFFile(name: "message.wav", data: audioData)
    chatsClass[CHAT_MESSAGE] = audioFile
    
    // Saving block
    chatsClass.saveInBackground { (success, error) -> Void in
        if error == nil {
            audioURLStr = ""
            self.hideHUD()
            
            // Update the tableView
            self.chatsArray.insert(chatsClass, at: 0)
            self.chatsTableView.reloadData()
            
            
            
            // Query room to get its owner
            let query = PFQuery(className: ROOMS_CLASS_NAME)
            query.whereKey(ROOMS_NAME, equalTo: "\(self.roomObj[ROOMS_NAME]!)")
            query.findObjectsInBackground { (objects, error)-> Void in
                if error == nil {
                    var rObj = PFObject(className: ROOMS_CLASS_NAME)
                    rObj = objects![0]
                    
                    
                    // Send Push Notification
                    let userPointer = rObj[ROOMS_USER_POINTER] as! PFUser
                    userPointer.fetchIfNeededInBackground(block: { (user, error) in
                     
                        let pushStr = "\(PFUser.current()![USER_USERNAME]!) sent a message on your Room: \(self.roomObj[ROOMS_NAME]!)"
                    
                        let data = [
                            "badge" : "Increment",
                            "alert" : pushStr,
                            "sound" : "bingbong.aiff"
                        ]
                        let request = [
                            "someKey" : userPointer.objectId!,
                            "data" : data
                        ] as [String : Any]
                        PFCloud.callFunction(inBackground: "push", withParameters: request as [String : Any], block: { (results, error) in
                            if error == nil {
                                print ("\nPUSH SENT TO: \(userPointer[USER_USERNAME]!)\nMESSAGE: \(pushStr)\n")
                            } else {
                                print ("\(error!.localizedDescription)")
                        }})
                    
                    })// end userPointer

                    
                // error in query
                } else {
                    self.simpleAlert("\(error!.localizedDescription)")
                    self.hideHUD()
            }}

            
            
        // error on saving
        } else {
            self.simpleAlert("\(error!.localizedDescription)")
            self.hideHUD()
    }}
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
                              height: banner.frame.size.height)
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
