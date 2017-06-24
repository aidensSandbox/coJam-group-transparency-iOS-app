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
    @IBOutlet weak var userName: UILabel!
}



class Jam: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate
{
    
    var codejamObj = PFObject(className: ROOMS_CLASS_NAME)
    var usersArray = [PFObject]()
    var refreshTimer = Timer()
    let liveQueryClient: Client = ParseLiveQuery.Client(server: "wss://audesis.back4app.io", applicationId:PARSE_APP_KEY, clientKey:PARSE_CLIENT_KEY)
    var subscription: Subscription<PFObject>?
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var awarenessBtn: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "\(codejamObj[ROOMS_NAME]!)"
        print("@@@ JAM LOADED @@@")
        subscribeTo();
    }
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        print("@@@ JAM PRINTED @@@")
        loadUsers()
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "users" {
          
            if let toViewController = segue.destination as? Users {
                toViewController.roomObj = codejamObj
            }
        }
    }
    
    @IBAction func activeAwareness(_ sender: UIButton) {
        activeJamAwareness()
    }
    
    func activeJamAwareness(){
        
        //print(codejamObj[AWARENESS])
        codejamObj[AWARENESS] = true
        // Saving block
        codejamObj.saveInBackground { (success, error) -> Void in
            if error == nil {
                print("Saved with success")
            } else {
                print("\(error!.localizedDescription)")
            }}
        
    }
    // MARK: - LOAD CHATS OF THIS ROOM
    func loadUsers() {
        showHUD()
        usersArray.removeAll()
        
        let query = PFQuery(className: USERCODEJAM_CLASS_NAME)
        query.whereKey(CHAT_ROOM_POINTER, equalTo: codejamObj)
        query.order(byAscending: "createdAt")
        
        query.findObjectsInBackground { (objects, error)-> Void in
            if error == nil {
                self.usersArray = objects!
                self.collectionView.reloadData()
                self.hideHUD()
                // Refresh the Room
                self.refreshTimer.invalidate()
                self.refreshTimer = Timer.scheduledTimer(timeInterval: REFRESH_TIME, target: self, selector: #selector(self.loadUsers), userInfo: nil, repeats: true)
                
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
        return usersArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserCell", for: indexPath) as! UserCell
        var jamClass = PFObject(className: USERCODEJAM_CLASS_NAME)
        jamClass = usersArray[(indexPath as NSIndexPath).row]
        // Get userPointer
        let userPointer = jamClass[USERCODEJAM_USER_POINTER] as! PFUser
        userPointer.fetchIfNeededInBackground { (user, error) in
            // Get user avatar
            cell.userName.layer.cornerRadius = cell.userImage.bounds.size.width/2
            let imageFile = userPointer[USER_AVATAR] as? PFFile
            imageFile?.getDataInBackground { (imageData, error) -> Void in
                if error == nil {
                    if let imageData = imageData {
                        cell.userImage.image = UIImage(data:imageData)
                    }}}
            
            // Get username
            cell.userName.text = "\(userPointer[USER_USERNAME]!)"
            
        }// end userpointer
        
        // cell layout
        cell.layer.cornerRadius = 5
        
        
        return cell
    }
    
}
