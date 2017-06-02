/*-------------------------

- BuzzIt -

created by FV iMAGINATION © 2015
All Rights reserved

-------------------------*/


import Foundation
import UIKit


// EDIT THE RED STRING BELOW ACCORDINGLY TO THE NEW NAME YOU'LL GIVE TO THIS APP
let APP_NAME = "BuzzIt"


// YOU CAN CHANGE THE VALUE OF THE MAX. DURATION OF A RECORDING (PLEASE NOTE THAT HIGHER VALUES MAY AFFET THE LOADING TIME OF POSTS)
let RECORD_MAX_DURATION: TimeInterval = 10.0



// YOU CAN CHANGE THE TIME WHEN THE APP WILL REFRESH THE CHATS (PLEASE NOTE THAT A LOW VALUE MAY AFFECT THE STABILITY OF THE APP, WE THINK 30 seconds A GOOD MINIMUM REFRESH TIME)
let REFRESH_TIME: TimeInterval = 30.0



// REPLACE THE RED STRING BELOW WITH YOUR OWN BANNER UNIT ID YOU'VE GOT ON http://apps.admob.com
let ADMOB_UNIT_ID = "ca-app-pub-9733347540588953/7805958028"



// REPLACE THE RED STRING BELOW WITH THE LINK TO YOUR OWN APP (You can find it on iTunes Connect, click More -> View on the App Store)
let APPSTORE_LINK = "https://itunes.apple.com/app/id957290825"


// REPLACE THE RED STRING BELOW WITH YOUR APP ID (still on iTC, click on More -> About this app)
let APP_ID = "957290825"



// HUD View
let hudView = UIView(frame: CGRect(x:0, y: 0, width: 80, height:80))
let indicatorView = UIActivityIndicatorView(frame: CGRect(x:0, y:0, width:80, height: 80))
extension UIViewController {
    func showHUD() {
        hudView.center = CGPoint(x: view.frame.size.width/2, y:view.frame.size.height/2)
        hudView.backgroundColor = UIColor.darkGray
        hudView.alpha = 0.9
        hudView.layer.cornerRadius = hudView.bounds.size.width/2

        indicatorView.center = CGPoint(x: hudView.frame.size.width/2, y: hudView.frame.size.height/2)
        indicatorView.activityIndicatorViewStyle = .white
        indicatorView.color = UIColor.white
        hudView.addSubview(indicatorView)
        indicatorView.startAnimating()
        view.addSubview(hudView)
    }
    func hideHUD() { hudView.removeFromSuperview() }

  func simpleAlert(_ mess:String) {
        UIAlertView(title: APP_NAME, message: mess, delegate: nil, cancelButtonTitle: "OK").show()
    }
}



// PARSE KEYS ------------------------------------------------------------------------
let PARSE_APP_KEY = "KJsBLVPpbDTU1MlGQfg7z00Ig0ogL6sGztBCa2HJ"
let PARSE_CLIENT_KEY = "f8GmmDpIcbYHc9z0qxGUZQvHe2qCXBslRnP0Nsf3"







/*************** DO NOT EDIT THE CODE BELOW! *************/

var audioURLStr = ""
var tenMessLimit = UserDefaults.standard.bool(forKey: "tenMessLimit")


let USER_USERNAME = "username"
let USER_AVATAR = "avatar"

let CHAT_CLASS_NAME = "ChatRooms"
let CHAT_USER_POINTER = "userPointer"
let CHAT_ROOM_NAME = "name"
let CHAT_ROOM_POINTER = "roomPointer"
let CHAT_MESSAGE = "message"
let CHAT_IS_REPORTED = "isReported"


let ROOMS_CLASS_NAME = "Rooms"
let ROOMS_NAME = "name"
let ROOMS_IMAGE = "image"
let ROOMS_USER_POINTER = "userPointer"





// EXTENSION TO SHOW TIME AGO DATES
extension UIViewController {
    func timeAgoSinceDate(_ date:Date,currentDate:Date, numericDates:Bool) -> String {
        let calendar = Calendar.current
        let now = currentDate
        let earliest = (now as NSDate).earlierDate(date)
        let latest = (earliest == now) ? date : now
        let components:DateComponents = (calendar as NSCalendar).components([NSCalendar.Unit.minute , NSCalendar.Unit.hour , NSCalendar.Unit.day , NSCalendar.Unit.weekOfYear , NSCalendar.Unit.month , NSCalendar.Unit.year , NSCalendar.Unit.second], from: earliest, to: latest, options: NSCalendar.Options())
        
        if (components.year! >= 2) {
            return "\(components.year!) years ago"
        } else if (components.year! >= 1){
            if (numericDates){
                return "1 year ago"
            } else {
                return "Last year"
            }
        } else if (components.month! >= 2) {
            return "\(components.month!) months ago"
        } else if (components.month! >= 1){
            if (numericDates){
                return "1 month ago"
            } else {
                return "Last month"
            }
        } else if (components.weekOfYear! >= 2) {
            return "\(components.weekOfYear!) weeks ago"
        } else if (components.weekOfYear! >= 1){
            if (numericDates){
                return "1 week ago"
            } else {
                return "Last week"
            }
        } else if (components.day! >= 2) {
            return "\(components.day!) days ago"
        } else if (components.day! >= 1){
            if (numericDates){
                return "1 day ago"
            } else {
                return "Yesterday"
            }
        } else if (components.hour! >= 2) {
            return "\(components.hour!) hours ago"
        } else if (components.hour! >= 1){
            if (numericDates){
                return "1 hour ago"
            } else {
                return "An hour ago"
            }
        } else if (components.minute! >= 2) {
            return "\(components.minute!) minutes ago"
        } else if (components.minute! >= 1){
            if (numericDates){
                return "1 minute ago"
            } else {
                return "A minute ago"
            }
        } else if (components.second! >= 3) {
            return "\(components.second!) seconds ago"
        } else {
            return "Just now"
        }
        
    }
}



