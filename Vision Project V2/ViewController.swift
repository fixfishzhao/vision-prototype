//
//  ViewController.swift
//  TG_Mobile_iOS_Demo1
//
//  Created by David on 17/06/2019.
//  Copyright © 2019 VisaulCamp. All rights reserved.
//
import UIKit
import WebKit
// import eye-tracking framework
import TrueGaze

class ViewController: UIViewController, WKUIDelegate {
    
    @IBOutlet weak var circle: UIImageView!
    @IBOutlet weak var circleBottom: UIImageView!
    @IBOutlet weak var calibrationPt: UIImageView!
    @IBOutlet weak var recalibrate: UIImageView!
    @IBOutlet weak var bar: UIImageView!
    @IBOutlet weak var barBottom: UIImageView!
    
    var webView: WKWebView!
    
    var sessionHandler :SessionHandler?
    // gaze ui view
    var gazePt : UIView?
    // gaze ui view size
    var gazeSize : CGSize = CGSize(width: 2, height: 2)
    
    var show : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let checkActionGesture = UITapGestureRecognizer(target: self, action:  #selector(self.checkAction))
//        self.view.addGestureRecognizer(checkActionGesture)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(recalibrateAction(tapGestureRecognizer:)))
        self.recalibrate.isUserInteractionEnabled = true
        self.recalibrate.addGestureRecognizer(tapGestureRecognizer)
                
        // initialize eye-tracking session
        sessionHandler = SessionHandler(key: "4-3uFBTIaQCRAmn637HweDzb99ThuGoO6dOOzyMXh44hce2jrZDWh5Q6lnLPdcPDRuJ9ZW_HStI0VpwPjJs8a0dUCuyq-09iTlXM4bimPp7P0VUXB7q6wuO8YPmj-s-iBiorpBJ91LmOBIhATb4KPTU4axRuVcrvoqsqXlnRMaoj_R--TJMXhheP1gy1RCzH", receiver: self)
        
        self.circle.alpha = 0
        self.bar.alpha = 0
        self.circleBottom.alpha = 0
        self.barBottom.alpha = 0
        self.recalibrate.alpha = 0
    }
    
    
    // preview on/off
    @objc func checkAction(_sender : Any){
        show = !show
        sessionHandler?.setDisplay(enable: show, root: self.view)
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // kill sessionHandler
    deinit {
        sessionHandler?.closeSession()
    }
    
    
}

extension ViewController : Receiver {
    // Initialization succeede.
    func onInitialized() {
        print("Initialization succeede.")
        // Landscape demo
        sessionHandler?.openSession(root: self.view, mode: ScreenMode.Portrait, isCalibration: true)
        sessionHandler?.setCalibrationUI(uiView: calibrationPt, size: CGSize(width: 50,height: 50))
        sessionHandler?.setCalibrationText(contents: "Focus here to calibrate", font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.thin), textColor: UIColor.white)
        sessionHandler?.startSession()
    }
    
    // errorCode 1000 : Key value is not normal, 1002 : Date expires.
    func onInitializeFailed(errorCode: Int) {
        print("Initialization failed. errorCode : \(errorCode)")
    }
    
