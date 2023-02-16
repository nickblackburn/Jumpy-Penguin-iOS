//
//  Player.swift
//  JumpyPenguin
//
//  Created by Nicholas Blackburn on 5/24/16.
//  Copyright © 2016 Nicholas Blackburn. All rights reserved.
//

import SpriteKit
import CoreMotion
import GameKit
import UIKit
import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class Player : SKSpriteNode, GameSprite {
    var textureAtlas:SKTextureAtlas = SKTextureAtlas(named:"jumpy.atlas")
    var flyAnimation = SKAction()
    var soarAnimation = SKAction()
    var damageAnimation = SKAction()
    var dieAnimation = SKAction()
    // Keep track of whether we're flapping our wings or in free-fall:
    var flapping = false
    // 57,000 is a force that feels good to me, you can adjust to taste:
    let maxFlappingForce:CGFloat = 57000
    // We want Penguin to slow down when he flies too high:
    let maxHeight:CGFloat = 1000
    var damaged = false
    var invulnerable = false
    var forwardVelocity:CGFloat = 200
    
    func spawn(_ parentNode:SKNode, position: CGPoint, size: CGSize = CGSize(width: 64, height: 64)) {
        parentNode.addChild(self)
        createAnimations()
        MyVariables.HEALTH = 3
        self.size = size
        self.position = position
        self.zPosition = 50
        self.run(soarAnimation, withKey: "soarAnimation")
        
        let physicsTexture = textureAtlas.textureNamed("jumpy-flying-3.png")
        self.physicsBody = SKPhysicsBody(
            texture: physicsTexture,
            size: size)
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.linearDamping = 0.9
        self.physicsBody?.mass = 30
        self.physicsBody?.categoryBitMask = PhysicsCategory.penguin.rawValue
        self.physicsBody?.contactTestBitMask = PhysicsCategory.enemy.rawValue |
            PhysicsCategory.ground.rawValue |
            PhysicsCategory.powerupstar.rawValue | PhysicsCategory.poweruplife.rawValue |
            PhysicsCategory.coin.rawValue
        
        // Instantiate an SKEmitterNode with the Penguin design:
        let dotEmitter = SKEmitterNode(fileNamed: "JumpyPath.sks")
        // Place the particle zPosition behind the penguin:
        dotEmitter!.particleZPosition = -1
        // By adding the emitter node to the player, the emitter will move forward
        // with the player and spawn new dots wherever the player moves:
        self.addChild(dotEmitter!)
        // However, we need the particles themselves to be part of the world,
        // so they trail behind the player. Otherwise, they move forward with Penguin.
        // (Note that self.parent refers to the world node)
        dotEmitter!.targetNode = self.parent
        
        // Grant a momentary reprieve from gravity:
        self.physicsBody?.affectedByGravity = false
        // Add some slight upward velocity:
        self.physicsBody?.velocity.dy = 50
        // Create an SKAction to start gravity after a small delay:
        let startGravitySequence = SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.run {
                self.physicsBody?.affectedByGravity = true
            }])
        self.run(startGravitySequence)
    }
    
    func createAnimations() {
        let rotateUpAction = SKAction.rotate(toAngle: 0, duration: 0.475)
        rotateUpAction.timingMode = .easeOut
        let rotateDownAction = SKAction.rotate(toAngle: -1, duration: 0.8)
        rotateDownAction.timingMode = .easeIn
        
        // Create the flying animation:
        let flyFrames:[SKTexture] = [
            textureAtlas.textureNamed("jumpy-flying-1.png"),
            textureAtlas.textureNamed("jumpy-flying-2.png"),
            textureAtlas.textureNamed("jumpy-flying-3.png"),
            textureAtlas.textureNamed("jumpy-flying-4.png"),
            textureAtlas.textureNamed("jumpy-flying-3.png"),
            textureAtlas.textureNamed("jumpy-flying-2.png")
        ]
        let flyAction = SKAction.animate(with: flyFrames, timePerFrame: 0.01)
        flyAnimation = SKAction.group([
            SKAction.repeatForever(flyAction),
            rotateUpAction
            ])
        
        // Create the soaring animation, just one frame for now:
        let soarFrames:[SKTexture] = [textureAtlas.textureNamed("jumpy-flying-1.png")]
        let soarAction = SKAction.animate(with: soarFrames, timePerFrame: 1)
        soarAnimation = SKAction.group([
            SKAction.repeatForever(soarAction),
            rotateDownAction
            ])
        
        // --- Create the taking damage animation ---
        let damageStart = SKAction.run {
            // Allow the penguin to pass through enemies without colliding:
            self.physicsBody?.categoryBitMask = PhysicsCategory.damagedPenguin.rawValue
            // Use the bitwise NOT operator ~ to remove enemies from the collision test:
            self.physicsBody?.collisionBitMask = ~PhysicsCategory.enemy.rawValue
        }
        // Create an opacity fade out and in, slow at first and fast at the end:
        let slowFade = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.35),
            SKAction.fadeAlpha(to: 0.7, duration: 0.35)
            ])
        let fastFade = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.2),
            SKAction.fadeAlpha(to: 0.7, duration: 0.2)
            ])
        let fadeOutAndIn = SKAction.sequence([
            SKAction.repeat(slowFade, count: 2),
            SKAction.repeat(fastFade, count: 5),
            SKAction.fadeAlpha(to: 1, duration: 0.15)
            ])
        // Return the penguin to normal:
        let damageEnd = SKAction.run {
            self.physicsBody?.categoryBitMask = PhysicsCategory.penguin.rawValue
            // Collide with everything again:
            self.physicsBody?.collisionBitMask = 0xFFFFFFFF
            self.damaged = false
            MyVariables.PLAYER_HURT = false

        }
        
        // Wire it all together and store it in the damageAnimation property:
        self.damageAnimation = SKAction.sequence([
            damageStart,
            fadeOutAndIn,
            damageEnd
            ])
        
        
        /* --- Create the death animation --- */
        let startDie = SKAction.run {
            MyVariables.DIE_ANIMATION_OVER = false
            // Switch to the death texture:
            self.texture = self.textureAtlas.textureNamed("jumpy-dead.png")
            // Suspend the penguin in space:
            self.physicsBody?.affectedByGravity = false
            // Stop any momentum:
            self.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            // Make the penguin pass through everything except the ground:
            self.physicsBody?.collisionBitMask = 0
        }
        
        let endDie = SKAction.run {
            // Turn gravity back on:
//            self.physicsBody?.affectedByGravity = true
            let moveToGround = SKAction.moveTo(y: 80, duration: 2.0)
            self.run(moveToGround)
            MyVariables.DIE_ANIMATION_OVER = true
        }
        
        // Alert the GameScene:
        let alertGameScene = SKAction.run {
            if let gameScene = self.parent?.parent as? GameScene {
                gameScene.gameOver()
            }
        }
        
