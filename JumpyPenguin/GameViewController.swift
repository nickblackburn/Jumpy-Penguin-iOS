//
//  GameViewController.swift
//  JumpyPenguin
//
//  Created by Nicholas Blackburn on 5/23/16.
//  Copyright (c) 2016 Nicholas Blackburn. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation
import GameKit

extension SKNode {
    class func unarchiveFromFile(_ file : String) -> SKNode? {
        if let path = Bundle.main.path(forResource: file, ofType: "sks") {
            let sceneData = try? Data(contentsOf: URL(fileURLWithPath: path))
            //            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            let archiver = NSKeyedUnarchiver(forReadingWith: sceneData!)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as! GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController {
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Build the menu scene:
        let menuScene = MenuScene()
        let skView = self.view as! SKView
        // Ignore drawing order of child nodes (performance increase)
        skView.ignoresSiblingOrder = true
        // Size our scene to fit the view exactly:
        menuScene.size = view.bounds.size
        // Show the menu:
        skView.presentScene(menuScene)
        
        // Start the background music:
        if let url = MyVariables.MUSIC_URL {
            
            MyVariables.MUSIC_PLAYER = try! AVAudioPlayer(contentsOf: url, fileTypeHint: nil)
            MyVariables.MUSIC_PLAYER.numberOfLoops = -1
            MyVariables.MUSIC_PLAYER.prepareToPlay()
            MyVariables.MUSIC_PLAYER.play()
            
        }
        
        authenticateLocalPlayer(menuScene)
    }
    
    // Create a function to authenticate the Game Center account
    // Because the authenticate response comes back asynchronously,
    // we will pass in the MenuScene instance so we can create a leaderboard
    // button if the player authenticates succesfully.
    func authenticateLocalPlayer(_ menuScene:MenuScene) {
        // Create a new Game Center localPlayer instance:
        let localPlayer = GKLocalPlayer.localPlayer();
        // Create a function to check if they are already authenticated
        // or show them the log in screen:
        localPlayer.authenticateHandler = {
            (viewController : UIViewController?, error) -> Void in
            if viewController != nil {
                // They are not logged in, show the log in screen:
                self.present(viewController!, animated: true, completion: nil)
            }
            else if localPlayer.isAuthenticated {
                // They authenticated succesfully
                menuScene.createLeaderboardButton()
            }
            else {
                // They were not able to authenticate, we'll skip Game Center features
            }
        }
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.landscape
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
}
