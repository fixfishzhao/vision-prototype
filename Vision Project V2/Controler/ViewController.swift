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
    
    @IBOutlet weak var nextButton: UITextField!
    @IBOutlet weak var readButton: UITextField!
    @IBOutlet weak var calibrationPt: UIImageView!
    @IBOutlet weak var recalibrate: UIImageView!
    var webView: WKWebView!
    
    var sessionHandler :SessionHandler?
    // gaze ui view
    var gazePt : UIImageView?
    // gaze ui view size
    var gazeSize : CGSize = CGSize(width: 50, height: 50)
    
    var imageView : UIImageView?
    var titleBox : UITextView?

    var articleURL : String = ""
    
    var currentArticleNumber : Int = 0
    
    var buttonConfirm : UIView?
    
    var show : Bool = false
    
    var buttonAnimationInProgress : Bool = false
    var cardAnimationInProgress : Bool = false

    let gazeTolerence : CGFloat = 20
    
    var onGazeAnimator : UIViewPropertyAnimator?
    var offGazeAnimator : UIViewPropertyAnimator?

    override func viewDidLoad() {
        super.viewDidLoad()
//        let checkActionGesture = UITapGestureRecognizer(target: self, action:  #selector(self.checkAction))
//        self.view.addGestureRecognizer(checkActionGesture)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(recalibrateAction(tapGestureRecognizer:)))
        self.recalibrate.isUserInteractionEnabled = true
        self.recalibrate.addGestureRecognizer(tapGestureRecognizer)
                
        // initialize eye-tracking session
        sessionHandler = SessionHandler(key: "4-3uFBTIaQCRAmn637HweDzb99ThuGoO6dOOzyMXh44hce2jrZDWh5Q6lnLPdcPDRuJ9ZW_HStI0VpwPjJs8a0dUCuyq-09iTlXM4bimPp7P0VUXB7q6wuO8YPmj-s-iBiorpBJ91LmOBIhATb4KPTU4axRuVcrvoqsqXlnRMaoj_R--TJMXhheP1gy1RCzH", receiver: self)
        
        self.recalibrate.alpha = 0
        
        self.readButton.alpha = 0
        self.readButton.layer.cornerRadius = 5
        self.readButton.clipsToBounds = true
        
        self.nextButton.alpha = 0
        self.nextButton.layer.cornerRadius = 5
        self.nextButton.clipsToBounds = true
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
        sessionHandler?.setStatusViewVisibility(on:false)
    }
    
    // errorCode 1000 : Key value is not normal, 1002 : Date expires.
    func onInitializeFailed(errorCode: Int) {
        print("Initialization failed. errorCode : \(errorCode)")
    }
    
    func onCalibrationStarted(){
        UIView.animate(withDuration: 0.3) {
            self.recalibrate.alpha = 0
            self.nextButton.alpha = 0
            self.readButton.alpha = 0
            self.titleBox?.alpha = 0
            self.imageView?.alpha = 0
        }
        self.gazePt?.removeFromSuperview()
    }
    
    
    // receive gaze point
    func onGaze(xy: [Double], state: GazeState, timestamp : Double) {
        DispatchQueue.main.async {
            if state == .tracking {
                
                let readButtonPolygon :Array = [self.readButton.frame.origin.x, self.readButton.frame.origin.y, self.readButton.frame.origin.x + self.readButton.frame.size.width, self.readButton.frame.origin.y + self.readButton.frame.size.height]
                
                let nextButtonPolygon :Array = [self.nextButton.frame.origin.x, self.nextButton.frame.origin.y, self.nextButton.frame.origin.x + self.nextButton.frame.size.width, self.nextButton.frame.origin.y + self.nextButton.frame.size.height]
                
                if CGFloat(xy[0]) >= readButtonPolygon[0] - self.gazeTolerence && CGFloat(xy[0]) <= readButtonPolygon[2] + self.gazeTolerence && CGFloat(xy[1]) >= readButtonPolygon[1] - self.gazeTolerence && CGFloat(xy[1]) <= readButtonPolygon[3] + self.gazeTolerence {
                    self.buttonOnGaze(buttonGazed: self.readButton, buttonPolygon: readButtonPolygon)
                } else if CGFloat(xy[0]) >= nextButtonPolygon[0] && CGFloat(xy[0]) <= nextButtonPolygon[2] && CGFloat(xy[1]) >= nextButtonPolygon[1] && CGFloat(xy[1]) <= nextButtonPolygon[3] {
                    self.buttonOnGaze(buttonGazed: self.nextButton, buttonPolygon: nextButtonPolygon)
                } else {
                    self.buttonOffGaze()
                }
                
                print("x : \(xy[0]), y : \(xy[1]), timestamp : \(timestamp), readButtonPolygon: \(readButtonPolygon)")
                
                let options: UIView.AnimationOptions = [.curveEaseInOut, .beginFromCurrentState]
                
                UIView.animate(withDuration: 0.3,
                               delay: 0,
                               options: options,
                               animations: { [weak self] in
                                self!.gazePt?.frame.origin.x = CGFloat(xy[0]) - self!.gazeSize.width/2
                                self!.gazePt?.frame.origin.y = CGFloat(xy[1]) - self!.gazeSize.height/2
                }, completion: nil)
            }
        }
    }
    // called when calibraiton is done. At this time, create a view to indicate gaze coordinate
    func onCalibrationFinished() {
        DispatchQueue.main.async {
            let imageName = "gazepoint.png"
            let image = UIImage(named: imageName)
            self.gazePt = UIImageView(image: image!)
            self.gazePt!.frame = CGRect(x: self.view.frame.width/2 - self.gazeSize.width/2, y: self.view.frame.height/2 - self.gazeSize.height/2, width: self.gazeSize.width, height: self.gazeSize.height)
//            self.gazePt!.layer.cornerRadius = self.gazeSize.width/2
//            self.gazePt!.backgroundColor = UIColor.white
            self.gazePt!.alpha = 0.6
            self.view.addSubview(self.gazePt!)
            
            UIView.animate(withDuration: 1) {
                self.recalibrate.alpha = 0.6
                self.readButton.alpha = 1
                self.nextButton.alpha = 1
                self.titleBox?.alpha = 1
                self.imageView?.alpha = 1
            }
            
            self.loadCards(articleNumber: self.currentArticleNumber)

        }
    }
    
    func loadCards(articleNumber: Int){
        if self.cardAnimationInProgress == false {
            let articlesCards = ArticleBank()
            
            let screenRect = UIScreen.main.bounds
            let screenWidth = screenRect.size.width
            let screenHeight = screenRect.size.height
            
            let imageName = "placeholderimage.png"
            let image = UIImage(named: imageName)
            self.imageView = UIImageView(image: image!)
            self.imageView!.frame = CGRect(x: (screenWidth - self.nextButton.frame.size.width)/2 , y: (screenHeight - self.nextButton.frame.size.width/6*4 - 40)/2, width: self.nextButton.frame.size.width, height: self.nextButton.frame.size.width/6*4)
            self.imageView!.contentMode = .scaleAspectFill
            self.view.addSubview(self.imageView!)
            self.view.bringSubviewToFront(self.imageView!)
            
            let articleTitle = articlesCards.list[articleNumber].articleTitle
            self.articleURL = articlesCards.list[articleNumber].articleURL
            
            self.titleBox = UITextView()
            self.titleBox!.frame = CGRect(x: self.imageView!.frame.origin.x, y: self.imageView!.frame.origin.y + self.imageView!.frame.size.height, width: self.nextButton.frame.size.width, height: 40)
            self.titleBox!.text = (articleTitle)
            self.titleBox!.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.thin)
            self.titleBox!.textAlignment = .center
            self.view.addSubview(self.titleBox!)
            self.view.bringSubviewToFront(self.titleBox!)
        }
    }
    
    func nextCard() {
        
        if self.cardAnimationInProgress == false {
            
            self.cardAnimationInProgress = true
            let options: UIView.AnimationOptions = [.curveEaseInOut, .beginFromCurrentState]
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           options: options,
                           animations: {
                            self.imageView!.frame.origin.x = 0 - self.imageView!.frame.size.width
                            self.titleBox!.frame.origin.x = 0 - self.titleBox!.frame.size.width
                }, completion: { finished in
                    self.cardAnimationInProgress = false
                    self.imageView!.removeFromSuperview()
                    self.titleBox!.removeFromSuperview()
                    self.currentArticleNumber = self.currentArticleNumber + 1
                    self.loadCards(articleNumber: self.currentArticleNumber)
                }
            )
        }
    }
    
    func confirmArticle() {
        let screenRect = UIScreen.main.bounds
        let screenWidth = screenRect.size.width
        let screenHeight = screenRect.size.height
        self.titleBox?.removeFromSuperview()
        let options: UIView.AnimationOptions = [.curveEaseInOut, .beginFromCurrentState]
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       options: options,
                       animations:{
                self.imageView?.frame.size.width = screenWidth
                self.imageView?.frame.size.height = screenHeight
                self.imageView?.frame.origin.x = 0
                self.imageView?.frame.origin.y = 0
            }, completion: { finished in
                self.loadBrowser()
            }
        )
    }
    
    func buttonOnGaze(buttonGazed: UIView, buttonPolygon: Array<CGFloat>) {
        
        if self.buttonAnimationInProgress == false {

            self.buttonConfirm?.removeFromSuperview()
            
            self.buttonConfirm = UIView(frame: CGRect(x: buttonPolygon[0], y: buttonPolygon[1], width: 0 , height: buttonPolygon[3] - buttonPolygon[1]))
            self.buttonConfirm!.layer.cornerRadius = 5
            self.buttonConfirm!.backgroundColor = UIColor.white
            self.buttonConfirm!.alpha = 1
            
            if buttonGazed == self.readButton {
                self.view.insertSubview(self.buttonConfirm!, belowSubview: self.readButton)
            } else {
                self.view.insertSubview(self.buttonConfirm!, belowSubview: self.nextButton)
            }
            
            self.buttonAnimationInProgress = true
            
            self.offGazeAnimator?.stopAnimation(true)

            self.onGazeAnimator = UIViewPropertyAnimator(duration: 1, curve: .easeInOut, animations: {
                self.buttonConfirm!.frame.size.width = buttonPolygon[2] - buttonPolygon[0]
            })
            
            self.onGazeAnimator?.addCompletion { position in
                if position == .end {
                    self.buttonAnimationInProgress = false
                    if buttonGazed == self.nextButton {
                        self.nextCard()
                    } else {
                        self.confirmArticle()
                    }
                }
            }
            
            self.onGazeAnimator?.startAnimation()
        }
    }
    
    func buttonOffGaze () {
        if self.buttonAnimationInProgress == true {
            self.buttonAnimationInProgress = false
            
            self.onGazeAnimator?.stopAnimation(true)
            
            self.offGazeAnimator = UIViewPropertyAnimator(duration: 1, curve: .easeInOut, animations: {
                 self.buttonConfirm!.frame.size.width = 0
            })
            
            self.offGazeAnimator?.addCompletion { position in
                if position == .end {
                    self.buttonConfirm?.removeFromSuperview()
                }
            }
            self.offGazeAnimator?.startAnimation()
        }
    }
    
    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat(sqrt(xDist * xDist + yDist * yDist))
    }
    
    func loadBrowser() {
        print("articleURL\(self.articleURL)")
        let webConfiguration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: webConfiguration)
        self.webView.uiDelegate = self
        self.imageView?.removeFromSuperview()
        self.view.addSubview(self.webView)
        let myURL = URL(string: "https://www.dailymail.co.uk/auhome/index.html")
        let myRequest = URLRequest(url: myURL!)
        self.webView.load(myRequest)
        self.webView.allowsBackForwardNavigationGestures = true
    }
    
    @objc func recalibrateAction(tapGestureRecognizer: UITapGestureRecognizer) {
        sessionHandler?.startCalibration()
    }
    
    
}

