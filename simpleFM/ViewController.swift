//
//  ViewController.swift
//  simpleFM
//
//  Created by zhangqiang on 15/10/15.
//  Copyright © 2015年 qiang. All rights reserved.
//

import  UIKit
import Alamofire
import MediaPlayer

class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,HttpProtocol,channelProtocol{
    
    
    @IBOutlet weak var iv: EkoImage!
    
    @IBOutlet weak var bg: UIImageView!
    
    @IBOutlet weak var tv: UITableView!
    
    @IBOutlet weak var process: UIImageView!
    
    @IBOutlet weak var playTime: UILabel!
    
    @IBOutlet weak var orderButton: UIButton!
    
    @IBOutlet weak var previousButton: UIButton!
    
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var playButton: UIButton!
    
    var play:Bool = true
    
    var timer = NSTimer()
    
    var eHttp:HTTPController = HTTPController()
    
    var audioPlayer:MPMoviePlayerController = MPMoviePlayerController()
    
    var isAutoFinish:Bool = true
    var currentIndex:Int = 0
    
    var songData:[JSON] = []
    var channelData:[JSON] = []
    var imageCache = Dictionary<String,UIImage>()
    
    let playImg = UIImage(named: "play.png")
    let pauseImg = UIImage(named: "pause.png")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        iv.onRotation()
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame.size = CGSize(width: view.frame.width,height: view.frame.height)
        bg.addSubview(blurView)
        
        tv.dataSource = self
        tv.delegate = self
        
        eHttp.delegate = self
        eHttp.onSearch("http://www.douban.com/j/app/radio/channels")
        //获取频道为0歌曲数据
        eHttp.onSearch("http://douban.fm/j/mine/playlist?type=n&channel=1&from=mainsite")
        
        tv.backgroundColor = UIColor.clearColor()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "play", name: MPMoviePlayerPlaybackDidFinishNotification, object: audioPlayer)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let rowData:JSON = songData[indexPath.row]
        let cell = tv.dequeueReusableCellWithIdentifier("douban") as UITableViewCell!
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel!.text = rowData["title"].string
        cell.detailTextLabel!.text = rowData["artist"].string
        cell.imageView?.image = UIImage(named: "thumb")
        let url = rowData["picture"].string
        onGetCacheImage(url!, imgView: cell.imageView!)
        return cell
    }
    
    
    @IBAction func clickToPlayOrPause(sender: AnyObject) {
        if play {
            playButton.setImage(playImg, forState: UIControlState.Normal)
        }else{
            playButton.setImage(pauseImg, forState: UIControlState.Normal)
        }
        play = !play
        playOrPause(self.play)
    }
    
    func playOrPause(play:Bool){
        if play {
            self.audioPlayer.play()
            self.iv.onRotation()
        }else{
            self.audioPlayer.pause()
            self.iv.stopAnimating()
        }
    }
    
    func onSetAudio(url:String){
        self.audioPlayer.stop()
        self.audioPlayer.contentURL = NSURL(string: url)
        self.audioPlayer.play()
        
        timer.invalidate()
        
        playTime.text = "00:00"
        
        timer = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: "updatePlayTime", userInfo: nil, repeats: true)
        isAutoFinish = true
    }
    
    func didRecieveResults(results:AnyObject){
        //print(results)
        var json = JSON(results)
        
        if let song = json["song"].array{
            self.songData = song
            self.tv.reloadData()
            onSelectRow(0)
        } else if let channel = json["channels"].array{
            self.channelData = channel
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        onSelectRow(indexPath.row)
        isAutoFinish = false
    }
    
    func onSelectRow(index:Int){
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        tv.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.Top)
        let rowData:JSON = songData[index] as JSON
        let picture:String = rowData["picture"].string!
        onSetImage(picture)
        let musicData:String = rowData["url"].string!
        onSetAudio(musicData)
    }
    
    func onSetImage(url:String){
        Alamofire.request(.GET, url).response{(_,_,data,error) -> Void in
            let image = UIImage(data: data! )
            self.iv.image = image
            self.bg.image = image
            self.iv.onRotation()
            
        }
    }
    
    func onGetCacheImage(url:String,imgView:UIImageView){
        let img = self.imageCache[url] as UIImage?
        if img == nil {
            Alamofire.request(.GET, url).response{(_,_,data,error) -> Void in
                let image = UIImage(data: data!)
                self.imageCache[url] = image
                imgView.image = image
            }
        } else {
            imgView.image = img!
            print("cell的图片沿用之前的缓存图片")
        }
    }
    
    func updatePlayTime(){
        let currentTime = audioPlayer.currentPlaybackTime
        if currentTime > 0 {
            let totalTime = audioPlayer.duration
            let partial = CGFloat(currentTime/totalTime)
            self.process.frame.size.width = self.view.frame.size.width * partial
            
            let now = Int(currentTime)
            let minute:Int = Int(now/60)
            let second:Int = now%60
            var time:String = ""
            
            if minute<10{
                time = "0\(minute):"
            }else {
                time = "\(minute):"
            }
            
            if second<10{
                time += "0\(second)"
            }else{
                time += "\(second)"
            }
            playTime.text = time
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let channelC:ChannelController = segue.destinationViewController as! ChannelController
        channelC.delegate = self
        channelC.channelData = self.channelData
    }
    
    func onChangeChannel(channel_id:String){
        let url:String = "http://douban.fm/j/mine/playlist?type=n&channel=\(channel_id)&from=mainsite"
        eHttp.onSearch(url)
        play = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}














