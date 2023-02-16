//
//  GameScene.swift
//  JumpyPenguin
//
//  Created by Nicholas Blackburn on 5/23/16.
//  Copyright (c) 2016 Nicholas Blackburn. All rights reserved.
//

import SpriteKit
import CoreMotion
import GameKit
import UIKit
import AVFoundation
import Foundation

struct MyVariables {
    static var HIGH_SCORE: Int = 0
    static var NEW_LIFE_HEART: Bool = false
    static var HEALTH:Int = 3
    static var PLAYER_IS_DEAD:Bool = false
    static var PLAYER_HURT:Bool = false
    static var GAME_PAUSED:Bool = false
    static var INVULNERABLE:Bool = false
    static var DIE_ANIMATION_OVER:Bool = false
    static var NO_SOUND:Bool = false
    static let COIN_SOUND = SKAction.playSoundFileNamed("Sound/Coin.aif", waitForCompletion: false)
    static let HEART_HEALTH_SOUND = SKAction.playSoundFileNamed("Sound/Powerup.aif", waitForCompletion: false)
    static let HURT_SOUND = SKAction.playSoundFileNamed("Sound/Hurt.aif", waitForCompletion: false)
    static var MUSIC_PLAYER = AVAudioPlayer()
    static let MUSIC_URL = Bundle.main.url(forResource: "Sound/BackgroundMusic.m4a", withExtension: nil)
    static let userDefaults = UserDefaults.standard
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    let world = SKNode()
    let player = Player()
    let ground = Ground()
    let hud = HUD()
    let screenSize = CGSize()
    var screenCenterY = CGFloat()
    let initialPlayerPosition = CGPoint(x: 150, y: 250)
    var playerProgress = CGFloat()
    let encounterManager = EncounterManager()
    var nextEncounterSpawnPosition = CGFloat(150)
    let powerUpStar = Star()
    let powerUpNewLife = NewLife()
    var coinsCollected = 0
    var backgrounds:[Background] = []
    
    override func didMove(to view: SKView) {
        // Set a sky-blue background color:
        self.backgroundColor = UIColor(red: 0.4, green: 0.6, blue: 0.95, alpha: 1.0)
        
        // Add the world node as a child of the scene:
        self.addChild(world)
        
        // Store the vertical center of the screen:
        screenCenterY = self.size.height / 2
        
        // Add the encounters as children of the world:
        encounterManager.addEncountersToWorld(self.world)
        
        // Spawn the ground:
        let groundPosition = CGPoint(x: -self.size.width, y: 30)
        let groundSize = CGSize(width: self.size.width * 3, height: 0)
        ground.spawn(world, position: groundPosition, size: groundSize)
        
        // Spawn the random star, out of the way for now
        powerUpStar.spawn(world, position: CGPoint(x: -2000, y: -2000))
        
        // Spawn the random new life heart, out of way for now
        powerUpNewLife.spawn(world, position: CGPoint(x: -2000, y: -2000))
        
        MyVariables.PLAYER_IS_DEAD = false
        MyVariables.PLAYER_HURT = false
        MyVariables.NEW_LIFE_HEART = false
        MyVariables.GAME_PAUSED = false
        MyVariables.INVULNERABLE = false
        MyVariables.DIE_ANIMATION_OVER = false
        
        // Spawn the player:
        player.spawn(world, position: initialPlayerPosition)
        
        // Set gravity
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        
        // Wire up the contact event:
        self.physicsWorld.contactDelegate = self
        
        // Create the HUD's child nodes:
        hud.createHudNodes(self.size)
        // Add the HUD to the scene:
        self.addChild(hud)
        // write it to disk
        MyVariables.HIGH_SCORE = (MyVariables.userDefaults.object(forKey: "highscore")! as AnyObject).intValue
        hud.setHighScoreDisplay()
        
        // Position the HUD in front of any other game element
        hud.zPosition = 50
        
        // Instantiate four Backgrounds to the backgrounds array:
        for i in 0...3 {
            backgrounds.append(Background())
        }
        // Spawn the new backgrounds:
        backgrounds[0].spawn(world, imageName: "Background-1", zPosition: -5, movementMultiplier: 0.75)
        backgrounds[1].spawn(world, imageName: "Background-2", zPosition: -10, movementMultiplier: 0.5)
        backgrounds[2].spawn(world, imageName: "Background-3", zPosition: -15, movementMultiplier: 0.2)
        backgrounds[3].spawn(world, imageName: "Background-4", zPosition: -20, movementMultiplier: 0.1)
        
        // Play the start sound:
        if (MyVariables.NO_SOUND == false) {
            self.run(SKAction.playSoundFileNamed("Sound/StartGame.aif", waitForCompletion: false))
        }
    }
    
