//
//  Ghost.swift
//  JumpyPenguin
//
//  Created by Nicholas Blackburn on 5/24/16.
//  Copyright © 2016 Nicholas Blackburn. All rights reserved.
//

import SpriteKit

class Ghost: SKSpriteNode, GameSprite {
    var textureAtlas:SKTextureAtlas = SKTextureAtlas(named:"enemies.atlas")
    var fadeAnimation = SKAction()
    
    var value = 10
    
    func spawn(_ parentNode:SKNode, position: CGPoint, size: CGSize = CGSize(width: 30, height: 44)) {
        parentNode.addChild(self)
        createAnimations()
        self.size = size
        self.position = position
        self.physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        self.physicsBody?.affectedByGravity = false
        self.texture = textureAtlas.textureNamed("ghost-frown.png")
        self.run(fadeAnimation)
        // Start the ghost semi-transparent:
        self.alpha = 0.8;
        
        self.physicsBody?.categoryBitMask = PhysicsCategory.enemy.rawValue
        self.physicsBody?.collisionBitMask = ~PhysicsCategory.damagedPenguin.rawValue
    }
    
    func createAnimations() {
        // Create a fade out action group:
        // The ghost becomes slightly smaller and more transparent.
        let fadeOutGroup = SKAction.group([
            SKAction.fadeAlpha(to: 0.3, duration: 2),
            SKAction.scale(to: 0.8, duration: 2)
            ]);
        // Create a fade in action group:
        // The ghost returns to full size and initial transparency.
        let fadeInGroup = SKAction.group([
            SKAction.fadeAlpha(to: 0.8, duration: 2),
            SKAction.scale(to: 1, duration: 2)
            ]);
        // Package the groups into a sequence, then a repeatActionForever action:
        let fadeSequence = SKAction.sequence([fadeOutGroup, fadeInGroup])
        fadeAnimation = SKAction.repeatForever(fadeSequence)
    }
    
    func collect() {
        // Prevent further contact:
        self.physicsBody?.categoryBitMask = 0
        // Fade out, move up, and scale up the Ghost at the same time:
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
            self.physicsBody?.categoryBitMask = PhysicsCategory.enemy.rawValue
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
