//
//  MenuScene.swift
//  JumpyPenguin
//
//  Created by Nicholas Blackburn on 5/24/16.
//  Copyright © 2016 Nicholas Blackburn. All rights reserved.
//

import SpriteKit
import GameKit

class MenuScene: SKScene, GKGameCenterControllerDelegate {
    // Grab the HUD texture atlas:
    let textureAtlas:SKTextureAtlas = SKTextureAtlas(named:"hud.atlas")
    var noSoundButton = SKSpriteNode()
    var soundButton = SKSpriteNode()
    // Instantiate a sprite node for the start button (we'll use
    // this in a moment):
    let startButton = SKSpriteNode()
    
    override func didMove(to view: SKView) {
        // Position nodes from the center of the scene:
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        // Set a sky-blue background color:
        self.backgroundColor = UIColor(red: 0.4, green: 0.6, blue: 0.95, alpha: 1.0)
        // Add the background image:
        let backgroundImage = SKSpriteNode(imageNamed: "Background-menu")
        backgroundImage.size = CGSize(width: 1024, height: 768)
        self.addChild(backgroundImage)

        // Draw the name of the game:
        let logoText = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        logoText.text = "Jumpy Penguin"
        logoText.position = CGPoint(x: 0, y: 50)
        logoText.fontSize = 60
        logoText.zPosition = 2
        self.addChild(logoText)
        
        // Build the start game button:
        startButton.texture = textureAtlas.textureNamed("button.png")
        startButton.size = CGSize(width: 295, height: 76)
        startButton.name = "StartBtn"
        startButton.position = CGPoint(x: 0, y: -20)
        startButton.zPosition = 1
        self.addChild(startButton)
        
        // Add text to the start button:
        let startText = SKLabelNode(fontNamed: "AvenirNext-HeavyItalic")
        startText.text = "START GAME"
        startText.verticalAlignmentMode = .center
        startText.position = CGPoint(x: 0, y: 2)
        startText.fontSize = 40
        startText.name = "StartBtn"
        startText.zPosition = 2
        startButton.addChild(startText)
        
        // Pulse the start button in and out gently:
        let pulseAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 0.9),
            SKAction.fadeAlpha(to: 1, duration: 0.9),
            ])
        startButton.run(SKAction.repeatForever(pulseAction))
        
        // Add mute button
        noSoundButton.texture = textureAtlas.textureNamed("mute-button.png")
        noSoundButton.size = CGSize(width: 50, height: 50)
        noSoundButton.name = "NoSoundBtn"
        noSoundButton.position = CGPoint(x: 305, y: 150)
        noSoundButton.zPosition = 1
        self.addChild(noSoundButton)
        
        // Add sound button
        soundButton.texture = textureAtlas.textureNamed("sound-button.png")
        soundButton.size = CGSize(width: 50, height: 50)
        soundButton.name = "SoundBtn"
        soundButton.position = CGPoint(x: 250, y: 150)
        soundButton.zPosition = 1
        self.addChild(soundButton)
        
        // If they're logged in, create the leaderboard button
        // (This will only apply to players returning to the menu after a game)
        if GKLocalPlayer.localPlayer().isAuthenticated {
            createLeaderboardButton()
        }
    }
    
    func createLeaderboardButton() {
        // Add some text to open the leaderboard
        let leaderboardText = SKLabelNode(fontNamed: "AvenirNext")
        leaderboardText.text = "Leaderboard"
        leaderboardText.name = "LeaderboardBtn"
        leaderboardText.position = CGPoint(x: 0, y: -100)
        leaderboardText.fontSize = 20
        leaderboardText.zPosition = 2
        self.addChild(leaderboardText)
    }
    
    func showLeaderboard() {
        // Create a new instance of a game center view controller:
        let gameCenter = GKGameCenterViewController()
        // Set this scene as the delegate (helps enable the done button in the game center)
        gameCenter.gameCenterDelegate = self
        // Show the leaderboards when the game center opens:
        gameCenter.viewState = GKGameCenterViewControllerState.leaderboards
        // Find the current view controller so we can show the leaderboard controller:
        if let gameViewController = self.view?.window?.rootViewController {
            // Display the new game center view controller to show the leader board:
            gameViewController.show(gameCenter, sender: self)
            gameViewController.navigationController?
                .pushViewController(gameCenter, animated: true)
        }
    }
    
    // The class requires this function to adhere to the GKGameCenterControllerDelegate protocol
    // It hides the game center view controller when the user taps 'done'
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in (touches ) {
            let location = touch.location(in: self)
            let nodeTouched = atPoint(location)
            
            if nodeTouched.name == "StartBtn" {
                self.view?.presentScene(GameScene(size: self.size))
            }
            else if nodeTouched.name == "LeaderboardBtn" {
                showLeaderboard()
            }
            else if nodeTouched.name == "NoSoundBtn" {
                MyVariables.MUSIC_PLAYER.pause()
                MyVariables.NO_SOUND = true
            }
            else if nodeTouched.name == "SoundBtn" {
                MyVariables.MUSIC_PLAYER.play()
                MyVariables.NO_SOUND = false
            }
        }

    }
    
}
