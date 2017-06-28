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
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addNew: UIImageView!
    
}

class User{
    // Can't init is singleton
    private init() { }
    // MARK: Shared Instance
    static let shared = User()
    var status = STATUS_AVAILABLE
    var awarenessMode = false
    var imageFile = UIImage(named: "logo")
}


// MARK:- ROOMS CONTROLLER
class CodeJam: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    GADBannerViewDelegate,
    UISearchBarDelegate
{
    
    /* Views */
    @IBOutlet weak var roomsCollView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var newRoomButton: UIBarButtonItem!
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var pageControl: UIPageControl!
    //@IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var awarenessIcon: UIImageView!
   
    //Ad banners properties
    var adMobBannerView = GADBannerView()
    
    
    
    /* Variables */
    var roomsArray = [PFObject]()
    
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("-----")
        print(PFUser.current())
        
        self.profileImg.layer.cornerRadius = self.profileImg.frame.size.width / 2;
        self.profileImg.clipsToBounds = true
        self.profileImg.layer.borderWidth = 4.0
        
        self.pageControl.numberOfPages = 2
        //self.pageControl.frame = CGRect(x: 0, y: 0, width: 386,height: 200)
        // USER IS NOT LOGGED IN
        self.awarenessIcon.isHidden = true;
        self.awarenessIcon.layer.cornerRadius = self.awarenessIcon.frame.size.width / 2;
        self.awarenessIcon.clipsToBounds = true
        self.awarenessIcon.layer.borderWidth = 3.0
        self.awarenessIcon.layer.borderColor = UIColor.black.cgColor
        if PFUser.current() == nil {
            let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "Login") as! Login
            present(loginVC, animated: true, completion: nil)
            
        } else {
            
            showUserDetails()
            setStatus()
            queryRooms()
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
        print("*********")
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        profileImg.isUserInteractionEnabled = true
        profileImg.addGestureRecognizer(tapGestureRecognizer)
        
        /*print((scrollView?.frame.size.width)!)
        let scrollWidth = (scrollView?.frame.size.width)!
        let scrollHeight = (scrollView?.frame.size.height)!
        scrollView?.contentSize = CGSize(width: (scrollWidth * 2), height: scrollHeight)
        scrollView?.delegate = self;
        scrollView?.isPagingEnabled=true
        
        for i in 0...2 {
            let textView = UITextView.init()
            /*textView.frame = CGRect(x: scrollWidth * CGFloat (i), y: 0, width: scrollWidth,height: scrollHeight)*/
            scrollView?.addSubview(textView)
        }*/
        
        // Init ad banners
        //initAdMobBanner()
        
        
        // Call the query
        //if PFUser.current() != nil { queryRooms() }
    }
    
    func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        print("imageTapped")
        if User.shared.awarenessMode {
            User.shared.awarenessMode = false;
            self.awarenessIcon.isHidden = true;
        } else{
            User.shared.awarenessMode = true;
            self.awarenessIcon.isHidden = false;
        }

        // Your action
    }
    
    
    // MARK: - SHOW CURRENT USER DETAILS
    func showUserDetails() {
        let CurrentUser = PFUser.current()!
        
        // Get avatar
        self.profileImg.image = UIImage(named: "logo")
        let imageFile = CurrentUser[USER_AVATAR] as? PFFile
        imageFile?.getDataInBackground { (imageData, error) -> Void in
            if error == nil {
                if let imageData = imageData {
                    User.shared.imageFile = UIImage(data:imageData)
                    self.profileImg.image = User.shared.imageFile
                }}}
    }
    
    func setStatus(){
        print("setStatus")
        print(User.shared.status)
        if User.shared.status == STATUS_AVAILABLE {
            self.profileImg.layer.borderColor = UIColor.green.cgColor
        } else{
            self.profileImg.layer.borderColor = UIColor.red.cgColor
        }
    }
    
    // MARK: - QUERY ROOMS
    func queryRooms() {
        //showHUD()
        roomsArray.removeAll()
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
    
    
    @IBAction func closeButt(_ sender: AnyObject) {
    
        let alert = UIAlertController(title: APP_NAME,
                                      message: "Are you sure you want to logout?",
                                      preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "Logout", style: .default, handler: { (action) -> Void in
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
    
    // MARK: - COLLECTION VIEW DELEGATES
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return roomsArray.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RoomCell", for: indexPath) as! RoomCell
        
        var roomsClass = PFObject(className: ROOMS_CLASS_NAME)
        let isIndexValid = roomsArray.indices.contains((indexPath as NSIndexPath).row)
        print(isIndexValid)
        if isIndexValid{
            roomsClass = roomsArray[indexPath.row]
            cell.addNew.isHidden = true
            cell.nameLabel.text = "\(roomsClass[ROOMS_NAME]!)"
        }else{
            cell.nameLabel.text = ""
            cell.addNew.isHidden = false
        }
        // Get room's name
        // Get image
        //let imageFile = roomsClass[ROOMS_IMAGE] as? PFFile
        //imageFile?.getDataInBackground { (imageData, error) -> Void in
        //    if error == nil {
        //        if let imageData = imageData {
        //            cell.roomImage.image = UIImage(data:imageData)
        //        }}}
        // cell layout
        cell.layer.cornerRadius = 5
        
        
        return cell
    }
    
    
    /*func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width/2 - 20, height: view.frame.size.width/2 - 20)
    }*/
    
    
    // MARK: - TAP ON A CELL -> ENTER A CHAT ROOM
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.row == (roomsArray.count){
            let jam = self.storyboard?.instantiateViewController(withIdentifier: "NewRoom") as! NewRoom
            jam.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            present(jam, animated: true, completion: nil)
        }else{
        
        var roomsClass = PFObject(className: ROOMS_CLASS_NAME)
        roomsClass = roomsArray[indexPath.row]
        
        //let jam = storyboard?.instantiateViewController(withIdentifier: "Jam") as! Jam
        //navigationController?.pushViewController(jam, animated: true)
        
        let jam = self.storyboard?.instantiateViewController(withIdentifier: "Jam") as! Jam
        jam.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        jam.codejamObj = roomsClass
        present(jam, animated: true, completion: nil)
        }
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
    
    @IBAction func newRoom(_ sender: UIBarButtonItem) {
        // MARK: - MAKE A NEW ROOM BUTTON
        let nrVC = self.storyboard?.instantiateViewController(withIdentifier: "NewRoom") as! NewRoom
        nrVC.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        present(nrVC, animated: true, completion: nil)
    }
    
    
    @IBAction func changeStatus(_ sender: UIPageControl) {
        
        print(sender.currentPage)
        if sender.currentPage == 0 {
            User.shared.status = STATUS_AVAILABLE
        }else{
            User.shared.status = STATUS_BUSY
        }
        setStatus()
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