    func onCalibrationStarted(){
        UIView.animate(withDuration: 0.3) {
            self.circle.alpha = 0
            self.bar.alpha = 0
            self.circleBottom.alpha = 0
            self.barBottom.alpha = 0
            self.recalibrate.alpha = 0
        }
        self.gazePt?.removeFromSuperview()
    }
    
    
    // receive gaze point
    func onGaze(xy: [Double], state: GazeState, timestamp : Double) {
        DispatchQueue.main.async {
            if state == .tracking {
                let screenRect = UIScreen.main.bounds
                let screenWidth = screenRect.size.width
                let tolerance:CGFloat = 40
                let button1MaxY = self.bar.frame.origin.y + tolerance
                let button2Min = self.barBottom.frame.origin.y - tolerance
                let barWidth:CGFloat = self.bar.frame.size.width
                let gapToEdge = (screenWidth - barWidth)/2
                
                let rightCutPoint:CGFloat = barWidth * 0.8 + gapToEdge

                if CGFloat(xy[1]) < button1MaxY {
                    if CGFloat(xy[0]) > gapToEdge && CGFloat(xy[0]) < (gapToEdge + barWidth) {
                        let imageView: UIImageView = self.circle
                        let imageViewWidth: CGFloat = imageView.frame.width
                        let newXPosision = CGFloat(xy[0]) - imageViewWidth/2
                        let rightEndPoint:CGFloat = barWidth + gapToEdge - imageViewWidth/2
                        let leftEndPoint:CGFloat = gapToEdge - imageViewWidth/2
                        self.circle.frame.origin.x = CGFloat(newXPosision)
                        if CGFloat(xy[0]) > rightCutPoint {
                            self.circle.frame.origin.x = rightEndPoint
                            self.loadBrowser()
                        } else if CGFloat(xy[0]) < barWidth * 0.3 + gapToEdge {
                            self.circle.frame.origin.x = leftEndPoint
                        }
                    }
                }
                if CGFloat(xy[1]) > button2Min {
                    if CGFloat(xy[0]) > gapToEdge && CGFloat(xy[0]) < (gapToEdge + barWidth) {
                        let imageView: UIImageView = self.circleBottom
                        let imageViewWidth: CGFloat = imageView.frame.width
                        let newXPosision = CGFloat(xy[0]) - imageViewWidth/2
                        let rightEndPoint:CGFloat = barWidth + gapToEdge - imageViewWidth/2
                        let leftEndPoint:CGFloat = gapToEdge - imageViewWidth/2
                        self.circleBottom.frame.origin.x = CGFloat(newXPosision)
                        print("rightCutPoint: \(rightCutPoint)")
                        if CGFloat(xy[0]) < (barWidth/4*1) + gapToEdge {
                            self.circleBottom.frame.origin.x =  leftEndPoint
                        } else if CGFloat(xy[0]) > rightCutPoint {
                            self.circleBottom.frame.origin.x = rightEndPoint
                        }
                    }
                }
                
                print("x : \(xy[0]), y : \(xy[1]), timestamp : \(timestamp), screenWidth: \(gapToEdge), barWidth: \(barWidth)")
                self.gazePt?.frame.origin.x = CGFloat(xy[0]) - self.gazeSize.width/2
                self.gazePt?.frame.origin.y = CGFloat(xy[1]) - self.gazeSize.height/2
            }
        }
    }
    // called when calibraiton is done. At this time, create a view to indicate gaze coordinate
    func onCalibrationFinished() {
        DispatchQueue.main.async {
            
            self.gazePt = UIView(frame: CGRect(x: self.view.frame.width/2 - self.gazeSize.width/2, y: self.view.frame.height/2 - self.gazeSize.height/2, width: self.gazeSize.width, height: self.gazeSize.height))
            self.gazePt!.layer.cornerRadius = self.gazeSize.width/2
            self.gazePt!.backgroundColor = UIColor.white
            self.view.addSubview(self.gazePt!)
            
            UIView.animate(withDuration: 1) {
                self.circle.alpha = 1
                self.bar.alpha = 1
                self.circleBottom.alpha = 1
                self.barBottom.alpha = 1
                self.recalibrate.alpha = 1
            }
        }
    }
    
    func buttonStarring() {
        
    }
    
    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat(sqrt(xDist * xDist + yDist * yDist))
    }
    
    func loadBrowser() {
        let webConfiguration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: webConfiguration)
        self.webView.uiDelegate = self
        self.view.addSubview(self.webView)
        let myURL = URL(string:"https://www.dailymail.co.uk/news/article-7708147/Brave-woman-ran-bushfire-rescue-koala-opens-heart-rendering-moment.html")
        let myRequest = URLRequest(url: myURL!)
        self.webView.load(myRequest)
        self.webView.allowsBackForwardNavigationGestures = true
    }
    
    @objc func recalibrateAction(tapGestureRecognizer: UITapGestureRecognizer) {
        sessionHandler?.startCalibration()
    }
    
    
}

