//
//  doubanFM.swift
//  ThumbsOnTheRun
//
//  Created by 丁松 on 15/1/14.
//  Copyright (c) 2015年 丁松. All rights reserved.
//

//
//  DouBanChannelsViewController.swift
//  DouBan
//
//  Created by Mave on 14/10/23.
//  Copyright (c) 2014年 com.gener-tech. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON


protocol doubanFMProtocol{
    
    func doubanPlayList(playList: JSON)
    
}
class doubanFM: UITableViewController {
    var channelJSON:JSON = JSON.nullJSON
    var delegate: doubanFMProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(self.channelJSON["channels"].count == 0){
            var doubanChannelUrl = "http://www.douban.com/j/app/radio/channels"
            Alamofire.request(.GET, doubanChannelUrl).responseJSON {
                (request, response, data, error) -> Void in
                if(data == nil){
                    println(error)
                    return
                }
                self.channelJSON = JSON(data!)
                //刷新
                self.tableView.reloadData()
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func viewWillAppear(animated: Bool) {
        //每次视图控制器的视图出现前调用函数
        self.tableView.reloadData()
    }
    
    func getPlayList(channel_id:String){
        var listUrl = "http://douban.fm/j/mine/playlist?channel=" + channel_id
        Alamofire.request(.GET, listUrl).responseJSON {
            (request, response, data, error) -> Void in
            if(data == nil){
                println(error)
                return
            }
            self.delegate?.doubanPlayList(JSON(data!))
        }
    }
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //数据还没有时，结果为0
        return self.channelJSON["channels"].count
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) ->   UITableViewCell {
        //let cell = tableView.dequeueReusableCellWithIdentifier("channel", forIndexPath: indexPath) as UITableViewCell
        let cellIdentifer = "channlesCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifer) as? UITableViewCell
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifer)
            cell?.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        }
        cell?.textLabel?.text = self.channelJSON["channels"][indexPath.row]["name"].string
        cell?.detailTextLabel?.text = self.channelJSON["channels"][indexPath.row]["name_en"].string
        return cell!
        
    }
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1)
        UIView.animateWithDuration(0.25, animations: {
            cell.layer.transform = CATransform3DMakeScale(1, 1, 1)
        })
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.getPlayList(self.channelJSON["channels"][indexPath.row]["channel_id"].string!)
    }
}
