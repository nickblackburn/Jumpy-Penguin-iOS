//
//  Background.swift
//  JumpyPenguin
//
//  Created by Nicholas Blackburn on 5/23/16.
//  Copyright © 2016 Nicholas Blackburn. All rights reserved.
//

import SpriteKit

class Background: SKSpriteNode {
    // movementMultiplier will store a value from 0-1 to indicate
    // how fast the background should move past.
    // 0 is full adjustment, no movement as the world goes past
    // 1 is no adjustment, background passes at normal speed
    var movementMultiplier = CGFloat(0)
    // Store a jump adjustment amount for looping with parallax positioning
    var jumpAdjustment = CGFloat(0)
    // Constant for background node size:
    let backgroundSize = CGSize(width: 1000, height: 1000)
    
    func spawn(_ parentNode:SKNode, imageName:String, zPosition:CGFloat, movementMultiplier:CGFloat) {
        // Position from the bottom left:
        self.anchorPoint = CGPoint.zero
        // Start backgrounds at the top of the ground (30 on the y-axis):
        self.position = CGPoint(x: 0, y: 30)
        // We can control the order of the backgrounds with zPosition:
        self.zPosition = zPosition
        // Store the movement multiplier:
        self.movementMultiplier = movementMultiplier
        // Add the background to the parentNode:
        parentNode.addChild(self)
        
        // Build three child node instances of the texture,
        // Looping from -1 to 1 so the backgrounds cover both
        // forward and behind the player at position zero.
        // The closed range operator, used here, includes both end points:
        for i in -1...1 {
            let newBGNode = SKSpriteNode(imageNamed: imageName)
            // Set the size for this node from our backgroundSize constant:
            newBGNode.size = backgroundSize
            // Position these nodes by their lower left corner:
            newBGNode.anchorPoint = CGPoint.zero
            // Position this background node:
            newBGNode.position = CGPoint(x: i * Int(backgroundSize.width), y: 0)
            // Add the node to the Background:
            self.addChild(newBGNode)
        }
    }
    
    // We will call updatePosition every update to
    // reposition the background:
    func updatePosition(_ playerProgress:CGFloat) {
        // Calculate a position adjustment after loops and parallax multiplier:
        let adjustedPosition = jumpAdjustment + playerProgress * (1 - movementMultiplier)
        // Check if we need to jump the background forward to loop it seamlessly:
        if playerProgress - adjustedPosition > backgroundSize.width {
            jumpAdjustment += backgroundSize.width
        }
        // Move this background forward to adjust for world movement back:
        self.position.x = adjustedPosition
    }
}