//        let disappear = SKAction.runBlock {
//            // Make player disappear
//            self.alpha = 0
//        }
        
        self.dieAnimation = SKAction.sequence([
            startDie,
            // Scale the penguin bigger:
            SKAction.scale(to: 2.2, duration: 1.0),
            // Use the waitForDuration action to provide a short pause:
            SKAction.wait(forDuration: 0.5),
            // Rotate the penguin on to his back:
            SKAction.rotate(toAngle: 3, duration: 1.5),
            SKAction.wait(forDuration: 0.5),
            endDie,
            SKAction.wait(forDuration: 2.0),
            alertGameScene
            ])
    }
    
    func update() {
        
        if (MyVariables.PLAYER_IS_DEAD != true || MyVariables.GAME_PAUSED != true) {
            // If we are flapping, apply a new force to push Penguin higher.
            if (self.flapping) {
                var forceToApply = maxFlappingForce
                
                //            print("player is flapping and actually flying")
                
                // Apply less force if Penguin is above position 600
                if (position.y > 600) {
                    // We will apply less and less force the higher Penguin goes.
                    // These next three lines determine just how much force to mitigate:
                    let percentageOfMaxHeight = position.y / maxHeight
                    let flappingForceSubtraction = percentageOfMaxHeight * maxFlappingForce
                    forceToApply -= flappingForceSubtraction
                }
                // Apply the final force:
                self.physicsBody?.applyImpulse(CGVector(dx: 0, dy: forceToApply))
                self.flapping = false
                //            print("applied \(forceToApply)")
            }
            
            // We need to limit Penguin's top speed as he shoots up the y-axis.
            // This prevents him from building up enough momentum to shoot high
            // over our max height. We are bending the physics to improve the gameplay:
            if (self.physicsBody?.velocity.dy > 300) {
                self.physicsBody?.velocity.dy = 300
            }
            
            // Set a constant velocity to the right:
            self.physicsBody?.velocity.dx = self.forwardVelocity
        }
    }
    
    // Begin the flapping animation, and set the flapping property to true:
    func startFlapping() {
        // unsure, comment back in??
//        if MyVariables.HEALTH <= 0 { return }
        
        self.removeAction(forKey: "soarAnimation")
        self.run(flyAnimation, withKey: "flyAnimation")
        self.flapping = true
        
//        print("player is actually flapping")
    }
    
    // Start the soar animation, and set the flapping property to false:
    func stopFlapping() {
        // unsure.. comment back in??
//        if MyVariables.HEALTH <= 0 { return }
        
        self.removeAction(forKey: "flyAnimation")
        self.run(soarAnimation, withKey: "soarAnimation")
        self.flapping = false
    }
    
    func takeDamage() {
        // If currently invulnerable or damaged, return out of the function:
        if self.invulnerable || self.damaged { return }
        // Player is hurt
        MyVariables.PLAYER_HURT = true
        // Set the damaged state to true after being hit:
        self.damaged = true
        
        // Remove one from our health pool
        MyVariables.HEALTH -= 1
        
        if MyVariables.HEALTH == 0 {
            // If we are out of health, run the die function:
            die()
        }
        else {
            // Run the take damage animation:
            self.run(self.damageAnimation)
        }
        
//        Play the hurt sound:
        if (MyVariables.NO_SOUND == false) {
            self.run(MyVariables.HURT_SOUND)
        }
    }
    
    func starPower() {
        MyVariables.INVULNERABLE = true
        // Remove any existing star powerup animation:
        // (if the player is already under the power of another star)
        self.removeAllActions()
        // Make penguin normal again if damaged
        if (MyVariables.PLAYER_HURT == true) {
            self.physicsBody?.categoryBitMask = PhysicsCategory.penguin.rawValue
            self.physicsBody?.collisionBitMask = 0xFFFFFFFF
            self.alpha = 1
            self.damaged = false
            MyVariables.PLAYER_HURT = false
        }
        // Make the player invulnerable:
        self.invulnerable = true
        // Grant great forward speed:
        self.forwardVelocity = 450
        // Create a sequence to scale the player larger,
        // wait 8 seconds, then scale back down and turn off
        // invulnerability, returning the player to normal speed:
        let starSequence = SKAction.sequence([
            SKAction.colorize(with: UIColor.green, colorBlendFactor: 1.0, duration: 0.05),
            SKAction.scale(to: 2.0, duration: 0.2),
            SKAction.wait(forDuration: 6),
            SKAction.colorize(with: UIColor.yellow, colorBlendFactor: 1.0, duration: 0.05),
            SKAction.scale(to: 1.7, duration: 0.2),
            SKAction.run {
                self.forwardVelocity = 300
            },
            SKAction.wait(forDuration: 2),
            SKAction.colorize(with: UIColor.red, colorBlendFactor: 1.0, duration: 0.05),
            SKAction.scale(to: 1.3, duration: 0.2),
            SKAction.run {
                self.forwardVelocity = 250
            },
            SKAction.wait(forDuration: 0.8),
            SKAction.scale(to: 1, duration: 0.2),
            SKAction.colorize(with: UIColor.red, colorBlendFactor: 0.0, duration: 0.01),
            SKAction.run {
                self.forwardVelocity = 200
                self.invulnerable = false
                MyVariables.INVULNERABLE = false
            }
            ])
        // Execute the sequence:
        self.run(starSequence, withKey: "starPower")
        // Play the powerup sound:
        if (MyVariables.NO_SOUND == false) {
            self.run(MyVariables.HEART_HEALTH_SOUND)
        }
    }
    
    func newLife() {
        if (MyVariables.HEALTH < 3) {
            MyVariables.HEALTH += 1
        
            MyVariables.NEW_LIFE_HEART = true
        }
    }
    
    func die() {
        // Player is dead
        MyVariables.PLAYER_IS_DEAD = true
        MyVariables.MUSIC_PLAYER.pause()
        // Remove interaction
        self.physicsBody?.categoryBitMask = 0
        // Prevent any further upward movement:
        self.flapping = false
        // Stop forward movement:
        self.forwardVelocity = 0
        // Make sure the player is fully visible:
        self.alpha = 1
        // Remove all animations:
        self.removeAllActions()
        // Run the die animation:
        self.run(self.dieAnimation)
    }
    
    func onTap() {}
}
