//
//  Ground.swift
//  JumpyPenguin
//
//  Created by Nicholas Blackburn on 5/24/16.
//  Copyright © 2016 Nicholas Blackburn. All rights reserved.
//

import SpriteKit

class Ground: SKSpriteNode, GameSprite {
    var textureAtlas: SKTextureAtlas = SKTextureAtlas(named: "ground.atlas")
    var groundTexture: SKTexture?
    var jumpWidth = CGFloat()
    var jumpCount = CGFloat(1)
    
    func spawn(_ parentNode: SKNode, position: CGPoint, size: CGSize) {
        parentNode.addChild(self)
        self.size = size
        self.position = position
        self.zPosition = -1
        
        self.anchorPoint = CGPoint(x: 0, y: 1)
        
        if groundTexture == nil {
            groundTexture = textureAtlas.textureNamed("ice-tile.png")
        }
        
        createChildren()
        
        let pointTopRight = CGPoint(x: size.width,y: 0)
        self.physicsBody = SKPhysicsBody(edgeFrom: CGPoint.zero, to: pointTopRight)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.restitution = 0.1
        
        self.physicsBody?.categoryBitMask = PhysicsCategory.ground.rawValue
//        self.physicsBody?.collisionBitMask = ~PhysicsCategory.penguin.rawValue
        // unsure about having the ~ as a NOT bitwise operator for the penguin and ground collision
        self.physicsBody?.collisionBitMask = PhysicsCategory.penguin.rawValue | PhysicsCategory.damagedPenguin.rawValue
    }
    
    func createChildren() {
        if let texture = groundTexture {
            var tileCount:CGFloat = 0
            let textureSize = texture.size()
            let tileSize = CGSize(width: textureSize.width / 2,height: textureSize.height / 2)
            
            while tileCount * tileSize.width < self.size.width {
                let tileNode = SKSpriteNode(texture: texture)
                tileNode.size = tileSize
                tileNode.position.x = tileCount * tileSize.width
                tileNode.anchorPoint = CGPoint(x: 0,y: 1)
                self.addChild(tileNode)
                
                tileCount += 1
            }
            
            jumpWidth = tileSize.width * floor(tileCount / 3)
        }
    }
    
    func checkForReposition(_ playerProgress:CGFloat) {
        let groundJumpPosition = jumpWidth * jumpCount
        
        if playerProgress >= groundJumpPosition {
            self.position.x += jumpWidth
            jumpCount += 1
        }
    }
    
    func onTap() {
        
    }
}
