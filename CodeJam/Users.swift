//
//  Users.swift
//  CodeJam
//
//  Created by Raminelli, Alvaro on 6/14/17.
//  Copyright © 2017 FV iMAGINATION. All rights reserved.
//

import UIKit
import Parse


class Users: UITableViewController, UISearchBarDelegate{
    
    var usersArray = [PFObject]()
    var roomObj = PFObject(className: ROOMS_CLASS_NAME)
    
    let cellReuseIdentifier = "cell"

    @IBOutlet weak var usersTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register the table view cell class and its reuse id
        self.usersTableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        // This view controller itself will provide the delegate methods and row data for the table view.
        usersTableView.delegate = self
        usersTableView.dataSource = self
        searchBar.delegate = self
        queryUsers()
        roomObj = User.shared.currentRoom as! PFObject
        
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        // Stop doing the search stuff
        // and clear the text in the search bar
        searchBar.text = ""
        // Hide the cancel button
        searchBar.showsCancelButton = false
        // You could also change the position, frame etc of the searchBar
    }
    
    // number of rows in table view
    override func tableView(_ usersTableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.usersArray.count
    }
    // create a cell for each table view row
    override func tableView(_ usersTableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // create a new cell if needed or reuse an old one
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell!
        
        var user = PFUser()
        user = usersArray[(indexPath as NSIndexPath).row] as! PFUser
        
        // set the text from the data model
        cell.textLabel?.text = "\(user[USER_USERNAME]!)"
        
        return cell
    }
    
    // method to run when table view cell is tapped
    override func tableView(_ usersTableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You tapped")
        print(roomObj)
        var user = PFUser()
        user = usersArray[(indexPath as NSIndexPath).row] as! PFUser
        addUser(user)
        

    }
    
    // MARK: - QUERY USERS
    func queryUsers() {
        showHUD()
        usersArray.removeAll()
        let query = PFUser.query()
        query?.findObjectsInBackground { (objects, error)-> Void in
            if error == nil {
                self.usersArray = objects!
                self.usersTableView.reloadData()
                self.hideHUD()
            } else {
                self.simpleAlert("\(error!.localizedDescription)")
                self.hideHUD()
            }}
    
    }
    
    //let CODEJAM_INVITE_CLASS_NAME = "CodeJamInvite"
    //let CODEJAM_INVITE_USER_POINTER = "userPointer"
    //let CODEJAM_INVITE_ROOM_POINTER = "roomPointer"
    
    func addUser(_ user: PFUser) {
        print("### Saving Invite ###")
        print(roomObj)
        var jamObj = PFObject(className: CODEJAM_INVITE_CLASS_NAME)
        jamObj[CODEJAM_INVITE_USER_POINTER] = user
        jamObj[CODEJAM_INVITE_ROOM_POINTER] = roomObj
        jamObj.saveInBackground { (success, error) -> Void in
            if error == nil {
                print("Saved with success")
                self.close()
            } else {
                print("\(error!.localizedDescription)")
            }
        }
    }
    
    func close(){
    
        let alert = UIAlertController(title: APP_NAME,
                                      message: "The invitation has been sent.",
                                      preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            self.dismiss(animated: true, completion: nil)
        })
        
        alert.addAction(ok);
        present(alert, animated: true, completion: nil)
        
    }
    
    // CREATE ROOM BUTTON -> SAVE IT TO PARSE DATABASE
    /*@IBAction func createRoomButt(_ sender: AnyObject) {
        
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
    }*/
    
}
