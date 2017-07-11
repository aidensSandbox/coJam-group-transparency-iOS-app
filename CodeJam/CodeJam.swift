/*-------------------------
 
 - Audesis -
 
 created by Alvaro Raminelli © 2017
 All Rights reserved
 
 -------------------------*/

import UIKit
import Parse
import AudioToolbox
import ParseLiveQuery

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
    var currentRoom:PFObject?
}


// MARK:- ROOMS CONTROLLER
class CodeJam: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    UISearchBarDelegate
{
    
    /* Views */
    @IBOutlet weak var roomsCollView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var newRoomButton: UIBarButtonItem!
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var awarenessIcon: UIImageView!
   
    /* Variables */
    var roomsArray = [PFObject]()
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear")
        self.profileImg.layer.cornerRadius = self.profileImg.frame.size.width / 2;
        self.profileImg.clipsToBounds = true
        self.profileImg.layer.borderWidth = 4.0
        
        self.pageControl.numberOfPages = 2
    
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
                }
            })
            
            if(User.shared.currentRoom != nil){
                self.joinInRoom()
            }
            
            subscribeToInvitation()
            
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        profileImg.isUserInteractionEnabled = true
        profileImg.addGestureRecognizer(tapGestureRecognizer)
        
        if PFUser.current() != nil {
            try? PFUser.current()?.fetch()
            if(PFUser.current()?[USER_CURRENTROOM] != nil){
                let currentRoom = PFUser.current()![USER_CURRENTROOM] as! PFObject
                let query = PFQuery(className: ROOMS_CLASS_NAME)
                if let object = try? query.getObjectWithId(currentRoom.objectId!) {
                    User.shared.currentRoom = object
                }
                User.shared.status = PFUser.current()![USER_STATUS] as! String
            }
        }
        
    }
    
    func showInvite(room:PFObject){
        
        let alert = UIAlertController(title: APP_NAME,
                                      message: "You have been invited to join in CodeJam \(room[ROOMS_NAME])",
            preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "Accept", style: .default, handler: { (action) -> Void in
            User.shared.currentRoom = room
            self.updateCurrentRoom()
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in })
        alert.addAction(ok); alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    var subscriptionInvitation: Subscription<PFObject>?
    func subscribeToInvitation(){
        print("@@@ subscribeTo JAM Invitation@@@")
        let query: PFQuery<PFObject> = PFQuery(className:CODEJAM_INVITE_CLASS_NAME)
        query.whereKey(CODEJAM_INVITE_USER_POINTER, equalTo: PFUser.current()!)
        subscriptionInvitation = liveQueryClient.subscribe(query).handle(Event.created) { _, object in
            var room = object[CODEJAM_INVITE_ROOM_POINTER] as! PFObject;
            let query = PFQuery(className: ROOMS_CLASS_NAME)
            query.whereKey("objectId", equalTo:room.objectId)
            query.findObjectsInBackground { (objects, error)-> Void in
                if error == nil {
                    var rObj = PFObject(className: ROOMS_CLASS_NAME)
                    rObj = objects![0]
                    self.showInvite(room:rObj)
                }}
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        subscriptionInvitation = nil
    }
    
    func imageTapped(tapGestureRecognizer: UITapGestureRecognizer){
        if User.shared.awarenessMode {
            User.shared.awarenessMode = false;
            self.awarenessIcon.isHidden = true;
        } else{
            User.shared.awarenessMode = true;
            self.awarenessIcon.isHidden = false;
        }
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
        
        if isIndexValid{
            roomsClass = roomsArray[indexPath.row]
            cell.addNew.isHidden = true
            cell.nameLabel.text = "\(roomsClass[ROOMS_NAME]!)"
        }else{
            cell.nameLabel.text = ""
            cell.addNew.isHidden = false
        }
        
        cell.layer.cornerRadius = 5
        
        return cell
    }
    
    // MARK: - TAP ON A CELL -> ENTER A JAM ROOM
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.row == (roomsArray.count){
            let jam = self.storyboard?.instantiateViewController(withIdentifier: "NewRoom") as! NewRoom
            jam.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            present(jam, animated: true, completion: nil)
        }else{
            
            var roomsClass = PFObject(className: ROOMS_CLASS_NAME)
            roomsClass = roomsArray[indexPath.row]
            User.shared.currentRoom = roomsClass
            updateCurrentRoom()
            
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
    
    func updateCurrentRoom(){
        let updatedUser = PFUser.current()!
        updatedUser[USER_CURRENTROOM] = User.shared.currentRoom
        updatedUser.saveInBackground { (success, error) -> Void in
            if error == nil {
                self.joinInRoom()
            } else {
            
            }
        }
    }
   
    func removeCurrentRoom(){
        let updatedUser = PFUser.current()!
        updatedUser[USER_CURRENTROOM] = NSNull()
        updatedUser.setObject(NSNull(),forKey: USER_CURRENTROOM)
        print(updatedUser)
        updatedUser.saveInBackground { (success, error) -> Void in
            if error == nil {
                print(success)
            } else {
                print(error)
            }
        }
    }

    func joinInRoom(){
        print("joinInRoom")
        print(User.shared.currentRoom!)
        let jam = self.storyboard?.instantiateViewController(withIdentifier: "Jam") as! Jam
        jam.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        jam.codejamObj = User.shared.currentRoom!
        present(jam, animated: true, completion: nil)
        
    }
    
    var subscription: Subscription<PFObject>?
    func subscribeTo(){
        print("@@@ subscribeTo JAM @@@")
        let query: PFQuery<PFObject> = PFQuery(className:USERCODEJAM_CLASS_NAME)
        query.whereKey(USERCODEJAM_USER_POINTER, equalTo: PFUser.current()!)
        query.whereKey(USERCODEJAM_USER_STATUS, equalTo: "invited")
        subscription = liveQueryClient.subscribe(query).handle(Event.created) { _, object in
            print("Inveted @ Chat Room");
            print(object);
            let alert = UIAlertController(title: APP_NAME,
                                          message: "You have been invited to join in CodeJam",
                                          preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "Accept", style: .default, handler: { (action) -> Void in
                self.dismiss(animated: true, completion: nil)
                User.shared.currentRoom = object[CHAT_ROOM_POINTER] as! PFObject
                self.updateCurrentRoom()
            })
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in })
            alert.addAction(ok); alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - REFRESH ROOMS BUTTON
    @IBAction func refreshButt(_ sender: AnyObject) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        
        // Call query
        if PFUser.current() != nil { queryRooms() }
    }

    
    @IBAction func changeStatus(_ sender: UIPageControl) {
        if sender.currentPage == 0 {
            User.shared.status = STATUS_AVAILABLE
        }else{
            User.shared.status = STATUS_BUSY
        }
        setStatus()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
