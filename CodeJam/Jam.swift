//
//  CodeJam.swift
//  CodeJam
//
//  Created by Raminelli, Alvaro on 6/11/17.
//  Copyright © 2017 FV iMAGINATION. All rights reserved.
//

import UIKit
import Parse
import ParseLiveQuery

// MARK: - CUSTOM ROOMS CELL
class UserCell: UICollectionViewCell {
    /* Views */
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var awarenessImage: UIImageView!
}



class Jam: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate
{
    // Profile
    @IBOutlet weak var exitJam: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    //@IBOutlet weak var awarenessBtn: UIButton!
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var awarenessIcon: UIImageView!
    @IBOutlet weak var statusControl: UIPageControl!
    @IBOutlet weak var activeButton: UIImageView!
    @IBOutlet weak var deactiveButton: UIImageView!
    
    var codejamObj = PFObject(className: ROOMS_CLASS_NAME)
    var codejamSessionObj = PFObject(className: USERCODEJAM_CLASS_NAME)
    var usersArray = [PFObject]()
    var refreshTimer = Timer()
    var roomAwarenessMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(awarenessSingleUserTapped)))
    }
    
    override func viewDidAppear(_ animated: Bool) {

        self.profileImg.layer.cornerRadius = self.profileImg.frame.size.width / 2;
        self.profileImg.clipsToBounds = true
        self.profileImg.layer.borderWidth = 4.0
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(awarenessTapped(tapGestureRecognizer:)))
        let deActiveroomTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(awarenessRoomTapped(tapGestureRecognizer:)))
        let activeRoomTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(awarenessRoomTapped(tapGestureRecognizer:)))
        
        self.activeButton.isUserInteractionEnabled = true
        self.deactiveButton.isUserInteractionEnabled = true
        
        self.activeButton.addGestureRecognizer(activeRoomTapGestureRecognizer)
        self.deactiveButton.addGestureRecognizer(deActiveroomTapGestureRecognizer)
        
        
        self.profileImg.isUserInteractionEnabled = true
        self.profileImg.addGestureRecognizer(tapGestureRecognizer)
        self.profileImg.image = User.shared.imageFile
        
        self.awarenessIcon.isHidden = true;
        self.awarenessIcon.layer.cornerRadius = self.awarenessIcon.frame.size.width / 2;
        self.awarenessIcon.clipsToBounds = true
        self.awarenessIcon.layer.borderWidth = 1.5
        self.awarenessIcon.layer.borderColor = UIColor.black.cgColor
        print("****************");
        setUserStatus()
        getRoomDetails()
        loadUsers()
        subscribeToAwareness()
        subscribeTo()
        subscribeToInvitation()
    }
    
    func getRoomDetails(){
        let query = PFQuery(className: ROOMS_CLASS_NAME)
        query.whereKey("objectId", equalTo: codejamObj.objectId!)
        query.findObjectsInBackground { (objects, error)-> Void in
            if error == nil {
                var rObj = PFObject(className: ROOMS_CLASS_NAME)
                rObj = objects![0]
                let result = Bool(rObj[AWARENESS] as! NSNumber)
                print("### getRoomDetails ###")
                print(result)
                self.roomAwarenessMode = result
                self.updateRoom()
                self.setUserAwareness(force:false)
            }}
        
    }
    
    func updateRoom(){
        print("updateRoom")
        DispatchQueue.global(qos: .background).async {
            // Background Thread
            DispatchQueue.main.async {
                // Run UI Updates
                if self.roomAwarenessMode {
                    self.activeButton.isHidden = true;
                    self.deactiveButton.isHidden = false;
                    //self.awarenessBtn.setTitle("Deactivate", for: .normal)
                    //self.awarenessBtn.backgroundColor = UIColor.red
                }else{
                    self.activeButton.isHidden = false;
                    self.deactiveButton.isHidden = true;
                    //self.awarenessBtn.backgroundColor = UIColor.darkGray
                    //self.awarenessBtn.setTitle("Activate", for: .normal)
                }
            }
        }
    }
    
    func updateUser(){
        
        
        if User.shared.status == STATUS_AVAILABLE {
            self.profileImg.layer.borderColor = UIColor.green.cgColor
            self.statusControl.currentPage = 0
        } else{
            self.profileImg.layer.borderColor = UIColor.red.cgColor
            self.statusControl.currentPage = 1
        }
        
        if User.shared.awarenessMode {
            self.awarenessIcon.isHidden = false;
            self.profileImg.layer.borderColor = UIColor.black.cgColor
        } else{
            self.awarenessIcon.isHidden = true;
        }
        
        
    }
    
    func pushEvent(event:String){
        let eventClass = PFObject(className: CODEJAM_EVENT_CLASS_NAME)
        let currentUser = PFUser.current()
        // Save PFUser as a Pointer
        eventClass[CODEJAM_EVENT_USER_POINTER] = currentUser
        // Save Name Event
        eventClass[CODEJAM_EVENT_NAME] = event
        eventClass[CHAT_ROOM_POINTER] = codejamObj
        // Saving block
        eventClass.saveInBackground { (success, error) -> Void in
            if error == nil {
        }}
    }
    
    func setUserStatus(){
        let updatedUser = PFUser.current()!
        updatedUser[USER_STATUS] = User.shared.status
        updatedUser.saveInBackground { (success, error) -> Void in
            if error == nil {
                self.updateUser()
                self.pushEvent(event: "refresh")
            }
        }
    }
    
    func awarenessSingleUserTapped(sender: UITapGestureRecognizer){
        
        
        if let indexPath = self.collectionView?.indexPathForItem(at: sender.location(in: self.collectionView)) {
            let cell = self.collectionView?.cellForItem(at: indexPath) as! UserCell
            if indexPath.row == (usersArray.count)
            {
                addFriend()
            }else{
                
                if cell.awarenessImage.isHidden {
                    cell.awarenessImage.isHidden = false;
                } else{
                    cell.awarenessImage.isHidden = true;
                }
            }
            
        } else {
            print("collection view was tapped")
        }
    }
    
    func awarenessTapped(tapGestureRecognizer: UITapGestureRecognizer){
        
        if User.shared.awarenessMode {
            User.shared.awarenessMode = false;
            User.shared.audioProcessor?.stop()
        } else{
            User.shared.awarenessMode = true;
            User.shared.audioProcessor?.start()
        }
        let updatedUser = PFUser.current()!
        updatedUser[AWARENESS] = User.shared.awarenessMode
        updatedUser.saveInBackground { (success, error) -> Void in
            if error == nil {
                self.updateUser()
                self.pushEvent(event: "refresh")
            }
        }
    }
    
    func awarenessRoomTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        setRoomAwareness()
        setUserAwareness(force: true)
    }
    
    func setRoomAwareness(){
    
        if self.roomAwarenessMode {
            self.roomAwarenessMode = false
        }else{
            self.roomAwarenessMode = true
        }
        
        self.updateRoom()
        codejamObj[AWARENESS] = self.roomAwarenessMode
        codejamObj.saveInBackground { (success, error) -> Void in
            if error == nil {
                print("setRoomAwareness Saved with success")
                //self.updateRoom()
            } else {
                print("\(error!.localizedDescription)")
            }
        }
    }
    
    func setUserAwareness(force:Bool){
        
        if User.shared.status == STATUS_AVAILABLE || force{
            User.shared.awarenessMode = self.roomAwarenessMode
            
            if User.shared.awarenessMode {
                User.shared.audioProcessor?.start()
            } else{
                User.shared.audioProcessor?.stop()
            }
            
            let updatedUser = PFUser.current()!
            updatedUser[AWARENESS] = User.shared.awarenessMode
            updatedUser.saveInBackground { (success, error) -> Void in
                if error == nil {
                    self.updateUser()
                    self.pushEvent(event: "refresh")
                }
            }
        }
    
    }
    
    func showInvite(room:PFObject){
    
        let alert = UIAlertController(title: APP_NAME,
                                      message: "You have been invited to join in CodeJam \(room[ROOMS_NAME])",
                                      preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "Accept", style: .default, handler: { (action) -> Void in
                        User.shared.currentRoom = room
            let updatedUser = PFUser.current()!
            updatedUser[USER_CURRENTROOM] = User.shared.currentRoom
            updatedUser.saveInBackground { (success, error) -> Void in
                if error == nil {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in })
        alert.addAction(ok); alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func changeStatus(_ sender: UIPageControl) {
        if sender.currentPage == 0 {
            User.shared.status = STATUS_AVAILABLE
        }else{
            User.shared.status = STATUS_BUSY
        }
        self.setUserStatus()
    }
    
    
    @IBAction func closeButt(_ sender: AnyObject) {
        User.shared.currentRoom = nil
        let updatedUser = PFUser.current()!
        updatedUser[USER_CURRENTROOM] = NSNull()
        updatedUser.setObject(NSNull(),forKey: USER_CURRENTROOM)
        updatedUser.saveInBackground { (success, error) -> Void in
            if error == nil {
                self.pushEvent(event: "refresh")
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    //let CODEJAM_INVITE_CLASS_NAME = "CodeJamInvite"
    //let CODEJAM_INVITE_USER_POINTER = "userPointer"
    //let CODEJAM_INVITE_ROOM_POINTER = "roomPointer"
    
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
    
    
    var subscription: Subscription<PFObject>?
    func subscribeTo(){
        print("@@@ subscribeTo JAM @@@")
        let query: PFQuery<PFObject> = PFQuery(className:CODEJAM_EVENT_CLASS_NAME)
        query.whereKey(CHAT_ROOM_POINTER, equalTo: codejamObj)
        query.whereKey(CODEJAM_EVENT_USER_POINTER, notEqualTo: PFUser.current()!)
        subscription = liveQueryClient.subscribe(query).handle(Event.created) { _, object in
            print("@@@ Created Event JAM @@@")
            var rObj = PFObject(className: CODEJAM_EVENT_CLASS_NAME)
            rObj = object
            if (rObj[CODEJAM_EVENT_USER_POINTER] as! PFUser).objectId != PFUser.current()!.objectId{
                self.loadUsers();
            }
        }
    }
    var subscriptionAwareness: Subscription<PFObject>?
    func subscribeToAwareness(){
        print("@@@ subscribeTo JAM Awareness @@@")
        let query: PFQuery<PFObject> = PFQuery(className:ROOMS_CLASS_NAME)
        query.whereKey("objectId", equalTo: codejamObj.objectId!)
        subscriptionAwareness = liveQueryClient.subscribe(query).handle(Event.updated) { _, object in
            var rObj = PFObject(className: ROOMS_CLASS_NAME)
            rObj = object
            let result = Bool(rObj[AWARENESS] as! NSNumber)
            self.roomAwarenessMode = result
            self.updateRoom()
            self.setUserAwareness(force:false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        subscription = nil
        subscriptionAwareness = nil
        subscriptionInvitation = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "users" {
            if let toViewController = segue.destination as? Users {
                toViewController.roomObj = codejamObj
            }
        }
    }
    
    func addFriend(){
        let users = self.storyboard!.instantiateViewController(withIdentifier: "UsersNav")
        present(users, animated: true, completion: nil)
    }
    
    
    // MARK: - LOAD CHATS OF THIS ROOM
    func loadUsers() {
        print("loadUsers")
        usersArray.removeAll()
        let query : PFQuery = PFUser.query()!
        query.whereKey(USER_CURRENTROOM, equalTo: codejamObj)
        query.whereKey("objectId", notEqualTo: PFUser.current()!.objectId!)
        query.order(byAscending: "createdAt")
        query.findObjectsInBackground { (objects, error)-> Void in
            if error == nil {
                self.usersArray = objects!
                self.collectionView.reloadData()
                //self.refreshTimer.invalidate()
                //self.refreshTimer = Timer.scheduledTimer(timeInterval: REFRESH_TIME, target: self, selector: #selector(self.loadUsers), userInfo: nil, repeats: true)
                
            } else {
                self.simpleAlert("\(error!.localizedDescription)")
            }}
    }
    
    // MARK: - COLLECTION VIEW DELEGATES
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return usersArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserCell", for: indexPath) as! UserCell
        
        //let isIndexValid = usersArray.indices.contains((indexPath as NSIndexPath).row)
        //if isIndexValid{
            
        let user = usersArray[(indexPath as NSIndexPath).row] as! PFUser
        let imageFile = user[USER_AVATAR] as? PFFile
        print(user)
        if imageFile == nil{
            cell.userImage.image = UIImage(named: "logo")
        }else{
            imageFile?.getDataInBackground { (imageData, error) -> Void in
                if error == nil {
                    if let imageData = imageData {
                        cell.userImage.image = UIImage(data:imageData)
                    }
                
                }}
        }
        
        cell.userImage.layer.cornerRadius = cell.userImage.frame.size.width / 2;
        cell.userImage.clipsToBounds = true
        cell.userImage.layer.borderWidth = 3.0
        
        cell.awarenessImage.layer.cornerRadius = cell.awarenessImage.frame.size.width / 2;
        cell.awarenessImage.clipsToBounds = true
        cell.awarenessImage.layer.borderWidth = 1.5
        cell.awarenessImage.layer.borderColor = UIColor.black.cgColor
        
        let userAwareness = Bool(user[AWARENESS] as! NSNumber)
        
        if user[USER_STATUS] as! String == STATUS_AVAILABLE {
            cell.userImage.layer.borderColor = UIColor.green.cgColor
        } else{
            cell.userImage.layer.borderColor = UIColor.red.cgColor
        }
        
        if userAwareness {
            cell.userImage.layer.borderColor = UIColor.black.cgColor
            cell.awarenessImage.isHidden = false;
        } else{
            cell.awarenessImage.isHidden = true;
        }
        
        /*}else{
            cell.userImage.layer.borderWidth = 0
            cell.userImage.image = UIImage(named: "newRoomButt")
            cell.awarenessImage.isHidden = true;
        }*/
        // cell layout
        //cell.layer.cornerRadius = 5
        
        return cell
    }
    
    
    
}
