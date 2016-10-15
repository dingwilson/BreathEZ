//
//  ViewController.swift
//  BreathEZ
//
//  Created by Wilson Ding on 10/15/16.
//  Copyright © 2016 Wilson Ding. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioRecorderDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var breathImage: UIView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var notifyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var circleLayer = CALayer()
    
    var checkTimer: Timer!
    var timeAtPress: Date!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    var isBreathingOut: Bool = false
    var isDataCollected: Bool = true
    var dataCollected: Int = 0
    var intervalData: Double!
    
    var journalData: [BreatheData] = []
    
    var phone = "4692659694"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.barTintColor = colorWithHexString(hex: "011A46")
        
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        titleLabel.fadeOut()
        titleLabel.fadeIn()
        
        breathImage.fadeOut()
        breathImage.fadeIn()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationItem.title = ""

        setupParallax()
        
        getPermissions()
    }
    
    @IBAction func notifyButtonPressed(_ sender: AnyObject) {
        let formatedNumber = self.phone.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        print("calling \(formatedNumber)")
        let phoneUrl = "tel://\(formatedNumber)"
        let url:URL = URL(string: phoneUrl)!
        UIApplication.shared.openURL(url)
    }

    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        self.cancelButton.isHidden = true
        self.notifyButton.isHidden = true
        self.isBreathingOut = false
        self.isDataCollected = true
        self.dataCollected = 0
        self.intervalData = nil
        self.timeAtPress = nil
        self.checkTimer = nil
    }

    // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
        if let vc = segue.destination as? JournalTableViewController {
            vc.journalData = self.journalData
        }
     }
}

// Recording Functionality
extension ViewController {
    func getPermissions() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.startRecording()
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            // failed to record!
        }
    }
    
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record()
            self.checkTimer = Timer.scheduledTimer(timeInterval: 0.04, target: self, selector: #selector(self.checkAudioVolume), userInfo: nil, repeats: true)
            
        } catch {
            //finishRecording(success: false)
        }
    }
    
    func checkAudioVolume() {
        audioRecorder.updateMeters()
        if isDataCollected {
            if audioRecorder.averagePower(forChannel: 0) > -3.5 {
                if !self.isBreathingOut {
                    self.isBreathingOut = true
                    if timeAtPress != nil{
                        endTimer()
                    }
                    startTimer()
                }
            }
                
            else {
                self.isBreathingOut = false
            }
        } else {
            animate(time: intervalData)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}

// Timer Functionality
extension ViewController {
    func startTimer() {
        timeAtPress = Date()
    }
    
    func endTimer() {
        dataCollected += 1
        //print(Date().timeIntervalSince(timeAtPress))
        
        if dataCollected == 1 {
            self.backgroundImage.image = UIImage(named: "Background_Red")
            self.navigationItem.title = "Detected abnormal breathing..."
            intervalData = Date().timeIntervalSince(timeAtPress)
            animate(time: intervalData)
        } else if dataCollected < 5 {
            self.navigationItem.title = "Recording Data..."
            intervalData = (intervalData + Date().timeIntervalSince(timeAtPress))/2
            animate(time: intervalData)
        } else if dataCollected == 5 {
            self.navigationItem.title = "Data Recorded..."
            intervalData = (intervalData + Date().timeIntervalSince(timeAtPress))/2
            self.journalData.append(BreatheData(date: Date(), interval: intervalData))
            animate(time: intervalData)
        } else {
            self.backgroundImage.image = UIImage(named: "Background_Blue")
            self.navigationItem.title = "Everything will be okay..."
            self.isDataCollected = false
            self.cancelButton.isHidden = false
            self.notifyButton.isHidden = false
            
            self.cancelButton.fadeOut()
            self.cancelButton.fadeIn()
            
            self.notifyButton.fadeOut()
            self.notifyButton.fadeIn()
        }
    }
}

// Animation Functionality
extension ViewController {
    func animate(time: Double) {
        if self.breathImage.layer.animationKeys() == nil {
            let halfTime = time/2
            UIView.animate(withDuration: halfTime, animations: {
                self.breathImage.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
                }, completion: { finish in
                    UIView.animate(withDuration: halfTime){
                        self.breathImage.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    }
            })
        }
        
        if intervalData < 4.0 {
            intervalData = intervalData + 0.005
        }
    }
}

// Parallax
extension ViewController {
    func setupParallax() {
        // Set vertical effect
        let verticalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        verticalMotionEffect.minimumRelativeValue = -10
        verticalMotionEffect.maximumRelativeValue = 10
        
        // Set horizontal effect
        let horizontalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontalMotionEffect.minimumRelativeValue = -10
        horizontalMotionEffect.maximumRelativeValue = 10
        
        // Create group to combine both
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontalMotionEffect, verticalMotionEffect]
        
        // Add both effects to your view
        self.view.addMotionEffect(group)
    }
}

// Picks pretty colors
extension ViewController {
    // Creates a UIColor from a Hex string.
    func colorWithHexString (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if (cString.hasPrefix("#")) {
            cString = (cString as NSString).substring(from: 1)
        }
        
        if (cString.characters.count != 6) {
            return UIColor.gray
        }
        
        let rString = (cString as NSString).substring(to: 2)
        let gString = ((cString as NSString).substring(from: 2) as NSString).substring(to: 2)
        let bString = ((cString as NSString).substring(from: 4) as NSString).substring(to: 2)
        
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        Scanner(string: rString).scanHexInt32(&r)
        Scanner(string: gString).scanHexInt32(&g)
        Scanner(string: bString).scanHexInt32(&b)
        
        
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1))
    }
}

// UIView Fade In/Fade Out Extensions
extension UIView {
    func fadeIn() {
        UIView.animate(withDuration: 1.0, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.alpha = 1.0
            }, completion: nil)
    }
    
    func fadeOut() {
        UIView.animate(withDuration: 1.0, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.alpha = 0.0
            }, completion: nil)
    }
}
