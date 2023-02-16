//
//  NewLife.swift
//  JumpyPenguin
//
//  Created by Nicholas Blackburn on 9/6/16.
//  Copyright © 2016 Nicholas Blackburn. All rights reserved.
//

import Foundation
import SpriteKit

class NewLife: SKSpriteNode, GameSprite {
    var textureAtlas:SKTextureAtlas = SKTextureAtlas(named:"hud.atlas")
    var pulseAnimation = SKAction()
    
    func spawn(_ parentNode:SKNode, position: CGPoint, size: CGSize = CGSize(width: 40, height: 38)) {
        parentNode.addChild(self)
        createAnimations()
        self.size = size
        self.position = position
        self.physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.categoryBitMask = PhysicsCategory.poweruplife.rawValue
        self.physicsBody?.collisionBitMask = PhysicsCategory.penguin.rawValue | PhysicsCategory.damagedPenguin.rawValue
        
        self.texture = textureAtlas.textureNamed("heart-full.png")
        self.run(pulseAnimation)
    }
    
    func createAnimations() {
        // Scale the heart/NewLife smaller and fade it slightly:
        let pulseOutGroup = SKAction.group([
            SKAction.fadeAlpha(to: 0.85, duration: 0.8),
            SKAction.scale(to: 0.6, duration: 0.8),
            SKAction.rotate(byAngle: -0.3, duration: 0.8)
            ]);
        // Push it big again, and fade it back in:
        let pulseInGroup = SKAction.group([
            SKAction.fadeAlpha(to: 1, duration: 1.5),
            SKAction.scale(to: 1, duration: 1.5),
            SKAction.rotate(byAngle: 3.5, duration: 1.5)
            ]);
        // Combine the two into a sequence:
        let pulseSequence = SKAction.sequence([pulseOutGroup, pulseInGroup])
        pulseAnimation = SKAction.repeatForever(pulseSequence)
    }
    
    func collect() {
        // Prevent further contact:
        self.physicsBody?.categoryBitMask = 0
        // Fade out, move up, and scale up the heart/NewLife at the same time:
        let collectAnimation = SKAction.group([
            SKAction.fadeAlpha(to: 0, duration: 0.2),
            SKAction.scale(to: 1.5, duration: 0.2),
            SKAction.move(by: CGVector(dx: 0, dy: 25), duration: 0.2)
            ])
        // After fading it out, move it out of the way until the encounter system wants to re-use it:
        let resetAfterCollected = SKAction.run {
            self.position.y = 10000
            self.alpha = 1
            self.xScale = 1
            self.yScale = 1
            self.physicsBody?.categoryBitMask = PhysicsCategory.poweruplife.rawValue
        }
        // Combine the actions into a sequence:
        let collectSequence = SKAction.sequence([
            collectAnimation,
            resetAfterCollected
            ])
        // Run the collect animation:
        self.run(collectSequence)
    }
    

    
    func onTap() {}
}
