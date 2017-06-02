/*-------------------------

- BuzzIt -

created by FV iMAGINATION © 2015
All Rights reserved

-------------------------*/

import UIKit
import AVFoundation


class Record: UIViewController,
AVAudioRecorderDelegate,
AVAudioPlayerDelegate,
UIAlertViewDelegate
{

    /* Views */
    @IBOutlet weak var recContainerView: UIView!
    @IBOutlet weak var recordImg: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    
    var circularProgress: KYCircularProgress!

    @IBOutlet weak var customAlertView: UIView!
    
    
    
    /* Variables */
    var recorder : AVAudioRecorder?
    var player : AVAudioPlayer?
    var recTimer = Timer()
    
    
    
    
// Hide the StatusBar
override var prefersStatusBarHidden : Bool {
    return true
}
    
override func viewDidLoad() {
        super.viewDidLoad()

    // Move customAlertView out of the screen
    customAlertView.frame.origin.y = view.frame.size.height
    
    
    // Prepare the device for recording
    prepareRecorder()
    
}

// MARK: - PREPARE THE AUDIO RECORDER
func prepareRecorder() {
    let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
    let recordingName = "sound.wav"
    let pathArray = [dirPath, recordingName]
    let filePath = NSURL.fileURL(withPathComponents: pathArray)
    let recordSettings = [
        AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue,
        AVEncoderBitRateKey: 8,
        AVNumberOfChannelsKey: 2,
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 44100.0] as [String : Any]
    print(filePath as Any)
    
    let session = AVAudioSession.sharedInstance()
    do { try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
         try session.overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
         recorder = try AVAudioRecorder(url: filePath!, settings: recordSettings as [String : AnyObject])
    } catch _ {  print("Error") }
    
    recorder!.delegate = self
    recorder!.isMeteringEnabled = true
    recorder!.prepareToRecord()
    
}
    

    
// MARK: - START RECORDING
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    // Get the location of the finger touch on the screen
    let touch = touches.first
    let touchLocation = touch!.location(in: self.recordImg)
    
    if recordImg.frame.contains(touchLocation) {
      if !recorder!.isRecording {
        progress = 0
        let calcTime = RECORD_MAX_DURATION * 0.004
        setupCircularProgress()
        recTimer = Timer.scheduledTimer(timeInterval: calcTime, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        recorder!.record(forDuration: RECORD_MAX_DURATION)
        
        // Set Info Label
        infoLabel.text = "Recording..."
        infoLabel.textColor = UIColor(red: 237.0/255.0, green: 85.0/255.0, blue: 100.0/255.0, alpha: 1.0)

      }
    }
}



// MARK: - STOP RECORDING
override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    if recorder!.isRecording {
        recorder!.stop()
        
        // reset info Label
        infoLabel.text = "Tap and hold to record"
        infoLabel.textColor = UIColor.darkGray
        
        // Check NSData out of the recorded audio
        let audioData = try! Data(contentsOf: recorder!.url)
        print("AUDIO DATA: \(audioData.count)")
        
        // Get recorded file's length in seconds
        let audioAsset = AVURLAsset(url: recorder!.url, options: nil)
        let audioDuration: CMTime = audioAsset.duration
        let audioDurationSeconds = CMTimeGetSeconds(audioDuration)
        print("AUDIO DURATION: \(audioDurationSeconds)")
    }
    
  
}
    

    
// MARK: - SETUP CIRCULAR PROGRESS
func setupCircularProgress() {
    circularProgress = KYCircularProgress(frame: CGRect(x: 0, y: 0, width: recContainerView.frame.size.width, height: recContainerView.frame.size.width))
    circularProgress.colors = [0xa4d22c, 0xa4d22c, 0xa4d22c, 0xa4d22c]
    circularProgress.center = recordImg.center
    circularProgress.lineWidth = 8
        
    circularProgress.progressChangedClosure({ (progress: Double, circularView: KYCircularProgress) in })
    recContainerView.addSubview(circularProgress)
    recContainerView.sendSubview(toBack: circularProgress)
}
    
func updateTimer() {
    progress = progress + 1
    let normalizedProgress = Double(progress) / 255.0
    circularProgress.progress = normalizedProgress
    // println("progress: \(normalizedProgress)")
        
    // Timer ends
    if normalizedProgress >= 1.01 {  recTimer.invalidate()  }
}
    
    
    
    
// MARK: - AUDIO RECORDER AND PLAYER DELEGATES
func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    showAlert()
    
    recTimer.invalidate()
    circularProgress.removeFromSuperview()
}
    
func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    showAlert()
}
    
   
    
    
// MARK: - DISMISS VIEW BUTTON
@IBAction func dismissButt(_ sender: AnyObject) {
    dismiss(animated: true, completion: nil)
}
    
    
    
    
// MARK: - SHOW/HIDE CUSTOM ALERT VIEW
func showAlert() {
    customAlertView.layer.cornerRadius = 10
    UIView.animate(withDuration: 0.1, delay: 0.0, options: UIViewAnimationOptions.curveLinear, animations: {
        self.customAlertView.center.y = self.view.center.y
    }, completion: { (finished: Bool) in })
}
func hideAlert() {
    UIView.animate(withDuration: 0.1, delay: 0.0, options: UIViewAnimationOptions.curveLinear, animations: {
        self.customAlertView.frame.origin.y = self.view.frame.size.height
    }, completion: { (finished: Bool) in })
}
 
    
// MARK: - CUSTOM ALERTVIEW BUTTONS:
@IBAction func alertButtons(_ sender: AnyObject) {
    let button = sender as! UIButton
    
    switch button.tag {
        
    // Replay your recorded message
    case 0:
        do { player = try AVAudioPlayer(contentsOf: recorder!.url)
        } catch _ {  print("Error") }
        
        player!.delegate = self
        player!.play()
        
        
    // Send your message
    case 1:
        audioURLStr = "\(recorder!.url)"
        dismiss(animated: true, completion: nil)
        
        
    // Retake message
    case 2:
        hideAlert()
        
    
    default:break }
    
    
    // Hide the customAlertView
    hideAlert()
}

    
    
    
    
    
override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
}
}

