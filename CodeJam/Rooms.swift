/*-------------------------

- BuzzIt -

created by FV iMAGINATION © 2015
All Rights reserved

-------------------------*/

import UIKit
import Parse
import GoogleMobileAds
import AudioToolbox


// MARK: - CUSTOM ROOMS CELL
class RoomCell: UICollectionViewCell {
    /* Views */
    @IBOutlet weak var roomImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
}






// MARK:- ROOMS CONTROLLER
class Rooms: UIViewController,
UICollectionViewDataSource,
UICollectionViewDelegate,
UICollectionViewDelegateFlowLayout,
GADBannerViewDelegate,
UISearchBarDelegate
{

    /* Views */
    @IBOutlet weak var roomsCollView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    //Ad banners properties
    var adMobBannerView = GADBannerView()
    

    
    /* Variables */
    var roomsArray = [PFObject]()
    
    
    

override func viewDidAppear(_ animated: Bool) {
    // USER IS NOT LOGGED IN
    if PFUser.current() == nil {
        let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "Login") as! Login
        present(loginVC, animated: true, completion: nil)
    
    } else {
        // Associate the device with a user for Push Notifications
        let installation = PFInstallation.current()
        installation?["username"] = PFUser.current()!.username
        installation?["userID"] = PFUser.current()!.objectId!
        installation?.saveInBackground(block: { (succ, error) in
            if error == nil {
                print("PUSH REGISTERED FOR: \(PFUser.current()!.username!)")
        }})
    }
}

    
override func viewDidLoad() {
        super.viewDidLoad()
 
    // Reset app's badge icon to 0
    UIApplication.shared.applicationIconBadgeNumber = 0
    
    // Init ad banners
    //initAdMobBanner()

    
    // Call the query
    if PFUser.current() != nil { queryRooms() }
}

    
    
// MARK: - QUERY ROOMS
func queryRooms() {
    showHUD()
    
    let query = PFQuery(className: ROOMS_CLASS_NAME)
    query.whereKey(ROOMS_NAME, contains: searchBar!.text!.uppercased())
    query.order(byDescending: "createdAt")
    query.findObjectsInBackground { (objects, error)-> Void in
        if error == nil {
            self.roomsArray = objects!
            self.roomsCollView.reloadData()
            self.hideHUD()
        } else {
            self.simpleAlert("\(error!.localizedDescription)")
            self.hideHUD()
    }}
}
    
    
    
    
// MARK: - COLLECTION VIEW DELEGATES
func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
}
func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return roomsArray.count
}

func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RoomCell", for: indexPath) as! RoomCell
    
    var roomsClass = PFObject(className: ROOMS_CLASS_NAME)
    roomsClass = roomsArray[indexPath.row]

    // Get room's name
    cell.nameLabel.text = "\(roomsClass[ROOMS_NAME]!)"

    // Get image
    let imageFile = roomsClass[ROOMS_IMAGE] as? PFFile
    imageFile?.getDataInBackground { (imageData, error) -> Void in
        if error == nil {
            if let imageData = imageData {
                cell.roomImage.image = UIImage(data:imageData)
    }}}

    
    // cell layout
    cell.layer.cornerRadius = 5
    
    
return cell
}
    

func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: view.frame.size.width/2 - 20, height: view.frame.size.width/2 - 20)
}
    

// MARK: - TAP ON A CELL -> ENTER A CHAT ROOM
func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    var roomsClass = PFObject(className: ROOMS_CLASS_NAME)
    roomsClass = roomsArray[indexPath.row]
    
    let chatsVC = storyboard?.instantiateViewController(withIdentifier: "Chats") as! Chats
    chatsVC.roomObj = roomsClass
    navigationController?.pushViewController(chatsVC, animated: true)
}
   
    

    

    
// MARK: - SEARCH BAR DELEGATES
func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
    queryRooms()
    searchBar.showsCancelButton = false
}
 
func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    searchBar.showsCancelButton = true
}
func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
    searchBar.showsCancelButton = false
    searchBar.text = ""
}
    

    
    
    
// MARK: - REFRESH ROOMS BUTTON
@IBAction func refreshButt(_ sender: AnyObject) {
    searchBar.text = ""
    searchBar.resignFirstResponder()
    searchBar.showsCancelButton = false
    
    // Call query
    if PFUser.current() != nil { queryRooms() }
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
