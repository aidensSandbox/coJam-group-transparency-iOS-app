/*-------------------------

- BuzzIt -

created by FV iMAGINATION © 2015
All Rights reserved

-------------------------*/


import UIKit

class TermsOfUse: UIViewController {

    /* Views */
    @IBOutlet var webView: UIWebView!
    
    
  
    
override var prefersStatusBarHidden : Bool {
        return true
}
override func viewDidLoad() {
        super.viewDidLoad()
    
    let url = Bundle.main.url(forResource: "tou", withExtension: "html")
    webView.loadRequest(URLRequest(url: url!))

}


    
override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