    override func didSimulatePhysics() {
        var worldYPos:CGFloat = 0
        
        // Zoom the world out slightly as the penguin flies higher
        if (player.position.y > screenCenterY) {
            let percentOfMaxHeight = (player.position.y - screenCenterY) / (player.maxHeight - screenCenterY)
            let scaleSubtraction = (percentOfMaxHeight > 1 ? 1 : percentOfMaxHeight) * 0.6
            let newScale = 1 - scaleSubtraction
            world.yScale = newScale
            world.xScale = newScale
            
            worldYPos = -(player.position.y * world.yScale - (self.size.height / 2))
        }
        
        let worldXPos = -(player.position.x * world.xScale - (self.size.width / 3))
        
        // Move the world for our adjustment:
        world.position = CGPoint(x: worldXPos, y: worldYPos)
        
        // Keep track of how far the player has flown
        playerProgress = player.position.x - initialPlayerPosition.x
        
        // Check to see if the ground should jump forward:
        ground.checkForReposition(playerProgress)
        
        // Check to see if we should set a new encounter:
        if player.position.x > nextEncounterSpawnPosition {
            encounterManager.placeNextEncounter(nextEncounterSpawnPosition)
            nextEncounterSpawnPosition += 1400
            
            // Each encounter has a 1 in 10 chance of spawning a star power-up:
            let starRoll = Int(arc4random_uniform(10))
            if starRoll == 0 {
                if abs(player.position.x - powerUpStar.position.x) > 1200 {
                    // Only move the star if it's already far away from the player.
                    let randomYPos = CGFloat(arc4random_uniform(400))
                    powerUpStar.position = CGPoint(x: nextEncounterSpawnPosition, y: randomYPos)
                    powerUpStar.physicsBody?.angularVelocity = 0
                    powerUpStar.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                }
            }
            
            // 1 in 10 chance for new life heart
            let newLifeHeart = Int(arc4random_uniform(10))
            if newLifeHeart == 0 {
                if abs(player.position.x - powerUpNewLife.position.x) > 1200 {
                    let randomYPos = CGFloat(arc4random_uniform(400))
                    powerUpNewLife.position = CGPoint(x: nextEncounterSpawnPosition, y: randomYPos)
                    powerUpNewLife.physicsBody?.angularVelocity = 0
                    powerUpNewLife.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                }
            }
        }
        
        // Position the backgrounds:
        for background in self.backgrounds {
            background.updatePosition(playerProgress)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Every contact has two bodies, we do not know which body is which.
        // We will find which body is the penguin, then use the other body
        // to determine what type of contact is happening.
        let otherBody:SKPhysicsBody
        // Combine the two penguin physics categories into one mask
        // using the bitwise OR operator |
        let penguinMask = PhysicsCategory.penguin.rawValue | PhysicsCategory.damagedPenguin.rawValue
        // Use the bitwise AND operator & to find the penguin.
        // This returns a positive number if bodyA’s category is
        // the same as either the penguin or damagedPenguin:
        if (contact.bodyA.categoryBitMask & penguinMask) > 0 {
            // bodyA is the penguin, we want to find out what bodyB is:
            otherBody = contact.bodyB
        }
        else {
            // bodyB is the penguin, we will test against bodyA:
            otherBody = contact.bodyA
        }
        // Find the contact type:
        switch otherBody.categoryBitMask {
        case PhysicsCategory.ground.rawValue:
//            print("player height: \(player.position.y)")
//            print("ground height: \(ground.position.y)")
            if (MyVariables.PLAYER_IS_DEAD != true) {
                player.stopFlapping()
                player.physicsBody?.affectedByGravity = false
                player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 100000))
                player.run(SKAction.sequence([SKAction.wait(forDuration: 0.3), SKAction.run {
                    self.player.physicsBody?.affectedByGravity = true
                    }]))
            }
//            else {
//                // Create snow explosion
//                let snowExplosion = SKEmitterNode(fileNamed: "SnowExplosion.sks")
//                player.addChild(snowExplosion!)
//                 
//            }
        case PhysicsCategory.enemy.rawValue:
            if (MyVariables.PLAYER_HURT != true) {
                player.takeDamage()
                hud.setHealthDisplay(MyVariables.HEALTH)
                
                if (MyVariables.PLAYER_IS_DEAD != true) {
                    // Try to cast the otherBody's node as a Bat:
                    if let bat = otherBody.node as? Bat {
                        bat.collect()
                    }
                    
                    // Try to cast the otherBody's node as a MadFly:
                    if let madfly = otherBody.node as? MadFly {
                        madfly.collect()
                    }
                    
                    // Try to cast the otherBody's node as a Ghost:
                    if let ghost = otherBody.node as? Ghost {
                        ghost.collect()
                    }
                    
                    // Try to cast the otherBody's node as a Bee:
                    if let bee = otherBody.node as? Bee {
                        bee.collect()
                    }
                }
            }
            
            // If in star power mode get points for smashing enemies
            if (MyVariables.INVULNERABLE == true) {
                if let bat = otherBody.node as? Bat {
                    self.coinsCollected += bat.value
                    hud.setCoinCountDisplay(self.coinsCollected)
                    bat.collect()
                    if (MyVariables.NO_SOUND == false) {
                        self.run(MyVariables.COIN_SOUND)
                    }
                }
                if let bee = otherBody.node as? Bee {
                    self.coinsCollected += bee.value
                    hud.setCoinCountDisplay(self.coinsCollected)
                    bee.collect()
                    if (MyVariables.NO_SOUND == false) {
                        self.run(MyVariables.COIN_SOUND)
                    }
                }
                if let ghost = otherBody.node as? Ghost {
                    self.coinsCollected += ghost.value
                    hud.setCoinCountDisplay(self.coinsCollected)
                    ghost.collect()
                    if (MyVariables.NO_SOUND == false) {
                        self.run(MyVariables.COIN_SOUND)
                    }
                }
                if let madfly = otherBody.node as? MadFly {
                    self.coinsCollected += madfly.value
                    hud.setCoinCountDisplay(self.coinsCollected)
                    madfly.collect()
                    if (MyVariables.NO_SOUND == false) {
                        self.run(MyVariables.COIN_SOUND)
                    }
                }
            }
        case PhysicsCategory.coin.rawValue:
            if (MyVariables.PLAYER_IS_DEAD != true) {
                // Try to cast the otherBody's node as a Coin:
                if let coin = otherBody.node as? Coin {
                    coin.collect()
                    self.coinsCollected += coin.value
                    hud.setCoinCountDisplay(self.coinsCollected)
                }
            }
        case PhysicsCategory.powerupstar.rawValue:
            player.starPower()
            if let star = otherBody.node as? Star {
                star.collect()
                self.coinsCollected += star.value
                    hud.setCoinCountDisplay(self.coinsCollected)
            }
        case PhysicsCategory.poweruplife.rawValue:
            hud.addHealthLife(screenSize)
            player.newLife()
            hud.setHealthDisplay(MyVariables.HEALTH)
            if let heart = otherBody.node as? NewLife {
                heart.collect()
                if (MyVariables.NO_SOUND == false) {
                    self.run(MyVariables.HEART_HEALTH_SOUND)
                }
            }

        default:
//            print("Contact with no game logic")
            break
        }
        
    
    }
    
    // So sad.
    func gameOver() {
        // Show the restart and main menu buttons:
        hud.playButton.alpha = 0
        hud.pauseButton.alpha = 0
        hud.menuButton1.alpha = 0
        if (MyVariables.DIE_ANIMATION_OVER == true) {
            hud.showButtons()
        }
        
        // Add high score
        highScore()
        
        // Check if they earned the achievement:
        checkForAchievements()
    }
    
    func highScore() {
        
        if (Int64(self.coinsCollected) > Int64(MyVariables.HIGH_SCORE)) {
            MyVariables.HIGH_SCORE = self.coinsCollected
            
            var theScore: NSNumber?
            theScore = NSNumber(value: MyVariables.HIGH_SCORE as Int)
            
            // write it to disk
            MyVariables.userDefaults.set(theScore, forKey: "highscore")
            MyVariables.userDefaults.synchronize()
            
            hud.setHighScoreDisplay()
            self.updateLeaderboard()
        }
    }
    
    func updateLeaderboard() {
        
        if GKLocalPlayer.localPlayer().isAuthenticated {
            // Create a new score object, with our new leaderboard:
            let score = GKScore(leaderboardIdentifier: "JumpyPenguin")
            // Set the score value to our coin score:
            score.value = Int64(self.coinsCollected)
            // Report the score (must use an array with the score instance):
            GKScore.report([score], withCompletionHandler: { (error) -> Void in
                // The error handler was used more in previous versions of iOS,
                // it would be unusual to receive an error now:
                if error != nil {
                    print(error)
                }
            })
        }
        
    }
    
    func checkForAchievements() {
        if GKLocalPlayer.localPlayer().isAuthenticated {
            // Check if they earned 500 coins or more in this game:
            if self.coinsCollected >= 100 {
                let achieve = GKAchievement(identifier: "70360258")
                // Show a notification that they earned it:
                achieve.showsCompletionBanner = true
                achieve.percentComplete = 100
                // Report the achievement! (must use an array with the achieve instance):
                GKAchievement.report([achieve], withCompletionHandler: { (error) -> Void in
                    // Again, given that the user is authenticated, it is unlikely
                    // to get an error back in current versions of iOS:
                    if error != nil {
                        print(error)
                    }
                })
            }
        }
    }
    
    func hidePauseButton() {
        hud.pauseButton.alpha = 0
    }
    
    func showPauseButton() {
        hud.pauseButton.alpha = 1
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (MyVariables.PLAYER_IS_DEAD != true) {
            player.startFlapping()
        }
        
        if (MyVariables.GAME_PAUSED == true) {
            player.stopFlapping()
        }
//        if (player.invulnerable == false && player.damaged == false)
//        {
//            showPauseButton()
//        }
//        print("player should be flapping")
        
        for touch in (touches ) {
            let location = touch.location(in: self)
            let nodeTouched = atPoint(location)
//            print("touched screen")
            
            if let gameSprite = nodeTouched as? GameSprite {
                gameSprite.onTap()
            }
            
            // Check for HUD buttons:
            if nodeTouched.name == "restartGame" {
                // Transition to the new scene:
                self.view?.presentScene(
                    GameScene(size: self.size),
                    transition: .crossFade(withDuration: 0.6))
                if (MyVariables.NO_SOUND == false) {
                    MyVariables.MUSIC_PLAYER.play()
                }
            }
            else if (nodeTouched.name == "returnToMenu" || nodeTouched.name == "menuButton1") {
                // Transition to the menu scene:
                self.view?.presentScene(
                    MenuScene(size: self.size),
                    transition: .crossFade(withDuration: 0.6))
                if (MyVariables.NO_SOUND == false) {
                    MyVariables.MUSIC_PLAYER.play()
                }
            }
            else if (nodeTouched.name == "pauseButton") {
                if (player.invulnerable == false && player.damaged == false) {
                    hidePauseButton()
                    if (MyVariables.NO_SOUND == false) {
                        MyVariables.MUSIC_PLAYER.pause()
                    }
                    hud.menuButton1.alpha = 1
                    hud.playButton.alpha = 1
                    MyVariables.GAME_PAUSED = true
                    player.physicsBody?.affectedByGravity = false
                    player.forwardVelocity = 0
                    player.flapping = false
                    player.removeAllActions()
                    player.physicsBody?.isDynamic = false
                    player.physicsBody?.categoryBitMask = 0
                }
                
            }
            else if (nodeTouched.name == "playButton") {
                hud.menuButton1.alpha = 0
                hud.playButton.alpha = 0
                showPauseButton()
                if (MyVariables.NO_SOUND == false) {
                    MyVariables.MUSIC_PLAYER.play()
                }
                MyVariables.GAME_PAUSED = false
                player.forwardVelocity = 200
                player.physicsBody?.affectedByGravity = true
                player.physicsBody?.isDynamic = true
                player.physicsBody?.categoryBitMask = PhysicsCategory.penguin.rawValue
                self.physicsBody?.collisionBitMask = 0xFFFFFFFF
                player.alpha = 1
            }
        }
        
    }
    
//    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        player.stopFlapping()
//    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (MyVariables.PLAYER_IS_DEAD != true) {
            player.stopFlapping()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (MyVariables.PLAYER_IS_DEAD != true) {
            player.stopFlapping()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if (MyVariables.PLAYER_IS_DEAD != true) {
            player.update()
        }
    }
}

/* Physics Categories */
enum PhysicsCategory:UInt32 {
    case penguin = 1
    case damagedPenguin = 2
    case ground = 4
    case enemy = 8
    case coin = 16
    case powerupstar = 30
    case poweruplife = 32
}
