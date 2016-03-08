XXNibBridge
===========

# Installation  

`pod 'XXNibBridge', '~> 2.2'`

or `pod search XXNibBridge` to check

# Overview

`XXNibBridge` bridges `xib` file to storyboards or another xib file  

Design time:  

<img src="http://ww2.sinaimg.cn/large/51530583gw1ehzgklik42j20m80go0ua.jpg" height="500" />

Runtime:  

<img src="http://ww3.sinaimg.cn/large/51530583gw1ehzgoiqfkfj20hs0qo75u.jpg" height="500" />

-----

# How to use

1. Build your view class and its xib file. (Same name required)  

    <img src="http://ww3.sinaimg.cn/large/51530583gw1ei03dn8rq8j206g036q2z.jpg" height="200" />

2. Put a placeholder view in target IB (xib or storyboard), Set its class.  

    <img src="http://ww1.sinaimg.cn/large/51530583gw1ei03b0vuzmj20z40a6q4e.jpg" width="500" />  
    
3. Conform to `XXNibBridge` and NOTHING to be implemented  

    ``` objc
        #import <XXNibBridge.h>
        @interface XXDogeView () <XXNibBridge>
        @end
    ```
    
Done:  
    <img src="http://ww4.sinaimg.cn/large/51530583gw1ei03g01mmej20ga07sjrt.jpg" width="500" />

# How it works

中文介绍请见[我的blog](http://blog.sunnyxx.com/2014/07/01/ios_ib_bridge/)
