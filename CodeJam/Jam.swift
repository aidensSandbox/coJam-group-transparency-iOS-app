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
    @IBOutlet weak var awarenessBtn: UIButton!
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var awarenessIcon: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(awarenessSingleUserTapped)))
        self.title = "\(codejamObj[ROOMS_NAME]!)"
        print("@@@ JAM LOADED @@@")
        subscribeTo();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.profileImg.layer.cornerRadius = self.profileImg.frame.size.width / 2;
        self.profileImg.clipsToBounds = true
        self.profileImg.layer.borderWidth = 4.0
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(awarenessTapped(tapGestureRecognizer:)))
        self.profileImg.isUserInteractionEnabled = true
        self.profileImg.addGestureRecognizer(tapGestureRecognizer)
        self.profileImg.image = User.shared.imageFile
        
        self.awarenessIcon.isHidden = true;
        self.awarenessIcon.layer.cornerRadius = self.awarenessIcon.frame.size.width / 2;
        self.awarenessIcon.clipsToBounds = true
        self.awarenessIcon.layer.borderWidth = 1.5
        self.awarenessIcon.layer.borderColor = UIColor.black.cgColor
        
        setStatus()
        loadUsers()
    }
    
    func setStatus(){
        if User.shared.status == STATUS_AVAILABLE {
            self.profileImg.layer.borderColor = UIColor.green.cgColor
        } else{
            self.profileImg.layer.borderColor = UIColor.red.cgColor
        }
    }
    
    func awarenessSingleUserTapped(sender: UITapGestureRecognizer)
    {
        
        
        if let indexPath = self.collectionView?.indexPathForItem(at: sender.location(in: self.collectionView)) {
            let cell = self.collectionView?.cellForItem(at: indexPath) as! UserCell
            print(indexPath.row)
            print(usersArray.count)
            if indexPath.row == (usersArray.count)
            {
                addFriend()
            }else{
                activeJamAwareness()
                //Improve the logic
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
    
    func awarenessTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        activeJamAwareness()
    }
    
    @IBAction func activeAwareness(_ sender: UIButton) {
        activeJamAwareness()
    }
    
    func activeJamAwareness(){
        
        if User.shared.awarenessMode {
            User.shared.awarenessMode = false;
            self.awarenessIcon.isHidden = true;
        } else{
            User.shared.awarenessMode = true;
            self.awarenessIcon.isHidden = false;
        }
        
        codejamObj[AWARENESS] = User.shared.awarenessMode
        codejamObj.saveInBackground { (success, error) -> Void in
            if error == nil {
                print("Saved with success")
            } else {
                print("\(error!.localizedDescription)")
            }
        }
        
    }
    
    @IBAction func changeStatus(_ sender: UIPageControl) {
        if sender.currentPage == 0 {
            User.shared.status = STATUS_AVAILABLE
        }else{
            User.shared.status = STATUS_BUSY
        }
        setStatus()
    }
    
    @IBAction func closeButt(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    // Users
    
    var codejamObj = PFObject(className: ROOMS_CLASS_NAME)
    var usersArray = [PFObject]()
    var refreshTimer = Timer()
    let liveQueryClient: Client = ParseLiveQuery.Client(server: "wss://audesis.back4app.io", applicationId:PARSE_APP_KEY, clientKey:PARSE_CLIENT_KEY)
    var subscription: Subscription<PFObject>?
    
    func subscribeTo(){
        print("@@@ subscribeTo JAM @@@")
        let query: PFQuery<PFObject> = PFQuery(className:ROOMS_CLASS_NAME)
        query.whereKey("objectId", equalTo: codejamObj.objectId)
        subscription = liveQueryClient.subscribe(query).handle(Event.updated) { _, object in
            // Called whenever an object was created
            print("Event @ Chat Room");
            print(object);
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "users" {
            if let toViewController = segue.destination as? Users {
                toViewController.roomObj = codejamObj
            }
        }
    }
    
    func addFriend(){
        //let users = storyboard?.instantiateViewController(withIdentifier: "Users") as! Users
        //let users = self.storyboard?.instantiateViewController(withIdentifier: "Users") as! Users
        //users.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        //users.roomObj = codejamObj
        //present(users, animated: true, completion: nil)
        //navigationController?.pushViewController(users, animated: true)
        
        //let appDelegate = UIApplication.shared.delegate! as! AppDelegate
        let users = self.storyboard!.instantiateViewController(withIdentifier: "UsersNav")
        present(users, animated: true, completion: nil)
        //appDelegate.window?.rootViewController = initialViewController
        //appDelegate.window?.makeKeyAndVisible()
        

    }
    
    
    // MARK: - LOAD CHATS OF THIS ROOM
    func loadUsers() {
        usersArray.removeAll()
        let query = PFQuery(className: USERCODEJAM_CLASS_NAME)
        query.whereKey(CHAT_ROOM_POINTER, equalTo: codejamObj)
        query.order(byAscending: "createdAt")
        
        query.findObjectsInBackground { (objects, error)-> Void in
            if error == nil {
                self.usersArray = objects!
                self.collectionView.reloadData()
                // Refresh the Room
                self.refreshTimer.invalidate()
                self.refreshTimer = Timer.scheduledTimer(timeInterval: REFRESH_TIME, target: self, selector: #selector(self.loadUsers), userInfo: nil, repeats: true)
                
            } else {
                self.simpleAlert("\(error!.localizedDescription)")
            }}
        
    }
    
    // MARK: - COLLECTION VIEW DELEGATES
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return usersArray.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserCell", for: indexPath) as! UserCell
        var jamClass = PFObject(className: USERCODEJAM_CLASS_NAME)
        
        let isIndexValid = usersArray.indices.contains((indexPath as NSIndexPath).row)
        print(isIndexValid)
        if isIndexValid{
            jamClass = usersArray[(indexPath as NSIndexPath).row]
            // Get userPointer
            let userPointer = jamClass[USERCODEJAM_USER_POINTER] as! PFUser
            userPointer.fetchIfNeededInBackground { (user, error) in
                // Get user avatar
                let imageFile = userPointer[USER_AVATAR] as? PFFile
                imageFile?.getDataInBackground { (imageData, error) -> Void in
                    if error == nil {
                        if let imageData = imageData {
                            cell.userImage.image = UIImage(data:imageData)
                            cell.userImage.layer.cornerRadius = cell.userImage.frame.size.width / 2;
                            cell.userImage.clipsToBounds = true
                        
                            cell.awarenessImage.isHidden = true;
                            cell.awarenessImage.layer.cornerRadius = cell.awarenessImage.frame.size.width / 2;
                            cell.awarenessImage.clipsToBounds = true
                            cell.awarenessImage.layer.borderWidth = 1.5
                            cell.awarenessImage.layer.borderColor = UIColor.black.cgColor
                        }
                    }
                }
            }
        }else{
            cell.userImage.image = UIImage(named: "newRoomButt")
            cell.awarenessImage.isHidden = true;
        }
        // cell layout
        cell.layer.cornerRadius = 5
        
        return cell
    }
    
    
    
}
